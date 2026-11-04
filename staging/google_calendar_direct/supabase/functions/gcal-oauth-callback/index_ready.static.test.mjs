import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
const dir=new URL('./',import.meta.url);
const live=readFileSync(new URL('index_ready.mjs',dir),'utf8');
const deployed=readFileSync(new URL('index.ts',dir),'utf8');
test('deployed production path remains locked and cannot call live broker',()=>{
 assert.match(deployed,/STAGING_NOT_ACTIVATED/);
 assert.match(deployed,/google_oauth_active: false/);
 assert.equal(deployed.includes('two_phase_core.mjs'),false);
 assert.equal(deployed.includes('exchangeGoogleCode'),false);
});
test('unreleased broker entrypoint requires explicit activation gate',()=>{
 assert.match(live,/ANNA_GCAL_STAGING_ENABLE/);
 assert.match(live,/approved-for-live-oauth-testing/);
 assert.match(live,/createGoogleCalendarStagingHandler\(\{enabled:false\}\)/);
 assert.match(live,/catch\s*\{[\s\S]*enabled:false/);
});
test('staging database URL and callback pinned to test, not production',()=>{
 assert.match(live,/const STAGING_REF='pdanpljacyozslrutsor'/);
 assert.match(live,/const PRODUCTION_REF='pxsxlorntswypdbeerzw'/);
 assert.match(live,/DATABASE_PROJECT_MISMATCH/);
 assert.match(live,/DATABASE_PROJECT_MISMATCH/);
 assert.match(live,/ssl:'require'/);
 assert.match(live,/prepare:false/);
});
test('JWT authentication and OAuth credentials remain server-side only',()=>{
 assert.match(live,/createProductionIdentityVerifier/);
 assert.match(live,/GcalTwoPhaseBroker/);
 assert.match(live,/GcalStageTokenLifecycle/);
 assert.match(live,/GcalStageRequestBudget/);
 assert.match(live,/requestBudget/);
 assert.equal(deployed.includes('request_budget.mjs'),false);
 assert.equal(deployed.includes('token_lifecycle.mjs'),false);
 assert.match(live,/ANNA_GCAL_STAGING_WEB_CLIENT_SECRET/);
 assert.match(live,/ANNA_GCAL_PRODUCTION_PUBLISHABLE_KEY/);
 assert.equal(live.includes('supabase.co/auth/v1/callback'),false);
 assert.equal(live.includes('service_role'),false);
 assert.equal(live.includes('console.log'),false);
});
