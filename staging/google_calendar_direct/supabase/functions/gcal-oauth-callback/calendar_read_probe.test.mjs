import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalStageCalendarReadProbe} from './calendar_read_probe.mjs';
const account='account-uuid-fixture',subject='google-subject-fixture';
const port={accessToken:async args=>{
  assert.deepEqual(args,{verifiedAccountId:account,googleSubject:subject});
  return 'MOCK_SERVER_ONLY_TOKEN';
}};
test('reads Google calendar list using server token, never returns token',async()=>{
  let requests=0;
  const probe=new GcalStageCalendarReadProbe({tokenLifecycle:port,fetcher:async(url,opts)=>{
    requests++;
    const u=new URL(url);
    assert.equal(u.origin,'https://www.googleapis.com');
    assert.equal(u.pathname,'/calendar/v3/users/me/calendarList');
    assert.equal(u.searchParams.get('maxResults'),'25');
    assert.equal(opts.method,'GET');
    assert.equal(opts.redirect,'error');
    assert.equal(opts.headers.authorization,'Bearer MOCK_SERVER_ONLY_TOKEN');
    return new Response(JSON.stringify({items:[
      {id:'primary',summary:'Personale',primary:true,accessRole:'owner'},
      {id:'other',summary:'Lavoro',accessRole:'reader'}
    ]}),{status:200,headers:{'content-type':'application/json'}});
  }});
  const result=await probe.calendars({verifiedAccountId:account,googleSubject:subject});
  assert.deepEqual(result,{readonly:true,calendars:[
    {id:'primary',name:'Personale',primary:true,accessRole:'owner'},
    {id:'other',name:'Lavoro',primary:false,accessRole:'reader'}
  ]});
  assert.equal(JSON.stringify(result).includes('MOCK_SERVER_ONLY_TOKEN'),false);
  assert.equal(requests,1);
});
test('rejects provider error, oversized body and malformed entries without leakage',async()=>{
  for(const response of [
    new Response('private error 401',{status:401}),
    new Response(JSON.stringify({items:[{id:'x',summary:123}]}),{status:200}),
    new Response('x'.repeat(140000),{status:200}),
  ]){
    const probe=new GcalStageCalendarReadProbe({tokenLifecycle:port,fetcher:async()=>response});
    await assert.rejects(probe.calendars({verifiedAccountId:account,googleSubject:subject}),
      /CALENDAR_READ_UNAVAILABLE/);
  }
});
test('rejects missing verified account and does not fetch Google',async()=>{
  let calls=0;
  const probe=new GcalStageCalendarReadProbe({tokenLifecycle:port,fetcher:async()=>{
    calls++;throw Error('should not happen');
  }});
  await assert.rejects(probe.calendars({verifiedAccountId:'',googleSubject:subject}),
    /CALENDAR_READ_UNAVAILABLE/);
  assert.equal(calls,0);
});
