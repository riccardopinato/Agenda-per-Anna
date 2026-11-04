// Google Calendar OAuth STAGING — WebCrypto-based, Deno/Node compatible.
// Never imported by production Flutter. Host auth, cookie and durable stores are mandatory.
export const GOOGLE_SCOPE_EVENTS = 'https://www.googleapis.com/auth/calendar.events.owned';
export const GOOGLE_SCOPE_CALENDAR_LIST = 'https://www.googleapis.com/auth/calendar.calendarlist.readonly';
export const REQUIRED_SCOPES = Object.freeze(['openid','email',GOOGLE_SCOPE_EVENTS,GOOGLE_SCOPE_CALENDAR_LIST]);
const GOOGLE_EMAIL_SCOPE_CANONICAL='https://www.googleapis.com/auth/userinfo.email';
export function scopesContainRequired(scope) {
  if(typeof scope!=='string'||scope.length===0||scope.length>4096)return false;
  const granted=new Set(scope.split(/\s+/).filter(Boolean));
  return REQUIRED_SCOPES.every(s=>s==='email'
    ?(granted.has('email')||granted.has(GOOGLE_EMAIL_SCOPE_CANONICAL))
    :granted.has(s));
}
export const AUTH_ENDPOINT = 'https://accounts.google.com/o/oauth2/v2/auth';
export const TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';
export const JWKS_ENDPOINT = 'https://www.googleapis.com/oauth2/v3/certs';

const utf8 = new TextEncoder();
const text = new TextDecoder('utf-8', {fatal:true});
export class GcalStageFault extends Error {
  constructor(kind) { super('Google OAuth staging: '+kind); this.name='GcalStageFault'; this.kind=kind; }
}
const deny = k => { throw new GcalStageFault(k); };
const str = (x, limit=1024) => typeof x==='string' && x.length>0 && x.length<=limit;
function bytesToB64url(bytes) {
  let raw=''; for (const byte of bytes) raw+=String.fromCharCode(byte);
  return btoa(raw).replaceAll('+','-').replaceAll('/','_').replaceAll('=','');
}
function b64urlToBytes(value) {
  if (!str(value,15000) || !/^[A-Za-z0-9_-]+$/.test(value)) deny('INVALID_BASE64URL');
  try {
    let s=value.replaceAll('-','+').replaceAll('_','/');
    s += '='.repeat((4-s.length%4)%4);
    const raw=atob(s); return Uint8Array.from(raw,c=>c.charCodeAt(0));
  } catch { deny('INVALID_BASE64URL'); }
}
export const randomUrl = (length=32) => {
  if (!Number.isInteger(length)||length<32||length>96) deny('INVALID_ENTROPY');
  return bytesToB64url(crypto.getRandomValues(new Uint8Array(length)));
};
export async function sha256Bytes(input) {
  const data=typeof input==='string'?utf8.encode(input):input;
  return new Uint8Array(await crypto.subtle.digest('SHA-256',data));
}
export const sha256Hex = async input => Array.from(await sha256Bytes(input),x=>x.toString(16).padStart(2,'0')).join('');
export const pkceS256 = async verifier => bytesToB64url(await sha256Bytes(verifier));
export function safeEqual(a,b) {
  if (!str(a,4096)||!str(b,4096)) return false;
  const x=utf8.encode(a), y=utf8.encode(b);
  let diff=x.length^y.length;
  for(let i=0;i<Math.max(x.length,y.length);i++) diff|=(x[i]??0)^(y[i]??0);
  return diff===0;
}
export function checkOauthConfig({clientId,redirectUri}) {
  if (!str(clientId,250)||!clientId.endsWith('.apps.googleusercontent.com')) deny('INVALID_CLIENT');
  let uri; try {uri=new URL(redirectUri);} catch {deny('INVALID_REDIRECT');}
  if(uri.protocol!=='https:'||!uri.hostname||uri.username||uri.password||uri.search||uri.hash||
    uri.hostname==='pxsxlorntswypdbeerzw.supabase.co') deny('INVALID_REDIRECT');
  return uri;
}
export class GcalStageVault {
  constructor(key) {
    if (!(key instanceof Uint8Array)||key.byteLength!==32) deny('INVALID_VAULT_KEY');
    this._keyBytes = new Uint8Array(key);
    this._keyPromise=crypto.subtle.importKey('raw',this._keyBytes,{name:'AES-GCM'},false,['encrypt','decrypt']);
  }
  async seal(value,aad) {
    if(!str(aad,256)) deny('INVALID_AAD');
    const iv=crypto.getRandomValues(new Uint8Array(12));
    const bytes=utf8.encode(JSON.stringify(value));
    const data=await crypto.subtle.encrypt({name:'AES-GCM',iv,additionalData:utf8.encode(aad),tagLength:128},await this._keyPromise,bytes);
    return {v:1,iv:bytesToB64url(iv),data:bytesToB64url(new Uint8Array(data))};
  }
  async open(record,aad) {
    if(record?.v!==1||!str(aad,256)) deny('INVALID_ENVELOPE');
    try {
      const iv=b64urlToBytes(record.iv),cipher=b64urlToBytes(record.data);
      if (iv.length!==12||cipher.length<17) deny('INVALID_ENVELOPE');
      const data=await crypto.subtle.decrypt({name:'AES-GCM',iv,additionalData:utf8.encode(aad),tagLength:128},await this._keyPromise,cipher);
      return JSON.parse(text.decode(data));
    } catch { deny('VAULT_INTEGRITY'); }
  }
}
export async function verifyGoogleIdToken(jwt,{clientId,nonce,now=Math.floor(Date.now()/1000),fetcher=fetch}) {
  if(!str(jwt,12000)||jwt.split('.').length!==3) deny('BAD_ID_TOKEN');
  const parts=jwt.split('.'); let header,claims;
  try {
    header=JSON.parse(text.decode(b64urlToBytes(parts[0])));
    claims=JSON.parse(text.decode(b64urlToBytes(parts[1])));
  } catch {deny('BAD_ID_TOKEN');}
  if(header.alg!=='RS256'||!str(header.kid,256)) deny('BAD_ALGORITHM');
  let response;
  try{response=await fetcher(JWKS_ENDPOINT,{method:'GET',redirect:'error',signal:AbortSignal.timeout(8000)});}catch{deny('JWKS_UNAVAILABLE');}
  if(!response.ok)deny('JWKS_UNAVAILABLE');
  let jwks;try{jwks=await response.json();}catch{deny('JWKS_UNAVAILABLE');}
  const jwk=(jwks.keys??[]).find(k=>k.kid===header.kid&&k.kty==='RSA'&&k.use==='sig'&&(!k.alg||k.alg==='RS256'));
  if(!jwk) deny('UNKNOWN_KID');
  let validSig=false;
  try {
    const key=await crypto.subtle.importKey('jwk',jwk,{name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['verify']);
    validSig=await crypto.subtle.verify({name:'RSASSA-PKCS1-v1_5'},key,b64urlToBytes(parts[2]),utf8.encode(parts[0]+'.'+parts[1]));
  } catch {deny('BAD_ID_SIGNATURE');}
  if(!validSig) deny('BAD_ID_SIGNATURE');
  if(!['accounts.google.com','https://accounts.google.com'].includes(claims.iss)||
     claims.aud!==clientId||claims.nonce!==nonce||!str(claims.sub,256)||
     !Number.isInteger(claims.exp)||claims.exp<=now||
     !Number.isInteger(claims.iat)||claims.iat>now+120||claims.iat<now-86400||
     (claims.nbf!==undefined&&(!Number.isInteger(claims.nbf)||claims.nbf>now))) deny('BAD_ID_CLAIMS');
  return {subject:claims.sub,email:typeof claims.email==='string'?claims.email:null,
    emailVerified:claims.email_verified===true};
}
export async function exchangeGoogleCode({clientId,clientSecret,redirectUri,code,verifier,fetcher=fetch}) {
  if(!str(clientSecret,4096)||!str(code,4096)||!str(verifier,128))deny('TOKEN_REQUEST_INVALID');
  checkOauthConfig({clientId,redirectUri});
  const body=new URLSearchParams({client_id:clientId,client_secret:clientSecret,
    code,code_verifier:verifier,grant_type:'authorization_code',redirect_uri:redirectUri});
  let response;
  try {response=await fetcher(TOKEN_ENDPOINT,{method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},
    body,signal:AbortSignal.timeout(8000),redirect:'error'});}catch{deny('GOOGLE_UNAVAILABLE');}
  if(!response.ok)deny('GOOGLE_TOKEN_REJECTED');
  try{return await response.json();}catch{deny('BAD_TOKEN_RESPONSE');}
}
export class GcalStageBroker {
  // pendingStore: create(stateHash,envelope,expiresAt), atomic take(stateHash)
  // linkStore: put(appAccountHash,googleSubjectHash,envelope)
  constructor({clientId,clientSecret,redirectUri,vault,pendingStore,linkStore,
    tokenExchange=exchangeGoogleCode,idVerifier=verifyGoogleIdToken,
    clock=()=>Math.floor(Date.now()/1000)}) {
    this.redirect=checkOauthConfig({clientId,redirectUri});
    if(!str(clientSecret,4096)||!vault||!pendingStore||!linkStore)deny('MISSING_ADAPTER');
    Object.assign(this,{clientId,clientSecret,vault,pendingStore,linkStore,tokenExchange,idVerifier,clock});
  }
  async start({verifiedAccountId}) {
    // Caller must be verified against production Supabase Auth in the HTTPS host.
    if(!str(verifiedAccountId,256))deny('UNAUTHENTICATED');
    const state=randomUrl(32),nonce=randomUrl(32),verifier=randomUrl(64),browserProof=randomUrl(32);
    const stateHash=await sha256Hex(state);
    const envelope=await this.vault.seal({accountId:verifiedAccountId,nonce,verifier,
      proofHash:await sha256Hex(browserProof),issuedAt:this.clock()},stateHash);
    if(await this.pendingStore.create(stateHash,envelope,this.clock()+600)!==true)deny('STATE_COLLISION');
    const q=new URLSearchParams({client_id:this.clientId,redirect_uri:this.redirect.toString(),
      response_type:'code',scope:REQUIRED_SCOPES.join(' '),state,nonce,
      code_challenge:await pkceS256(verifier),code_challenge_method:'S256',
      access_type:'offline',prompt:'select_account consent',include_granted_scopes:'false'});
    // Host must set browserProof in a Secure HttpOnly SameSite=Lax cookie
    // via first-party navigation; cross-origin POST/XHR is insufficient.
    return {authorizationUrl:AUTH_ENDPOINT+'?'+q,browserProof};
  }
  async callback({callbackUrl,browserProof}) {
    let url;try{url=new URL(callbackUrl);}catch{deny('WRONG_CALLBACK');}
    if(url.origin!==this.redirect.origin||url.pathname!==this.redirect.pathname||url.hash)deny('WRONG_CALLBACK');
    const states=url.searchParams.getAll('state');
    if(states.length!==1||!/^[A-Za-z0-9_-]{43}$/.test(states[0]))deny('BAD_STATE');
    const stateHash=await sha256Hex(states[0]);
    const envelope=await this.pendingStore.take(stateHash);
    if(!envelope)deny('REPLAY_OR_UNKNOWN_STATE');
    const tx=await this.vault.open(envelope,stateHash);
    if(!safeEqual(tx.proofHash,await sha256Hex(browserProof||'')))deny('WRONG_BROWSER');
    const elapsed=this.clock()-tx.issuedAt;
    if(!Number.isFinite(elapsed)||elapsed<0||elapsed>600)deny('EXPIRED');
    const errors=url.searchParams.getAll('error'),codes=url.searchParams.getAll('code');
    if(errors.length>0){if(codes.length>0||errors.length!==1)deny('BAD_CALLBACK');deny('ACCESS_DENIED');}
    if(codes.length!==1||!str(codes[0],4096)||url.searchParams.has('access_token')||
      url.searchParams.has('id_token'))deny('BAD_CALLBACK');
    const tokens=await this.tokenExchange({clientId:this.clientId,clientSecret:this.clientSecret,
      redirectUri:this.redirect.toString(),code:codes[0],verifier:tx.verifier});
    if(!str(tokens?.access_token,10000)||!str(tokens?.refresh_token,10000)||
      !str(tokens?.id_token,12000)||tokens.token_type?.toLowerCase()!=='bearer'||
      !Number.isInteger(tokens.expires_in)||tokens.expires_in<60||tokens.expires_in>86400||
      !str(tokens.scope,4096)) deny('BAD_TOKEN_RESPONSE');
    const scopes=new Set(tokens.scope.split(/\s+/));
    if(!scopesContainRequired(tokens.scope)) deny('SCOPE_MISMATCH');
    const identity=await this.idVerifier(tokens.id_token,{clientId:this.clientId,
      nonce:tx.nonce,now:this.clock()});
    if(!str(identity?.subject,256))deny('BAD_GOOGLE_ID');
    const accountHash=await sha256Hex('anna-staging-account-v1:'+tx.accountId);
    const subjectHash=await sha256Hex('anna-staging-google-v1:'+identity.subject);
    const encrypted=await this.vault.seal({googleSubject:identity.subject,
      accessToken:tokens.access_token,refreshToken:tokens.refresh_token,
      expiresAt:this.clock()+tokens.expires_in,scope:tokens.scope},accountHash+':'+subjectHash);
    await this.linkStore.put(accountHash,subjectHash,encrypted);
    return {connected:true,accountHash,subjectHash}; // No tokens, email or secret.
  }
}
