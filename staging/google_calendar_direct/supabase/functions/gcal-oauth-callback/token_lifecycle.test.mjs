import test from 'node:test';
import assert from 'node:assert/strict';
import {GcalStageTokenLifecycle} from './token_lifecycle.mjs';
import {GcalStageVault,REQUIRED_SCOPES} from './webcrypto_core.mjs';

const USER='test-app-user',SUB='test-google-sub',NOW=1793710000;
function setup(expired=false,provider=async()=>({ok:true,status:200,
  json:async()=>({access_token:'fresh',token_type:'Bearer',expires_in:3600})})) {
  const records=new Map();
  const vault=new GcalStageVault(crypto.getRandomValues(new Uint8Array(32)));
  const sql={
    async getLink(a,s){return records.get(a+':'+s)??null;},
    async replaceLink(a,s,old,next){
      const key=a+':'+s;
      if(JSON.stringify(records.get(key))!==JSON.stringify(old))return false;
      records.set(key,next);return true;
    },
    async takeLink(a,s){const k=a+':'+s,v=records.get(k);records.delete(k);return v??null;}
  };
  const requests=[];
  const subject=new GcalStageTokenLifecycle({
    clientId:'test.apps.googleusercontent.com',clientSecret:'fixture-only',
    vault,linkStore:sql,clock:()=>NOW,fetcher:async(url,options)=>{
      requests.push({url,options});return provider(url,options,records);
    },
  });
  const seed=async()=>{
    const {accountHash,subjectHash,aad}=await subject._scope(USER,SUB);
    const record={googleSubject:SUB,accessToken:'old',refreshToken:'renew',
      expiresAt:NOW+(expired?-60:600),scope:REQUIRED_SCOPES.join(' ')};
    const key=accountHash+':'+subjectHash;
    records.set(key,await vault.seal(record,aad));
    return {key,aad};
  };
  return {subject,seed,records,requests,vault};
}
test('unexpired access stays server-side and does not contact provider',async()=>{
  const f=setup();await f.seed();
  assert.equal(await f.subject.accessToken({verifiedAccountId:USER,googleSubject:SUB}),'old');
  assert.equal(f.requests.length,0);
});
test('refresh replaces encrypted access and preserves the renewal grant',async()=>{
  const f=setup(true);const s=await f.seed();
  assert.equal(await f.subject.accessToken({verifiedAccountId:USER,googleSubject:SUB}),'fresh');
  assert.equal(f.requests.length,1);
  const data=await f.vault.open(f.records.get(s.key),s.aad);
  assert.equal(data.refreshToken,'renew');assert.equal(data.expiresAt,NOW+3600);
  assert.equal(JSON.stringify([...f.records]).includes('renew'),false);
});
test('wrong app account cannot use another account link',async()=>{
  const f=setup();await f.seed();
  await assert.rejects(f.subject.accessToken({
    verifiedAccountId:'other-app-user',googleSubject:SUB}),e=>e.kind==='NOT_CONNECTED');
});
test('parallel disconnection does not permit refresh to restore the link',async()=>{
  const f=setup(true,async(_url,_opts,records)=>{
    records.clear();
    return {ok:true,status:200,json:async()=>({
      access_token:'fresh',token_type:'Bearer',expires_in:3600})};
  });await f.seed();
  await assert.rejects(f.subject.accessToken({verifiedAccountId:USER,googleSubject:SUB}),
    e=>e.kind==='TOKEN_CHANGED_RETRY');
  assert.equal(f.records.size,0);
});
test('disconnect requires confirmation and reports provider success separately',async()=>{
  const f=setup(false,async()=>({status:200}));await f.seed();
  await assert.rejects(f.subject.disconnect({verifiedAccountId:USER,googleSubject:SUB}),
    e=>e.kind==='CONFIRMATION_REQUIRED');
  assert.deepEqual(await f.subject.disconnect({verifiedAccountId:USER,googleSubject:SUB,
    explicitConfirmation:true}),{disconnected:true,providerRevoked:true});
  assert.equal(f.records.size,0);
  assert.equal(f.requests.length,1);
});
test('provider outage unlinks locally but is not reported as revoked',async()=>{
  const f=setup(false,async()=>{throw Error('unavailable');});await f.seed();
  assert.deepEqual(await f.subject.disconnect({verifiedAccountId:USER,googleSubject:SUB,
    explicitConfirmation:true}),{disconnected:true,providerRevoked:false});
  assert.equal(f.records.size,0);
});
