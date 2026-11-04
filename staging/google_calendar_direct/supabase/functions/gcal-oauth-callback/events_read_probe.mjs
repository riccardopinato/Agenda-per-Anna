// Anna's Diary Google Calendar STAGING: bounded, owner-only event preview.
// GET-only provider access. NEVER persist Google event content or send tokens to Flutter.
const EVENTS_ROOT='https://www.googleapis.com/calendar/v3/calendars/';
const MAX_RESPONSE_BYTES=65536, MAX_EVENTS=60;
const dateOnly=/^\d{4}-\d{2}-\d{2}$/;
const isoUtc=/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,3})?Z$/;
const validText=(v,max)=>typeof v==='string'&&v.length>0&&v.length<=max;
function fail(code){throw Error(code);}
async function boundedJson(response){
  const size=Number(response.headers?.get?.('content-length')??0);
  if(!Number.isFinite(size)||size<0||size>MAX_RESPONSE_BYTES)fail('EVENTS_UNAVAILABLE');
  const reader=response.body?.getReader();
  if(!reader)fail('EVENTS_UNAVAILABLE');
  let sizeRead=0;
  const chunks=[];
  try{
    while(true){
      const {done,value}=await reader.read();
      if(done)break;
      sizeRead+=value?.byteLength??0;
      if(sizeRead>MAX_RESPONSE_BYTES)fail('EVENTS_UNAVAILABLE');
      chunks.push(value);
    }
  }catch{fail('EVENTS_UNAVAILABLE');}
  finally{reader.releaseLock();}
  const bytes=new Uint8Array(sizeRead);let offset=0;
  for(const chunk of chunks){bytes.set(chunk,offset);offset+=chunk.byteLength;}
  try{return JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(bytes));}
  catch{fail('EVENTS_UNAVAILABLE');}
}
function safeDate(date){
  return dateOnly.test(date)&&!Number.isNaN(Date.parse(date+'T00:00:00Z'))&&
    new Date(date+'T00:00:00Z').toISOString().slice(0,10)===date;
}
function parseEvent(raw){
  if(!validText(raw?.id,1024)||raw.status==='cancelled')return null;
  const start=raw.start,end=raw.end;
  const allDay=typeof start?.date==='string'&&typeof end?.date==='string';
  let begins,ends;
  if(allDay){
    if(!safeDate(start.date)||!safeDate(end.date)||end.date<=start.date)return null;
    begins=start.date;ends=end.date; // Exclusive end for all-day Google events.
  }else{
    if(!validText(start?.dateTime,80)||!validText(end?.dateTime,80))return null;
    const from=Date.parse(start.dateTime),to=Date.parse(end.dateTime);
    if(!Number.isFinite(from)||!Number.isFinite(to)||to<=from)return null;
    begins=new Date(from).toISOString();ends=new Date(to).toISOString();
  }
  return {
    eventId:raw.id,
    title:typeof raw.summary==='string'?raw.summary.slice(0,300):'Senza titolo',
    start:begins,end:ends,allDay,
    recurringEventId:validText(raw.recurringEventId,1024)?raw.recurringEventId:null,
    iCalUID:validText(raw.iCalUID,1024)?raw.iCalUID:null,
  };
}
export class GcalStageEventsReadProbe{
  constructor({tokenLifecycle,calendarReadProbe,fetcher=fetch,timeoutMs=8000}={}){
    if(!tokenLifecycle||typeof tokenLifecycle.accessToken!=='function'||
      !calendarReadProbe||typeof calendarReadProbe.calendars!=='function'||
      typeof fetcher!=='function'||!Number.isInteger(timeoutMs)||
      timeoutMs<1000||timeoutMs>15000)fail('EVENTS_PORT_MISSING');
    Object.assign(this,{tokenLifecycle,calendarReadProbe,fetcher,timeoutMs});
  }
  async events({verifiedAccountId,googleSubject,calendarId,timeMin,timeMax}={}){
    if(!validText(verifiedAccountId,256)||!validText(googleSubject,256)||
      !validText(calendarId,1024)||!isoUtc.test(timeMin??'')||
      !isoUtc.test(timeMax??''))fail('EVENTS_INVALID_INPUT');
    const start=Date.parse(timeMin),end=Date.parse(timeMax);
    if(!Number.isFinite(start)||!Number.isFinite(end)||end<=start||
      end-start>32*86400000)fail('EVENTS_INVALID_WINDOW');
    // Scope calendar.events.owned does NOT grant other people's events.
    // Verify Google calendar ownership on each read rather than trusting
    // user-supplied calendarId or the last Flutter inventory response.
    const list=await this.calendarReadProbe.calendars({verifiedAccountId,googleSubject});
    if(!list.calendars.some(c=>c.id===calendarId&&c.accessRole==='owner'))
      fail('EVENTS_OWNER_ONLY');
    const token=await this.tokenLifecycle.accessToken({verifiedAccountId,googleSubject});
    const url=new URL(EVENTS_ROOT+encodeURIComponent(calendarId)+'/events');
    url.searchParams.set('timeMin',timeMin);
    url.searchParams.set('timeMax',timeMax);
    url.searchParams.set('singleEvents','true');
    url.searchParams.set('orderBy','startTime');
    url.searchParams.set('showDeleted','false');
    url.searchParams.set('maxResults',String(MAX_EVENTS));
    let response;
    try{
      response=await this.fetcher(url.href,{
        method:'GET',redirect:'error',cache:'no-store',
        headers:{authorization:'Bearer '+token,accept:'application/json'},
        signal:AbortSignal.timeout(this.timeoutMs),
      });
    }catch{fail('EVENTS_UNAVAILABLE');}
    if(!response?.ok)fail('EVENTS_UNAVAILABLE');
    const data=await boundedJson(response);
    const items=data?.items??[];
    if(!Array.isArray(items)||items.length>MAX_EVENTS)
      fail('EVENTS_UNAVAILABLE');
    const events=[],seen=new Set();
    for(const source of items){
      const event=parseEvent(source);
      if(!event)continue;
      if(seen.has(event.eventId))continue;
      seen.add(event.eventId);
      events.push(event);
    }
    return {
      calendarId,events,truncated:validText(data.nextPageToken,2048),
      readonly:true,windowStart:timeMin,windowEnd:timeMax,
    };
  }
}