import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalStageCallbackBudget} from './callback_budget.mjs';

test('public callback quota uses a shared durable atomic database row, no spoofable IP',async()=>{
  const calls=[];
  const sql=(strings,...params)=>{
    calls.push({query:strings.join('?'),params});
    return Promise.resolve([{request_count:1}]);
  };
  const budget=new GcalStageCallbackBudget(sql);
  assert.equal(await budget.consume(),true);
  assert.equal(calls.length,1);
  assert.match(calls[0].query,/insert into gcal_stage\.oauth_callback_budget/);
  assert.match(calls[0].query,/values \('staging',date_trunc\('minute',statement_timestamp\(\)\),1\)/);
  assert.match(calls[0].query,/on conflict \(scope\) do update/);
  assert.match(calls[0].query,/where budget.window_start<>excluded.window_start/);
  assert.deepEqual(calls[0].params,[30]);
});
test('no quota or DB outage is fail-closed, never unlimited in-memory fallback',async()=>{
  const budget=new GcalStageCallbackBudget(()=>Promise.resolve([]));
  assert.equal(await budget.consume(),false);
  const broken=new GcalStageCallbackBudget(()=>{throw Error('STAGING_DB_UNAVAILABLE');});
  await assert.rejects(broken.consume(),/STAGING_DB_UNAVAILABLE/);
  assert.throws(()=>new GcalStageCallbackBudget(null),/CALLBACK_BUDGET_SQL_NOT_CONFIGURED/);
});
