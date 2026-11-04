// Staging-only Postgres completion-port adapter. Requires injected privileged,
// reviewed Postgres client. No embedded credentials or open DB connections.
import {GcalStageDbError} from './db_ports.mjs';
const bad=code=>{throw new GcalStageDbError(code);};
const isHash=x=>typeof x==='string'&&/^[0-9a-f]{64}$/.test(x);
const isEnvelope=x=>x?.v===1&&typeof x.iv==='string'&&x.iv.length<96&&
  typeof x.data==='string'&&x.data.length>10&&x.data.length<40000;
export class GcalStageConfirmationPorts {
  constructor(sql) {
    if(typeof sql!=='function'||typeof sql.json!=='function')bad('SQL_NOT_CONFIGURED');
    this.sql=sql;
  }
  async create(handleHash,accountHash,envelope,expiresAt) {
    if(!isHash(handleHash)||!isHash(accountHash))bad('INVALID_SCOPE');
    if(!isEnvelope(envelope))bad('INVALID_ENVELOPE');
    if(!Number.isInteger(expiresAt)||expiresAt<=0)bad('INVALID_EXPIRY');
    const rows=await this.sql`
      insert into gcal_stage.oauth_completions
        (handle_hash,app_account_hash,envelope,expires_at)
      values (${handleHash},${accountHash},${this.sql.json(envelope)},to_timestamp(${expiresAt}))
      on conflict (handle_hash) do nothing returning handle_hash
    `;
    return rows.length===1;
  }
  async read(handleHash,accountHash) {
    if(!isHash(handleHash)||!isHash(accountHash))bad('INVALID_SCOPE');
    const rows=await this.sql`
      select envelope from gcal_stage.oauth_completions
       where handle_hash=${handleHash} and app_account_hash=${accountHash}
        and expires_at>now()
    `;
    return rows[0]?.envelope??null;
  }
  async take(handleHash,accountHash) {
    if(!isHash(handleHash)||!isHash(accountHash))bad('INVALID_SCOPE');
    // Atomically consume only the authorized caller's confirmation.
    // Cross-account attempts cannot delete somebody else's pending grant.
    const rows=await this.sql`
      delete from gcal_stage.oauth_completions
       where handle_hash=${handleHash} and app_account_hash=${accountHash}
        and expires_at>now()
      returning envelope
    `;
    return rows[0]?.envelope??null;
  }
}
