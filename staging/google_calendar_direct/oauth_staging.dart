// STAGING ONLY — NOT IMPORTED BY PRODUCTION.
// Separate Google Calendar OAuth authorization-code handshake with PKCE.
// No token endpoint, refresh token, Google API call, callback listener,
// persistent secret store, production Supabase integration or login change.
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'calendar_staging.dart';

const googleCalendarOAuthAuthorizeEndpoint =
    'https://accounts.google.com/o/oauth2/v2/auth';
const googleCalendarOAuthIdentityScopes = 'openid email';

enum GcalOAuthStagingFailure {
  invalidConfiguration,
  alreadyPending,
  notPending,
  expired,
  accountChanged,
  wrongRedirect,
  badState,
  malformedResponse,
  accessDenied,
}

/// Do not log error response parameters or Google authorization codes.
class GcalOAuthStagingException implements Exception {
  final GcalOAuthStagingFailure kind;
  const GcalOAuthStagingException(this.kind);

  @override
  String toString() => 'Google Calendar staging OAuth: ${kind.name}';
}

/// Must return cryptographically random, base64url characters with no padding.
/// This port is injected for deterministic tests; never use a seeded PRNG
/// or predictable counter as the provider in real OAuth flows.
abstract class GcalOAuthEntropy {
  String randomBase64Url(int bytes);
}

class SecureGcalOAuthEntropy implements GcalOAuthEntropy {
  final Random _random = Random.secure();

  @override
  String randomBase64Url(int bytes) {
    if (bytes < 32) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.invalidConfiguration);
    }
    final data = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64Url.encode(data).replaceAll('=', '');
  }
}

class GcalOAuthStagingConfig {
  final String clientId;
  final Uri redirectUri;
  final Duration maxCallbackAge;

  const GcalOAuthStagingConfig({
    required this.clientId,
    required this.redirectUri,
    this.maxCallbackAge = const Duration(minutes: 10),
  });

  void validate() {
    // The OAuth Web client requires an owned HTTPS backend callback.
    // Never use the production Supabase callback for this staging client,
    // nor an Android custom-scheme URI with a Google Web client.
    if (!clientId.endsWith('.apps.googleusercontent.com') ||
        clientId.trim().isEmpty ||
        redirectUri.scheme != 'https' ||
        redirectUri.host.isEmpty ||
        redirectUri.userInfo.isNotEmpty ||
        redirectUri.hasQuery ||
        redirectUri.hasFragment ||
        maxCallbackAge <= Duration.zero ||
        maxCallbackAge > const Duration(minutes: 15)) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.invalidConfiguration);
    }
  }
}

/// The public URL only: the PKCE verifier remains in the in-memory session.
class GcalOAuthAuthorizationRequest {
  final Uri url;
  const GcalOAuthAuthorizationRequest(this.url);
}

/// Authorization code is not a verified Google identity or access token.
/// Never log, serialize, display, or store this transient exchange material.
/// The future HTTPS backend must verify state binding, PKCE, ID token issuer,
/// audience, nonce, subject, granted scopes and app account before linking.
class GcalOAuthAuthorizationGrant {
  final String code;
  final String codeVerifier;
  final String nonce;
  final String appAccountId;
  final Uri redirectUri;

  const GcalOAuthAuthorizationGrant({
    required this.code,
    required this.codeVerifier,
    required this.nonce,
    required this.appAccountId,
    required this.redirectUri,
  });

  @override
  String toString() => 'GcalOAuthAuthorizationGrant(REDACTED)';
}

class _PendingGoogleConsent {
  final String state;
  final String verifier;
  final String nonce;
  final String appAccountId;
  final DateTime issuedAt;
  const _PendingGoogleConsent(
    this.state, this.verifier, this.nonce, this.appAccountId, this.issuedAt);
}

/// One request per instance. No web reload recovery or platform callback
/// registration: those require an independently reviewed integration PR.
class GcalOAuthStagingHandshake {
  final GcalOAuthStagingConfig config;
  final GcalOAuthEntropy entropy;
  final DateTime Function() now;
  _PendingGoogleConsent? _pending;

  GcalOAuthStagingHandshake({
    required this.config,
    GcalOAuthEntropy? entropy,
    DateTime Function()? now,
  }) : entropy = entropy ?? SecureGcalOAuthEntropy(),
       now = now ?? DateTime.now {
    config.validate();
  }

  bool get hasPendingConsent => _pending != null;

  GcalOAuthAuthorizationRequest begin({required String appAccountId}) {
    if (_pending != null) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.alreadyPending);
    }
    if (appAccountId.trim().isEmpty) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.invalidConfiguration);
    }
    final verifier = entropy.randomBase64Url(64);
    final state = entropy.randomBase64Url(32);
    final nonce = entropy.randomBase64Url(32);
    final valid = RegExp(r'^[A-Za-z0-9_-]+$');
    if (verifier.length < 43 || verifier.length > 128 ||
        state.length < 43 || nonce.length < 43 ||
        !valid.hasMatch(verifier) ||
        !valid.hasMatch(state) || !valid.hasMatch(nonce) ||
        verifier == state || nonce == state || nonce == verifier) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.invalidConfiguration);
    }
    final challenge = base64Url.encode(
      sha256.convert(utf8.encode(verifier)).bytes,
    ).replaceAll('=', '');
    _pending = _PendingGoogleConsent(
        state, verifier, nonce, appAccountId, now().toUtc());
    final authorizationUrl = Uri.parse(googleCalendarOAuthAuthorizeEndpoint)
        .replace(queryParameters: <String, String>{
      'client_id': config.clientId,
      'redirect_uri': config.redirectUri.toString(),
      'response_type': 'code',
      'scope':
          '$googleCalendarOAuthIdentityScopes '
          '$googleCalendarOwnedEventsScope $googleCalendarListReadScope',
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
      'state': state,
      'nonce': nonce,
      'access_type': 'offline',
      'prompt': 'select_account consent',
      'include_granted_scopes': 'false',
    });
    return GcalOAuthAuthorizationRequest(authorizationUrl);
  }

  /// Consume once; even rejected/expired callbacks invalidate the attempt.
  /// A completed handshake does NOT prove Google authentication.
  GcalOAuthAuthorizationGrant acceptCallback(
    Uri response, {
    required String currentAppAccountId,
  }) {
    final pending = _pending;
    if (pending == null) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.notPending);
    }
    _pending = null;

    final elapsed = now().toUtc().difference(pending.issuedAt);
    if (elapsed.isNegative || elapsed > config.maxCallbackAge) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.expired);
    }
    if (currentAppAccountId.trim().isEmpty ||
        currentAppAccountId != pending.appAccountId) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.accountChanged);
    }
    if (response.scheme != config.redirectUri.scheme ||
        response.host != config.redirectUri.host ||
        response.port != config.redirectUri.port ||
        response.path != config.redirectUri.path ||
        response.userInfo != config.redirectUri.userInfo ||
        response.hasFragment) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.wrongRedirect);
    }
    final fields = response.queryParametersAll;
    if (fields['state']?.length != 1 ||
        fields['state']!.single != pending.state) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.badState);
    }
    final hasError = fields.containsKey('error');
    final hasCode = fields.containsKey('code');
    if (hasError == hasCode ||
        (hasCode && (fields['code']?.length != 1 ||
            fields['code']!.single.trim().isEmpty)) ||
        (hasError && fields['error']?.length != 1) ||
        fields.containsKey('access_token') ||
        fields.containsKey('id_token')) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.malformedResponse);
    }
    if (hasError) {
      throw const GcalOAuthStagingException(
          GcalOAuthStagingFailure.accessDenied);
    }
    return GcalOAuthAuthorizationGrant(
      code: fields['code']!.single,
      codeVerifier: pending.verifier,
      nonce: pending.nonce,
      appAccountId: pending.appAccountId,
      redirectUri: config.redirectUri,
    );
  }

  void cancel() => _pending = null;
}
