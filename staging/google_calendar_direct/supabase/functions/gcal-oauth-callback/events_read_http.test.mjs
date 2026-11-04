import test from 'node:test';
import assert from 'node:assert/strict';
import {createGoogleCalendarStagingHandler} from './http_handler.mjs';
const base='https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';
const account='test-verified-app-account',subject='test-google-sub';
function fixture({enabled=true,readProbe}={}){
  let called=0,budget=0;
  const handler=createGoogleCalendarStagingHandler({
    enabled,broker:{},verifyAppIdentity:async header=>{
      if(header!=='Bearer TEST_JWT')throw Error('AUTH_FAILED');
      return {accountId:account};
    },
    requestBudget:{async consume(a,action){
      assert.equal(a,account);assert.equal(action,'events');budget++;return true;
    }},
    callbackBudget:{async consume(){return true;}},
    eventsReadProbe:readProbe??{async events(args){
      called++;
      assert.deepEqual(args,{
        verifiedAccountId:account,googleSubject:subject,
        calendarId:'owner@example.com',
        timeMin:'2026-11-01T00:00:00.000Z',
        timeMax:'2026-12-01T00:00:00.000Z',
      });
      return {readonly:true,calendarId:args.calendarId,events:[],truncated:false};
    }},
  });
  return {handler,get called(){return called;},get budget(){return budget;}};
}
const valid={
  googleSubject:subject,calendarId:'owner@example.com',
  timeMin:'2026-11-01T00:00:00.000Z',
  timeMax:'2026-12-01T00:00:00.000Z',
};
function post(body=valid,auth='Bearer TEST_JWT'){
  return new Request(base+'/events',{method:'POST',headers:{
    'content-type':'application/json',authorization:auth,
  },body:JSON.stringify(body)});
}
test('read route enforces app JWT and exact fields before Google',async()=>{
 const f=fixture();
 let r=await f.handler(post(valid,'Bearer WRONG'));
 assert.equal(r.status,401);assert.equal(f.called,0);assert.equal(f.budget,0);
 r=await f.handler(post({...valid,description:'PRIVATE_LOCAL_DIARY'}));
 assert.equal(r.status,400);assert.equal(f.called,0);
 r=await f.handler(post(valid));
 assert.equal(r.status,200);
 assert.deepEqual(await r.json(),{readonly:true,calendarId:valid.calendarId,events:[],truncated:false});
 assert.equal(f.called,1);
 assert.equal(r.headers.get('cache-control'),'no-store, max-age=0');
});
test('locked staging never reaches provider',async()=>{
 const f=fixture({enabled:false});
 const r=await f.handler(post());
 assert.equal(r.status,503);assert.equal(f.called,0);
 assert.deepEqual(await r.json(),{error:'STAGING_NOT_ACTIVATED'});
});
test('non-owned calendar and malformed windows produce only whitelisted errors',async()=>{
 for(const [error,status,code] of [
  ['EVENTS_OWNER_ONLY',403,'EVENTS_OWNER_ONLY'],
  ['EVENTS_INVALID_WINDOW',400,'EVENTS_INVALID_INPUT'],
  ['SECRET_PROVIDER_ERROR',503,'EVENTS_UNAVAILABLE'],
 ]){
  const f=fixture({readProbe:{async events(){throw Error(error);}}});
  const r=await f.handler(post());
  assert.equal(r.status,status);
  assert.deepEqual(await r.json(),{error:code});
  assert(!JSON.stringify(await r.headers).includes('SECRET_PROVIDER_ERROR'));
 }
});
test('event mutation fields are rejected rather than acted upon',async()=>{
 const f=fixture();
 for(const key of ['action','updates','event','newEvents','overwrite','description']){
  const r=await f.handler(post({...valid,[key]:'WRITE'}));
  assert.equal(r.status,400);assert.equal(f.called,0);
 }
});
