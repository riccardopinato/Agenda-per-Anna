import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalStageEventsReadProbe} from './events_read_probe.mjs';
const account='TEST_APP_ACCOUNT_UUID',subject='TEST_GOOGLE_SUB',calendarId='own@gmail.com';
const since='2026-11-01T00:00:00.000Z',until='2026-12-01T00:00:00.000Z';
function fixture({role='owner',items,token='PRIVATE_TEST_TOKEN',fetcher}={}){
  const calls={list:0,token:0,google:0};
  const list={
    async calendars({verifiedAccountId,googleSubject}){
      calls.list++;assert.equal(verifiedAccountId,account);assert.equal(googleSubject,subject);
      return {calendars:[{id:calendarId,accessRole:role}]};
    },
  };
  const lifecycle={async accessToken(){
    calls.token++;return token;
  }};
  const provider=fetcher??(async (url,options)=>{
    calls.google++;
    const u=new URL(url);
    assert.equal(u.origin,'https://www.googleapis.com');
    assert.equal(u.pathname,'/calendar/v3/calendars/'+encodeURIComponent(calendarId)+'/events');
    assert.equal(u.searchParams.get('timeMin'),since);
    assert.equal(u.searchParams.get('timeMax'),until);
    assert.equal(u.searchParams.get('singleEvents'),'true');
    assert.equal(u.searchParams.get('orderBy'),'startTime');
    assert.equal(u.searchParams.get('showDeleted'),'false');
    assert.equal(u.searchParams.get('maxResults'),'60');
    assert.equal(options.method,'GET');
    assert.equal(options.redirect,'error');
    assert.equal(options.headers.authorization,'Bearer '+token);
    return new Response(JSON.stringify({items:items??[
      {id:'ev-one',summary:'Dentista',start:{dateTime:'2026-11-10T14:00:00+01:00'},end:{dateTime:'2026-11-10T14:30:00+01:00'},iCalUID:'uid@google'},
      {id:'holiday',summary:'Festività',start:{date:'2026-11-12'},end:{date:'2026-11-13'}},
      {id:'cancelled',status:'cancelled',start:{date:'2026-11-12'},end:{date:'2026-11-13'}},
    ]}),{status:200});
  });
  return {probe:new GcalStageEventsReadProbe({
    tokenLifecycle:lifecycle,calendarReadProbe:list,fetcher:provider}),calls};
}
test('owner-only GET returns bounded sanitized time-aware events and stable identifiers',async()=>{
  const f=fixture();
  const data=await f.probe.events({
    verifiedAccountId:account,googleSubject:subject,calendarId,
    timeMin:since,timeMax:until,
  });
  assert.equal(data.readonly,true);
  assert.equal(data.truncated,false);
  assert.equal(data.events.length,2);
  assert.deepEqual(data.events[0],{
    eventId:'ev-one',title:'Dentista',start:'2026-11-10T13:00:00.000Z',
    end:'2026-11-10T13:30:00.000Z',allDay:false,
    recurringEventId:null,iCalUID:'uid@google',
  });
  assert.equal(data.events[1].allDay,true);
  assert.equal(data.events[1].end,'2026-11-13');
  assert.deepEqual(f.calls,{list:1,token:1,google:1});
  assert(!JSON.stringify(data).includes('PRIVATE_TEST_TOKEN'));
});
test('reader-only calendar is excluded by granted owner scope before any token use',async()=>{
 const f=fixture({role:'reader'});
 await assert.rejects(f.probe.events({
  verifiedAccountId:account,googleSubject:subject,calendarId,
  timeMin:since,timeMax:until,
 }),/EVENTS_OWNER_ONLY/);
 assert.deepEqual(f.calls,{list:1,token:0,google:0});
});
test('invalid window and arbitrary calendars fail closed',async()=>{
 const f=fixture();
 for(const args of [
  {timeMin:until,timeMax:since},{timeMin:since,timeMax:'2027-03-01T00:00:00.000Z'},
  {timeMin:'not-a-date',timeMax:until},
 ]){
  await assert.rejects(f.probe.events({
   verifiedAccountId:account,googleSubject:subject,calendarId,...args
  }),/EVENTS_INVALID/);
 }
 assert.deepEqual(f.calls,{list:0,token:0,google:0});
});
test('owner calendar event body is limited and paginated results disclose incompleteness',async()=>{
 const provider=async()=>new Response(JSON.stringify({
  items:[{id:'x',summary:'A',start:{date:'2026-11-01'},end:{date:'2026-11-02'}}],
  nextPageToken:'next-private-page-token'
 }),{status:200});
 const f=fixture({fetcher:provider});
 const data=await f.probe.events({
  verifiedAccountId:account,googleSubject:subject,calendarId,
  timeMin:since,timeMax:until
 });
 assert.equal(data.truncated,true);
 assert.equal(JSON.stringify(data).includes('next-private-page-token'),false);
 const huge=fixture({fetcher:async()=>new Response('Z'.repeat(70000),{status:200})});
 await assert.rejects(huge.probe.events({
  verifiedAccountId:account,googleSubject:subject,calendarId,
  timeMin:since,timeMax:until}),/EVENTS_UNAVAILABLE/);
});
test('never sends a Google write operation even when provider returns an error',async()=>{
 const f=fixture({fetcher:async(url,opts)=>{
  assert.equal(opts.method,'GET');
  assert.equal(url.startsWith('https://www.googleapis.com/calendar/v3/calendars/'),true);
  return new Response('{"error":"private-provider-message"}',{status:403});
 }});
 await assert.rejects(f.probe.events({
  verifiedAccountId:account,googleSubject:subject,calendarId,
  timeMin:since,timeMax:until
 }),/EVENTS_UNAVAILABLE/);
});