// STAGING SOURCE ONLY — NOT DEPLOYED. This is the future live Edge entrypoint.
// Current deployed index.ts is a 503 kill-switch. NO actual OAuth is initiated.
// Runtime fails CLOSED if any dependency/secret/project invariant is missing.
// Stage secrets must be configured privately in Supabase, never in GitHub.
import postgres from 'npm:postgres@3.4.7';
import {GcalStageVault} from './webcrypto_core.mjs';
import {GcalTwoPhaseBroker} from './two_phase_core.mjs';
import {GcalStageTokenLifecycle} from './token_lifecycle.mjs';
import {GcalStageRequestBudget} from './request_budget.mjs';
import {GcalStageCallbackBudget} from './callback_budget.mjs';
import {GcalStagePostgresPorts} from './db_ports.mjs';
import {GcalStageConfirmationPorts} from './confirmation_ports.mjs';
import {createProductionIdentityVerifier} from './production_identity.mjs';
import {createGoogleCalendarStagingHandler} from './http_handler.mjs';

const STAGING_REF='pdanpljacyozslrutsor';
const CALLBACK='https://'+STAGING_REF+'.supabase.co/functions/v1/gcal-oauth-callback';
const PRODUCTION_REF='pxsxlorntswypdbeerzw';
function readSecret(name) {
  const value=Deno.env.get(name);
  if(!value||value.length>10000)throw Error('MISSING_STAGING_CONFIGURATION');
  return value;
}
function base64Key(value) {
  if(!/^[A-Za-z0-9+/]{42,44}={0,2}$/.test(value))throw Error('INVALID_KEY_CONFIGURATION');
  let binary;
  try{binary=atob(value);}catch{throw Error('INVALID_KEY_CONFIGURATION');}
  if(binary.length!==32)throw Error('INVALID_KEY_CONFIGURATION');
  return Uint8Array.from(binary,c=>c.charCodeAt(0));
}
function databaseIsStaging(urlText) {
  let u;
  try{u=new URL(urlText);}catch{throw Error('BAD_DATABASE_URL');}
  if(!['postgres:','postgresql:'].includes(u.protocol)||
    u.password.length===0||u.pathname!=='/postgres')throw Error('BAD_DATABASE_URL');
  const direct=u.hostname==='db.'+STAGING_REF+'.supabase.co';
  const pooled=u.hostname.endsWith('.pooler.supabase.com')&&
    u.username.endsWith('.'+STAGING_REF);
  if(!(direct||pooled)||u.hostname.includes(PRODUCTION_REF))
    throw Error('DATABASE_PROJECT_MISMATCH');
}
function readyRouter() {
  const clientId=readSecret('ANNA_GCAL_STAGING_WEB_CLIENT_ID');
  const clientSecret=readSecret('ANNA_GCAL_STAGING_WEB_CLIENT_SECRET');
  const prodPublicKey=readSecret('ANNA_GCAL_PRODUCTION_PUBLISHABLE_KEY');
  const encryptionKey=base64Key(readSecret('ANNA_GCAL_STAGING_AES256_KEY_BASE64'));
  const dbUrl=readSecret('SUPABASE_DB_URL');
  databaseIsStaging(dbUrl);
  const conn=postgres(dbUrl,{
    max:1,prepare:false,ssl:'require',connect_timeout:8,idle_timeout:10,
    connection:{application_name:'anna_gcal_staging'},
  });
  const ports=new GcalStagePostgresPorts(conn);
  const confirmations=new GcalStageConfirmationPorts(conn);
  const vault=new GcalStageVault(encryptionKey);
  const broker=new GcalTwoPhaseBroker({
    clientId,clientSecret,redirectUri:CALLBACK,vault,
    pendingStore:ports,completionStore:confirmations,linkStore:ports,
  });
  const requestBudget=new GcalStageRequestBudget(conn);
  const callbackBudget=new GcalStageCallbackBudget(conn);
  const tokenLifecycle=new GcalStageTokenLifecycle({
    clientId,clientSecret,vault,linkStore:ports,
  });
  const verifyAppIdentity=createProductionIdentityVerifier({
    productionPublishableKey:prodPublicKey,
  });
  return createGoogleCalendarStagingHandler({
    enabled:true,broker,verifyAppIdentity,tokenLifecycle,requestBudget,callbackBudget,
    allowedWebOrigins:['https://riccardopinato.github.io'],
  });
}
let handler=createGoogleCalendarStagingHandler({enabled:false});
if(Deno.env.get('ANNA_GCAL_STAGING_ENABLE')==='approved-for-live-oauth-testing' &&
   Deno.env.get('ANNA_GCAL_STAGING_LIVE_APPROVED_20261104')==='owner-authorized-google-consent') {
  try {handler=readyRouter();}
  catch {
    // Do NOT print environment variables or provider secrets.
    handler=createGoogleCalendarStagingHandler({enabled:false});
  }
}
Deno.serve(req=>handler(req));
