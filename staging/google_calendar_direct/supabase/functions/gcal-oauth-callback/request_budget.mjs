// STAGING SOURCE ONLY: durable per-account throttle for authenticated OAuth operations.
// This is NOT a public-callback/IP flood limiter. Deploy only after the private
// gcal_staging_rate_budget_v1 migration and separate ingress rate-limit review.
import {sha256Hex} from './webcrypto_core.mjs';
const limits=Object.freeze({start:6,preview:30,confirm:8,disconnect:6,connections:20,calendars:10,events:6});
const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export class GcalStageRequestBudget {
  constructor(sql) {
    if(typeof sql!=='function')throw Error('BUDGET_SQL_NOT_CONFIGURED');
    this.sql=sql;
  }
  async consume(verifiedAccountId,action) {
    if(typeof verifiedAccountId!=='string'||!uuid.test(verifiedAccountId)||
       !Object.prototype.hasOwnProperty.call(limits,action))
      throw Error('BUDGET_INVALID_SCOPE');
    const accountHash=await sha256Hex('anna-staging-request-budget-v1:'+verifiedAccountId.toLowerCase());
    const limit=limits[action];
    // A single conflict-safe SQL statement works across Edge isolates. The
    // database clock owns the minute window; no user-supplied timestamps.
    const rows=await this.sql`
      insert into gcal_stage.oauth_request_budget as budget
        (app_account_hash,action,window_start,request_count)
      values (${accountHash},${action},date_trunc('minute',statement_timestamp()),1)
      on conflict (app_account_hash,action) do update
        set window_start=excluded.window_start,
            request_count=case
              when budget.window_start=excluded.window_start
              then budget.request_count+1 else 1 end
       where budget.window_start<>excluded.window_start
          or budget.request_count<${limit}
      returning request_count
    `;
    return rows.length===1;
  }
}
