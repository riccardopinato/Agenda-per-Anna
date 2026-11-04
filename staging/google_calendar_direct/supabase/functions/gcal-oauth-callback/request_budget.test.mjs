import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalStageRequestBudget} from './request_budget.mjs';
const UUID='c16e0ec0-415c-4e53-a488-5c6ed75d2662';
test('rate budget uses one atomic backend-only statement and account hashes',async()=>{
 const calls=[];
 const sql=(parts,...params)=>{
   calls.push({query:parts.join('?'),params});
   return Promise.resolve([{request_count:1}]);
 };
 const port=new GcalStageRequestBudget(sql);
 assert.equal(await port.consume(UUID,'start'),true);
 assert.equal(calls.length,1);
 assert.match(calls[0].query,/insert into gcal_stage\.oauth_request_budget/);
 assert.match(calls[0].query,/on conflict \(app_account_hash,action\) do update/);
 assert.match(calls[0].query,/statement_timestamp\(\)/);
 assert.match(calls[0].query,/where budget.window_start<>excluded.window_start/);
 assert.equal(calls[0].params.includes(UUID),false);
 assert.equal(calls[0].params[1],'start');
 assert.equal(calls[0].params[2],6);
 assert.match(calls[0].params[0],/^[0-9a-f]{64}$/);
});
test('rate budget denies excessive attempts without bypassing via route spelling',async()=>{
 let calls=0;
 const sql=()=>{calls++;return Promise.resolve([]);};
 const port=new GcalStageRequestBudget(sql);
 assert.equal(await port.consume(UUID,'confirm'),false);
 assert.equal(calls,1);
 await assert.rejects(port.consume(UUID,'CONFIRM'),/BUDGET_INVALID_SCOPE/);
 await assert.rejects(port.consume('not-an-account','start'),/BUDGET_INVALID_SCOPE/);
 await assert.rejects(port.consume(UUID,'callback'),/BUDGET_INVALID_SCOPE/);
 assert.equal(calls,1);
});
test('rate budget propagates database outages for fail-closed HTTP handling',async()=>{
 const port=new GcalStageRequestBudget(()=>{throw Error('DB_UNAVAILABLE');});
 await assert.rejects(port.consume(UUID,'preview'),/DB_UNAVAILABLE/);
 assert.throws(()=>new GcalStageRequestBudget(null),/BUDGET_SQL_NOT_CONFIGURED/);
});
