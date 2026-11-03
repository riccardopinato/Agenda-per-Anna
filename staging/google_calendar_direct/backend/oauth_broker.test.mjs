import test from 'node:test';
import assert from 'node:assert/strict';
import {randomBytes,generateKeyPairSync,sign} from 'node:crypto';
import {
 GoogleCalendarOAuthBroker,AesGcmTokenVault,GoogleTokenClient,GoogleIdTokenVerifier,
 testOnlyInMemoryStores,OWNED_EVENTS,CALENDAR_LIST,OAuthStagingError,
} from './oauth_broker.mjs';
const CLIENT='fake-test-client.apps.googleusercontent.com';
const CALLBACK='https://example.org/oauth/google-calendar/callback';
const ALL=['openid','email',OWNED_EVENTS,CALENDAR_LIST].join(' ');
const CLOCK=1800000000;
function harness(overrides={}){
 const store=testOnlyInMemoryStores(),vault=new AesGcmTokenVault(randomBytes(32));
 let calls=0;
 const tokenClient={async exchange(){calls++;return {
  access_token:'mock-access-token',refresh_token:'mock-refresh-token',
  id_token:'mock-id-token',token_type:'Bearer',expires_in:3600,scope:ALL,
 };}};
 const idVerifier={async verify(){return {sub:'google-person-id'};}};
 const broker=new GoogleCalendarOAuthBroker({
  clientId:CLIENT,clientSecret:'server-secret-not-in-flutter',
  redirectUri:CALLBACK,pendingStore:store.pendingStore,linkStore:store.linkStore,
  tokenClient,idVerifier,vault,clock:()=>CLOCK,...overrides,
 });
 return {broker,store,vault,calls:()=>calls};
}
async function makeCallback(broker,account='account-one'){
 const flow=await broker.start({verifiedAppAccountId:account});
 const url=new URL(CALLBACK);url.searchParams.set('state',
   new URL(flow.authorizationUrl).searchParams.get('state'));
 url.searchParams.set('code','only-a-test-code');
 return {flow,url};
}
const fails=(promise,code)=>assert.rejects(promise,
 error=>error instanceof OAuthStagingError&&error.code===code);

test('request has PKCE S256, narrow Calendar scopes and never contains secrets',async()=>{
 const {broker}=harness(),flow=await broker.start({verifiedAppAccountId:'account-one'});
 const url=new URL(flow.authorizationUrl);
 assert.equal(url.host,'accounts.google.com');
 assert.equal(url.searchParams.get('redirect_uri'),CALLBACK);
 assert.equal(url.searchParams.get('scope'),ALL);
 assert.equal(url.searchParams.get('code_challenge_method'),'S256');
 assert.match(url.searchParams.get('state'),/^[a-zA-Z0-9_-]{43}$/);
 assert.match(url.searchParams.get('code_challenge'),/^[a-zA-Z0-9_-]{43}$/);
 for(const key of ['client_secret','code_verifier','refresh_token','access_token'])
   assert.equal(url.searchParams.has(key),false);
 assert.equal(flow.authorizationUrl.includes(flow.browserProof),false);
});

test('mock callback binds account and browser, stores ciphertext, blocks replay',async()=>{
 const {broker,store,vault,calls}=harness(),{flow,url}=await makeCallback(broker);
 const result=await broker.callback({callbackUrl:url.toString(),
    verifiedAppAccountId:'account-one',browserProof:flow.browserProof});
 assert.deepEqual(result,{connected:true,googleSubject:'google-person-id',
   scopes:[OWNED_EVENTS,CALENDAR_LIST]});
 assert.equal(calls(),1);assert.equal(store._pending.size,0);
 assert.equal(store._links.size,1);
 const [key,entry]=[...store._links][0];
 assert.equal(JSON.stringify(entry).includes('mock-refresh-token'),false);
 assert.equal((await vault.open(entry.encrypted,key)).refresh_token,'mock-refresh-token');
 await fails(broker.callback({callbackUrl:url.toString(),
   verifiedAppAccountId:'account-one',browserProof:flow.browserProof}),
   'UNKNOWN_OR_REPLAYED_STATE');
});

test('wrong account and browser binding fail before contacting provider',async()=>{
 for(const change of [
   {verifiedAppAccountId:'different-user'},
   {browserProof:'forged'},
   {browserProof:''},
 ]) {
   const {broker,store,calls}=harness(),{flow,url}=await makeCallback(broker);
   await fails(broker.callback({callbackUrl:url.toString(),
    verifiedAppAccountId:'account-one',browserProof:flow.browserProof,...change}),
    change.verifiedAppAccountId?'ACCOUNT_MISMATCH':'BROWSER_MISMATCH');
   assert.equal(calls(),0);assert.equal(store._links.size,0);
 }
});

test('expired state, wrong state, cancellation and code/error mix fail closed',async()=>{
 let tick=CLOCK;let scenario=harness({clock:()=>tick});
 let {flow,url}=await makeCallback(scenario.broker);tick+=601;
 await fails(scenario.broker.callback({callbackUrl:url.toString(),
   verifiedAppAccountId:'account-one',browserProof:flow.browserProof}),'EXPIRED');
 scenario=harness();({flow,url}=await makeCallback(scenario.broker));
 url.searchParams.set('state','q'.repeat(43));
 await fails(scenario.broker.callback({callbackUrl:url.toString(),
   verifiedAppAccountId:'account-one',browserProof:flow.browserProof}),
   'UNKNOWN_OR_REPLAYED_STATE');
 scenario=harness();({flow,url}=await makeCallback(scenario.broker));
 url.searchParams.delete('code');url.searchParams.set('error','access_denied');
 await fails(scenario.broker.callback({callbackUrl:url.toString(),
   verifiedAppAccountId:'account-one',browserProof:flow.browserProof}),'ACCESS_DENIED');
 scenario=harness();({flow,url}=await makeCallback(scenario.broker));
 url.searchParams.set('error','access_denied');
 await fails(scenario.broker.callback({callbackUrl:url.toString(),
   verifiedAppAccountId:'account-one',browserProof:flow.browserProof}),'BAD_CALLBACK');
});

test('missing Calendar permissions, refresh token and bad Google identity cannot link',async()=>{
 const incomplete={async exchange(){return {access_token:'t',refresh_token:'r',
  id_token:'i',token_type:'Bearer',expires_in:3600,scope:'openid email'};}};
 let h=harness({tokenClient:incomplete});let {flow,url}=await makeCallback(h.broker);
 await fails(h.broker.callback({callbackUrl:url.toString(),
   verifiedAppAccountId:'account-one',browserProof:flow.browserProof}),
   'INSUFFICIENT_SCOPES');
 assert.equal(h.store._links.size,0);
 const noRefresh={async exchange(){return {access_token:'t',id_token:'i',
   token_type:'Bearer',expires_in:3600,scope:ALL};}};
 h=harness({tokenClient:noRefresh});({flow,url}=await makeCallback(h.broker));
 await fails(h.broker.callback({callbackUrl:url.toString(),
   verifiedAppAccountId:'account-one',browserProof:flow.browserProof}),
   'BAD_TOKEN_RESPONSE');
 h=harness({idVerifier:{async verify(){throw new OAuthStagingError('BAD_ID_SIGNATURE');}}});
 ({flow,url}=await makeCallback(h.broker));
 await fails(h.broker.callback({callbackUrl:url.toString(),
   verifiedAppAccountId:'account-one',browserProof:flow.browserProof}),
   'BAD_ID_SIGNATURE');
 assert.equal(h.store._links.size,0);
});

test('AES-GCM rejects changed account AAD and incorrect master key',async()=>{
 const vault=new AesGcmTokenVault(randomBytes(32)),key='a'.repeat(64);
 const sealed=await vault.seal({refresh_token:'private'},key);
 await fails(vault.open(sealed,'b'.repeat(64)),'VAULT_INTEGRITY');
 await fails(new AesGcmTokenVault(randomBytes(32)).open(sealed,key),'VAULT_INTEGRITY');
});

test('Google code exchange sends form to official server only',async()=>{
 let called=0;
 const tokenClient=new GoogleTokenClient({fetchImpl:async(url,options)=>{
  called++;assert.equal(url,'https://oauth2.googleapis.com/token');
  assert.equal(options.method,'POST');assert.equal(options.redirect,'error');
  assert.equal(options.body.get('client_secret'),'server-secret');
  assert.equal(options.body.get('code_verifier'),'pkce-verifier');
  return {ok:true,async json(){return {access_token:'mock'};}};
 }});
 await tokenClient.exchange({clientId:CLIENT,clientSecret:'server-secret',
   redirectUri:CALLBACK,code:'test-code',codeVerifier:'pkce-verifier'});
 assert.equal(called,1);
});

test('real RS256 JWK verification checks signature, issuer, audience, expiry and nonce',async()=>{
 const {privateKey,publicKey}=generateKeyPairSync('rsa',{modulusLength:2048});
 const jwk=publicKey.export({format:'jwk'});Object.assign(jwk,{kid:'k1',use:'sig',alg:'RS256'});
 const verifier=new GoogleIdTokenVerifier({fetchImpl:async(url)=>{
  assert.equal(url,'https://www.googleapis.com/oauth2/v3/certs');
  return {ok:true,async json(){return {keys:[jwk]};}};
 }});
 const jwt=(claim)=>{
  const h=Buffer.from(JSON.stringify({alg:'RS256',kid:'k1'})).toString('base64url');
  const p=Buffer.from(JSON.stringify(claim)).toString('base64url');
  const sig=sign('RSA-SHA256',Buffer.from(h+'.'+p),privateKey).toString('base64url');
  return h+'.'+p+'.'+sig;
 };
 const claims={iss:'https://accounts.google.com',aud:CLIENT,
  sub:'google-test-id',nonce:'nonce-test',iat:CLOCK-30,exp:CLOCK+3600};
 assert.equal((await verifier.verify(jwt(claims),
  {audience:CLIENT,nonce:'nonce-test',now:CLOCK})).sub,'google-test-id');
 for(const changed of [
  {...claims,aud:'foreign-app'}, {...claims,nonce:'fake-nonce'},
  {...claims,exp:CLOCK-1},{...claims,iss:'other.issuer'},
 ]) await fails(verifier.verify(jwt(changed),
     {audience:CLIENT,nonce:'nonce-test',now:CLOCK}),'BAD_ID_CLAIMS');
 const valid=jwt(claims);
 await fails(verifier.verify(valid.slice(0,-4)+'abcd',
  {audience:CLIENT,nonce:'nonce-test',now:CLOCK}),'BAD_ID_SIGNATURE');
});

test('no production Supabase callback and no anonymous authorization',async()=>{
 assert.throws(()=>harness({
  redirectUri:'https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/callback',
 }),e=>e instanceof OAuthStagingError&&e.code==='INVALID_REDIRECT');
 const {broker}=harness();
 await fails(broker.start({verifiedAppAccountId:''}),'UNAUTHENTICATED');
});
