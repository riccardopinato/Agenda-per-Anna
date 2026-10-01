-- v0.86 shared-password backend contract verification.
-- Run only after loading migration 027 in the same transaction or on a DB
-- where migration 027 is already applied. The entire script rolls back.

begin;

do $$
declare
  v_user_a uuid;
  v_user_b uuid;
begin
  select u.id
    into v_user_a
  from auth.users u
  order by u.created_at
  limit 1;

  select u.id
    into v_user_b
  from auth.users u
  where u.id is distinct from v_user_a
  order by u.created_at
  limit 1;

  if v_user_a is null or v_user_b is null then
    raise exception 'shared_password_contract_requires_two_auth_users';
  end if;

  perform set_config('annas_diary.test_user_a', v_user_a::text, true);
  perform set_config('annas_diary.test_user_b', v_user_b::text, true);
end;
$$;

set local role authenticated;

do $$
declare
  v_user_a uuid := current_setting('annas_diary.test_user_a')::uuid;
  v_user_b uuid := current_setting('annas_diary.test_user_b')::uuid;
  v_space uuid;
  v_invite text;
  v_claim jsonb;
  v_mutation jsonb;
  v_envelope jsonb;
  v_envelope_id text := repeat('e', 64);
  v_payload jsonb := jsonb_build_object(
    'v', 1,
    'cipher', 'AES-256-GCM',
    'nonce', 'AAAAAAAAAAAAAAAA',
    'data', 'BBBBBBBBBBBBBBBBBBBB'
  );
  v_failed boolean;
begin
  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', v_user_a::text,
      'role', 'authenticated'
    )::text,
    true
  );

  v_space := public.create_shared_space('v086-contract-test');
  v_invite := public.create_space_invite(v_space);

  v_claim := public.claim_shared_password_key_meta(
    v_space,
    repeat('a', 64)
  );
  if coalesce((v_claim ->> 'claimed')::boolean, false) is not true
     or v_claim ->> 'fingerprint' <> repeat('a', 64) then
    raise exception 'key_claim_first_writer_failed';
  end if;

  v_claim := public.claim_shared_password_key_meta(
    v_space,
    repeat('b', 64)
  );
  if coalesce((v_claim ->> 'claimed')::boolean, true) is not false
     or v_claim ->> 'fingerprint' <> repeat('a', 64) then
    raise exception 'key_claim_not_atomic';
  end if;

  perform public.upsert_shared_password_key_envelope(
    v_space,
    v_envelope_id,
    jsonb_build_object(
      'v', 1,
      'salt', 'AAAAAAAAAAAAAAAAAAAAAA==',
      'wrapped', jsonb_build_object(
        'nonce', 'AAAAAAAAAAAAAAAA',
        'data', 'BBBBBBBBBBBBBBBBBBBB'
      ),
      'expiresAt', (clock_timestamp() + interval '15 minutes')::text
    ),
    clock_timestamp()
  );

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', v_user_b::text,
      'role', 'authenticated'
    )::text,
    true
  );

  perform public.join_shared_space(v_invite);

  v_failed := false;
  begin
    perform public.upsert_shared_password_key_envelope(
      v_space,
      repeat('f', 64),
      jsonb_build_object(
        'v', 1,
        'salt', 'AAAAAAAAAAAAAAAAAAAAAA==',
        'wrapped', jsonb_build_object(
          'nonce', 'AAAAAAAAAAAAAAAA',
          'data', 'BBBBBBBBBBBBBBBBBBBB'
        ),
        'expiresAt', (clock_timestamp() + interval '15 minutes')::text
      ),
      clock_timestamp()
    );
  exception
    when others then
      if position('shared_password_key_owner_required' in sqlerrm) > 0 then
        v_failed := true;
      else
        raise;
      end if;
  end;
  if not v_failed then
    raise exception 'non_owner_pairing_envelope_was_not_rejected';
  end if;

  v_envelope := public.consume_shared_password_key_envelope(
    v_space,
    v_envelope_id
  );
  if coalesce(v_envelope ->> 'salt', '') = '' then
    raise exception 'pairing_envelope_first_consume_failed';
  end if;

  v_failed := false;
  begin
    perform public.consume_shared_password_key_envelope(
      v_space,
      v_envelope_id
    );
  exception
    when others then
      if position('shared_password_pairing_code_unavailable' in sqlerrm) > 0 then
        v_failed := true;
      else
        raise;
      end if;
  end;
  if not v_failed then
    raise exception 'pairing_envelope_was_consumed_twice';
  end if;

  v_failed := false;
  begin
    perform public.claim_shared_password_key_meta(
      v_space,
      repeat('c', 64)
    );
  exception
    when others then
      if position('shared_password_key_owner_required' in sqlerrm) > 0 then
        v_failed := true;
      else
        raise;
      end if;
  end;
  if not v_failed then
    raise exception 'non_owner_key_claim_was_not_rejected';
  end if;

  v_mutation := public.upsert_shared_password_credential(
    v_space,
    'credential-contract',
    v_payload,
    0,
    '2100-01-01T00:00:00Z'::timestamptz
  );
  if (v_mutation ->> 'revision')::bigint <> 1 then
    raise exception 'initial_revision_not_one';
  end if;
  if (v_mutation ->> 'clientUpdatedAt')::timestamptz >
      clock_timestamp() + interval '5 minutes' then
    raise exception 'shared_password_timestamp_not_server_authoritative';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', v_user_a::text,
      'role', 'authenticated'
    )::text,
    true
  );

  v_failed := false;
  begin
    perform public.upsert_shared_password_credential(
      v_space,
      'credential-contract',
      v_payload,
      0,
      clock_timestamp()
    );
  exception
    when sqlstate '40001' then
      v_failed := true;
  end;
  if not v_failed then
    raise exception 'stale_update_was_not_rejected';
  end if;

  v_mutation := public.upsert_shared_password_credential(
    v_space,
    'credential-contract',
    v_payload,
    1,
    clock_timestamp()
  );
  if (v_mutation ->> 'revision')::bigint <> 2 then
    raise exception 'second_revision_not_two';
  end if;

  v_failed := false;
  begin
    perform public.merge_agenda_record(
      v_space::text || ':shared:shared_credential:credential-contract',
      v_user_a,
      v_space,
      'shared',
      'shared_credential',
      'credential-contract',
      v_payload || jsonb_build_object('revision', 3),
      clock_timestamp(),
      null
    );
  exception
    when others then
      if position('shared_password_dedicated_rpc_required' in sqlerrm) > 0 then
        v_failed := true;
      else
        raise;
      end if;
  end;
  if not v_failed then
    raise exception 'generic_merge_bypass_was_not_rejected';
  end if;

  v_failed := false;
  begin
    perform public.merge_agenda_record(
      v_space::text || ':shared:shared_password_key_envelope:' || repeat('d', 64),
      v_user_a,
      v_space,
      'shared',
      'shared_password_key_envelope',
      repeat('d', 64),
      jsonb_build_object(
        'v', 1,
        'salt', 'AAAAAAAAAAAAAAAAAAAAAA==',
        'wrapped', jsonb_build_object(
          'nonce', 'AAAAAAAAAAAAAAAA',
          'data', 'BBBBBBBBBBBBBBBBBBBB'
        ),
        'expiresAt', (clock_timestamp() + interval '15 minutes')::text
      ),
      clock_timestamp(),
      null
    );
  exception
    when others then
      if position('shared_password_dedicated_rpc_required' in sqlerrm) > 0 then
        v_failed := true;
      else
        raise;
      end if;
  end;
  if not v_failed then
    raise exception 'generic_envelope_merge_bypass_was_not_rejected';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', v_user_b::text,
      'role', 'authenticated'
    )::text,
    true
  );

  v_failed := false;
  begin
    perform public.delete_shared_password_credential(
      v_space,
      'credential-contract',
      1
    );
  exception
    when sqlstate '40001' then
      v_failed := true;
  end;
  if not v_failed then
    raise exception 'stale_delete_was_not_rejected';
  end if;

  v_mutation := public.delete_shared_password_credential(
    v_space,
    'credential-contract',
    2
  );
  if (v_mutation ->> 'revision')::bigint <> 3 then
    raise exception 'delete_revision_not_three';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', v_user_a::text,
      'role', 'authenticated'
    )::text,
    true
  );
  perform public.remove_shared_space_member(v_space, v_user_b);

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', v_user_b::text,
      'role', 'authenticated'
    )::text,
    true
  );

  v_failed := false;
  begin
    perform public.upsert_shared_password_credential(
      v_space,
      'another-credential',
      v_payload,
      0,
      clock_timestamp()
    );
  exception
    when others then
      if position('shared_space_membership_required' in sqlerrm) > 0 then
        v_failed := true;
      else
        raise;
      end if;
  end;
  if not v_failed then
    raise exception 'removed_member_was_not_rejected';
  end if;

  raise notice 'v0.86 shared-password backend contract PASS';
end;
$$;

reset role;
rollback;
