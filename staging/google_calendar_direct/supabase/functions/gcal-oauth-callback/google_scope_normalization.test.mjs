import test from 'node:test';
import assert from 'node:assert/strict';
import {scopesContainRequired,GOOGLE_SCOPE_EVENTS,
  GOOGLE_SCOPE_CALENDAR_LIST} from './webcrypto_core.mjs';

test("accepts Google's canonical userinfo.email while requiring every Calendar scope",()=>{
  const google='openid https://www.googleapis.com/auth/userinfo.email '+
    GOOGLE_SCOPE_EVENTS+' '+GOOGLE_SCOPE_CALENDAR_LIST;
  assert.equal(scopesContainRequired(google),true);
  assert.equal(scopesContainRequired('openid email '+GOOGLE_SCOPE_EVENTS+' '+
    GOOGLE_SCOPE_CALENDAR_LIST),true);
});
test('never treats email alias as a grant for missing calendar permission',()=>{
  const required='openid https://www.googleapis.com/auth/userinfo.email';
  assert.equal(scopesContainRequired(required),false);
  assert.equal(scopesContainRequired(required+' '+GOOGLE_SCOPE_CALENDAR_LIST),false);
  assert.equal(scopesContainRequired(required+' '+GOOGLE_SCOPE_EVENTS),false);
  assert.equal(scopesContainRequired(''),false);
  assert.equal(scopesContainRequired(null),false);
});
