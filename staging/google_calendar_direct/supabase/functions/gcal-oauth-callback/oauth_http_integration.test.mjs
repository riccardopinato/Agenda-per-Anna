// Fully in-memory staging integration contract. NO network, credentials or Google API.
import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalTwoPhaseBroker} from './two_phase_core.mjs';
import {GcalStageVault,REQUIRED_SCOPES} from './webcrypto_core.mjs';
import {GcalStageTokenLifecycle} from './token_lifecycle.mjs';
import {createGoogleCalendarStagingHandler} from './http_handler.mjs';

const base='https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';
const APP='c16e0ec0-415c-4e53-a488-5c6ed75d2662';
const OTHER='a99d34ac-4859-475e-a43c-789c8192651e';
const NOW=1793710000;
const providerSubject='mock-google-subject';
function scenario() {
  const states=new Map(),completions=new Map(),links=new Map(),budgetActions=[];
  const vault=new GcalStageVault(crypto.getRandomValues(new Uint8Array(32)));
  let exchanges=0,revocations=0,callbackChecks=0;
  const broker=new GcalTwoPhaseBroker({
    clientId:'mock-staging.apps.googleusercontent.com',
    clientSecret:'mock-server-only',redirectUri:base,
    vault,clock:()=>NOW,
    pendingStore:{
      async create(hash,blob){if(states.has(hash))return false;states.set(hash,blob);return true;},
      async take(hash){const v=states.get(hash);states.delete(hash);return v??null;},
    },
    completionStore:{
      async create(hash,account,blob){if(completions.has(hash))return false;completions.set(hash,{account,blob});return true;},
      async read(hash,account){const v=completions.get(hash);return v?.account===account?v.blob:null;},
      async take(hash,account){const v=completions.get(hash);if(!v||v.account!==account)return null;completions.delete(hash);return v.blob;},
    },
    linkStore:{async put(account,subject,blob){links.set(account+':'+subject,blob);}},
    tokenExchange:async()=>{exchanges++;return {
      access_token:'MOCK_ACCESS_SECRET',refresh_token:'MOCK_REFRESH_SECRET',
      id_token:'MOCK_ID_TOKEN',scope:REQUIRED_SCOPES.join(' '),
      token_type:'Bearer',expires_in:3600,
    };},
    idVerifier:async()=>({subject:providerSubject,email:'fixture@example.invalid',emailVerified:true}),
  });
  const lifecycle=new GcalStageTokenLifecycle({
    clientId:'mock-staging.apps.googleusercontent.com',clientSecret:'mock-server-only',
    vault,clock:()=>NOW,fetcher:async(url)=>{
      assert.equal(url,'https://oauth2.googleapis.com/revoke');
      revocations++;return {status:200};
    },
    linkStore:{
      async getLink(a,s){return links.get(a+':'+s)??null;},
      async replaceLink(a,s,old,next){
        const k=a+':'+s;
        if(JSON.stringify(links.get(k))!==JSON.stringify(old))return false;
        links.set(k,next);return true;
      },
      async takeLink(a,s){const k=a+':'+s;const v=links.get(k);links.delete(k);return v??null;}
    },
  });
  const handler=createGoogleCalendarStagingHandler({
    enabled:true,broker,tokenLifecycle:lifecycle,
    requestBudget:{async consume(account,action){budgetActions.push([account,action]);return true;}},
    callbackBudget:{async consume(){callbackChecks++;return true;}},
    verifyAppIdentity:async bearer=>{
      if(bearer==='Bearer FIRST_TEST_JWT')return {accountId:APP};
      if(bearer==='Bearer OTHER_TEST_JWT')return {accountId:OTHER};
      throw Error('BAD_APP_AUTH');
    },
    allowedWebOrigins:['https://riccardopinato.github.io'],
  });
  const post=(route,body={},auth='Bearer FIRST_TEST_JWT')=>handler(new Request(base+route,{
    method:'POST',
    headers:{'content-type':'application/json','authorization':auth,
      'origin':'https://riccardopinato.github.io'},
    body:JSON.stringify(body),
  }));
  return {handler,post,states,completions,links,budgetActions,
    exchanges:()=>exchanges,revocations:()=>revocations,callbackChecks:()=>callbackChecks};
}
test('authenticated start -> public callback -> account preview -> explicit confirm -> revoke',async()=>{
  const f=scenario();
  let r=await f.post('/start');
  assert.equal(r.status,200);
  const started=await r.json();
  assert.match(started.handle,/^[A-Za-z0-9_-]{43}$/);
  assert.equal(started.authorizationUrl.includes(started.handle),false);
  const u=new URL(started.authorizationUrl);
  assert.equal(u.host,'accounts.google.com');
  assert.equal(u.searchParams.get('client_id'),'mock-staging.apps.googleusercontent.com');
  assert.equal(f.states.size,1);
  r=await f.post('/preview',{handle:started.handle});
  assert.equal((await r.json()).status,'waiting');

  const callback=new URL(base);
  callback.searchParams.set('state',u.searchParams.get('state'));
  callback.searchParams.set('code','MOCK_AUTHORIZATION_CODE');
  r=await f.handler(new Request(callback.href));
  assert.equal(r.status,200);
  const html=await r.text();
  assert.equal(html.includes('MOCK_AUTHORIZATION_CODE'),false);
  assert.equal(html.includes('MOCK_ACCESS_SECRET'),false);
  assert.equal(f.exchanges(),1);
  assert.equal(f.callbackChecks(),1);
  assert.equal(f.links.size,0); // Google consent alone never links account.

  r=await f.post('/preview',{handle:started.handle},'Bearer OTHER_TEST_JWT');
  assert.equal((await r.json()).status,'waiting');
  r=await f.post('/confirm',{handle:started.handle,explicitConfirmation:true},'Bearer OTHER_TEST_JWT');
  assert.equal(r.status,409);
  assert.equal(f.completions.size,1); // Wrong account can't consume.

  r=await f.post('/preview',{handle:started.handle});
  const preview=await r.json();
  assert.equal(preview.status,'awaiting_confirmation');
  assert.equal(preview.googleEmail,'fixture@example.invalid');
  r=await f.post('/confirm',{handle:started.handle});
  assert.equal(r.status,400);
  assert.equal(f.links.size,0);

  r=await f.post('/confirm',{handle:started.handle,explicitConfirmation:true});
  assert.equal(r.status,200);
  const connected=await r.json();
  assert.equal(connected.connected,true);
  assert.equal(connected.googleSubject,providerSubject);
  assert.equal(f.links.size,1);
  assert.equal(JSON.stringify([...f.links]).includes('MOCK_REFRESH_SECRET'),false);
  r=await f.post('/confirm',{handle:started.handle,explicitConfirmation:true});
  assert.equal(r.status,409);
  r=await f.handler(new Request(callback.href));
  assert.equal(r.status,400); // One-time state, no second exchange.
  assert.equal(f.exchanges(),1);

  r=await f.post('/disconnect',{googleSubject:providerSubject,explicitConfirmation:true});
  assert.equal(r.status,200);
  assert.deepEqual(await r.json(),{disconnected:true,providerRevoked:true});
  assert.equal(f.links.size,0);
  assert.equal(f.revocations(),1);
  r=await f.post('/disconnect',{googleSubject:providerSubject,explicitConfirmation:true});
  assert.equal(r.status,200);
  assert.deepEqual(await r.json(),{disconnected:true,providerRevoked:null});
  assert.equal(f.revocations(),1);
  assert.deepEqual(f.budgetActions[0],[APP,'start']);
});
