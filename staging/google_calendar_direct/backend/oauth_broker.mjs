import {
  randomBytes, createHash, timingSafeEqual, createPublicKey,
  verify as verifySignature, createCipheriv, createDecipheriv,
} from 'node:crypto';

// SOURCE-ONLY STAGING, Node >=20; not mounted in production Flutter or deployed.
export const OWNED_EVENTS='https://www.googleapis.com/auth/calendar.events.owned';
export const CALENDAR_LIST='https://www.googleapis.com/auth/calendar.calendarlist.readonly';
const SCOPES=['openid','email',OWNED_EVENTS,CALENDAR_LIST];
const AUTH_URL='https://accounts.google.com/o/oauth2/v2/auth';
const TOKEN_URL='https://oauth2.googleapis.com/token';
const JWKS_URL='https://www.googleapis.com/oauth2/v3/certs';
export class OAuthStagingError extends Error {
  constructor(code){super('OAuth staging: '+code);this.name='OAuthStagingError';this.code=code;}
}
const fail=(code)=>{throw new OAuthStagingError(code);};
const valid=(s,n=512)=>typeof s==='string'&&s.length>0&&s.length<=n;
const hash=(s)=>createHash('sha256').update(s).digest('hex');
const b64=(b)=>Buffer.from(b).toString('base64url');
const eq=(a,b)=>{
  if(!valid(a,4096)||!valid(b,4096))return false;
  const aa=Buffer.from(a),bb=Buffer.from(b);
  return aa.length===bb.length&&timingSafeEqual(aa,bb);
};
export function checkConfig({clientId,clientSecret,redirectUri}){
  if(!valid(clientId,200)||!clientId.endsWith('.apps.googleusercontent.com')||
     !valid(clientSecret,4096))fail('INVALID_CONFIGURATION');
  let url;try{url=new URL(redirectUri);}catch{fail('INVALID_REDIRECT');}
  if(url.protocol!=='https:'||!url.hostname||url.username||url.password||
     url.search||url.hash||url.hostname==='pxsxlorntswypdbeerzw.supabase.co')
     fail('INVALID_REDIRECT');
  return url;
}
export class GoogleCalendarOAuthBroker {
  constructor({clientId,clientSecret,redirectUri,pendingStore,linkStore,
      tokenClient,idVerifier,vault,clock=()=>Math.floor(Date.now()/1000),
      entropy=(n)=>randomBytes(n)}){
    this.redirect=checkConfig({clientId,clientSecret,redirectUri});
    for(const item of [pendingStore,linkStore,tokenClient,idVerifier,vault])
      if(!item)fail('MISSING_SECURE_ADAPTER');
    Object.assign(this,{clientId,clientSecret,pendingStore,linkStore,
      tokenClient,idVerifier,vault,clock,entropy});
  }
  async start({verifiedAppAccountId}){
    // The host MUST verify the Supabase session. Never read this from client JSON.
    if(!valid(verifiedAppAccountId,256))fail('UNAUTHENTICATED');
    const state=b64(this.entropy(32)),verifier=b64(this.entropy(64));
    const nonce=b64(this.entropy(32)),browserProof=b64(this.entropy(32));
    if(new Set([state,verifier,nonce,browserProof]).size!==4||
      ![state,verifier,nonce,browserProof].every(x=>/^[A-Za-z0-9_-]{43,128}$/.test(x)))
      fail('BAD_ENTROPY');
    // This must be an atomic, durable TTL store (test Map is NEVER a production adapter).
    const pending={accountId:verifiedAppAccountId,verifier,nonce,
      browserProofHash:hash(browserProof),issuedAt:this.clock()};
    if(await this.pendingStore.create(hash(state),pending)!==true)fail('STATE_COLLISION');
    const query=new URLSearchParams({
      client_id:this.clientId,redirect_uri:this.redirect.toString(),
      response_type:'code',scope:SCOPES.join(' '),state,nonce,
      code_challenge:b64(createHash('sha256').update(verifier).digest()),
      code_challenge_method:'S256',access_type:'offline',
      prompt:'select_account consent',include_granted_scopes:'false',
    });
    // The HTTPS host MUST set browserProof as a Secure HttpOnly SameSite=Lax cookie.
    // Never expose browserProof to client JavaScript, URL, telemetry or logs.
    return {authorizationUrl:AUTH_URL+'?'+query,browserProof};
  }
  async callback({callbackUrl,verifiedAppAccountId,browserProof}){
    if(!valid(verifiedAppAccountId,256))fail('UNAUTHENTICATED');
    let url;try{url=new URL(callbackUrl);}catch{fail('CALLBACK_MISMATCH');}
    if(url.origin!==this.redirect.origin||url.pathname!==this.redirect.pathname||
       url.hash||url.protocol!=='https:')fail('CALLBACK_MISMATCH');
    const states=url.searchParams.getAll('state');
    if(states.length!==1||!/^[A-Za-z0-9_-]{43,128}$/.test(states[0]))fail('BAD_STATE');
    // take is an atomic delete; even denied or expired callbacks are consumed.
    const tx=await this.pendingStore.take(hash(states[0]));
    if(!tx)fail('UNKNOWN_OR_REPLAYED_STATE');
    if(!eq(tx.accountId,verifiedAppAccountId))fail('ACCOUNT_MISMATCH');
    if(!eq(tx.browserProofHash,hash(browserProof||'')))fail('BROWSER_MISMATCH');
    const elapsed=this.clock()-tx.issuedAt;
    if(!Number.isFinite(elapsed)||elapsed<0||elapsed>600)fail('EXPIRED');
    if(url.searchParams.has('error')&&url.searchParams.has('code'))fail('BAD_CALLBACK');
    if(url.searchParams.has('error'))fail('ACCESS_DENIED');
    if(url.searchParams.getAll('code').length!==1||
       !valid(url.searchParams.get('code'),4096)||
       url.searchParams.has('access_token')||url.searchParams.has('id_token'))
      fail('BAD_CALLBACK');
    // Google receives the secret and PKCE verifier ONLY on this backend.
    const tokens=await this.tokenClient.exchange({clientId:this.clientId,
      clientSecret:this.clientSecret,redirectUri:this.redirect.toString(),
      code:url.searchParams.get('code'),codeVerifier:tx.verifier});
    if(!tokens||!valid(tokens.access_token,8192)||!valid(tokens.refresh_token,8192)||
       !valid(tokens.id_token,10000)||tokens.token_type?.toLowerCase()!=='bearer'||
       !Number.isInteger(tokens.expires_in)||tokens.expires_in<=0||
       tokens.expires_in>86400||!valid(tokens.scope,4096))fail('BAD_TOKEN_RESPONSE');
    const granted=new Set(tokens.scope.split(/\s+/));
    if(!SCOPES.every(scope=>granted.has(scope)))fail('INSUFFICIENT_SCOPES');
    const identity=await this.idVerifier.verify(tokens.id_token,
      {audience:this.clientId,nonce:tx.nonce,now:this.clock()});
    if(!valid(identity?.sub,256))fail('BAD_GOOGLE_IDENTITY');
    const key=hash(JSON.stringify(['anna-gcal-v1',verifiedAppAccountId,identity.sub]));
    const encrypted=await this.vault.seal({
      access_token:tokens.access_token,refresh_token:tokens.refresh_token,
      expires_at:this.clock()+tokens.expires_in,scope:tokens.scope,
    },key);
    await this.linkStore.put(key,{encrypted,googleSubject:identity.sub,
      appAccountHash:hash(verifiedAppAccountId)});
    return {connected:true,googleSubject:identity.sub,
      scopes:[OWNED_EVENTS,CALENDAR_LIST]}; // NEVER return access/refresh token.
  }
}
export class AesGcmTokenVault {
  constructor(key){if(!Buffer.isBuffer(key)||key.length!==32)fail('BAD_VAULT_KEY');
    this.key=Buffer.from(key);}
  async seal(record,aad){
    if(!/^[a-f0-9]{64}$/.test(aad))fail('BAD_VAULT_SCOPE');
    const iv=randomBytes(12),cipher=createCipheriv('aes-256-gcm',this.key,iv);
    cipher.setAAD(Buffer.from(aad));
    const encrypted=Buffer.concat([cipher.update(JSON.stringify(record)),cipher.final()]);
    return {version:1,iv:b64(iv),data:b64(encrypted),tag:b64(cipher.getAuthTag())};
  }
  async open(record,aad){
    if(record?.version!==1||!/^[a-f0-9]{64}$/.test(aad))fail('BAD_VAULT_SCOPE');
    try{
      const decipher=createDecipheriv('aes-256-gcm',this.key,Buffer.from(record.iv,'base64url'));
      decipher.setAAD(Buffer.from(aad));
      decipher.setAuthTag(Buffer.from(record.tag,'base64url'));
      return JSON.parse(Buffer.concat([decipher.update(Buffer.from(record.data,'base64url')),
        decipher.final()]).toString('utf8'));
    }catch{fail('VAULT_INTEGRITY');}
  }
}
export class GoogleTokenClient {
  constructor({fetchImpl=fetch}={}){this.fetchImpl=fetchImpl;}
  async exchange({clientId,clientSecret,redirectUri,code,codeVerifier}){
    const body=new URLSearchParams({client_id:clientId,client_secret:clientSecret,
      redirect_uri:redirectUri,code,code_verifier:codeVerifier,
      grant_type:'authorization_code'});
    let response;
    try{response=await this.fetchImpl(TOKEN_URL,{
      method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},
      body,signal:AbortSignal.timeout(8000),redirect:'error',
    });}catch{fail('PROVIDER_UNAVAILABLE');}
    if(!response.ok)fail('TOKEN_EXCHANGE_FAILED');
    return response.json();
  }
}
export class GoogleIdTokenVerifier {
  constructor({fetchImpl=fetch}={}){this.fetchImpl=fetchImpl;}
  async verify(jwt,{audience,nonce,now=Math.floor(Date.now()/1000)}){
    if(!valid(jwt,10000)||jwt.split('.').length!==3)fail('BAD_ID_TOKEN');
    let header,claims,parts;
    try{parts=jwt.split('.');header=JSON.parse(Buffer.from(parts[0],'base64url'));
      claims=JSON.parse(Buffer.from(parts[1],'base64url'));}
    catch{fail('BAD_ID_TOKEN');}
    if(header.alg!=='RS256'||!valid(header.kid,128))fail('UNTRUSTED_JWT_ALGORITHM');
    let response;
    try{response=await this.fetchImpl(JWKS_URL,{
      signal:AbortSignal.timeout(8000),redirect:'error',
    });}catch{fail('JWKS_UNAVAILABLE');}
    if(!response.ok)fail('JWKS_UNAVAILABLE');
    const payload=await response.json();
    const jwk=(payload.keys||[]).find(k=>k.kid===header.kid&&k.kty==='RSA'&&
      k.use==='sig'&&(!k.alg||k.alg==='RS256'));
    if(!jwk)fail('UNKNOWN_GOOGLE_KEY');
    let verified=false;
    try{verified=verifySignature('RSA-SHA256',Buffer.from(parts[0]+'.'+parts[1]),
      createPublicKey({key:jwk,format:'jwk'}),Buffer.from(parts[2],'base64url'));}
    catch{fail('BAD_ID_SIGNATURE');}
    if(!verified)fail('BAD_ID_SIGNATURE');
    if(!['https://accounts.google.com','accounts.google.com'].includes(claims.iss)||
       claims.aud!==audience||claims.nonce!==nonce||!valid(claims.sub,256)||
       !Number.isInteger(claims.exp)||claims.exp<=now||
       (claims.iat!=null&&(!Number.isInteger(claims.iat)||claims.iat>now+120))||
       (claims.nbf!=null&&claims.nbf>now))fail('BAD_ID_CLAIMS');
    return {sub:claims.sub,email:claims.email||null};
  }
}
// Fakes ONLY for unit tests. Never use in a deployed host.
export function testOnlyInMemoryStores(){
  const pending=new Map(),links=new Map();
  return {
    pendingStore:{
      async create(k,v){if(pending.has(k))return false;pending.set(k,v);return true;},
      async take(k){const v=pending.get(k);pending.delete(k);return v;}
    },
    linkStore:{
      async put(k,v){links.set(k,v);},
      async get(k){return links.get(k);}
    },
    _pending:pending,_links:links,
  };
}
