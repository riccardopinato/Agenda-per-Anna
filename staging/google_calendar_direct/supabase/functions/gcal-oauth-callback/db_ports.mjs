// Only for a trusted staging Edge Function's privileged Postgres connection.
// Caller must inject a reviewed SQL tagged-template client (e.g. Postgres.js).
// This module NEVER opens a database connection on its own.
export class GcalStageDbError extends Error {
  constructor(code) {super('gcal staging db: '+code);this.code=code;}
}
const hashOk = x => typeof x==='string' && /^[0-9a-f]{64}$/.test(x);
const envelopeOk = x => x && x.v===1 && typeof x.iv==='string' &&
  typeof x.data==='string' && x.iv.length<96 && x.data.length<40000;
const check = (valid,code) => {if(!valid)throw new GcalStageDbError(code);};
export class GcalStagePostgresPorts {
  constructor(sql) {check(typeof sql==='function'&&typeof sql.json==='function','SQL_NOT_CONFIGURED');this.sql=sql;}
  async create(stateHash,envelope,expirySeconds) {
    check(hashOk(stateHash),'BAD_HASH');check(envelopeOk(envelope),'BAD_ENVELOPE');
    check(Number.isInteger(expirySeconds)&&expirySeconds>0,'BAD_EXPIRY');
    const rows=await this.sql`
      insert into gcal_stage.oauth_pending (state_hash,envelope,expires_at)
      values (${stateHash}, ${this.sql.json(envelope)}, to_timestamp(${expirySeconds}))
      on conflict (state_hash) do nothing returning state_hash
    `;
    return rows.length===1;
  }
  async take(stateHash) {
    check(hashOk(stateHash),'BAD_HASH');
    // Single SQL statement gives cross-instance atomic one-time consumption.
    const rows=await this.sql`
      delete from gcal_stage.oauth_pending
       where state_hash=${stateHash} and expires_at>now()
       returning envelope
    `;
    return rows[0]?.envelope??null;
  }
  async listLinks(accountHash) {
    check(hashOk(accountHash),'BAD_HASH');
    // Bound the decrypted result count: never enumerate another account.
    const rows=await this.sql`
      select google_subject_hash,envelope from gcal_stage.oauth_links
       where app_account_hash=${accountHash}
       order by google_subject_hash asc limit 11
    `;
    if(rows.length>10)throw new GcalStageDbError('TOO_MANY_LINKS');
    return rows;
  }
  async getLink(accountHash,subjectHash) {
    check(hashOk(accountHash)&&hashOk(subjectHash),'BAD_HASH');
    const rows=await this.sql`
      select envelope from gcal_stage.oauth_links
       where app_account_hash=${accountHash} and google_subject_hash=${subjectHash}
    `;
    return rows[0]?.envelope??null;
  }
  async replaceLink(accountHash,subjectHash,prior,next) {
    check(hashOk(accountHash)&&hashOk(subjectHash),'BAD_HASH');
    check(envelopeOk(prior)&&envelopeOk(next),'BAD_ENVELOPE');
    // Optimistic compare-and-swap prevents stale refresh writing after unlink.
    const rows=await this.sql`
      update gcal_stage.oauth_links set envelope=${this.sql.json(next)},updated_at=now()
       where app_account_hash=${accountHash} and google_subject_hash=${subjectHash}
         and envelope=${this.sql.json(prior)}
       returning app_account_hash
    `;
    return rows.length===1;
  }
  async takeLink(accountHash,subjectHash) {
    check(hashOk(accountHash)&&hashOk(subjectHash),'BAD_HASH');
    const rows=await this.sql`
      delete from gcal_stage.oauth_links
       where app_account_hash=${accountHash} and google_subject_hash=${subjectHash}
       returning envelope
    `;
    return rows[0]?.envelope??null;
  }
  async put(accountHash,subjectHash,envelope) {
    check(hashOk(accountHash)&&hashOk(subjectHash),'BAD_HASH');
    check(envelopeOk(envelope),'BAD_ENVELOPE');
    await this.sql`
      insert into gcal_stage.oauth_links
        (app_account_hash,google_subject_hash,envelope)
      values (${accountHash},${subjectHash},${this.sql.json(envelope)})
      on conflict (app_account_hash,google_subject_hash)
      do update set envelope=excluded.envelope,updated_at=now()
    `;
  }
}
