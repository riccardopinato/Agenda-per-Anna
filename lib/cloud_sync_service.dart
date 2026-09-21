import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum CloudConnectionState {
  disabled,
  initializing,
  signedOut,
  syncing,
  synced,
  error,
}

class CloudSyncOperation {
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime updatedAt;
  final bool deleted;

  const CloudSyncOperation({
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.updatedAt,
    this.deleted = false,
  });

  String get localKey => '$entityType:$entityId';

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'updatedAt': updatedAt.toIso8601String(),
        'deleted': deleted,
      };

  factory CloudSyncOperation.fromJson(Map<String, dynamic> json) =>
      CloudSyncOperation(
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        payload: json['payload'] == null
            ? null
            : Map<String, dynamic>.from(json['payload'] as Map),
        updatedAt:
            DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                DateTime.now(),
        deleted: json['deleted'] as bool? ?? false,
      );
}

class CloudRemoteRecord {
  final String recordKey;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;

  const CloudRemoteRecord({
    required this.recordKey,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.clientUpdatedAt,
    required this.deletedAt,
  });

  String get localKey => '$entityType:$entityId';

  factory CloudRemoteRecord.fromJson(Map<String, dynamic> json) =>
      CloudRemoteRecord(
        recordKey: json['record_key'] as String,
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String,
        payload: json['payload'] == null
            ? null
            : Map<String, dynamic>.from(json['payload'] as Map),
        clientUpdatedAt:
            DateTime.tryParse(json['client_updated_at'] as String? ?? '') ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        deletedAt: json['deleted_at'] == null
            ? null
            : DateTime.tryParse(json['deleted_at'] as String),
      );
}

class CloudSyncService extends ChangeNotifier {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pxsxlorntswypdbeerzw.supabase.co',
  );
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_RWgJneLG9V-pu2IcsDRQCg_G14_kqS7',
  );

  SupabaseClient? _client;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;
  CloudConnectionState _state = CloudConnectionState.disabled;
  DateTime? _lastSyncAt;
  String? _lastError;

  bool get configured =>
      _url.trim().isNotEmpty && _publishableKey.trim().isNotEmpty;
  bool get initialized => _initialized;
  CloudConnectionState get state => _state;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastError => _lastError;
  User? get user => _client?.auth.currentUser;
  String? get userId => user?.id;
  String? get email => user?.email;
  bool get signedIn => user != null;

  Future<void> initialize() async {
    if (_initialized) return;

    if (!configured) {
      _state = CloudConnectionState.disabled;
      _initialized = true;
      notifyListeners();
      return;
    }

    _state = CloudConnectionState.initializing;
    notifyListeners();

    try {
      await Supabase.initialize(
        url: _url,
        publishableKey: _publishableKey,
      );
      _client = Supabase.instance.client;
      _initialized = true;
      _state = signedIn
          ? CloudConnectionState.synced
          : CloudConnectionState.signedOut;

      _authSubscription =
          _client!.auth.onAuthStateChange.listen((_) {
        _state = signedIn
            ? CloudConnectionState.synced
            : CloudConnectionState.signedOut;
        _lastError = null;
        notifyListeners();
      });
    } catch (error) {
      _initialized = true;
      _state = CloudConnectionState.error;
      _lastError = error.toString();
    }

    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    _state = CloudConnectionState.initializing;
    _lastError = null;
    notifyListeners();

    try {
      await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      _state = CloudConnectionState.synced;
    } catch (error) {
      _state = CloudConnectionState.error;
      _lastError = error.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    _state = CloudConnectionState.initializing;
    _lastError = null;
    notifyListeners();

    try {
      await client.auth.signUp(
        email: email.trim(),
        password: password,
      );
      _state = signedIn
          ? CloudConnectionState.synced
          : CloudConnectionState.signedOut;
    } catch (error) {
      _state = CloudConnectionState.error;
      _lastError = error.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
    _lastSyncAt = null;
    _state = CloudConnectionState.signedOut;
    notifyListeners();
  }

  Future<List<CloudRemoteRecord>> pullPrivateRecords() async {
    final client = _requireSignedInClient();
    final uid = userId!;

    final response = await client
        .from('agenda_records')
        .select(
          'record_key,entity_type,entity_id,payload,client_updated_at,deleted_at',
        )
        .eq('owner_id', uid)
        .eq('visibility', 'private');

    return (response as List)
        .map(
          (row) => CloudRemoteRecord.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }

  Future<void> pushPrivateOperations(
    Iterable<CloudSyncOperation> operations,
  ) async {
    final ops = operations.toList();
    if (ops.isEmpty) return;

    final client = _requireSignedInClient();
    final uid = userId!;
    final rows = ops.map((op) {
      final recordKey =
          '$uid:private:${op.entityType}:${op.entityId}';
      return {
        'record_key': recordKey,
        'owner_id': uid,
        'space_id': null,
        'visibility': 'private',
        'entity_type': op.entityType,
        'entity_id': op.entityId,
        'payload': op.deleted ? null : op.payload,
        'client_updated_at': op.updatedAt.toUtc().toIso8601String(),
        'deleted_at':
            op.deleted ? op.updatedAt.toUtc().toIso8601String() : null,
      };
    }).toList();

    await client.from('agenda_records').upsert(
          rows,
          onConflict: 'record_key',
        );
  }

  void markSyncStarted() {
    _state = CloudConnectionState.syncing;
    _lastError = null;
    notifyListeners();
  }

  void markSyncSuccess() {
    _state = CloudConnectionState.synced;
    _lastSyncAt = DateTime.now();
    _lastError = null;
    notifyListeners();
  }

  void markSyncError(Object error) {
    _state = CloudConnectionState.error;
    _lastError = error.toString();
    notifyListeners();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError(
        configured
            ? 'Cloud non ancora inizializzato.'
            : 'Cloud non configurato in questa build.',
      );
    }
    return client;
  }

  SupabaseClient _requireSignedInClient() {
    final client = _requireClient();
    if (client.auth.currentUser == null) {
      throw StateError('Accedi prima di sincronizzare.');
    }
    return client;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
