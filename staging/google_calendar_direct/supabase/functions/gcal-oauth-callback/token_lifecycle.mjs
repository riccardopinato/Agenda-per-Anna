// STAGING SOURCE ONLY — server-side token lifecycle for the selected two-phase flow.
// Do NOT import from Flutter or deploy as the live callback before gated QA.
// Only a trusted backend may call accessToken(); never serialize its return to HTTP.
import {GcalStageFault,GcalStageVault,sha256Hex,REQUIRED_SCOPES,TOKEN_ENDPOINT} from './webcrypto_core.mjs';

const REVOCATION_ENDPOINT='https://oauth2.googleapis.com/revoke';
const fail=code=>{throw new GcalStageFault(code);};
const textOk=(x,max=4096)=>typeof x==='string'&&x.length>0&&x.length<=max;
const scopesOk=s=>textOk(s)&&REQUIRED_SCOPES.every(x=>new Set(s.split(/\s+/)).has(x));

export class GcalStageTokenLifecycle {
  // linkStore.getLink(accountHash,subjectHash): encrypted envelope|null
  // linkStore.replaceLink(accountHash,subjectHash,oldEnvelope,newEnvelope): boolean (CAS)
  // linkStore.takeLink(accountHash,subjectHash): encrypted envelope|null (atomic delete)
  constructor({clientId,clientSecret,vault,linkStore,fetcher=fetch,
    clock=()=>Math.floor(Date.now()/1000),timeoutMs=8000}={}) {
    if(!textOk(clientId,256)||!clientId.endsWith('.apps.googleusercontent.com')||
       !textOk(clientSecret)||!(vault instanceof GcalStageVault)||
       !linkStore||!['getLink','replaceLink','takeLink'].every(x=>typeof linkStore[x]==='function')||
       typeof fetcher!=='function'||typeof clock!=='function'||
       !Number.isInteger(timeoutMs)||timeoutMs<1000||timeoutMs>15000) fail('LIFECYCLE_NOT_CONFIGURED');
    Object.assign(this,{clientId,clientSecret,vault,linkStore,fetcher,clock,timeoutMs});
  }
  async _scope(verifiedAccountId,googleSubject) {
    if(!textOk(verifiedAccountId,256)||!textOk(googleSubject,256))fail('ACCOUNT_REQUIRED');
    const accountHash=await sha256Hex('anna-staging-account-v2:'+verifiedAccountId);
    const subjectHash=await sha256Hex('anna-staging-google-v2:'+googleSubject);
    return {accountHash,subjectHash,aad:accountHash+':'+subjectHash};
  }
  _assertRecord(record,googleSubject) {
    if(!record||record.googleSubject!==googleSubject||
       !textOk(record.accessToken,10000)||!textOk(record.refreshToken,10000)||
       !Number.isInteger(record.expiresAt)||!scopesOk(record.scope))fail('REAUTH_REQUIRED');
  }
  async accessToken({verifiedAccountId,googleSubject}={}) {
    const {accountHash,subjectHash,aad}=await this._scope(verifiedAccountId,googleSubject);
    const oldEnvelope=await this.linkStore.getLink(accountHash,subjectHash);
    if(!oldEnvelope)fail('NOT_CONNECTED');
    const record=await this.vault.open(oldEnvelope,aad);
    this._assertRecord(record,googleSubject);
    const now=this.clock();
    if(record.expiresAt>now+120)return record.accessToken;
    const form=new URLSearchParams({
      client_id:this.clientId,client_secret:this.clientSecret,
      refresh_token:record.refreshToken,grant_type:'refresh_token',
    });
    let response;
    try {
      response=await this.fetcher(TOKEN_ENDPOINT,{
        method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},
        body:form,redirect:'error',cache:'no-store',signal:AbortSignal.timeout(this.timeoutMs),
      });
    } catch {fail('REFRESH_UNAVAILABLE');}
    if(!response?.ok)fail(response?.status===400||response?.status===401?
      'REAUTH_REQUIRED':'REFRESH_UNAVAILABLE');
    let next;
    try{next=await response.json();}catch{fail('BAD_REFRESH_RESPONSE');}
    if(!textOk(next?.access_token,10000)||next?.token_type?.toLowerCase()!=='bearer'||
       !Number.isInteger(next.expires_in)||next.expires_in<60||next.expires_in>86400||
       (next.refresh_token!==undefined&&!textOk(next.refresh_token,10000))||
       (next.scope!==undefined&&!scopesOk(next.scope)))fail('BAD_REFRESH_RESPONSE');
    const updated={
      ...record,accessToken:next.access_token,
      refreshToken:next.refresh_token??record.refreshToken,
      expiresAt:now+next.expires_in,scope:next.scope??record.scope,
    };
    // AES-GCM binds the ciphertext to this app account and Google subject.
    // CAS prevents a delayed refresh from recreating a disconnected account link.
    const encrypted=await this.vault.seal(updated,aad);
    if(await this.linkStore.replaceLink(accountHash,subjectHash,oldEnvelope,encrypted)!==true)
      fail('TOKEN_CHANGED_RETRY');
    return updated.accessToken;
  }
  async disconnect({verifiedAccountId,googleSubject,explicitConfirmation=false}={}) {
    if(explicitConfirmation!==true)fail('CONFIRMATION_REQUIRED');
    const {accountHash,subjectHash,aad}=await this._scope(verifiedAccountId,googleSubject);
    // Locally unlink first, atomically. Provider revocation can be unavailable;
    // NEVER claim it succeeded when it has not.
    const encrypted=await this.linkStore.takeLink(accountHash,subjectHash);
    if(!encrypted)return {disconnected:true,providerRevoked:null};
    let token=null;
    try {
      const record=await this.vault.open(encrypted,aad);
      this._assertRecord(record,googleSubject);
      token=record.refreshToken;
    } catch {return {disconnected:true,providerRevoked:false};}
    try {
      const response=await this.fetcher(REVOCATION_ENDPOINT,{
        method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},
        body:new URLSearchParams({token}),redirect:'error',cache:'no-store',
        signal:AbortSignal.timeout(this.timeoutMs),
      });
      return {disconnected:true,providerRevoked:response?.status===200};
    } catch {
      return {disconnected:true,providerRevoked:false};
    }
  }
}
