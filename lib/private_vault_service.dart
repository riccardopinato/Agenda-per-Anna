import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultEntry {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VaultEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  VaultEntry copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
  }) {
    return VaultEntry(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory VaultEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now().toUtc();
    return VaultEntry(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')
              ?.toUtc() ??
          now,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')
              ?.toUtc() ??
          now,
    );
  }
}

class VaultUnlockException implements Exception {
  final String message;
  const VaultUnlockException(this.message);

  @override
  String toString() => message;
}

class VaultCrypto {
  static const int defaultIterations = 180000;
  static const int _keyLength = 32;
  static const int _nonceLength = 12;

  const VaultCrypto._();

  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static Uint8List deriveKey(
    String secret,
    Uint8List salt, {
    int iterations = defaultIterations,
  }) {
    final derivator = PBKDF2KeyDerivator(
      HMac(SHA256Digest(), 64),
    )..init(
        Pbkdf2Parameters(
          salt,
          iterations,
          _keyLength,
        ),
      );
    return derivator.process(
      Uint8List.fromList(utf8.encode(secret)),
    );
  }

  static Map<String, String> encrypt(
    Uint8List key,
    Uint8List plaintext, {
    required String aad,
  }) {
    if (key.length != _keyLength) {
      throw ArgumentError('AES-256 requires a 32-byte key.');
    }
    final nonce = randomBytes(_nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters<KeyParameter>(
          KeyParameter(key),
          128,
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

  static Uint8List decrypt(
    Uint8List key,
    Map<String, dynamic> envelope, {
    required String aad,
  }) {
    if (key.length != _keyLength) {
      throw ArgumentError('AES-256 requires a 32-byte key.');
    }
    final nonce = base64Url.decode(envelope['nonce']?.toString() ?? '');
    final encrypted = base64Url.decode(envelope['data']?.toString() ?? '');
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters<KeyParameter>(
          KeyParameter(key),
          128,
          nonce,
          Uint8List.fromList(utf8.encode(aad)),
        ),
      );
    return cipher.process(encrypted);
  }

  static Map<String, String> wrapMasterKey(
    Uint8List derivedKey,
    Uint8List masterKey,
  ) =>
      encrypt(
        derivedKey,
        masterKey,
        aad: 'annas-diary-vault:keywrap:v1',
      );

  static Uint8List unwrapMasterKey(
    Uint8List derivedKey,
    Map<String, dynamic> envelope,
  ) =>
      decrypt(
        derivedKey,
        envelope,
        aad: 'annas-diary-vault:keywrap:v1',
      );
}

class PrivateVaultService extends ChangeNotifier {
  PrivateVaultService._();

  static final PrivateVaultService instance = PrivateVaultService._();

  static const int _formatVersion = 1;
  static const String _metaPrefix = 'private_vault_meta_v1_';
  static const String _payloadPrefix = 'private_vault_payload_v1_';
  static const MethodChannel _androidKeystore =
      MethodChannel('annas_diary/private_vault');

  SharedPreferences? _prefs;
  String _scope = '';
  String _scopeToken = '';
  Map<String, dynamic>? _metadata;
  Uint8List? _masterKey;
  final List<VaultEntry> _entries = [];
  bool _configured = false;
  bool _unlocked = false;
  bool _biometricEnabled = false;
  bool _loading = false;
  String? _storageError;

  bool get configured => _configured;
  bool get unlocked => _unlocked;
  bool get biometricEnabled => _biometricEnabled;
  bool get loading => _loading;
  String? get storageError => _storageError;
  List<VaultEntry> get entries => List.unmodifiable(_entries);

  String get _metaKey => '$_metaPrefix$_scopeToken';
  String get _payloadKey => '$_payloadPrefix$_scopeToken';

  static String? validateSecret(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.length > 128) {
      return 'Inserisci un codice o una password valida.';
    }
    if (RegExp(r'^\d+$').hasMatch(value)) {
      if (value.length < 4) {
        return 'Il PIN deve avere almeno 4 cifre.';
      }
      return null;
    }
    if (value.length < 6) {
      return 'La password deve avere almeno 6 caratteri.';
    }
    return null;
  }

  Future<void> selectScope(String scope) async {
    final normalized = scope.trim().isEmpty ? 'device' : scope.trim();
    if (_scope == normalized && _prefs != null) return;

    lock(notify: false);
    _scope = normalized;
    _scopeToken = base64UrlEncode(utf8.encode(normalized)).replaceAll('=', '');
    _loading = true;
    _storageError = null;
    notifyListeners();

    try {
      _prefs ??= await SharedPreferences.getInstance();
      final rawMeta = _prefs!.getString(_metaKey);
      final rawPayload = _prefs!.getString(_payloadKey);
      _configured = rawMeta != null && rawPayload != null;
      _metadata = null;
      _biometricEnabled = false;

      if (_configured) {
        final decoded = jsonDecode(rawMeta!);
        if (decoded is! Map) {
          throw const FormatException('Metadati cassaforte non validi.');
        }
        _metadata = Map<String, dynamic>.from(decoded);
        if (_metadata!['version'] != _formatVersion) {
          throw const FormatException('Versione cassaforte non supportata.');
        }
        _biometricEnabled =
            _metadata!['biometricEnabled'] as bool? ?? false;
      }
    } catch (_) {
      _configured = false;
      _metadata = null;
      _biometricEnabled = false;
      _storageError =
          'La cassaforte locale non è leggibile. Nessun dato è stato sovrascritto.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setupVault(
    String rawSecret, {
    bool enableBiometrics = false,
  }) async {
    final validation = validateSecret(rawSecret);
    if (validation != null) throw FormatException(validation);
    await _ensureReady();

    final secret = rawSecret.trim();
    final salt = VaultCrypto.randomBytes(16);
    final masterKey = VaultCrypto.randomBytes(32);
    final derivedKey = VaultCrypto.deriveKey(secret, salt);
    final wrappedKey = VaultCrypto.wrapMasterKey(derivedKey, masterKey);
    _wipe(derivedKey);

    final metadata = <String, dynamic>{
      'version': _formatVersion,
      'salt': base64UrlEncode(salt),
      'iterations': VaultCrypto.defaultIterations,
      'wrappedKey': wrappedKey,
      'biometricEnabled': false,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    final payload = _encryptEntries(masterKey, const <VaultEntry>[]);
    await _prefs!.setString(_payloadKey, jsonEncode(payload));
    await _prefs!.setString(_metaKey, jsonEncode(metadata));

    _metadata = metadata;
    _masterKey = masterKey;
    _entries.clear();
    _configured = true;
    _unlocked = true;
    _biometricEnabled = false;
    _storageError = null;
    notifyListeners();

    if (enableBiometrics && await canUseBiometrics()) {
      try {
        await setBiometricEnabled(true);
      } catch (_) {
        // The vault remains valid and PIN/password access always works.
      }
    }
  }

  Future<void> unlockWithSecret(String rawSecret) async {
    await _ensureReady();
    if (!_configured || _metadata == null) {
      throw const VaultUnlockException('Cassaforte non configurata.');
    }

    final secret = rawSecret.trim();
    try {
      final salt =
          Uint8List.fromList(base64Url.decode(_metadata!['salt'] as String));
      final iterations =
          (_metadata!['iterations'] as num?)?.toInt() ??
              VaultCrypto.defaultIterations;
      final wrapped = Map<String, dynamic>.from(
        _metadata!['wrappedKey'] as Map,
      );
      final derived = VaultCrypto.deriveKey(
        secret,
        salt,
        iterations: iterations,
      );
      final master = VaultCrypto.unwrapMasterKey(derived, wrapped);
      _wipe(derived);
      await _unlockWithMasterKey(master);
    } catch (_) {
      throw const VaultUnlockException(
        'Codice/password non corretto oppure cassaforte danneggiata.',
      );
    }
  }

  Future<bool> unlockWithBiometrics() async {
    await _ensureReady();
    if (!_configured || !_biometricEnabled || !await canUseBiometrics()) {
      return false;
    }
    final authenticated = await _authenticateBiometric(
      'Sblocca la cassaforte privata di Anna\'s Diary',
    );
    if (!authenticated) return false;

    try {
      final encoded = await _androidKeystore.invokeMethod<String>(
        'readBiometricKey',
        {'scope': _scopeToken},
      );
      if (encoded == null || encoded.isEmpty) return false;
      final master = Uint8List.fromList(base64Url.decode(encoded));
      if (master.length != 32) return false;
      await _unlockWithMasterKey(master);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _unlockWithMasterKey(Uint8List master) async {
    final rawPayload = _prefs!.getString(_payloadKey);
    if (rawPayload == null) {
      _wipe(master);
      throw const VaultUnlockException('Contenuto cassaforte mancante.');
    }
    final envelopeValue = jsonDecode(rawPayload);
    if (envelopeValue is! Map) {
      _wipe(master);
      throw const VaultUnlockException('Contenuto cassaforte non valido.');
    }

    final plaintext = VaultCrypto.decrypt(
      master,
      Map<String, dynamic>.from(envelopeValue),
      aad: 'annas-diary-vault:payload:v1:$_scopeToken',
    );
    final decoded = jsonDecode(utf8.decode(plaintext));
    if (decoded is! Map || decoded['entries'] is! List) {
      _wipe(master);
      throw const VaultUnlockException('Contenuto cassaforte non valido.');
    }

    final entries = (decoded['entries'] as List)
        .whereType<Map>()
        .map((raw) => VaultEntry.fromJson(Map<String, dynamic>.from(raw)))
        .where((entry) => entry.id.isNotEmpty)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    lock(notify: false);
    _masterKey = master;
    _entries
      ..clear()
      ..addAll(entries);
    _unlocked = true;
    _storageError = null;
    notifyListeners();
  }

  Future<VaultEntry> upsertEntry({
    VaultEntry? existing,
    required String title,
    required String body,
  }) async {
    _requireUnlocked();
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty && cleanBody.isEmpty) {
      throw const FormatException('Scrivi un titolo o un contenuto.');
    }

    final now = DateTime.now().toUtc();
    final entry = existing == null
        ? VaultEntry(
            id: base64UrlEncode(VaultCrypto.randomBytes(18)).replaceAll('=', ''),
            title: cleanTitle,
            body: cleanBody,
            createdAt: now,
            updatedAt: now,
          )
        : existing.copyWith(
            title: cleanTitle,
            body: cleanBody,
            updatedAt: now,
          );

    _entries.removeWhere((item) => item.id == entry.id);
    _entries.add(entry);
    _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _savePayload();
    notifyListeners();
    return entry;
  }

  Future<void> deleteEntry(String id) async {
    _requireUnlocked();
    _entries.removeWhere((item) => item.id == id);
    await _savePayload();
    notifyListeners();
  }

  Future<void> changeSecret(
    String currentSecret,
    String newSecret,
  ) async {
    _requireUnlocked();
    final validation = validateSecret(newSecret);
    if (validation != null) throw FormatException(validation);

    final metadata = _metadata;
    if (metadata == null) {
      throw const VaultUnlockException('Metadati cassaforte mancanti.');
    }

    try {
      final oldSalt =
          Uint8List.fromList(base64Url.decode(metadata['salt'] as String));
      final oldIterations =
          (metadata['iterations'] as num?)?.toInt() ??
              VaultCrypto.defaultIterations;
      final oldDerived = VaultCrypto.deriveKey(
        currentSecret.trim(),
        oldSalt,
        iterations: oldIterations,
      );
      final verifiedMaster = VaultCrypto.unwrapMasterKey(
        oldDerived,
        Map<String, dynamic>.from(metadata['wrappedKey'] as Map),
      );
      _wipe(oldDerived);
      _wipe(verifiedMaster);
    } catch (_) {
      throw const VaultUnlockException('Codice/password attuale non corretto.');
    }

    final newSalt = VaultCrypto.randomBytes(16);
    final newDerived = VaultCrypto.deriveKey(newSecret.trim(), newSalt);
    final wrapped = VaultCrypto.wrapMasterKey(newDerived, _masterKey!);
    _wipe(newDerived);

    final updated = Map<String, dynamic>.from(metadata)
      ..['salt'] = base64UrlEncode(newSalt)
      ..['iterations'] = VaultCrypto.defaultIterations
      ..['wrappedKey'] = wrapped;
    await _prefs!.setString(_metaKey, jsonEncode(updated));
    _metadata = updated;
    notifyListeners();
  }

  Future<bool> canUseBiometrics() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported() || !await auth.canCheckBiometrics) {
        return false;
      }
      return (await auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _requireUnlocked();
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Sblocco biometrico disponibile solo su Android in questa versione.',
      );
    }

    if (enabled) {
      if (!await canUseBiometrics()) {
        throw const VaultUnlockException('Biometria non disponibile.');
      }
      final authenticated = await _authenticateBiometric(
        'Conferma l’impronta per proteggere la cassaforte',
      );
      if (!authenticated) {
        throw const VaultUnlockException('Autenticazione biometrica annullata.');
      }
      await _androidKeystore.invokeMethod<void>(
        'storeBiometricKey',
        {
          'scope': _scopeToken,
          'value': base64UrlEncode(_masterKey!),
        },
      );
    } else {
      await _deleteBiometricKey();
    }

    final metadata = Map<String, dynamic>.from(_metadata!)
      ..['biometricEnabled'] = enabled;
    await _prefs!.setString(_metaKey, jsonEncode(metadata));
    _metadata = metadata;
    _biometricEnabled = enabled;
    notifyListeners();
  }

  Future<bool> _authenticateBiometric(String reason) async {
    try {
      return await LocalAuthentication().authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> destroyVault() async {
    await _ensureReady();
    await _deleteBiometricKey();
    await _prefs!.remove(_payloadKey);
    await _prefs!.remove(_metaKey);
    lock(notify: false);
    _metadata = null;
    _configured = false;
    _biometricEnabled = false;
    _storageError = null;
    notifyListeners();
  }

  Future<void> _deleteBiometricKey() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _androidKeystore.invokeMethod<void>(
        'deleteBiometricKey',
        {'scope': _scopeToken},
      );
    } catch (_) {
      // PIN/password remains the recovery path.
    }
  }

  Future<void> _savePayload() async {
    _requireUnlocked();
    final envelope = _encryptEntries(_masterKey!, _entries);
    await _prefs!.setString(_payloadKey, jsonEncode(envelope));
  }

  Map<String, String> _encryptEntries(
    Uint8List masterKey,
    List<VaultEntry> entries,
  ) {
    final plaintext = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'version': _formatVersion,
          'entries': entries.map((entry) => entry.toJson()).toList(),
        }),
      ),
    );
    return VaultCrypto.encrypt(
      masterKey,
      plaintext,
      aad: 'annas-diary-vault:payload:v1:$_scopeToken',
    );
  }

  Future<void> _ensureReady() async {
    if (_prefs == null) {
      await selectScope(_scope.isEmpty ? 'device' : _scope);
    }
  }

  void _requireUnlocked() {
    if (!_unlocked || _masterKey == null) {
      throw const VaultUnlockException('Cassaforte bloccata.');
    }
  }

  void lock({bool notify = true}) {
    final key = _masterKey;
    if (key != null) _wipe(key);
    _masterKey = null;
    _entries.clear();
    _unlocked = false;
    if (notify) notifyListeners();
  }

  static void _wipe(Uint8List bytes) {
    bytes.fillRange(0, bytes.length, 0);
  }
}
