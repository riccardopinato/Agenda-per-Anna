// STAGING SOURCE ONLY. Verification with the EXISTING production Supabase Auth
// endpoint is read-only. No production keys or live sessions in test fixtures.
import {GcalStageFault} from './webcrypto_core.mjs';
const fail=code=>{throw new GcalStageFault(code);};
const PROD_AUTH_USER_URL='https://pxsxlorntswypdbeerzw.supabase.co/auth/v1/user';
const expectedHost='pxsxlorntswypdbeerzw.supabase.co';
export function createProductionIdentityVerifier({
  productionPublishableKey,fetcher=fetch,timeoutMs=7000,
}={}) {
  // Supabase publishable / legacy anon API key, NOT service_role/secret key.
  if(typeof productionPublishableKey!=='string'||productionPublishableKey.length<10||
    productionPublishableKey.length>4096||
    !Number.isInteger(timeoutMs)||timeoutMs<1000||timeoutMs>15000)
    fail('PRODUCTION_AUTH_CONFIG_MISSING');
  if(productionPublishableKey.startsWith('sb_secret_')) fail('NOT_A_PUBLIC_KEY');
  if(!productionPublishableKey.startsWith('sb_publishable_')) {
    // Legacy anon keys are JWTs. Decode only to classify the *configured key*,
    // never to authenticate a request. Reject legacy service_role credentials.
    let role;
    try {
      const fields=productionPublishableKey.split('.');
      if(fields.length!==3) fail('NOT_A_PUBLIC_KEY');
      const payload=fields[1].replaceAll('-','+').replaceAll('_','/');
      role=JSON.parse(atob(payload)).role;
    } catch {fail('NOT_A_PUBLIC_KEY');}
    if(role!=='anon')fail('NOT_A_PUBLIC_KEY');
  }
  return async function verifiedIdentity(authHeader) {
    if(typeof authHeader!=='string'||!/^Bearer [A-Za-z0-9._-]{50,8192}$/.test(authHeader))
      fail('MISSING_USER_TOKEN');
    const jwt=authHeader.slice(7);
    if(jwt.split('.').length!==3)fail('INVALID_USER_TOKEN');
    let response;
    try {
      const url=new URL(PROD_AUTH_USER_URL);
      if(url.hostname!==expectedHost||url.protocol!=='https:')fail('BAD_AUTH_HOST');
      response=await fetcher(url.href,{
        method:'GET',
        headers:{
          apikey:productionPublishableKey,
          authorization:'Bearer '+jwt,
          accept:'application/json',
        },
        redirect:'error',
        cache:'no-store',
        signal:AbortSignal.timeout(timeoutMs),
      });
    } catch {fail('PRODUCTION_AUTH_UNAVAILABLE');}
    if(!response?.ok)fail('PRODUCTION_AUTH_REJECTED');
    let body;
    try{body=await response.json();}catch{fail('PRODUCTION_AUTH_RESPONSE_INVALID');}
    // ID is derived only from the Supabase Auth /user response after remote
    // verification, NEVER from caller JSON, local JWT parsing or user_metadata.
    if(!body||typeof body.id!=='string'||
      !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(body.id)||
      body.is_anonymous===true) fail('UNTRUSTED_APP_IDENTITY');
    return Object.freeze({accountId:body.id.toLowerCase()});
  };
}
