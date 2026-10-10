import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';

import 'cloud_sync_service.dart';
import 'vault_service.dart';
import 'src/security/pbkdf2_worker.dart';

class SharedPasswordConflictException implements Exception {
  final String message;

  const SharedPasswordConflictException([
    this.message = 'shared_password_revision_conflict',
  ]);

  @override
  String toString() => message;
}

class SharedPasswordCredential {
  final String id;
  final String spaceId;
  final String service;
  final String username;
  final String email;
  final String password;
  final String notes;
  final DateTime updatedAt;
  final String updatedBy;
  final int revision;

  const SharedPasswordCredential({
    required this.id,
    required this.spaceId,
    required this.service,
    required this.username,
    required this.email,
    required this.password,
    required this.notes,
    required this.updatedAt,
    required this.updatedBy,
    this.revision = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'spaceId': spaceId,
        'service': service,
        'username': username,
        'email': email,
        'password': password,
        'notes': notes,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
        'updatedBy': updatedBy,
      };

  factory SharedPasswordCredential.fromJson(Map<String, dynamic> json) =>
      SharedPasswordCredential(
        id: json['id']?.toString() ?? '',
        spaceId: json['spaceId']?.toString() ?? '',
        service: json['service']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        password: json['password']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
        updatedAt:
            DateTime.tryParse(json['updatedAt']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
        updatedBy: json['updatedBy']?.toString() ?? '',
        revision: (json['revision'] as num?)?.toInt() ?? 0,
      );

  SharedPasswordCredential withServerRevision({
    required int revision,
    required DateTime updatedAt,
  }) =>
      SharedPasswordCredential(
        id: id,
        spaceId: spaceId,
        service: service,
        username: username,
        email: email,
        password: password,
        notes: notes,
        updatedAt: updatedAt,
        updatedBy: updatedBy,
        revision: revision,
      );
}

class SharedPasswordService {
  SharedPasswordService._();

  static final SharedPasswordService instance = SharedPasswordService._();

  static const _credentialEntityType = 'shared_credential';
  static const _keyMetaEntityType = 'shared_password_key_meta';
  static const _keyMetaEntityId = 'v1';
  static const _payloadVersion = 1;
  static const _pairingIterations = 180000;
  static const _recoveryIterations = 600000;
  static const _tagBits = 128;
  static const _nonceLength = 12;
  static const _keyLength = 32;
  static const _pairingLifetime = Duration(minutes: 15);
  static const _recoveryPrefix = 'ADSP1.';

  final Random _random = Random.secure();
  Object? _lastReconcileError;

  Object? get lastReconcileError => _lastReconcileError;
  final Uuid _uuid = const Uuid();

  bool hasKey(String spaceId) =>
      PrivateVaultService.instance.hasSharedPasswordKey(spaceId);

  Future<void> ensureOwnerKey(String spaceId) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('shared_password_unlock_vault');
    }
    if (!cloud.signedIn) {
      throw StateError('shared_password_sign_in');
    }

    final local = vault.sharedPasswordKeyCopy(spaceId);
    if (local != null) {
      try {
        final localFingerprint = _fingerprint(local);
        final claim = await cloud.claimSharedPasswordKeyMeta(
          spaceId: spaceId,
          fingerprint: localFingerprint,
        );
        if (claim.fingerprint != localFingerprint) {
          await vault.removeSharedPasswordSpace(spaceId);
          throw StateError(
            'shared_password_key_conflict',
          );
        }
        return;
      } finally {
        _zero(local);
      }
    }

    final candidate = _randomBytes(_keyLength);
    try {
      final fingerprint = _fingerprint(candidate);
      final claim = await cloud.claimSharedPasswordKeyMeta(
        spaceId: spaceId,
        fingerprint: fingerprint,
      );
      if (!claim.claimed || claim.fingerprint != fingerprint) {
        throw StateError(
          'shared_password_key_exists',
        );
      }
      await vault.importSharedPasswordKey(spaceId, candidate);
    } finally {
      _zero(candidate);
    }
  }

  Future<String> createPairingCode(String spaceId) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('shared_password_unlock_vault');
    }
    if (!cloud.signedIn) {
      throw StateError('shared_password_sign_in');
    }

    final spaceKey = vault.sharedPasswordKeyCopy(spaceId);
    if (spaceKey == null) {
      throw StateError('shared_password_initialize_first');
    }

    Uint8List? wrappingKey;
    try {
      await _assertLocalKeyMatchesServer(spaceId, spaceKey);

      final code = _newPairingCode();
      final normalized = _normalizePairingCode(code);
      final codeHash = sha256.convert(utf8.encode(normalized)).toString();
      final salt = _randomBytes(16);
      wrappingKey = await _derivePairingKey(normalized, salt);
      final wrapped = _encrypt(
        key: wrappingKey,
        plaintext: spaceKey,
        aad: _keyEnvelopeAad(spaceId),
      );
      final expiresAt = DateTime.now().toUtc().add(_pairingLifetime);

      await cloud.upsertSharedPasswordKeyEnvelope(
        spaceId: spaceId,
        entityId: codeHash,
        payload: {
          'v': _payloadVersion,
          'salt': base64UrlEncode(salt),
          'wrapped': wrapped,
          'expiresAt': expiresAt.toIso8601String(),
        },
        updatedAt: DateTime.now(),
      );
      return code;
    } finally {
      _zero(spaceKey);
      if (wrappingKey != null) _zero(wrappingKey);
    }
  }

  Future<bool> importPairingCode({
    required String spaceId,
    required String code,
  }) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('shared_password_unlock_vault');
    }
    if (!cloud.signedIn) {
      throw StateError('shared_password_sign_in');
    }

    final normalized = _normalizePairingCode(code);
    if (normalized.length != 32) return false;
    final codeHash = sha256.convert(utf8.encode(normalized)).toString();

    final keyMeta = await _loadKeyMeta(spaceId);
    if (keyMeta == null) return false;

    try {
      final payload = await cloud.consumeSharedPasswordKeyEnvelope(
        spaceId: spaceId,
        entityId: codeHash,
      );
      final expiresAt =
          DateTime.tryParse(payload['expiresAt']?.toString() ?? '')?.toUtc();
      if (expiresAt == null || !expiresAt.isAfter(DateTime.now().toUtc())) {
        return false;
      }
      final salt = base64Url.decode(payload['salt']?.toString() ?? '');
      final wrapped = Map<String, dynamic>.from(payload['wrapped'] as Map);
      final wrappingKey = await _derivePairingKey(normalized, salt);
      Uint8List? spaceKey;
      try {
        spaceKey = _decrypt(
          key: wrappingKey,
          envelope: wrapped,
          aad: _keyEnvelopeAad(spaceId),
        );
        if (spaceKey.length != _keyLength) return false;
        if (!_fingerprintMatches(spaceKey, keyMeta)) return false;
        await vault.importSharedPasswordKey(spaceId, spaceKey);
      } finally {
        _zero(wrappingKey);
        if (spaceKey != null) _zero(spaceKey);
      }

      await refreshSpace(spaceId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String> createRecoveryPackage({
    required String spaceId,
    required String recoveryPassword,
  }) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('shared_password_unlock_vault');
    }
    if (!cloud.signedIn) {
      throw StateError('shared_password_sign_in');
    }
    if (recoveryPassword.length < 12) {
      throw const FormatException(
        'shared_password_recovery_min_12',
      );
    }

    final key = vault.sharedPasswordKeyCopy(spaceId);
    if (key == null) {
      throw StateError('shared_password_key_unavailable');
    }
    final salt = _randomBytes(16);
    Uint8List? wrappingKey;
    try {
      await _assertLocalKeyMatchesServer(spaceId, key);
      wrappingKey = await _deriveSecretKey(
        recoveryPassword,
        salt,
        _recoveryIterations,
      );
      final wrapped = _encrypt(
        key: wrappingKey,
        plaintext: key,
        aad: _recoveryAad(spaceId),
      );
      final package = {
        'v': 1,
        'spaceId': spaceId,
        'iterations': _recoveryIterations,
        'salt': base64UrlEncode(salt),
        'fingerprint': _fingerprint(key),
        'wrapped': wrapped,
      };
      return _recoveryPrefix +
          base64UrlEncode(utf8.encode(jsonEncode(package)));
    } finally {
      _zero(key);
      if (wrappingKey != null) _zero(wrappingKey);
    }
  }

  Future<bool> importRecoveryPackage({
    required String spaceId,
    required String package,
    required String recoveryPassword,
  }) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked || !cloud.signedIn) return false;
    if (!package.startsWith(_recoveryPrefix) ||
        recoveryPassword.length < 12) {
      return false;
    }

    Uint8List? wrappingKey;
    Uint8List? spaceKey;
    try {
      final encoded = package.substring(_recoveryPrefix.length);
      final decoded = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(base64Url.decode(encoded))) as Map,
      );
      if ((decoded['v'] as num?)?.toInt() != 1 ||
          decoded['spaceId']?.toString() != spaceId) {
        return false;
      }
      final iterations = (decoded['iterations'] as num?)?.toInt() ?? 0;
      if (iterations < 100000 || iterations > 2000000) return false;
      final salt = base64Url.decode(decoded['salt']?.toString() ?? '');
      wrappingKey = await _deriveSecretKey(
        recoveryPassword,
        salt,
        iterations,
      );
      spaceKey = _decrypt(
        key: wrappingKey,
        envelope: Map<String, dynamic>.from(decoded['wrapped'] as Map),
        aad: _recoveryAad(spaceId),
      );
      if (spaceKey.length != _keyLength) return false;

      final packageFingerprint = decoded['fingerprint']?.toString() ?? '';
      if (packageFingerprint != _fingerprint(spaceKey)) return false;

      final meta = await _loadKeyMeta(spaceId);
      if (meta == null || !_fingerprintMatches(spaceKey, meta)) {
        return false;
      }

      await vault.importSharedPasswordKey(spaceId, spaceKey);
      await refreshSpace(spaceId);
      return true;
    } catch (_) {
      return false;
    } finally {
      if (wrappingKey != null) _zero(wrappingKey);
      if (spaceKey != null) _zero(spaceKey);
    }
  }

  Future<List<SharedPasswordCredential>> refreshSpace(String spaceId) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked || !cloud.signedIn || !hasKey(spaceId)) {
      return const [];
    }

    final meta = await _loadKeyMeta(spaceId);
    final keyForCheck = vault.sharedPasswordKeyCopy(spaceId);
    if (keyForCheck == null) return const [];
    try {
      if (meta == null || !_fingerprintMatches(keyForCheck, meta)) {
        throw StateError('shared_password_key_mismatch');
      }
    } finally {
      _zero(keyForCheck);
    }

    final records = await cloud.pullSharedRecordsByType(
      spaceId,
      _credentialEntityType,
    );
    final activeIds = <String>{};
    final result = <SharedPasswordCredential>[];

    for (final record in records) {
      if (record.deletedAt != null || record.payload == null) {
        await vault.deleteSharedCredentialMirror(spaceId, record.entityId);
        continue;
      }

      final credential = _decryptCredential(
        spaceId: spaceId,
        credentialId: record.entityId,
        payload: record.payload!,
        authoritativeUpdatedAt: record.clientUpdatedAt,
        authoritativeUpdatedBy: record.updatedBy,
      );
      activeIds.add(record.entityId);
      result.add(credential);
      await vault.upsertSharedCredentialMirror(
        spaceId: spaceId,
        credentialId: credential.id,
        service: credential.service,
        username: credential.username,
        email: credential.email,
        password: credential.password,
        notes: credential.notes,
        updatedAt: credential.updatedAt,
        sharedRevision: credential.revision,
      );
    }

    for (final mirror
        in List<PrivateVaultEntry>.from(vault.sharedCredentialEntries(spaceId))) {
      if (!activeIds.contains(mirror.sharedCredentialId)) {
        await vault.deleteSharedCredentialMirror(
          spaceId,
          mirror.sharedCredentialId,
        );
      }
    }

    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  Future<SharedPasswordCredential> upsertCredential({
    required String spaceId,
    String? credentialId,
    required String service,
    required String username,
    required String email,
    required String password,
    required String notes,
    int expectedRevision = 0,
  }) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('shared_password_unlock_vault');
    }
    if (!cloud.signedIn) {
      throw StateError('shared_password_sign_in');
    }
    final localKey = vault.sharedPasswordKeyCopy(spaceId);
    if (localKey == null) {
      throw StateError('shared_password_key_unavailable');
    }
    try {
      await _assertLocalKeyMatchesServer(spaceId, localKey);
    } finally {
      _zero(localKey);
    }

    final cleanService = service.trim();
    final cleanUsername = username.trim();
    final cleanEmail = email.trim();
    final cleanNotes = notes.trim();
    if (cleanService.isEmpty) {
      throw const FormatException('credential_service_required');
    }
    if (cleanService.length > 160) {
      throw const FormatException('credential_service_too_long');
    }
    if (cleanUsername.length > 320 || cleanEmail.length > 320) {
      throw const FormatException('credential_identity_too_long');
    }
    if (password.length > 4096) {
      throw const FormatException('shared_password_password_too_long');
    }
    if (cleanNotes.length > 12000) {
      throw const FormatException('credential_notes_too_long');
    }

    final id = credentialId?.trim().isNotEmpty == true
        ? credentialId!.trim()
        : _uuid.v4();
    final now = DateTime.now();
    final pending = SharedPasswordCredential(
      id: id,
      spaceId: spaceId,
      service: cleanService,
      username: cleanUsername,
      email: cleanEmail,
      password: password,
      notes: cleanNotes,
      updatedAt: now,
      updatedBy: cloud.userId ?? '',
      revision: expectedRevision,
    );

    final payload = _encryptCredential(pending);
    try {
      final mutation = await cloud.upsertSharedPasswordCredential(
        spaceId: spaceId,
        entityId: id,
        payload: payload,
        expectedRevision: expectedRevision,
        updatedAt: now,
      );
      final committed = pending.withServerRevision(
        revision: mutation.revision,
        updatedAt: mutation.clientUpdatedAt,
      );
      await vault.upsertSharedCredentialMirror(
        spaceId: spaceId,
        credentialId: id,
        service: committed.service,
        username: committed.username,
        email: committed.email,
        password: committed.password,
        notes: committed.notes,
        updatedAt: committed.updatedAt,
        sharedRevision: committed.revision,
      );
      return committed;
    } catch (error) {
      _throwIfRevisionConflict(error);
      rethrow;
    }
  }

  Future<void> deleteCredential({
    required String spaceId,
    required String credentialId,
    int expectedRevision = 0,
  }) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('shared_password_unlock_vault');
    }
    if (!cloud.signedIn) {
      throw StateError('shared_password_sign_in');
    }
    try {
      await cloud.deleteSharedPasswordCredential(
        spaceId: spaceId,
        entityId: credentialId,
        expectedRevision: expectedRevision,
      );
      await vault.deleteSharedCredentialMirror(spaceId, credentialId);
    } catch (error) {
      _throwIfRevisionConflict(error);
      rethrow;
    }
  }

  Future<void> applyRealtimeChange(SharedRealtimeRecordChange change) async {
    if (change.entityType != _credentialEntityType) return;
    final vault = PrivateVaultService.instance;
    if (!vault.unlocked || !hasKey(change.spaceId)) return;

    if (change.deletedAt != null || change.payload == null) {
      await vault.deleteSharedCredentialMirror(
        change.spaceId,
        change.entityId,
      );
      return;
    }

    final credential = _decryptCredential(
      spaceId: change.spaceId,
      credentialId: change.entityId,
      payload: change.payload!,
      authoritativeUpdatedAt: change.clientUpdatedAt,
      authoritativeUpdatedBy: change.updatedBy,
    );
    await vault.upsertSharedCredentialMirror(
      spaceId: change.spaceId,
      credentialId: credential.id,
      service: credential.service,
      username: credential.username,
      email: credential.email,
      password: credential.password,
      notes: credential.notes,
      updatedAt: credential.updatedAt,
      sharedRevision: credential.revision,
    );
  }

  Future<void> refreshAllAvailableSpaces() async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked || !cloud.signedIn) return;

    final spaces = await cloud.listSharedSpaces();
    final activeIds = spaces.map((space) => space.id).toSet();
    await reconcileMembershipWithSpaceIds(activeIds);

    for (final space in spaces) {
      if (!hasKey(space.id)) continue;
      await refreshSpace(space.id);
    }
  }

  Future<bool> refreshAllAvailableSpacesSafe() async {
    try {
      _lastReconcileError = null;
      await refreshAllAvailableSpaces();
      return true;
    } catch (error) {
      _lastReconcileError = error;
      return false;
    }
  }

  Future<void> reconcileMembership() async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked || !cloud.signedIn) return;
    final spaces = await cloud.listSharedSpaces();
    await reconcileMembershipWithSpaceIds(
      spaces.map((space) => space.id).toSet(),
    );
  }

  Future<void> reconcileMembershipWithSpaceIds(
    Set<String> activeSpaceIds,
  ) async {
    final vault = PrivateVaultService.instance;
    if (!vault.unlocked) return;
    await vault.reconcileSharedPasswordSpaces(activeSpaceIds);
  }

  Future<void> revokeLocalSpace(String spaceId) async {
    final vault = PrivateVaultService.instance;
    if (!vault.unlocked) return;
    await vault.removeSharedPasswordSpace(spaceId);
  }

  Map<String, dynamic> _encryptCredential(
    SharedPasswordCredential credential,
  ) {
    final key = PrivateVaultService.instance
        .sharedPasswordKeyCopy(credential.spaceId);
    if (key == null) {
      throw StateError('shared_password_key_unavailable');
    }
    try {
      final plaintext =
          Uint8List.fromList(utf8.encode(jsonEncode(credential.toJson())));
      try {
        final encrypted = _encrypt(
          key: key,
          plaintext: plaintext,
          aad: _credentialAad(credential.spaceId, credential.id),
        );
        return {
          'v': _payloadVersion,
          'cipher': 'AES-256-GCM',
          ...encrypted,
        };
      } finally {
        _zero(plaintext);
      }
    } finally {
      _zero(key);
    }
  }

  SharedPasswordCredential _decryptCredential({
    required String spaceId,
    required String credentialId,
    required Map<String, dynamic> payload,
    required DateTime authoritativeUpdatedAt,
    String? authoritativeUpdatedBy,
  }) {
    if ((payload['v'] as num?)?.toInt() != _payloadVersion) {
      throw const FormatException('shared_password_version_unsupported');
    }
    final revision = (payload['revision'] as num?)?.toInt() ?? 0;
    if (revision <= 0) {
      throw const FormatException('shared_password_revision_invalid');
    }
    final key = PrivateVaultService.instance.sharedPasswordKeyCopy(spaceId);
    if (key == null) {
      throw StateError('shared_password_key_unavailable');
    }
    Uint8List? plaintext;
    try {
      plaintext = _decrypt(
        key: key,
        envelope: payload,
        aad: _credentialAad(spaceId, credentialId),
      );
      final decoded = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(plaintext)) as Map,
      );
      final base = SharedPasswordCredential.fromJson(decoded);
      if (base.id != credentialId || base.spaceId != spaceId) {
        throw const FormatException('shared_password_credential_invalid');
      }
      return SharedPasswordCredential(
        id: base.id,
        spaceId: base.spaceId,
        service: base.service,
        username: base.username,
        email: base.email,
        password: base.password,
        notes: base.notes,
        updatedAt: authoritativeUpdatedAt.toLocal(),
        updatedBy: authoritativeUpdatedBy ?? base.updatedBy,
        revision: revision,
      );
    } finally {
      _zero(key);
      if (plaintext != null) _zero(plaintext);
    }
  }

  Future<void> _assertLocalKeyMatchesServer(
    String spaceId,
    Uint8List key,
  ) async {
    final meta = await _loadKeyMeta(spaceId);
    if (meta != null) {
      if (!_fingerprintMatches(key, meta)) {
        throw StateError('shared_password_key_mismatch');
      }
      return;
    }

    final fingerprint = _fingerprint(key);
    final claim = await CloudSyncService.instance.claimSharedPasswordKeyMeta(
      spaceId: spaceId,
      fingerprint: fingerprint,
    );
    if (claim.fingerprint != fingerprint) {
      throw StateError('shared_password_key_mismatch');
    }
  }

  Future<SharedSpaceRecord?> _loadKeyMeta(String spaceId) async {
    final records = await CloudSyncService.instance.pullSharedRecordsByType(
      spaceId,
      _keyMetaEntityType,
      entityId: _keyMetaEntityId,
    );
    for (final record in records) {
      if (record.entityId == _keyMetaEntityId &&
          record.deletedAt == null &&
          record.payload != null) {
        return record;
      }
    }
    return null;
  }

  bool _fingerprintMatches(Uint8List key, SharedSpaceRecord meta) {
    final expected = meta.payload?['fingerprint']?.toString() ?? '';
    if (expected.isEmpty) return false;
    return _fingerprint(key) == expected;
  }

  String _fingerprint(Uint8List key) => sha256.convert(key).toString();

  Future<Uint8List> _derivePairingKey(String code, Uint8List salt) =>
      _deriveSecretKey(code, salt, _pairingIterations);

  Future<Uint8List> _deriveSecretKey(
    String secret,
    Uint8List salt,
    int iterations,
  ) =>
      derivePbkdf2Sha256Key(
        secret: secret,
        salt: salt,
        iterations: iterations,
        length: _keyLength,
      );

  Map<String, dynamic> _encrypt({
    required Uint8List key,
    required Uint8List plaintext,
    required String aad,
  }) {
    final nonce = _randomBytes(_nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          _tagBits,
          nonce,
          Uint8List.fromList(utf8.encode(aad)),
        ),
      );
    final encrypted = cipher.process(plaintext);
    return {
      'nonce': base64UrlEncode(nonce),
      'data': base64UrlEncode(encrypted),
    };
  }

  Uint8List _decrypt({
    required Uint8List key,
    required Map<String, dynamic> envelope,
    required String aad,
  }) {
    final nonce = base64Url.decode(envelope['nonce']?.toString() ?? '');
    final encrypted = base64Url.decode(envelope['data']?.toString() ?? '');
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(key),
          _tagBits,
          nonce,
          Uint8List.fromList(utf8.encode(aad)),
        ),
      );
    return cipher.process(encrypted);
  }

  Uint8List _randomBytes(int length) => Uint8List.fromList(
        List<int>.generate(length, (_) => _random.nextInt(256)),
      );

  String _newPairingCode() {
    final bytes = _randomBytes(16);
    final raw = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return [
      raw.substring(0, 8),
      raw.substring(8, 16),
      raw.substring(16, 24),
      raw.substring(24, 32),
    ].join('-').toUpperCase();
  }

  String _normalizePairingCode(String value) =>
      value.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '').toUpperCase();

  String _credentialAad(String spaceId, String credentialId) =>
      'annas-diary-noi-password:$spaceId:$credentialId:v1';

  String _keyEnvelopeAad(String spaceId) =>
      'annas-diary-noi-password-key:$spaceId:v1';

  String _recoveryAad(String spaceId) =>
      'annas-diary-noi-password-recovery:$spaceId:v1';

  void _throwIfRevisionConflict(Object error) {
    final text = error.toString();
    if (text.contains('shared_password_revision_conflict') ||
        text.contains('40001')) {
      throw const SharedPasswordConflictException();
    }
  }

  void _zero(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
