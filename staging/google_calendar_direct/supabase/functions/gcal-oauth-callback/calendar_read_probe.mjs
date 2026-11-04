// STAGING QA ONLY: read-only Google Calendar inventory.
// This deliberately NEVER sends POST/PATCH/PUT/DELETE to Google Calendar.
const GOOGLE_CALENDAR_LIST = 'https://www.googleapis.com/calendar/v3/users/me/calendarList';
const LIMIT_BYTES=128*1024;
function fail() { throw Error('CALENDAR_READ_UNAVAILABLE'); }
export class GcalStageCalendarReadProbe {
  constructor({tokenLifecycle,fetcher=fetch,timeoutMs=8000}={}) {
    if(!tokenLifecycle||typeof tokenLifecycle.accessToken!=='function'||
      typeof fetcher!=='function'||!Number.isInteger(timeoutMs)||
      timeoutMs<1000||timeoutMs>15000)throw Error('CALENDAR_READ_PORT_MISSING');
    this.tokenLifecycle=tokenLifecycle;
    this.fetcher=fetcher;
    this.timeoutMs=timeoutMs;
  }
  async calendars({verifiedAccountId,googleSubject}={}) {
    if(typeof verifiedAccountId!=='string'||verifiedAccountId.length<1||
       verifiedAccountId.length>256||typeof googleSubject!=='string'||
       googleSubject.length<1||googleSubject.length>256)fail();
    const accessToken=await this.tokenLifecycle.accessToken({
      verifiedAccountId,googleSubject
    });
    // Access token is used only by the backend, never sent to Flutter.
    const url=new URL(GOOGLE_CALENDAR_LIST);
    url.searchParams.set('maxResults','25');
    url.searchParams.set('showHidden','false');
    let response;
    try {
      response=await this.fetcher(url.href,{
        method:'GET',
        headers:{authorization:'Bearer '+accessToken,accept:'application/json'},
        redirect:'error',cache:'no-store',
        signal:AbortSignal.timeout(this.timeoutMs)
      });
    } catch { fail(); }
    if(!response?.ok)fail();
    if(Number(response.headers?.get?.('content-length')??0)>LIMIT_BYTES)fail();
    let json;
    try {
      const reader=response.body?.getReader();
      if(!reader)fail();
      const chunks=[];let total=0;
      try {
        while(true){
          const {done,value}=await reader.read();
          if(done)break;
          total+=value?.byteLength??0;
          if(total>LIMIT_BYTES)fail();
          chunks.push(value);
        }
      } finally{reader.releaseLock();}
      const buffer=new Uint8Array(total);let pos=0;
      for(const part of chunks){buffer.set(part,pos);pos+=part.byteLength;}
      json=JSON.parse(new TextDecoder('utf-8',{fatal:true}).decode(buffer));
    } catch {fail();}
    if(!Array.isArray(json?.items)||json.items.length>25)fail();
    const calendars=json.items.map(c=>{
      if(typeof c?.id!=='string'||c.id.length<1||c.id.length>1024||
         typeof c.summary!=='string'||c.summary.length>300)fail();
      return {id:c.id,name:c.summary,primary:c.primary===true,
        accessRole:typeof c.accessRole==='string'&&
          ['owner','writer','reader','freeBusyReader'].includes(c.accessRole)
          ?c.accessRole:'unknown'};
    });
    return {calendars,readonly:true};
  }
}
