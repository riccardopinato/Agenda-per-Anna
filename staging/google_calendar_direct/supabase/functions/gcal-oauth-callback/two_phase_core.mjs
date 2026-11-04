// STAGING SOURCE ONLY — two-phase Google OAuth for an external browser.
// The deployed Edge Function does NOT import this module.
// Host MUST pass verified Supabase account IDs, not user-controlled IDs.
// Start returns an opaque confirmation handle only via authenticated JSON;
// Google callback consumes single-use state, then parks encrypted credentials;
// explicitly confirmed authenticated completion is required to link accounts.
// No cookies or cross-origin bearer URLs required.
import {GcalStageFault, GcalStageVault, randomUrl,sha256Hex,pkceS256,
  REQUIRED_SCOPES,AUTH_ENDPOINT,checkOauthConfig,exchangeGoogleCode,
  verifyGoogleIdToken} from './webcrypto_core.mjs';

const fail = kind => { throw new GcalStageFault(kind); };
const valid=(v,max=256)=>typeof v==='string'&&v.length>0&&v.length<=max;
const safeEqual=(a,b)=>{
  if (!valid(a,4096)||!valid(b,4096)) return false;
  let diff=a.length^b.length;
  for(let i=0;i<Math.max(a.length,b.length);i++) diff|=(a.charCodeAt(i)||0)^(b.charCodeAt(i)||0);
  return diff===0;
};
export class GcalTwoPhaseBroker {
  // pendingStore.create(stateHash, envelope, expiresAt): boolean
  // pendingStore.take(stateHash): envelope|null (atomic DELETE RETURNING)
  // completionStore.create(handleHash, accountHash, envelope, expiresAt): boolean
  // completionStore.read(handleHash, accountHash): envelope|null
  // completionStore.take(handleHash, accountHash): envelope|null (atomic)
  // linkStore.put(accountHash, subjectHash, envelope): void
  constructor({clientId,clientSecret,redirectUri,vault,pendingStore,completionStore,
    linkStore,tokenExchange=exchangeGoogleCode,idVerifier=verifyGoogleIdToken,
    clock=()=>Math.floor(Date.now()/1000)}) {
    this.redirect=checkOauthConfig({clientId,redirectUri});
    if(!valid(clientSecret,4096)||!(vault instanceof GcalStageVault)||
       !pendingStore||!completionStore||!linkStore)fail('MISSING_ADAPTER');
    Object.assign(this,{clientId,clientSecret,vault,pendingStore,completionStore,
      linkStore,tokenExchange,idVerifier,clock});
  }
  async start({verifiedAccountId}) {
    if(!valid(verifiedAccountId))fail('UNAUTHENTICATED');
    const state=randomUrl(32),verifier=randomUrl(64),nonce=randomUrl(32),
      handle=randomUrl(32),stateHash=await sha256Hex(state),
      handleHash=await sha256Hex(handle),issuedAt=this.clock();
    const accountHash=await sha256Hex('anna-staging-account-v2:'+verifiedAccountId);
    const envelope=await this.vault.seal({accountHash,nonce,verifier,
      handleHash,issuedAt},stateHash);
    if(await this.pendingStore.create(stateHash,envelope,issuedAt+600)!==true)
      fail('STATE_COLLISION');
    const query=new URLSearchParams({client_id:this.clientId,
      redirect_uri:this.redirect.toString(),response_type:'code',
      scope:REQUIRED_SCOPES.join(' '),code_challenge:await pkceS256(verifier),
      code_challenge_method:'S256',state,nonce,
      access_type:'offline',prompt:'select_account consent',
      include_granted_scopes:'false'});
    return {authorizationUrl:AUTH_ENDPOINT+'?'+query,handle,expiresAt:issuedAt+600};
  }
  async callback({callbackUrl}) {
    let url;try{url=new URL(callbackUrl);}catch{fail('WRONG_CALLBACK');}
    if(url.origin!==this.redirect.origin||url.pathname!==this.redirect.pathname||
       url.hash)fail('WRONG_CALLBACK');
    const states=url.searchParams.getAll('state');
    if(states.length!==1||!/^[A-Za-z0-9_-]{43}$/.test(states[0]))fail('BAD_STATE');
    const stateHash=await sha256Hex(states[0]);
    const envelope=await this.pendingStore.take(stateHash);
    if(!envelope)fail('REPLAY_OR_UNKNOWN_STATE');
    const tx=await this.vault.open(envelope,stateHash);
    const elapsed=this.clock()-tx.issuedAt;
    if(!Number.isFinite(elapsed)||elapsed<0||elapsed>600)fail('EXPIRED');
    const errors=url.searchParams.getAll('error'),codes=url.searchParams.getAll('code');
    if(errors.length){
      if(errors.length!==1||codes.length)fail('BAD_CALLBACK');
      fail('ACCESS_DENIED');
    }
    if(codes.length!==1||!valid(codes[0],4096)||
      url.searchParams.has('access_token')||url.searchParams.has('id_token'))
      fail('BAD_CALLBACK');
    const tokens=await this.tokenExchange({clientId:this.clientId,
      clientSecret:this.clientSecret,redirectUri:this.redirect.toString(),
      code:codes[0],verifier:tx.verifier});
    if(!valid(tokens?.access_token,10000)||!valid(tokens?.refresh_token,10000)||
       !valid(tokens?.id_token,12000)||tokens?.token_type?.toLowerCase()!=='bearer'||
       !Number.isInteger(tokens.expires_in)||tokens.expires_in<60||
       tokens.expires_in>86400||!valid(tokens.scope,4096))fail('BAD_TOKEN_RESPONSE');
    const granted=new Set(tokens.scope.split(/\s+/));
    if(!REQUIRED_SCOPES.every(s=>granted.has(s)))fail('SCOPE_MISMATCH');
    const identity=await this.idVerifier(tokens.id_token,{
      clientId:this.clientId,nonce:tx.nonce,now:this.clock()});
    if(!valid(identity?.subject))fail('BAD_GOOGLE_SUBJECT');
    const subjectHash=await sha256Hex('anna-staging-google-v2:'+identity.subject);
    const pendingEnvelope=await this.vault.seal({
      accountHash:tx.accountHash,subjectHash,googleSubject:identity.subject,
      googleEmail:identity.emailVerified===true?identity.email:null,
      accessToken:tokens.access_token,refreshToken:tokens.refresh_token,
      expiresAt:this.clock()+tokens.expires_in,scope:tokens.scope,
      issuedAt:this.clock(),
    },tx.handleHash);
    // Must use a durable store with atomic CREATE and expiry; an authorizing
    // Google callback cannot create the permanent link.
    if(await this.completionStore.create(tx.handleHash,tx.accountHash,
      pendingEnvelope,this.clock()+600)!==true)fail('COMPLETION_COLLISION');
    return {received:true,connected:false}; // Do not return tokens or handle to browser.
  }
  async preview({verifiedAccountId,handle}) {
    const {accountHash,handleHash}=await this._keyFor(verifiedAccountId,handle);
    const envelope=await this.completionStore.read(handleHash,accountHash);
    if(!envelope) return {status:'waiting'};
    const record=await this.vault.open(envelope,handleHash);
    this._checkPending(record,accountHash);
    return {status:'awaiting_confirmation',googleSubject:record.googleSubject,
      googleEmail:record.googleEmail||null}; // No access/refresh tokens.
  }
  async confirm({verifiedAccountId,handle,explicitConfirmation=false}) {
    if(explicitConfirmation!==true)fail('CONFIRMATION_REQUIRED');
    const {accountHash,handleHash}=await this._keyFor(verifiedAccountId,handle);
    // SQL DELETE is scoped by BOTH handle and authenticated user ID hash.
    // Wrong-account requests cannot consume another user's confirmation.
    const envelope=await this.completionStore.take(handleHash,accountHash);
    if(!envelope)fail('COMPLETION_NOT_READY');
    const record=await this.vault.open(envelope,handleHash);
    this._checkPending(record,accountHash);
    const encrypted=await this.vault.seal({
      googleSubject:record.googleSubject,googleEmail:record.googleEmail||null,
      accessToken:record.accessToken,refreshToken:record.refreshToken,
      expiresAt:record.expiresAt,scope:record.scope,
    },accountHash+':'+record.subjectHash);
    await this.linkStore.put(accountHash,record.subjectHash,encrypted);
    return {connected:true,googleSubject:record.googleSubject,
      googleEmail:record.googleEmail||null}; // Never return provider tokens.
  }
  _checkPending(record,accountHash) {
    if(!safeEqual(record?.accountHash,accountHash))fail('ACCOUNT_MISMATCH');
    const age=this.clock()-record.issuedAt;
    if(!Number.isInteger(age)||age<0||age>600)fail('EXPIRED');
  }
  async _keyFor(account,handle) {
    if(!valid(account)||!valid(handle,128)||!/^[A-Za-z0-9_-]{43}$/.test(handle))
      fail('UNAUTHENTICATED_OR_INVALID_HANDLE');
    return {
      accountHash:await sha256Hex('anna-staging-account-v2:'+account),
      handleHash:await sha256Hex(handle),
    };
  }
}
