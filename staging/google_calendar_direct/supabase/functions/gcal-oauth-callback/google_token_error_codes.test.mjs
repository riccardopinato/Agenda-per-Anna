import test from 'node:test';
import assert from 'node:assert/strict';
import {exchangeGoogleCode,GcalStageFault} from './webcrypto_core.mjs';

const params={
  clientId:'test-client.apps.googleusercontent.com',
  clientSecret:'STAGING-TEST-SECRET',
  redirectUri:'https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback',
  code:'ONE_USE_CODE_TEST',
  verifier:'VALID_TEST_VERIFIER',
};
const expected={
  invalid_client:'GOOGLE_TOKEN_INVALID_CLIENT',
  invalid_grant:'GOOGLE_TOKEN_INVALID_GRANT',
  invalid_request:'GOOGLE_TOKEN_INVALID_REQUEST',
  unauthorized_client:'GOOGLE_TOKEN_UNAUTHORIZED_CLIENT',
  rare_provider_value:'GOOGLE_TOKEN_REJECTED'
};
for(const [googleCode,expectedFault] of Object.entries(expected)){
  test('whitelist provider token failure '+googleCode,async()=>{
    const fetcher=async(url,request)=>{
      assert.equal(url,'https://oauth2.googleapis.com/token');
      assert.equal(request.method,'POST');
      return new Response(JSON.stringify({
        error:googleCode,
        error_description:'PRIVATE-STAGING-SECRET-AND-CODE-MUST-NEVER-BE-LOGGED',
      }),{status:400,headers:{'content-type':'application/json'}});
    };
    await assert.rejects(
      exchangeGoogleCode({...params,fetcher}),
      error=>error instanceof GcalStageFault&&error.kind===expectedFault&&
        !error.message.includes('PRIVATE-STAGING-SECRET')
    );
  });
}
test('oversized untrusted token failure is never parsed into logs',async()=>{
  const fetcher=async()=>new Response(JSON.stringify({
    error:'invalid_client',other:'X'.repeat(3000),
  }),{status:401,headers:{'content-length':'3050'}});
  await assert.rejects(exchangeGoogleCode({...params,fetcher}),
    error=>error.kind==='GOOGLE_TOKEN_REJECTED');
});
