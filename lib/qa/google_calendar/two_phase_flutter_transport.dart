// STAGING ONLY — no production app entrypoint imports this file.
// Google tokens/client secrets stay solely on the Supabase staging backend.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'two_phase_flutter_client.dart';

const gcalStagingEdgeBase =
    'https://pdanpljacyozslrutsor.supabase.co/functions/v1/gcal-oauth-callback';

/// Uses the logged-in production Supabase account only for identity.
/// Never sends JWTs in URLs, error messages or QA health checks.
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

class GcalStagingEdgeTransport {
  final http.Client client;
  final Uri _base;
  const GcalStagingEdgeTransport(this.client, this._base);

  factory GcalStagingEdgeTransport.forStaging(http.Client client) =>
      GcalStagingEdgeTransport(client, Uri.parse(gcalStagingEdgeBase));

  void _requireBase() {
    if (_base.scheme != 'https' ||
        _base.host != 'pdanpljacyozslrutsor.supabase.co' ||
        _base.path != '/functions/v1/gcal-oauth-callback') {
      throw const GcalStageClientException(
          GcalStageClientFault.malformedBackendResponse);
    }
  }

  Uri _uri(String suffix) => Uri(
        scheme: 'https',
        host: _base.host,
        path: _base.path + suffix,
      );

  Future<GcalStageResponse> _sendJson(http.Request request, {int maxBytes = 8192}) async {
    request.followRedirects = false;
    try {
      final response =
          await client.send(request).timeout(const Duration(seconds: 10));
      final bytes = <int>[];
      await for (final part
          in response.stream.timeout(const Duration(seconds: 10))) {
        if (bytes.length + part.length > maxBytes) {
          throw const FormatException('Oversized response');
        }
        bytes.addAll(part);
      }
      if (response.statusCode >= 300 && response.statusCode < 400) {
        throw const FormatException('Unexpected redirect');
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw const FormatException('Not a JSON map');
      return GcalStageResponse(
          response.statusCode, Map<String, Object?>.from(decoded));
    } on TimeoutException {
      throw const GcalStageClientException(GcalStageClientFault.requestTimedOut);
    } on http.ClientException {
      throw const GcalStageClientException(
          GcalStageClientFault.networkUnavailable);
    } on FormatException {
      throw const GcalStageClientException(
          GcalStageClientFault.invalidServerResponse);
    } on GcalStageClientException {
      rethrow;
    } catch (_) {
      // Do not print exception bodies; they may contain URLs/headers.
      throw const GcalStageClientException(
          GcalStageClientFault.requestRejected);
    }
  }

  Future<GcalStageResponse> post(
      String route, String productionJwt, Map<String, Object?> json) async {
    _requireBase();
    if (!const {
      '/start', '/preview', '/confirm', '/disconnect',
      '/connections', '/calendars', '/events'
    }.contains(route) || productionJwt.trim().isEmpty) {
      throw const GcalStageClientException(
          GcalStageClientFault.malformedBackendResponse);
    }
    final request = http.Request('POST', _uri(route));
    request.headers.addAll({
      'authorization': 'Bearer $productionJwt',
      'content-type': 'application/json; charset=utf-8',
      'accept': 'application/json',
      'cache-control': 'no-store',
    });
    request.body = jsonEncode(json);
    return _sendJson(request, maxBytes: route == '/events' ? 65536 : 8192);
  }

  /// Public connectivity-only probe. Never sends JWTs or user identifiers.
  Future<GcalStageServerHealth> probeServer() async {
    _requireBase();
    final request = http.Request('GET', _uri('/health'));
    request.headers.addAll({
      'accept': 'application/json',
      'cache-control': 'no-store',
    });
    final response = await _sendJson(request);
    if (response.status != 200) {
      throw const GcalStageClientException(
          GcalStageClientFault.serverUnavailable);
    }
    final json = response.json;
    if (json['service'] != 'anna-calendar-staging' ||
        !const {'locked', 'configured'}.contains(json['status']) ||
        json['google_oauth_active'] is! bool ||
        json['google_calendar_writes_active'] != false ||
        (json['status'] == 'configured') != json['google_oauth_active']) {
      throw const GcalStageClientException(
          GcalStageClientFault.invalidServerResponse);
    }
    return GcalStageServerHealth(
      json['status'] as String,
      json['google_oauth_active'] as bool,
    );
  }
}

/// Google consent opens in the system browser, never inside a WebView.
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

GcalTwoPhaseFlutterStagingClient createGcalStagingClient(
        {required http.Client httpClient}) =>
    GcalTwoPhaseFlutterStagingClient(
      currentAuth: gcalCurrentAppAuth,
      post: GcalStagingEdgeTransport.forStaging(httpClient).post,
      openBrowser: gcalOpenSystemBrowser,
    );
