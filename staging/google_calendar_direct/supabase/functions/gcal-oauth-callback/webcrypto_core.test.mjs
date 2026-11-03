import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalStageBroker,GcalStageVault,GcalStageFault,
  verifyGoogleIdToken,REQUIRED_SCOPES,pkceS256,checkOauthConfig} from './webcrypto_core.mjs';
const redirectUri='https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';
const clientId='mock-staging.apps.googleusercontent.com';
const now=()=>1793700000;
const fault=(promise,kind)=>assert.rejects(promise,e=>e instanceof GcalStageFault&&e.kind===kind);
function fixture(overrides={}) {
  const states=new Map(), links=new Map(), vault=new GcalStageVault(crypto.getRandomValues(new Uint8Array(32)));
  let exchanges=0;
  const broker=new GcalStageBroker({clientId,clientSecret:'TEST-server-secret',
    redirectUri,vault,clock:now,
    pendingStore:{
      async create(k,v){if(states.has(k))return false;states.set(k,v);return true;},
      async take(k){const entry=states.get(k);states.delete(k);return entry;},
    },
    linkStore:{async put(a,s,v){links.set(a+':'+s,v);}},
    tokenExchange:async()=>{exchanges++;return {access_token:'TEST-access',
      refresh_token:'TEST-refresh',id_token:'TEST-id',
      scope:REQUIRED_SCOPES.join(' '),expires_in:3600,token_type:'Bearer'};},
    idVerifier:async()=>({subject:'google-sub-test'}),...overrides});
  return {broker,states,links,vault,exchanges:()=>exchanges};
}
async function begin(broker) {
  const result=await broker.start({verifiedAccountId:'test-supabase-user'});
  const auth=new URL(result.authorizationUrl);
  const callback=new URL(redirectUri);
  callback.searchParams.set('state',auth.searchParams.get('state'));
  callback.searchParams.set('code','TEST-code');
  return {...result,auth,callback};
}
test('PKCE S256 official vector, narrowly scoped authorization and no browser secret in URL',async()=>{
  assert.equal(await pkceS256('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
    'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM');
  const f=fixture(),r=await begin(f.broker);
  assert.equal(r.auth.host,'accounts.google.com');
  assert.equal(r.auth.searchParams.get('scope'),REQUIRED_SCOPES.join(' '));
  assert.equal(r.auth.searchParams.get('code_challenge_method'),'S256');
  assert.match(r.auth.searchParams.get('state'),/^[A-Za-z0-9_-]{43}$/);
  assert.equal(r.authorizationUrl.includes(r.browserProof),false);
  assert.equal(r.authorizationUrl.includes('TEST-server-secret'),false);
});
test('success stores only AES-GCM encrypted tokens and consumes state once',async()=>{
  const f=fixture(),r=await begin(f.broker);
  const reply=await f.broker.callback({callbackUrl:r.callback.toString(),browserProof:r.browserProof});
  assert.equal(reply.connected,true);
  assert.equal(f.exchanges(),1);
  assert.equal(f.links.size,1);
  assert.equal(JSON.stringify([...f.links]).includes('TEST-refresh'),false);
  assert.equal(JSON.stringify(reply).includes('TEST-access'),false);
  await fault(f.broker.callback({callbackUrl:r.callback.toString(),browserProof:r.browserProof}),
    'REPLAY_OR_UNKNOWN_STATE');
});
test('wrong browser cookie is rejected before Google token exchange',async()=>{
  const f=fixture(),r=await begin(f.broker);
  await fault(f.broker.callback({callbackUrl:r.callback.toString(),browserProof:'fake'}),
    'WRONG_BROWSER');
  assert.equal(f.exchanges(),0);
  assert.equal(f.states.size,0);
});
test('declined Google consent and insufficient scopes never create links',async()=>{
  let f=fixture(),r=await begin(f.broker);
  r.callback.searchParams.delete('code');
  r.callback.searchParams.set('error','access_denied');
  await fault(f.broker.callback({callbackUrl:r.callback.toString(),browserProof:r.browserProof}),
    'ACCESS_DENIED');
  assert.equal(f.links.size,0);
  f=fixture({tokenExchange:async()=>({
    access_token:'x',refresh_token:'y',id_token:'z',token_type:'Bearer',
    expires_in:3600,scope:'openid email',
  })});
  r=await begin(f.broker);
  await fault(f.broker.callback({callbackUrl:r.callback.toString(),browserProof:r.browserProof}),
    'SCOPE_MISMATCH');
  assert.equal(f.links.size,0);
});
test('callback host mismatch fails closed and leaves state intact',async()=>{
  const f=fixture(),r=await begin(f.broker);r.callback.host='evil.invalid';
  await fault(f.broker.callback({callbackUrl:r.callback.toString(),browserProof:r.browserProof}),
    'WRONG_CALLBACK');
  assert.equal(f.states.size,1);
});
test('AES-GCM rejects modified AAD and an unrelated encryption key',async()=>{
  const vault=new GcalStageVault(crypto.getRandomValues(new Uint8Array(32)));
  const wrapped=await vault.seal({refresh_token:'test-private'},'aad-A');
  assert.deepEqual(await vault.open(wrapped,'aad-A'),{refresh_token:'test-private'});
  await fault(vault.open(wrapped,'aad-B'),'VAULT_INTEGRITY');
  const other=new GcalStageVault(crypto.getRandomValues(new Uint8Array(32)));
  await fault(other.open(wrapped,'aad-A'),'VAULT_INTEGRITY');
});
test('reject production login callback and anonymous start',async()=>{
  assert.throws(()=>checkOauthConfig({clientId,
    redirectUri:'https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/callback'}),
    e=>e.kind==='INVALID_REDIRECT');
  const f=fixture();await fault(f.broker.start({verifiedAccountId:''}),'UNAUTHENTICATED');
});
test('Google RSA signature and OIDC claims are verified using WebCrypto',async()=>{
  const pair=await crypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',
    modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),
    hash:'SHA-256'},true,['sign','verify']);
  const jwk=await crypto.subtle.exportKey('jwk',pair.publicKey);
  jwk.kid='test-kid';jwk.use='sig';jwk.alg='RS256';
  const b64=x=>btoa(String.fromCharCode(...x)).replaceAll('+','-').replaceAll('/','_').replaceAll('=','');
  const jwt=async claims=>{
    const h=b64(new TextEncoder().encode(JSON.stringify({alg:'RS256',kid:'test-kid'})));
    const p=b64(new TextEncoder().encode(JSON.stringify(claims)));
    const sig=new Uint8Array(await crypto.subtle.sign('RSASSA-PKCS1-v1_5',
      pair.privateKey,new TextEncoder().encode(h+'.'+p)));
    return h+'.'+p+'.'+b64(sig);
  };
  const fetcher=async url=>{
    assert.equal(url,'https://www.googleapis.com/oauth2/v3/certs');
    return {ok:true,json:async()=>({keys:[jwk]})};
  };
  const claims={iss:'https://accounts.google.com',aud:clientId,
    sub:'test-google-sub',nonce:'test-nonce',iat:now()-60,exp:now()+600};
  const token=await jwt(claims);
  assert.equal((await verifyGoogleIdToken(token,{clientId,nonce:'test-nonce',
    now:now(),fetcher})).subject,'test-google-sub');
  for(const bad of [{...claims,aud:'other-client'},{...claims,exp:now()-1},
    {...claims,nonce:'wrong'}]) {
    await fault(verifyGoogleIdToken(await jwt(bad),{clientId,nonce:'test-nonce',
      now:now(),fetcher}),'BAD_ID_CLAIMS');
  }
});
