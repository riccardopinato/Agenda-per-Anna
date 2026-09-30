import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:uuid/uuid.dart';

import 'cloud_sync_service.dart';
import 'vault_service.dart';

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
      );
}

class SharedPasswordService {
  SharedPasswordService._();

  static final SharedPasswordService instance = SharedPasswordService._();

  static const _credentialEntityType = 'shared_credential';
  static const _keyEnvelopeEntityType = 'shared_password_key_envelope';
  static const _keyMetaEntityType = 'shared_password_key_meta';
  static const _keyMetaEntityId = 'v1';
  static const _payloadVersion = 1;
  static const _pairingIterations = 180000;
  static const _tagBits = 128;
  static const _nonceLength = 12;
  static const _keyLength = 32;
  static const _pairingLifetime = Duration(minutes: 15);

  final Random _random = Random.secure();
  final Uuid _uuid = const Uuid();

  bool hasKey(String spaceId) =>
      PrivateVaultService.instance.hasSharedPasswordKey(spaceId);

  Future<void> ensureOwnerKey(String spaceId) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('Sblocca prima la Cassaforte privata.');
    }
    if (!cloud.signedIn) {
      throw StateError('Accedi prima a Noi ♡.');
    }

    final records = await cloud.pullSharedRecords(spaceId);
    final meta = _activeKeyMeta(records);
    final local = vault.sharedPasswordKeyCopy(spaceId);

    if (meta != null) {
      if (local == null) {
        throw StateError(
          'Esiste già una chiave Password Noi ♡. Importala da un dispositivo collegato.',
        );
      }
      try {
        if (!_fingerprintMatches(local, meta)) {
          throw StateError('Chiave Password Noi ♡ non coerente con lo spazio.');
        }
        return;
      } finally {
        _zero(local);
      }
    }

    if (local != null) {
      try {
        await _publishKeyMeta(spaceId, local);
        return;
      } finally {
        _zero(local);
      }
    }

    final created = await vault.ensureSharedPasswordKey(spaceId);
    try {
      await _publishKeyMeta(spaceId, created);
    } finally {
      _zero(created);
    }
  }

  Future<String> createPairingCode(String spaceId) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('Sblocca prima la Cassaforte privata.');
    }
    if (!cloud.signedIn) {
      throw StateError('Accedi prima a Noi ♡.');
    }

    final spaceKey = vault.sharedPasswordKeyCopy(spaceId);
    if (spaceKey == null) {
      throw StateError('Inizializza prima Password Noi ♡.');
    }
    await _assertLocalKeyMatchesServer(spaceId, spaceKey);

    final code = _newPairingCode();
    final normalized = _normalizePairingCode(code);
    final codeHash = sha256.convert(utf8.encode(normalized)).toString();
    final salt = _randomBytes(16);
    final wrappingKey = _derivePairingKey(normalized, salt);
    final wrapped = _encrypt(
      key: wrappingKey,
      plaintext: spaceKey,
      aad: _keyEnvelopeAad(spaceId),
    );
    final expiresAt = DateTime.now().toUtc().add(_pairingLifetime);

    try {
      await cloud.upsertSharedRecord(
        spaceId: spaceId,
        entityType: _keyEnvelopeEntityType,
        entityId: codeHash,
        payload: {
          'v': _payloadVersion,
          'salt': base64UrlEncode(salt),
          'wrapped': wrapped,
          'expiresAt': expiresAt.toIso8601String(),
        },
      );
      return code;
    } finally {
      _zero(spaceKey);
      _zero(wrappingKey);
    }
  }

  Future<bool> importPairingCode({
    required String spaceId,
    required String code,
  }) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('Sblocca prima la Cassaforte privata.');
    }
    if (!cloud.signedIn) {
      throw StateError('Accedi prima a Noi ♡.');
    }

    final normalized = _normalizePairingCode(code);
    if (normalized.length != 32) return false;
    final codeHash = sha256.convert(utf8.encode(normalized)).toString();
    final records = await cloud.pullSharedRecords(spaceId);
    final keyMeta = _activeKeyMeta(records);
    SharedSpaceRecord? match;
    for (final record in records) {
      if (record.entityType == _keyEnvelopeEntityType &&
          record.entityId == codeHash &&
          record.deletedAt == null &&
          record.payload != null) {
        match = record;
        break;
      }
    }
    if (match == null) return false;

    try {
      final payload = match.payload!;
      final expiresAt =
          DateTime.tryParse(payload['expiresAt']?.toString() ?? '')?.toUtc();
      if (expiresAt == null || !expiresAt.isAfter(DateTime.now().toUtc())) {
        return false;
      }
      final salt = base64Url.decode(payload['salt']?.toString() ?? '');
      final wrapped = Map<String, dynamic>.from(payload['wrapped'] as Map);
      final wrappingKey = _derivePairingKey(normalized, salt);
      Uint8List? spaceKey;
      try {
        spaceKey = _decrypt(
          key: wrappingKey,
          envelope: wrapped,
          aad: _keyEnvelopeAad(spaceId),
        );
        if (spaceKey.length != _keyLength) return false;
        if (keyMeta != null && !_fingerprintMatches(spaceKey, keyMeta)) {
          return false;
        }
        await vault.importSharedPasswordKey(spaceId, spaceKey);
        if (keyMeta == null) {
          await _publishKeyMeta(spaceId, spaceKey);
        }
      } finally {
        _zero(wrappingKey);
        if (spaceKey != null) _zero(spaceKey);
      }

      await cloud.deleteSharedRecord(
        spaceId: spaceId,
        entityType: _keyEnvelopeEntityType,
        entityId: codeHash,
      );
      await refreshSpace(spaceId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<SharedPasswordCredential>> refreshSpace(String spaceId) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked || !cloud.signedIn || !hasKey(spaceId)) {
      return const [];
    }

    final records = await cloud.pullSharedRecords(spaceId);
    final meta = _activeKeyMeta(records);
    final keyForCheck = vault.sharedPasswordKeyCopy(spaceId);
    if (keyForCheck == null) return const [];
    try {
      if (meta != null && !_fingerprintMatches(keyForCheck, meta)) {
        throw StateError('Chiave Password Noi ♡ non coerente con lo spazio.');
      }
    } finally {
      _zero(keyForCheck);
    }
    final activeIds = <String>{};
    final result = <SharedPasswordCredential>[];

    for (final record in records) {
      if (record.entityType != _credentialEntityType) continue;
      if (record.deletedAt != null || record.payload == null) {
        await vault.deleteSharedCredentialMirror(spaceId, record.entityId);
        continue;
      }

      final credential = _decryptCredential(
        spaceId: spaceId,
        credentialId: record.entityId,
        payload: record.payload!,
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
  }) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('Sblocca prima la Cassaforte privata.');
    }
    if (!cloud.signedIn) {
      throw StateError('Accedi prima a Noi ♡.');
    }
    final localKey = vault.sharedPasswordKeyCopy(spaceId);
    if (localKey == null) {
      throw StateError('Chiave Password Noi ♡ non disponibile.');
    }
    try {
      await _assertLocalKeyMatchesServer(spaceId, localKey);
    } finally {
      _zero(localKey);
    }

    final cleanService = service.trim();
    if (cleanService.isEmpty) {
      throw const FormatException('Inserisci il nome del servizio.');
    }
    final id = credentialId?.trim().isNotEmpty == true
        ? credentialId!.trim()
        : _uuid.v4();
    final now = DateTime.now();
    final credential = SharedPasswordCredential(
      id: id,
      spaceId: spaceId,
      service: cleanService,
      username: username.trim(),
      email: email.trim(),
      password: password,
      notes: notes.trim(),
      updatedAt: now,
      updatedBy: cloud.userId ?? '',
    );

    final payload = _encryptCredential(credential);
    await cloud.upsertSharedRecord(
      spaceId: spaceId,
      entityType: _credentialEntityType,
      entityId: id,
      payload: payload,
      updatedAt: now,
    );
    await vault.upsertSharedCredentialMirror(
      spaceId: spaceId,
      credentialId: id,
      service: credential.service,
      username: credential.username,
      email: credential.email,
      password: credential.password,
      notes: credential.notes,
      updatedAt: now,
    );
    return credential;
  }

  Future<void> deleteCredential({
    required String spaceId,
    required String credentialId,
  }) async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked) {
      throw StateError('Sblocca prima la Cassaforte privata.');
    }
    if (!cloud.signedIn) {
      throw StateError('Accedi prima a Noi ♡.');
    }
    await cloud.deleteSharedRecord(
      spaceId: spaceId,
      entityType: _credentialEntityType,
      entityId: credentialId,
    );
    await vault.deleteSharedCredentialMirror(spaceId, credentialId);
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
    );
  }

  Future<void> refreshAllAvailableSpaces() async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked || !cloud.signedIn) return;

    final spaces = await cloud.listSharedSpaces();
    final activeIds = spaces.map((space) => space.id).toSet();
    await vault.reconcileSharedPasswordSpaces(activeIds);

    for (final space in spaces) {
      if (!hasKey(space.id)) continue;
      await refreshSpace(space.id);
    }
  }

  Future<void> reconcileMembership() async {
    final vault = PrivateVaultService.instance;
    final cloud = CloudSyncService.instance;
    if (!vault.unlocked || !cloud.signedIn) return;
    final spaces = await cloud.listSharedSpaces();
    await vault.reconcileSharedPasswordSpaces(
      spaces.map((space) => space.id).toSet(),
    );
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
      throw StateError('Chiave Password Noi ♡ non disponibile.');
    }
    try {
      final plaintext =
          Uint8List.fromList(utf8.encode(jsonEncode(credential.toJson())));
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
      _zero(key);
    }
  }

  SharedPasswordCredential _decryptCredential({
    required String spaceId,
    required String credentialId,
    required Map<String, dynamic> payload,
  }) {
    if ((payload['v'] as num?)?.toInt() != _payloadVersion) {
      throw const FormatException('Versione Password Noi ♡ non supportata.');
    }
    final key = PrivateVaultService.instance.sharedPasswordKeyCopy(spaceId);
    if (key == null) {
      throw StateError('Chiave Password Noi ♡ non disponibile.');
    }
    try {
      final plaintext = _decrypt(
        key: key,
        envelope: payload,
        aad: _credentialAad(spaceId, credentialId),
      );
      final decoded = Map<String, dynamic>.from(
        jsonDecode(utf8.decode(plaintext)) as Map,
      );
      final credential = SharedPasswordCredential.fromJson(decoded);
      if (credential.id != credentialId || credential.spaceId != spaceId) {
        throw const FormatException('Credenziale Noi ♡ non valida.');
      }
      return credential;
    } finally {
      _zero(key);
    }
  }

  Future<void> _assertLocalKeyMatchesServer(
    String spaceId,
    Uint8List key,
  ) async {
    final records = await CloudSyncService.instance.pullSharedRecords(spaceId);
    final meta = _activeKeyMeta(records);
    if (meta == null) {
      await _publishKeyMeta(spaceId, key);
      return;
    }
    if (!_fingerprintMatches(key, meta)) {
      throw StateError('Chiave Password Noi ♡ non coerente con lo spazio.');
    }
  }

  SharedSpaceRecord? _activeKeyMeta(List<SharedSpaceRecord> records) {
    for (final record in records) {
      if (record.entityType == _keyMetaEntityType &&
          record.entityId == _keyMetaEntityId &&
          record.deletedAt == null &&
          record.payload != null) {
        return record;
      }
    }
    return null;
  }

  Future<void> _publishKeyMeta(String spaceId, Uint8List key) async {
    await CloudSyncService.instance.upsertSharedRecord(
      spaceId: spaceId,
      entityType: _keyMetaEntityType,
      entityId: _keyMetaEntityId,
      payload: {
        'v': _payloadVersion,
        'fingerprint': sha256.convert(key).toString(),
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      },
    );
  }

  bool _fingerprintMatches(Uint8List key, SharedSpaceRecord meta) {
    final expected = meta.payload?['fingerprint']?.toString() ?? '';
    if (expected.isEmpty) return false;
    return sha256.convert(key).toString() == expected;
  }

  Uint8List _derivePairingKey(String code, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _pairingIterations, _keyLength));
    return derivator.process(
      Uint8List.fromList(utf8.encode(code)),
    );
  }

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

  void _zero(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
