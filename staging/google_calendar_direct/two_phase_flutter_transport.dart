// STAGING ONLY — no import from production lib/ entrypoints.
// The Google OAuth client secret, Google refresh/access tokens and code exchange
// belong exclusively to the staging Edge Function. This client transports only
// the existing short-lived Supabase app session JWT over pinned HTTPS.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'two_phase_flutter_client.dart';

const gcalStagingEdgeBase =
    'https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';

/// The already configured production Supabase identity is authoritative.
/// Never copy Supabase tokens to URLs, callback query parameters or logs.
Future<GcalStageAppAuth?> gcalCurrentAppAuth() async {
  final client = Supabase.instance.client;
  final session = client.auth.currentSession;
  final user = client.auth.currentUser;
  if (session == null || user == null || session.user.id != user.id) {
    return null;
  }
  if (session.accessToken.isEmpty) return null;
  return GcalStageAppAuth(user.id, session.accessToken);
}

/// Only the four authenticated app routes are permitted. Browser callback
/// is handled by Google -> Supabase, not by Flutter.
class GcalStagingEdgeTransport {
  final http.Client client;
  final Uri _base;
  const GcalStagingEdgeTransport(this.client, this._base);

  factory GcalStagingEdgeTransport.forStaging(http.Client client) =>
      GcalStagingEdgeTransport(client, Uri.parse(gcalStagingEdgeBase));

  Future<GcalStageResponse> post(
      String route, String productionJwt, Map<String, Object?> json) async {
    if (!const {'/start', '/preview', '/confirm', '/disconnect'}
        .contains(route)) {
      throw const GcalStageClientException(
          GcalStageClientFault.malformedBackendResponse);
    }
    if (_base.scheme != 'https' ||
        _base.host != 'pdanpljacyozslrutsor.supabase.co' ||
        _base.path != '/functions/v1/gcal-oauth-callback' ||
        productionJwt.trim().isEmpty) {
      throw const GcalStageClientException(
          GcalStageClientFault.malformedBackendResponse);
    }
    final uri = Uri(
        scheme: 'https',
        host: _base.host,
        path: _base.path + route);
    final request = http.Request('POST', uri);
    request.followRedirects = false; // Never forward an app JWT to a redirect.
    request.headers.addAll({
      'authorization': 'Bearer $productionJwt',
      'content-type': 'application/json; charset=utf-8',
      'accept': 'application/json',
      'cache-control': 'no-store',
    });
    request.body = jsonEncode(json);

    http.StreamedResponse response;
    try {
      response = await client.send(request).timeout(const Duration(seconds: 10));
      final bytes = <int>[];
      await for (final part in response.stream.timeout(const Duration(seconds: 10))) {
        if (bytes.length + part.length > 8192) {
          throw const FormatException('response too large');
        }
        bytes.addAll(part);
      }
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw const FormatException('unexpected redirect');
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException('not a JSON object');
      return GcalStageResponse(
          response.statusCode, Map<String, Object?>.from(decoded));
    } catch (_) {
      // No credentials, URLs or response bodies escape in an exception.
      throw const GcalStageClientException(GcalStageClientFault.requestRejected);
    }
  }
}

/// Opens Google in the external system browser (not an embedded WebView).
Future<void> gcalOpenSystemBrowser(Uri url) async {
  if (url.scheme != 'https' ||
      url.host != 'accounts.google.com' ||
      url.port != 443 ||
      url.hasFragment ||
      url.path != '/o/oauth2/v2/auth') {
    throw const GcalStageClientException(
        GcalStageClientFault.malformedBackendResponse);
  }
  final opened = await launchUrl(url,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication);
  if (!opened) {
    throw const GcalStageClientException(
        GcalStageClientFault.failedToOpenBrowser);
  }
}

/// No provider tokens or callback handles are written to disk.
GcalTwoPhaseFlutterStagingClient createGcalStagingClient(
        {required http.Client httpClient}) =>
    GcalTwoPhaseFlutterStagingClient(
      currentAuth: gcalCurrentAppAuth,
      post: GcalStagingEdgeTransport.forStaging(httpClient).post,
      openBrowser: gcalOpenSystemBrowser,
    );
