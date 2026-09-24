import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_state_store.dart';

class PrivateVaultEntry {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PrivateVaultEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory PrivateVaultEntry.fromJson(Map<String, dynamic> json) =>
      PrivateVaultEntry(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')
                ?.toLocal() ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '')
                ?.toLocal() ??
            DateTime.now(),
      );
}

class PrivateVaultService extends ChangeNotifier {
  PrivateVaultService._();

  static final PrivateVaultService instance = PrivateVaultService._();

  static const _metaKey = 'private_vault_meta_v1';
  static const _payloadKey = 'private_vault_payload_v1';
  static const _version = 1;
  static const _iterations = 180000;
  static const _tagBits = 128;
  static const _nonceLength = 12;
  static const _masterKeyLength = 32;
  static const _keyAad = 'annas-diary-vault-key-v1';
  static const _payloadAad = 'annas-diary-vault-payload-v1';
  static const MethodChannel _native =
      MethodChannel('annas_diary/private_vault');

  final Random _random = Random.secure();
  final List<PrivateVaultEntry> _entries = [];

  LocalStateStore? _store;
  Uint8List? _masterKey;
  Map<String, dynamic>? _meta;
  bool _initialized = false;

  bool get initialized => _initialized;
  bool get configured => _meta != null;
  bool get unlocked => _masterKey != null;
  bool get biometricAvailable =>
      (_meta?['biometricWrap'] as String?)?.isNotEmpty == true;
  List<PrivateVaultEntry> get entries =>
      List<PrivateVaultEntry>.unmodifiable(_entries);

  Future<void> initialize() async {
    if (_initialized) return;
    final legacy = await SharedPreferences.getInstance();
    _store = await LocalStateStore.instance.open(
      legacyPreferences: legacy,
    );
    final raw = _store!.getString(_metaKey);
    if (raw != null) {
      try {
        final parsed = Map<String, dynamic>.from(jsonDecode(raw) as Map);
        if (parsed['v'] == _version) {
          _meta = parsed;
        }
      } catch (_) {
        _meta = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> setup({
    required String password,
    required bool enableBiometric,
  }) async {
    await initialize();
    if (configured) {
      throw StateError('La cassaforte è già configurata.');
    }
    _validatePassword(password);

    final salt = _randomBytes(16);
    final master = _randomBytes(_masterKeyLength);
    final passwordKey = _derivePasswordKey(password, salt);
    final wrapped = _encrypt(
      key: passwordKey,
      plaintext: master,
      aad: _keyAad,
    );

    String? biometricWrap;
    if (enableBiometric && !kIsWeb) {
      try {
        biometricWrap = await _native.invokeMethod<String>(
          'protectMasterKey',
          {'key': base64UrlEncode(master)},
        );
      } catch (_) {
        biometricWrap = null;
      }
    }

    _meta = {
      'v': _version,
      'salt': base64UrlEncode(salt),
      'iterations': _iterations,
      'passwordWrap': wrapped,
      'biometricWrap': biometricWrap,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    _masterKey = Uint8List.fromList(master);
    _entries.clear();

    await _store!.writeBatch({
      _metaKey: jsonEncode(_meta),
      _payloadKey: jsonEncode(
        _encrypt(
          key: master,
          plaintext: Uint8List.fromList(utf8.encode('{"entries":[]}')),
          aad: _payloadAad,
        ),
      ),
    });
    _zero(passwordKey);
    notifyListeners();
  }

  Future<bool> unlockWithPassword(String password) async {
    await initialize();
    final meta = _meta;
    if (meta == null) return false;

    try {
      final salt = base64Url.decode(meta['salt'] as String);
      final passwordKey = _derivePasswordKey(password, salt);
      final wrapped = Map<String, dynamic>.from(meta['passwordWrap'] as Map);
      final master = _decrypt(
        key: passwordKey,
        envelope: wrapped,
        aad: _keyAad,
      );
      _zero(passwordKey);
      if (master.length != _masterKeyLength) return false;
      _masterKey = Uint8List.fromList(master);
      await _loadEntries();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlockWithBiometricKey() async {
    await initialize();
    final wrap = _meta?['biometricWrap'] as String?;
    if (kIsWeb || wrap == null || wrap.isEmpty) return false;
    try {
      final encoded = await _native.invokeMethod<String>(
        'unprotectMasterKey',
        {'blob': wrap},
      );
      if (encoded == null) return false;
      final master = base64Url.decode(encoded);
      if (master.length != _masterKeyLength) return false;
      _masterKey = Uint8List.fromList(master);
      await _loadEntries();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enableBiometricForCurrentKey() async {
    final master = _masterKey;
    if (kIsWeb || master == null || _meta == null) return false;
    try {
      final wrap = await _native.invokeMethod<String>(
        'protectMasterKey',
        {'key': base64UrlEncode(master)},
      );
      if (wrap == null || wrap.isEmpty) return false;
      _meta = {..._meta!, 'biometricWrap': wrap};
      await _store!.setString(_metaKey, jsonEncode(_meta));
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void lock() {
    final key = _masterKey;
    if (key != null) _zero(key);
    _masterKey = null;
    _entries.clear();
    notifyListeners();
  }

  Future<void> upsert({
    String? id,
    required String title,
    required String body,
  }) async {
    _requireUnlocked();
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty && cleanBody.isEmpty) {
      throw const FormatException('Scrivi almeno un titolo o un contenuto.');
    }

    final now = DateTime.now();
    final existingIndex =
        id == null ? -1 : _entries.indexWhere((entry) => entry.id == id);
    if (existingIndex >= 0) {
      final previous = _entries[existingIndex];
      _entries[existingIndex] = PrivateVaultEntry(
        id: previous.id,
        title: cleanTitle,
        body: cleanBody,
        createdAt: previous.createdAt,
        updatedAt: now,
      );
    } else {
      _entries.add(
        PrivateVaultEntry(
          id: id ?? _newId(),
          title: cleanTitle,
          body: cleanBody,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    _sortEntries();
    await _persistEntries();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _requireUnlocked();
    _entries.removeWhere((entry) => entry.id == id);
    await _persistEntries();
    notifyListeners();
  }

  Future<void> destroy() async {
    await initialize();
    lock();
    await _store!.writeBatch({
      _metaKey: null,
      _payloadKey: null,
    });
    if (!kIsWeb) {
      try {
        await _native.invokeMethod<void>('deleteMasterKey');
      } catch (_) {}
    }
    _meta = null;
    notifyListeners();
  }

  @visibleForTesting
  void resetMemoryForTesting() {
    lock();
    _meta = null;
    _store = null;
    _initialized = false;
  }

  Future<void> setSecureScreen(bool enabled) async {
    if (kIsWeb) return;
    try {
      await _native.invokeMethod<void>(
        'setSecureScreen',
        {'enabled': enabled},
      );
    } catch (_) {}
  }

  Future<void> _loadEntries() async {
    final master = _masterKey;
    if (master == null) return;
    final raw = _store!.getString(_payloadKey);
    if (raw == null) {
      _entries.clear();
      return;
    }
    final envelope = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final plaintext = _decrypt(
      key: master,
      envelope: envelope,
      aad: _payloadAad,
    );
    final decoded = Map<String, dynamic>.from(
      jsonDecode(utf8.decode(plaintext)) as Map,
    );
    final list = decoded['entries'] as List? ?? const [];
    _entries
      ..clear()
      ..addAll(
        list.map(
          (raw) => PrivateVaultEntry.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        ),
      );
    _sortEntries();
  }

  Future<void> _persistEntries() async {
    final master = _requireUnlocked();
    final plaintext = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'entries': _entries.map((entry) => entry.toJson()).toList(),
        }),
      ),
    );
    final envelope = _encrypt(
      key: master,
      plaintext: plaintext,
      aad: _payloadAad,
    );
    await _store!.setString(_payloadKey, jsonEncode(envelope));
  }

  Uint8List _derivePasswordKey(String password, Uint8List salt) {
    final derivator = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, _iterations, 32));
    return derivator.process(
      Uint8List.fromList(utf8.encode(password)),
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
    final nonce = base64Url.decode(envelope['nonce'] as String);
    final encrypted = base64Url.decode(envelope['data'] as String);
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

  String _newId() {
    final bytes = _randomBytes(16);
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  void _sortEntries() {
    _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Uint8List _requireUnlocked() {
    final key = _masterKey;
    if (key == null) {
      throw StateError('La cassaforte è bloccata.');
    }
    return key;
  }

  void _validatePassword(String value) {
    if (value.length < 8) {
      throw const FormatException(
        'La password della cassaforte deve avere almeno 8 caratteri.',
      );
    }
  }

  void _zero(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}
