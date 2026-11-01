part of '../main.dart';

/// Pure payload projection. Does not export notes, media or shared content.
Map<String, Object?>? androidCalendarEventPayload(
  AgendaItem item, {required String scope, required String calendarId,
}) {
  if (item.type != ItemType.appointment || item.title.trim().isEmpty) return null;
  final start = item.start;
  final end = item.end;
  if (start != null && end == null) { return null; }
  final allDay = start == null;
  final begins = allDay
      ? DateTime.utc(item.date.year, item.date.month, item.date.day)
      : DateTime(item.date.year, item.date.month, item.date.day,
          start.hour, start.minute);
  final overnight = start != null && end != null &&
      end.hour * 60 + end.minute <= start.hour * 60 + start.minute;
  final finishes = allDay
      ? DateTime.utc(item.date.year, item.date.month, item.date.day + 1)
      : DateTime(item.date.year, item.date.month,
          item.date.day + (overnight ? 1 : 0), end!.hour, end.minute);
  return <String, Object?>{
    'calendarId': calendarId,
    'ownerKey': '$scope:${item.id}',
    'title': item.title,
    'startMs': begins.millisecondsSinceEpoch,
    'endMs': finishes.millisecondsSinceEpoch,
    'allDay': allDay,
  };
}


/// Hide only an exported instance that corresponds to a still-visible
/// canonical private appointment in the current account. Exports belonging
/// to another account, or whose source appointment was deleted, stay visible.
bool isOwnedAndroidCalendarDuplicate(
    AgendaStore store, ExternalCalendarEvent event) {
  if (!event.description.contains('[AnnaDiary:')) return false;
  final scope = store.activeAccountId == null
      ? 'guest' : 'user:${store.activeAccountId}';
  return store.forDay(event.date).any((item) {
    if (item.type != ItemType.appointment) return false;
    final ownerKey = '$scope:${item.id}|${event.calendarId}';
    final token = '[AnnaDiary:${sha256.convert(utf8.encode(ownerKey))}]';
    return event.description.contains(token);
  });
}

/// B3 opt-in outbound only. AgendaStore is the source of truth.
class AndroidCalendarSyncService extends ChangeNotifier
    with WidgetsBindingObserver {
  AndroidCalendarSyncService._();
  static final AndroidCalendarSyncService instance =
      AndroidCalendarSyncService._();
  static const _channel = MethodChannel('annas_diary/external_calendar');
  static const _prefix = 'b3_android_calendar_v1_';

  AgendaStore? _store;
  Timer? _debounce;
  String? _scope;
  String? _calendarId;
  String? _error;
  DateTime? _lastSuccess;
  bool _enabled = false;
  bool _loaded = false;
  bool _working = false;
  bool _pendingReconcile = false;
  bool _writePermissionGranted = false;
  int _updated = 0;
  int _skipped = 0;

  bool get supported => !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android;
  bool get enabled => _enabled;
  bool get loaded => _loaded;
  bool get working => _working;
  bool get writePermissionGranted => _writePermissionGranted;
  String? get calendarId => _calendarId;
  String? get error => _error;
  DateTime? get lastSuccess => _lastSuccess;
  int get updated => _updated;
  int get skipped => _skipped;

  String _accountScope(AgendaStore store) =>
      store.activeAccountId == null ? 'guest' : 'user:${store.activeAccountId}';
  String _key(String scope) =>
      '$_prefix${base64UrlEncode(utf8.encode(scope))}';

  Future<void> attach(AgendaStore store) async {
    if (!supported) return;
    if (!identical(_store, store)) {
      _store?.agendaRevision.removeListener(_schedule);
      _store?.accountRevision.removeListener(_onAccountChanged);
      _store = store;
      store.agendaRevision.addListener(_schedule);
      store.accountRevision.addListener(_onAccountChanged);
      WidgetsBinding.instance.addObserver(this);
    }
    await _loadScope();
    _schedule();
  }

  void _onAccountChanged() {
    _debounce?.cancel();
    _enabled = false;
    _calendarId = null;
    _scope = null;
    _loaded = false;
    _error = null;
    notifyListeners();
    unawaited(_loadScope().then((_) => _schedule()));
  }

  Future<void> _loadScope() async {
    final store = _store;
    if (store == null || !store.entryScopeReady) return;
    final scope = _accountScope(store);
    final prefs = await SharedPreferences.getInstance();
    if (_accountScope(store) != scope) return;
    _scope = scope;
    _calendarId = prefs.getString('${_key(scope)}_calendar');
    _enabled = prefs.getBool('${_key(scope)}_enabled') == true &&
        _calendarId != null && _calendarId!.isNotEmpty;
    _loaded = true;
    await refreshPermission();
    notifyListeners();
  }

  Future<void> refreshPermission() async {
    if (!supported) return;
    try {
      _writePermissionGranted =
          await _channel.invokeMethod<bool>('writePermissionStatus') ?? false;
    } on PlatformException catch (e) {
      _writePermissionGranted = false;
      _error = e.code;
    }
    notifyListeners();
  }

  Future<bool> requestWriteAccess() async {
    if (!supported) return false;
    try {
      _writePermissionGranted =
          await _channel.invokeMethod<bool>('requestWritePermission') ?? false;
      notifyListeners();
      return _writePermissionGranted;
    } on PlatformException catch (e) {
      _writePermissionGranted = false;
      _error = e.code;
      notifyListeners();
      return false;
    }
  }

  Future<List<ExternalCalendarInfo>> writableCalendars() async {
    if (!supported) return const [];
    await ExternalCalendarService.instance.initialize();
    if (!ExternalCalendarService.instance.permissionGranted) return const [];
    try {
      final values = await _channel.invokeListMethod<Object?>(
          'writableCalendars') ?? const <Object?>[];
      return values.whereType<Map>().map((value) =>
          ExternalCalendarInfo.fromPlatform(
              Map<Object?, Object?>.from(value))).toList();
    } on PlatformException catch (e) {
      _error = e.code;
      notifyListeners();
      return const [];
    }
  }

  Future<void> configure({required bool enabled, String? calendarId}) async {
    final store = _store;
    if (store == null || !store.entryScopeReady) return;
    final scope = _accountScope(store);
    final target = calendarId ?? _calendarId;
    if (enabled && (!supported || !_writePermissionGranted ||
        target == null || target.isEmpty)) {
      _error = 'calendar_permission_or_selection_missing';
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_key(scope)}_enabled', enabled);
    if (target != null) {
      await prefs.setString('${_key(scope)}_calendar', target);
    }
    if (_accountScope(store) != scope) return;
    _scope = scope;
    _calendarId = target;
    _enabled = enabled;
    _error = null;
    notifyListeners();
    if (enabled) _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    if (!_enabled || !supported) return;
    _debounce = Timer(const Duration(milliseconds: 900),
        () => unawaited(reconcile()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshPermission().then((_) => _schedule()));
    }
  }

  Future<void> reconcile() async {
    if (_working) {
      _pendingReconcile = true;
      return;
    }
    final store = _store;
    final scope = _scope;
    final calendar = _calendarId;
    if (!supported || !_enabled || _working || !_loaded ||
        store == null || !store.entryScopeReady || scope == null ||
        calendar == null || _accountScope(store) != scope) { return; }
    _working = true;
    _error = null;
    notifyListeners();
    try {
      await refreshPermission();
      if (!_writePermissionGranted) {
        throw StateError('calendar_permission_required');
      }
      // Bounded first release: only private appointments for the next year,
      // never historical data, shared-space entries, notes or Vault data.
      final now = DateTime.now();
      final from = DateTime(now.year, now.month, now.day);
      final until = DateTime(now.year + 1, now.month, now.day);
      final items = store.items.where((item) =>
          item.type == ItemType.appointment &&
          !item.isSensitive &&
          !item.date.isBefore(from) && item.date.isBefore(until)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      var updated = 0;
      var skipped = 0;
      var conflicts = 0;
      for (final item in items.take(200)) {
        if (!_enabled || _accountScope(store) != scope ||
            _calendarId != calendar) { return; }
        final payload = androidCalendarEventPayload(
          item, scope: scope, calendarId: calendar);
        if (payload == null) {
          skipped++;
          continue;
        }
        try {
          await _channel.invokeMethod<String>('upsertOwnedEvent', payload);
          updated++;
        } on PlatformException catch (e) {
          final message = e.message ?? '';
          if (message.contains('external_event_missing_or_moved') ||
              message.contains('duplicate_external_event_marker')) {
            conflicts++;
            continue;
          }
          rethrow;
        }
      }
      if (_accountScope(store) == scope && _calendarId == calendar) {
        _updated = updated;
        _skipped = skipped + conflicts +
            (items.length > 200 ? items.length - 200 : 0);
        if (conflicts == 0) {
          _lastSuccess = DateTime.now();
        } else {
          _error = 'calendar_owned_event_conflicts:$conflicts';
        }
      }
    } on PlatformException catch (e) {
      _error = '${e.code}: ${e.message ?? ''}';
    } catch (e) {
      _error = e.toString();
    } finally {
      _working = false;
      notifyListeners();
      if (_pendingReconcile) {
        _pendingReconcile = false;
        _schedule();
      }
    }
  }
}
