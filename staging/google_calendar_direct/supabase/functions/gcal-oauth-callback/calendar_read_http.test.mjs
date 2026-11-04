import test from 'node:test';
import assert from 'node:assert/strict';
import {createGoogleCalendarStagingHandler} from './http_handler.mjs';
const base='https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';
const account='sample-production-account-uuid';
const subject='sample-google-subject';
function makeHandler({locked=false,calendarReadProbe,identity=true}={}) {
  return createGoogleCalendarStagingHandler({
    enabled:!locked,
    broker:{},
    verifyAppIdentity:async header=>{
      if(!identity||header!=='Bearer TEST_PRODUCTION_JWT')throw Error('wrong session');
      return {accountId:account};
    },
    requestBudget:{async consume(a,action){
      assert.equal(a,account);
      assert.equal(action,'calendars');
      return true;
    }},
    callbackBudget:{consume:async()=>true},
    calendarReadProbe,
    allowedWebOrigins:['https://riccardopinato.github.io'],
  });
}
const req=(body={},auth='Bearer TEST_PRODUCTION_JWT')=>
  new Request(base+'/calendars',{
    method:'POST',
    headers:{'content-type':'application/json','authorization':auth},
    body:JSON.stringify(body),
  });
test('read-only calendar list requires real app auth and returns whitelisted metadata',async()=>{
  let calls=0;
  const handler=makeHandler({calendarReadProbe:{async calendars(args){
    calls++;assert.deepEqual(args,{verifiedAccountId:account,googleSubject:subject});
    return {readonly:true,calendars:[{id:'primary',name:'Personale',
      primary:true,accessRole:'owner'}]};
  }}});
  let response=await handler(req({googleSubject:subject},'Bearer WRONG'));
  assert.equal(response.status,401);
  assert.equal(calls,0);
  response=await handler(req({googleSubject:subject,includeTokens:true}));
  assert.equal(response.status,400);
  assert.equal(calls,0);
  response=await handler(req({googleSubject:subject}));
  assert.equal(response.status,200);
  const body=await response.json();
  assert.equal(body.readonly,true);
  assert.equal(body.calendars.length,1);
  assert.equal(JSON.stringify(body).includes('TEST_PRODUCTION_JWT'),false);
  assert.equal(response.headers.get('cache-control'),'no-store, max-age=0');
  assert.equal(calls,1);
});
test('locked public staging never calls Google calendar probe',async()=>{
  let called=false;
  const handler=makeHandler({locked:true,calendarReadProbe:{
    async calendars(){called=true;throw Error('SHOULD_NOT_BE_CALLED');}
  }});
  const response=await handler(req({googleSubject:subject}));
  assert.equal(response.status,503);
  assert.deepEqual(await response.json(),{error:'STAGING_NOT_ACTIVATED'});
  assert.equal(called,false);
});
test('calendars route disabled without server-only provider adapter',async()=>{
  const handler=makeHandler();
  const r=await handler(req({googleSubject:subject}));
  assert.equal(r.status,503);
  assert.deepEqual(await r.json(),{error:'CALENDAR_READ_NOT_READY'});
});
