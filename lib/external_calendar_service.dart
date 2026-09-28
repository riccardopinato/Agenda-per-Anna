import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExternalCalendarStatus {
  final bool supported;
  final bool permissionGranted;
  final String? error;

  const ExternalCalendarStatus({
    required this.supported,
    required this.permissionGranted,
    this.error,
  });
}

class ExternalCalendarInfo {
  final String id;
  final String name;
  final String accountName;
  final int? colorValue;

  const ExternalCalendarInfo({
    required this.id,
    required this.name,
    required this.accountName,
    this.colorValue,
  });

  factory ExternalCalendarInfo.fromPlatform(Map<Object?, Object?> raw) {
    return ExternalCalendarInfo(
      id: '${raw['id'] ?? ''}',
      name: ('${raw['name'] ?? ''}').trim().isEmpty
          ? 'Calendario'
          : ('${raw['name'] ?? ''}').trim(),
      accountName: ('${raw['accountName'] ?? ''}').trim(),
      colorValue: (raw['color'] as num?)?.toInt(),
    );
  }
}

class ExternalCalendarEvent {
  final String id;
  final String calendarId;
  final String calendarName;
  final String title;
  final String description;
  final String location;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final int? colorValue;

  const ExternalCalendarEvent({
    required this.id,
    required this.calendarId,
    required this.calendarName,
    required this.title,
    required this.description,
    required this.location,
    required this.start,
    required this.end,
    required this.allDay,
    this.colorValue,
  });

  factory ExternalCalendarEvent.fromPlatform(Map<Object?, Object?> raw) {
    final startMs = (raw['startMs'] as num?)?.toInt() ?? 0;
    final endMs = (raw['endMs'] as num?)?.toInt() ?? startMs;
    final allDay = raw['allDay'] == true;

    DateTime decode(int milliseconds) {
      if (!allDay) {
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
      final utc = DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      );
      return DateTime(utc.year, utc.month, utc.day);
    }

    final calendarId = '${raw['calendarId'] ?? ''}';
    final eventId = '${raw['eventId'] ?? ''}';
    final instanceStart = decode(startMs);

    return ExternalCalendarEvent(
      id: '$calendarId:$eventId:${instanceStart.toIso8601String()}',
      calendarId: calendarId,
      calendarName: ('${raw['calendarName'] ?? ''}').trim().isEmpty
          ? 'Calendario esterno'
          : ('${raw['calendarName'] ?? ''}').trim(),
      title: ('${raw['title'] ?? ''}').trim().isEmpty
          ? 'Evento senza titolo'
          : ('${raw['title'] ?? ''}').trim(),
      description: ('${raw['description'] ?? ''}').trim(),
      location: ('${raw['location'] ?? ''}').trim(),
      start: instanceStart,
      end: decode(endMs),
      allDay: allDay,
      colorValue: (raw['color'] as num?)?.toInt(),
    );
  }

  DateTime get date => DateTime(start.year, start.month, start.day);

  TimeOfDay? get startTime =>
      allDay ? null : TimeOfDay(hour: start.hour, minute: start.minute);

  TimeOfDay? get endTime =>
      allDay ? null : TimeOfDay(hour: end.hour, minute: end.minute);

  bool occursOn(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    final first = DateTime(start.year, start.month, start.day);
    DateTime lastExclusive;
    if (allDay) {
      lastExclusive = DateTime(end.year, end.month, end.day);
    } else {
      final effectiveEnd = end.isAfter(start)
          ? end.subtract(const Duration(microseconds: 1))
          : start;
      final lastDay = DateTime(
        effectiveEnd.year,
        effectiveEnd.month,
        effectiveEnd.day,
      );
      lastExclusive = lastDay.add(const Duration(days: 1));
    }
    if (!lastExclusive.isAfter(first)) {
      lastExclusive = first.add(const Duration(days: 1));
    }
    return !target.isBefore(first) && target.isBefore(lastExclusive);
  }
}

class ExternalCalendarService extends ChangeNotifier {
  ExternalCalendarService._();

  static final ExternalCalendarService instance = ExternalCalendarService._();

  static const MethodChannel _channel =
      MethodChannel('annas_diary/external_calendar');
  static const _enabledKey = 'external_calendar_enabled_v1';
  static const _selectedKey = 'external_calendar_selected_v1';
  static const _selectionInitializedKey =
      'external_calendar_selection_initialized_v1';

  bool _initialized = false;
  bool _initializing = false;
  bool _busy = false;
  bool _enabled = false;
  bool _selectionInitialized = false;
  bool _permissionGranted = false;
  String? _lastError;
  DateTime? _loadedStart;
  DateTime? _loadedEnd;
  final List<ExternalCalendarInfo> _calendars = [];
  final List<ExternalCalendarEvent> _events = [];
  final Set<String> _selectedCalendarIds = <String>{};

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get initialized => _initialized;
  bool get busy => _busy;
  bool get enabled => _enabled;
  bool get permissionGranted => _permissionGranted;
  String? get lastError => _lastError;
  List<ExternalCalendarInfo> get calendars =>
      List<ExternalCalendarInfo>.unmodifiable(_calendars);
  Set<String> get selectedCalendarIds =>
      Set<String>.unmodifiable(_selectedCalendarIds);

  Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? false;
      _selectionInitialized =
          prefs.getBool(_selectionInitializedKey) ?? false;
      _selectedCalendarIds
        ..clear()
        ..addAll(prefs.getStringList(_selectedKey) ?? const <String>[]);

      if (supported) {
        final status = await _readStatus();
        _permissionGranted = status.permissionGranted;
        if (_permissionGranted) {
          await _refreshCalendarsInternal();
        }
      }
      _initialized = true;
    } finally {
      _initializing = false;
      notifyListeners();
    }
  }

  Future<ExternalCalendarStatus> refreshStatus() async {
    await initialize();
    final status = await _readStatus();
    _permissionGranted = status.permissionGranted;
    _lastError = status.error;
    if (_permissionGranted) {
      await _refreshCalendarsInternal();
    } else {
      _events.clear();
      _loadedStart = null;
      _loadedEnd = null;
    }
    notifyListeners();
    return status;
  }

  Future<bool> requestAccess() async {
    await initialize();
    if (!supported) return false;
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      final granted =
          await _channel.invokeMethod<bool>('requestPermission') ?? false;
      _permissionGranted = granted;
      if (granted) {
        await _refreshCalendarsInternal();
      }
      return granted;
    } on PlatformException catch (error) {
      _lastError = error.message ?? error.code;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    await initialize();
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    if (!value) {
      _events.clear();
      _loadedStart = null;
      _loadedEnd = null;
    }
    notifyListeners();
  }

  Future<void> setCalendarSelected(String id, bool selected) async {
    await initialize();
    if (selected) {
      _selectedCalendarIds.add(id);
    } else {
      _selectedCalendarIds.remove(id);
    }
    _selectionInitialized = true;
    await _persistSelection();
    _events.clear();
    _loadedStart = null;
    _loadedEnd = null;
    notifyListeners();
  }

  Future<void> refreshCalendars() async {
    await initialize();
    if (!_permissionGranted) return;
    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      await _refreshCalendarsInternal();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> loadRange(DateTime startInclusive, DateTime endExclusive) async {
    await initialize();
    if (!supported || !_enabled || !_permissionGranted) return;
    if (_selectedCalendarIds.isEmpty) {
      if (_events.isNotEmpty) {
        _events.clear();
        notifyListeners();
      }
      return;
    }

    final start = DateTime(
      startInclusive.year,
      startInclusive.month,
      startInclusive.day,
    );
    final end = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );
    if (!end.isAfter(start)) return;

    if (_loadedStart != null &&
        _loadedEnd != null &&
        !start.isBefore(_loadedStart!) &&
        !end.isAfter(_loadedEnd!)) {
      return;
    }

    _busy = true;
    _lastError = null;
    notifyListeners();
    try {
      final raw = await _channel.invokeListMethod<Object?>(
            'listEvents',
            <String, Object?>{
              'startMs': start.millisecondsSinceEpoch,
              'endMs': end.millisecondsSinceEpoch,
              'calendarIds': _selectedCalendarIds.toList(growable: false),
            },
          ) ??
          const <Object?>[];

      final events = <ExternalCalendarEvent>[];
      for (final value in raw) {
        if (value is Map) {
          events.add(
            ExternalCalendarEvent.fromPlatform(
              Map<Object?, Object?>.from(value),
            ),
          );
        }
      }
      events.sort((a, b) {
        final startOrder = a.start.compareTo(b.start);
        if (startOrder != 0) return startOrder;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      _events
        ..clear()
        ..addAll(events);
      _loadedStart = start;
      _loadedEnd = end;
    } on PlatformException catch (error) {
      _lastError = error.message ?? error.code;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  List<ExternalCalendarEvent> eventsForDay(DateTime date) {
    if (!_enabled || !_permissionGranted) {
      return const <ExternalCalendarEvent>[];
    }
    return List<ExternalCalendarEvent>.unmodifiable(
      _events.where((event) => event.occursOn(date)),
    );
  }

  Future<ExternalCalendarStatus> _readStatus() async {
    if (!supported) {
      return const ExternalCalendarStatus(
        supported: false,
        permissionGranted: false,
      );
    }
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>('status');
      return ExternalCalendarStatus(
        supported: true,
        permissionGranted: raw?['granted'] == true,
      );
    } on PlatformException catch (error) {
      return ExternalCalendarStatus(
        supported: true,
        permissionGranted: false,
        error: error.message ?? error.code,
      );
    }
  }

  Future<void> _refreshCalendarsInternal() async {
    if (!supported || !_permissionGranted) return;
    try {
      final raw =
          await _channel.invokeListMethod<Object?>('listCalendars') ??
              const <Object?>[];
      final calendars = <ExternalCalendarInfo>[];
      for (final value in raw) {
        if (value is Map) {
          calendars.add(
            ExternalCalendarInfo.fromPlatform(
              Map<Object?, Object?>.from(value),
            ),
          );
        }
      }
      calendars.sort((a, b) {
        final account =
            a.accountName.toLowerCase().compareTo(b.accountName.toLowerCase());
        if (account != 0) return account;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      _calendars
        ..clear()
        ..addAll(calendars);

      final validIds = calendars.map((calendar) => calendar.id).toSet();
      _selectedCalendarIds.removeWhere((id) => !validIds.contains(id));
      if (!_selectionInitialized && calendars.isNotEmpty) {
        _selectedCalendarIds.addAll(validIds);
        _selectionInitialized = true;
        await _persistSelection();
      } else if (_selectionInitialized) {
        await _persistSelection();
      }
    } on PlatformException catch (error) {
      _lastError = error.message ?? error.code;
    }
  }

  Future<void> _persistSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _selectedKey,
      _selectedCalendarIds.toList(growable: false)..sort(),
    );
    await prefs.setBool(
      _selectionInitializedKey,
      _selectionInitialized,
    );
  }
}
