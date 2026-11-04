import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalStagePostgresPorts,GcalStageDbError} from './db_ports.mjs';
// The CI job for this test file also runs the new source-only lifecycle cases.
import './token_lifecycle.test.mjs';
function fixture() {
  const calls=[];
  const sql=(strings,...values)=>{calls.push({query:strings.join('?'),values});return Promise.resolve(
    calls.length===1?[{state_hash:'x'.repeat(64)}]:[]);};
  sql.json=value=>({json:value});
  return {port:new GcalStagePostgresPorts(sql),calls};
}
const hash='a'.repeat(64),envelope={v:1,iv:'abc',data:'encrypted'};
test('create validates and inserts only encrypted state',async()=>{
  const {port,calls}=fixture(); assert.equal(await port.create(hash,envelope,1793700600),true);
  assert.match(calls[0].query,/insert into gcal_stage\.oauth_pending/);
  assert.match(calls[0].query,/on conflict \(state_hash\) do nothing/);
  assert.deepEqual(calls[0].values[1],{json:envelope});
  assert.equal(calls[0].values[0],hash);
});
test('take atomically consumes state with DELETE RETURNING',async()=>{
  const {port,calls}=fixture();assert.equal(await port.take(hash),null);
  assert.match(calls[0].query,/delete from gcal_stage\.oauth_pending/);
  assert.match(calls[0].query,/expires_at>now\(\)/);
  assert.match(calls[0].query,/returning envelope/);
});
test('link upsert stores only ciphertext in private schema',async()=>{
  const {port,calls}=fixture();await port.put(hash,'b'.repeat(64),envelope);
  assert.match(calls[0].query,/gcal_stage\.oauth_links/);
  assert.match(calls[0].query,/on conflict \(app_account_hash,google_subject_hash\)/);
  assert.deepEqual(calls[0].values[2],{json:envelope});
});
test('reject unhashed owner IDs and plaintext or missing envelopes',async()=>{
  const {port,calls}=fixture();
  await assert.rejects(port.put('my-account','google-user',envelope),GcalStageDbError);
  await assert.rejects(port.create(hash,{token:'plaintext'},1793700600),GcalStageDbError);
  await assert.rejects(port.create(hash,envelope,-1),GcalStageDbError);
  assert.equal(calls.length,0);
});


test('link lifecycle uses owner-scoped read, CAS replacement and atomic unlink',async()=>{
  let f=fixture();
  assert.equal(await f.port.getLink(hash,'b'.repeat(64)),null);
  assert.match(f.calls[0].query,/select envelope from gcal_stage\.oauth_links/);
  assert.match(f.calls[0].query,/app_account_hash=\?/);
  f=fixture();
  assert.equal(await f.port.replaceLink(hash,'b'.repeat(64),envelope,
    {v:1,iv:'new',data:'more-ciphertext'}),true);
  assert.match(f.calls[0].query,/update gcal_stage\.oauth_links/);
  assert.match(f.calls[0].query,/and envelope=\?/);
  assert.match(f.calls[0].query,/returning app_account_hash/);
  f=fixture();
  assert.equal(await f.port.takeLink(hash,'b'.repeat(64)),null);
  assert.match(f.calls[0].query,/delete from gcal_stage\.oauth_links/);
  assert.match(f.calls[0].query,/returning envelope/);
  await assert.rejects(f.port.takeLink('invalid','b'.repeat(64)),GcalStageDbError);
});
