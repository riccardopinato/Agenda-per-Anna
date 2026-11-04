// STAGING SOURCE ONLY. Global, durable callback throttle shared by all Edge isolates.
// Never derive public quotas from caller-supplied IP headers; they can be spoofed.
// This protects token exchange/database state consumption, NOT the Edge ingress
// itself. An upstream verified-network limit is still required for flood defense.
const CALLBACKS_PER_MINUTE=30;
export class GcalStageCallbackBudget {
  constructor(sql) {
    if(typeof sql!=='function')throw Error('CALLBACK_BUDGET_SQL_NOT_CONFIGURED');
    this.sql=sql;
  }
  async consume() {
    const rows=await this.sql`
      insert into gcal_stage.oauth_callback_budget as budget
        (scope,window_start,request_count)
      values ('staging',date_trunc('minute',statement_timestamp()),1)
      on conflict (scope) do update
        set window_start=excluded.window_start,
            request_count=case
              when budget.window_start=excluded.window_start
              then budget.request_count+1 else 1 end
       where budget.window_start<>excluded.window_start
          or budget.request_count<${CALLBACKS_PER_MINUTE}
      returning request_count
    `;
    return rows.length===1;
  }
}
