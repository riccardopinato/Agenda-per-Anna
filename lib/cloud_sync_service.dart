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
  final String? ownerId;

  const CloudSyncOperation({
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.updatedAt,
    this.deleted = false,
    this.ownerId,
  });

  String get localKey => '$entityType:$entityId';

  Map<String, dynamic> toJson() => {
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'updatedAt': updatedAt.toIso8601String(),
        'deleted': deleted,
        'ownerId': ownerId,
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
        ownerId: json['ownerId'] as String?,
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

class SharedSpace {
  final String id;
  final String ownerId;
  final String name;
  final String role;
  final DateTime createdAt;

  const SharedSpace({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.role,
    required this.createdAt,
  });

  bool get isOwner => role == 'owner';

  factory SharedSpace.fromJson(
    Map<String, dynamic> json, {
    required String role,
  }) =>
      SharedSpace(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String? ?? 'Noi ♡',
        role: role,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
                DateTime.now(),
      );
}

class SharedSpaceRecord {
  final String recordKey;
  final String spaceId;
  final String ownerId;
  final String? updatedBy;
  final String entityType;
  final String entityId;
  final Map<String, dynamic>? payload;
  final DateTime clientUpdatedAt;
  final DateTime? deletedAt;

  const SharedSpaceRecord({
    required this.recordKey,
    required this.spaceId,
    required this.ownerId,
    required this.updatedBy,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.clientUpdatedAt,
    required this.deletedAt,
  });

  factory SharedSpaceRecord.fromJson(Map<String, dynamic> json) =>
      SharedSpaceRecord(
        recordKey: json['record_key'] as String,
        spaceId: json['space_id'] as String,
        ownerId: json['owner_id'] as String,
        updatedBy: json['updated_by'] as String?,
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
  final Map<String, RealtimeChannel> _sharedChannels = {};
  bool _initialized = false;
  bool _initializing = false;
  int _sessionEpoch = 0;
  CloudConnectionState _state = CloudConnectionState.disabled;
  DateTime? _lastSyncAt;
  String? _lastError;

  bool get configured =>
      _url.trim().isNotEmpty && _publishableKey.trim().isNotEmpty;
  bool get initialized => _initialized;
  int get sessionEpoch => _sessionEpoch;
  CloudConnectionState get state => _state;
  DateTime? get lastSyncAt => _lastSyncAt;
  String? get lastError => _lastError;
  User? get user => _client?.auth.currentUser;
  String? get userId => user?.id;
  String? get email => user?.email;
  bool get signedIn => user != null;

  Future<void> initialize() async {
    if (_initialized || _initializing) return;

    if (!configured) {
      _state = CloudConnectionState.disabled;
      _initialized = true;
      notifyListeners();
      return;
    }

    _initializing = true;
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
        _sessionEpoch++;
        unawaited(_clearSharedChannels());
        _state = signedIn
            ? CloudConnectionState.synced
            : CloudConnectionState.signedOut;
        _lastError = null;
        notifyListeners();
      });
    } catch (error) {
      _initialized = false;
      _client = null;
      _state = CloudConnectionState.error;
      _lastError = error.toString();
    } finally {
      _initializing = false;
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
    const pageSize = 500;
    final records = <CloudRemoteRecord>[];

    for (var from = 0;; from += pageSize) {
      final response = await client
          .from('agenda_records')
          .select(
            'record_key,entity_type,entity_id,payload,client_updated_at,deleted_at',
          )
          .eq('owner_id', uid)
          .eq('visibility', 'private')
          .order('record_key')
          .range(from, from + pageSize - 1);

      final page = (response as List)
          .map(
            (row) => CloudRemoteRecord.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
      records.addAll(page);
      if (page.length < pageSize) break;
    }

    return records;
  }

  Future<void> _mergeRecord({
    required String recordKey,
    required String ownerId,
    required String? spaceId,
    required String visibility,
    required String entityType,
    required String entityId,
    required Map<String, dynamic>? payload,
    required DateTime clientUpdatedAt,
    required DateTime? deletedAt,
  }) async {
    final client = _requireSignedInClient();
    final result = await client.rpc(
      'merge_agenda_record',
      params: {
        'p_record_key': recordKey,
        'p_owner_id': ownerId,
        'p_space_id': spaceId,
        'p_visibility': visibility,
        'p_entity_type': entityType,
        'p_entity_id': entityId,
        'p_payload': payload,
        'p_client_updated_at':
            clientUpdatedAt.toUtc().toIso8601String(),
        'p_deleted_at': deletedAt?.toUtc().toIso8601String(),
      },
    );

    if (result != true) {
      throw StateError('remote_record_is_newer');
    }
  }

  Future<void> pushPrivateOperations(
    Iterable<CloudSyncOperation> operations,
  ) async {
    final uid = userId!;
    final ops = operations
        .where((op) => op.ownerId == null || op.ownerId == uid)
        .toList();
    if (ops.isEmpty) return;

    for (final op in ops) {
      final at = op.updatedAt.toUtc();
      await _mergeRecord(
        recordKey: '$uid:private:${op.entityType}:${op.entityId}',
        ownerId: uid,
        spaceId: null,
        visibility: 'private',
        entityType: op.entityType,
        entityId: op.entityId,
        payload: op.deleted ? null : op.payload,
        clientUpdatedAt: at,
        deletedAt: op.deleted ? at : null,
      );
    }
  }

  Future<List<SharedSpace>> listSharedSpaces() async {
    final client = _requireSignedInClient();
    final uid = userId!;

    final membershipResponse = await client
        .from('space_members')
        .select('space_id,role')
        .eq('user_id', uid);

    final memberships = (membershipResponse as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();

    if (memberships.isEmpty) return const [];

    final roleBySpace = <String, String>{
      for (final row in memberships)
        row['space_id'] as String: row['role'] as String? ?? 'member',
    };

    final response = await client
        .from('shared_spaces')
        .select('id,owner_id,name,created_at');

    final spaces = (response as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .where((row) => roleBySpace.containsKey(row['id'] as String))
        .map(
          (row) => SharedSpace.fromJson(
            row,
            role: roleBySpace[row['id'] as String]!,
          ),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return spaces;
  }

  Future<String> createSharedSpace({
    String name = 'Noi ♡',
  }) async {
    final client = _requireSignedInClient();
    final result = await client.rpc(
      'create_shared_space',
      params: {'p_name': name.trim()},
    );
    return result.toString();
  }

  Future<String> createSpaceInvite(String spaceId) async {
    final client = _requireSignedInClient();
    final result = await client.rpc(
      'create_space_invite',
      params: {'p_space_id': spaceId},
    );
    return result.toString().toUpperCase();
  }

  Future<String> joinSharedSpace(String code) async {
    final client = _requireSignedInClient();
    final result = await client.rpc(
      'join_shared_space',
      params: {'p_code': code.trim().toUpperCase()},
    );
    return result.toString();
  }

  Future<void> leaveSharedSpace(String spaceId) async {
    final client = _requireSignedInClient();
    await client.rpc(
      'leave_shared_space',
      params: {'p_space_id': spaceId},
    );
  }

  Future<void> deleteSharedSpace(String spaceId) async {
    final client = _requireSignedInClient();
    await client.rpc(
      'delete_shared_space',
      params: {'p_space_id': spaceId},
    );
  }

  Future<List<SharedSpaceRecord>> pullSharedRecords(
    String spaceId,
  ) async {
    final client = _requireSignedInClient();
    const pageSize = 500;
    final records = <SharedSpaceRecord>[];

    for (var from = 0;; from += pageSize) {
      final response = await client
          .from('agenda_records')
          .select(
            'record_key,space_id,owner_id,updated_by,entity_type,entity_id,payload,client_updated_at,deleted_at',
          )
          .eq('space_id', spaceId)
          .eq('visibility', 'shared')
          .order('record_key')
          .range(from, from + pageSize - 1);

      final page = (response as List)
          .map(
            (row) => SharedSpaceRecord.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
      records.addAll(page);
      if (page.length < pageSize) break;
    }

    return records;
  }

  Future<void> upsertSharedRecord({
    required String spaceId,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    DateTime? updatedAt,
  }) async {
    final uid = userId!;
    final at = (updatedAt ?? DateTime.now()).toUtc();
    await _mergeRecord(
      recordKey: '$spaceId:shared:$entityType:$entityId',
      ownerId: uid,
      spaceId: spaceId,
      visibility: 'shared',
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      clientUpdatedAt: at,
      deletedAt: null,
    );
  }

  Future<void> deleteSharedRecord({
    required String spaceId,
    required String entityType,
    required String entityId,
    DateTime? updatedAt,
  }) async {
    final uid = userId!;
    final at = (updatedAt ?? DateTime.now()).toUtc();
    await _mergeRecord(
      recordKey: '$spaceId:shared:$entityType:$entityId',
      ownerId: uid,
      spaceId: spaceId,
      visibility: 'shared',
      entityType: entityType,
      entityId: entityId,
      payload: null,
      clientUpdatedAt: at,
      deletedAt: at,
    );
  }

  RealtimeChannel subscribeSharedSpace({
    required String spaceId,
    required String listenerKey,
    required VoidCallback onChanged,
    void Function(RealtimeSubscribeStatus status, Object? error)? onStatus,
  }) {
    final client = _requireSignedInClient();
    final uid = userId!;
    final key = '$listenerKey:$spaceId';
    final previous = _sharedChannels.remove(key);
    if (previous != null) {
      unawaited(client.removeChannel(previous));
    }

    final channel = client.channel('agenda:$uid:$spaceId:$listenerKey');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'agenda_records',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'space_id',
            value: spaceId,
          ),
          callback: (_) => onChanged(),
        )
        .subscribe((status, error) {
          onStatus?.call(status, error);
        });

    _sharedChannels[key] = channel;
    return channel;
  }

  Future<void> unsubscribeSharedSpace({
    required String spaceId,
    required String listenerKey,
  }) async {
    final key = '$listenerKey:$spaceId';
    final channel = _sharedChannels.remove(key);
    if (channel == null) return;
    final client = _client;
    if (client != null) {
      await client.removeChannel(channel);
    } else {
      await channel.unsubscribe();
    }
  }

  Future<void> _clearSharedChannels() async {
    final channels = _sharedChannels.values.toList();
    _sharedChannels.clear();
    for (final channel in channels) {
      try {
        final client = _client;
        if (client != null) {
          await client.removeChannel(channel);
        } else {
          await channel.unsubscribe();
        }
      } catch (_) {
        // Realtime cleanup must never block auth/session transitions.
      }
    }
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
    for (final channel in _sharedChannels.values) {
      unawaited(channel.unsubscribe());
    }
    _sharedChannels.clear();
    super.dispose();
  }
}
