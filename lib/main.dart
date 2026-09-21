import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import 'backup_service.dart';
import 'cloud_sync_service.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('it_IT', null);
  } catch (_) {}

  final store = AgendaStore();
  try {
    await store.load();
  } catch (_) {}

  runApp(AgendaApp(store: store));

  Future<void>.delayed(Duration.zero, () async {
    try {
      await NotificationService.instance.initialize();
    } catch (_) {
      // Le notifiche non devono mai impedire l'avvio dell'agenda.
    }

    try {
      await CloudSyncService.instance.initialize();
      await store.initializeCloudSync();
    } catch (_) {
      // Il cloud è opzionale: l'agenda deve restare pienamente offline.
    }
  });
}

class AgendaApp extends StatelessWidget {
  final AgendaStore store;
  const AgendaApp({super.key, required this.store});

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: store.preferences.palette.seed,
      brightness: brightness,
    );
    final dark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          dark ? const Color(0xFF151316) : const Color(0xFFFFFAFC),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final mode = switch (store.preferences.themeMode) {
          AgendaThemeMode.system => ThemeMode.system,
          AgendaThemeMode.light => ThemeMode.light,
          AgendaThemeMode.dark => ThemeMode.dark,
        };

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Agenda per Anna',
          themeMode: mode,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          builder: (context, child) => _PrivacyGate(
            store: store,
            child: child ?? const SizedBox.shrink(),
          ),
          home: AgendaRoot(store: store),
        );
      },
    );
  }
}

class AgendaRoot extends StatelessWidget {
  final AgendaStore store;

  const AgendaRoot({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    if (!store.preferences.onboardingDone) {
      return _OnboardingScreen(store: store);
    }
    return MainShell(store: store);
  }
}

class _OnboardingScreen extends StatelessWidget {
  final AgendaStore store;

  const _OnboardingScreen({required this.store});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  size: 36,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'La tua agenda, davvero tua.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Appuntamenti, diario, abitudini, idee e ricordi in un unico posto. '
                'I dati restano sul dispositivo finché non scegli tu di esportarli.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              const _OnboardingFeature(
                icon: Icons.bolt_outlined,
                title: 'Cattura veloce',
                subtitle: 'Aggiungi un pensiero o un impegno in pochi secondi.',
              ),
              const SizedBox(height: 10),
              const _OnboardingFeature(
                icon: Icons.favorite_outline,
                title: 'Diario personale',
                subtitle: 'Mood, cose belle e abitudini quotidiane.',
              ),
              const SizedBox(height: 10),
              const _OnboardingFeature(
                icon: Icons.lock_outline,
                title: 'Privacy opzionale',
                subtitle: 'PIN e biometria se vuoi proteggere l’agenda.',
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => store.savePreferences(
                    store.preferences.copyWith(onboardingDone: true),
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Inizia'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingFeature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(child: Icon(icon)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrivacyGate extends StatefulWidget {
  final AgendaStore store;
  final Widget child;

  const _PrivacyGate({
    required this.store,
    required this.child,
  });

  @override
  State<_PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<_PrivacyGate>
    with WidgetsBindingObserver {
  bool locked = false;
  bool authenticating = false;
  DateTime? backgroundedAt;
  final pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    locked = widget.store.preferences.privacyLockEnabled;
    if (locked && widget.store.preferences.biometricUnlock) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _biometricUnlock());
    }
  }

  @override
  void didUpdateWidget(covariant _PrivacyGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.store.preferences.privacyLockEnabled && locked) {
      setState(() => locked = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prefs = widget.store.preferences;

    if (state == AppLifecycleState.resumed) {
      unawaited(widget.store.handleAppResumed());
    }

    if (!prefs.privacyLockEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      backgroundedAt ??= DateTime.now();
      return;
    }

    if (state == AppLifecycleState.resumed && backgroundedAt != null) {
      final minutes = prefs.autoLockMinutes;
      final elapsed = DateTime.now().difference(backgroundedAt!);
      backgroundedAt = null;
      if (minutes == 0 || elapsed >= Duration(minutes: minutes)) {
        setState(() => locked = true);
        if (prefs.biometricUnlock) {
          _biometricUnlock();
        }
      }
    }
  }

  Future<void> _biometricUnlock() async {
    if (!mounted || authenticating || kIsWeb) return;
    final prefs = widget.store.preferences;
    if (!prefs.biometricUnlock || !prefs.privacyLockEnabled) return;

    setState(() => authenticating = true);
    try {
      final auth = LocalAuthentication();
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      if (!supported || !canCheck) return;
      final ok = await auth.authenticate(
        localizedReason: 'Sblocca Agenda per Anna',
      );
      if (ok && mounted) {
        setState(() {
          locked = false;
          pinController.clear();
        });
      }
    } catch (_) {
      // Il PIN resta sempre disponibile come fallback.
    } finally {
      if (mounted) setState(() => authenticating = false);
    }
  }

  void _unlockWithPin() {
    if (widget.store.verifyPin(pinController.text)) {
      setState(() {
        locked = false;
        pinController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN non corretto.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.store.preferences.privacyLockEnabled || !locked) {
      return widget.child;
    }

    final prefs = widget.store.preferences;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline, size: 54),
                  const SizedBox(height: 16),
                  Text(
                    'Agenda bloccata',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Inserisci il PIN per continuare.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: pinController,
                    autofocus: !prefs.biometricUnlock,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    onSubmitted: (_) => _unlockWithPin(),
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _unlockWithPin,
                      child: const Text('Sblocca'),
                    ),
                  ),
                  if (prefs.biometricUnlock && !kIsWeb) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: authenticating ? null : _biometricUnlock,
                      icon: const Icon(Icons.fingerprint),
                      label: Text(
                        authenticating
                            ? 'Verifica in corso...'
                            : 'Usa biometria',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AgendaThemeMode { system, light, dark }

enum AgendaPalette { rose, lilac, sage, peach, sky }

extension AgendaPaletteUi on AgendaPalette {
  String get label => switch (this) {
        AgendaPalette.rose => 'Rosa',
        AgendaPalette.lilac => 'Lilla',
        AgendaPalette.sage => 'Salvia',
        AgendaPalette.peach => 'Pesca',
        AgendaPalette.sky => 'Cielo',
      };

  Color get seed => switch (this) {
        AgendaPalette.rose => const Color(0xFFE98FAA),
        AgendaPalette.lilac => const Color(0xFF9A8ED0),
        AgendaPalette.sage => const Color(0xFF7FAF98),
        AgendaPalette.peach => const Color(0xFFE9A47D),
        AgendaPalette.sky => const Color(0xFF78A9D1),
      };
}

enum StartTab { home, month, week, today }

extension StartTabUi on StartTab {
  String get label => switch (this) {
        StartTab.home => 'Home',
        StartTab.month => 'Mese',
        StartTab.week => 'Settimana',
        StartTab.today => 'Oggi',
      };
}

class AgendaPreferences {
  final String displayName;
  final AgendaThemeMode themeMode;
  final AgendaPalette palette;
  final bool showDailyQuote;
  final StartTab startTab;
  final AgendaCategory defaultCategory;
  final int defaultEventMinutes;
  final int? defaultPrimaryReminder;
  final int? defaultSecondaryReminder;
  final bool privacyLockEnabled;
  final bool biometricUnlock;
  final int autoLockMinutes;
  final bool hideHomeDetails;
  final String? pinSalt;
  final String? pinHash;
  final bool onboardingDone;

  const AgendaPreferences({
    this.displayName = 'Anna',
    this.themeMode = AgendaThemeMode.system,
    this.palette = AgendaPalette.rose,
    this.showDailyQuote = true,
    this.startTab = StartTab.home,
    this.defaultCategory = AgendaCategory.personal,
    this.defaultEventMinutes = 60,
    this.defaultPrimaryReminder = 30,
    this.defaultSecondaryReminder,
    this.privacyLockEnabled = false,
    this.biometricUnlock = false,
    this.autoLockMinutes = 2,
    this.hideHomeDetails = false,
    this.pinSalt,
    this.pinHash,
    this.onboardingDone = true,
  });

  AgendaPreferences copyWith({
    String? displayName,
    AgendaThemeMode? themeMode,
    AgendaPalette? palette,
    bool? showDailyQuote,
    StartTab? startTab,
    AgendaCategory? defaultCategory,
    int? defaultEventMinutes,
    int? defaultPrimaryReminder,
    int? defaultSecondaryReminder,
    bool? privacyLockEnabled,
    bool? biometricUnlock,
    int? autoLockMinutes,
    bool? hideHomeDetails,
    String? pinSalt,
    String? pinHash,
    bool? onboardingDone,
    bool clearPrimaryReminder = false,
    bool clearSecondaryReminder = false,
    bool clearPin = false,
  }) {
    return AgendaPreferences(
      displayName: displayName ?? this.displayName,
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
      showDailyQuote: showDailyQuote ?? this.showDailyQuote,
      startTab: startTab ?? this.startTab,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      defaultEventMinutes: defaultEventMinutes ?? this.defaultEventMinutes,
      defaultPrimaryReminder: clearPrimaryReminder
          ? null
          : (defaultPrimaryReminder ?? this.defaultPrimaryReminder),
      defaultSecondaryReminder: clearSecondaryReminder
          ? null
          : (defaultSecondaryReminder ?? this.defaultSecondaryReminder),
      privacyLockEnabled:
          privacyLockEnabled ?? this.privacyLockEnabled,
      biometricUnlock: biometricUnlock ?? this.biometricUnlock,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      hideHomeDetails: hideHomeDetails ?? this.hideHomeDetails,
      pinSalt: clearPin ? null : (pinSalt ?? this.pinSalt),
      pinHash: clearPin ? null : (pinHash ?? this.pinHash),
      onboardingDone: onboardingDone ?? this.onboardingDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'themeMode': themeMode.name,
        'palette': palette.name,
        'showDailyQuote': showDailyQuote,
        'startTab': startTab.name,
        'defaultCategory': defaultCategory.name,
        'defaultEventMinutes': defaultEventMinutes,
        'defaultPrimaryReminder': defaultPrimaryReminder,
        'defaultSecondaryReminder': defaultSecondaryReminder,
        'privacyLockEnabled': privacyLockEnabled,
        'biometricUnlock': biometricUnlock,
        'autoLockMinutes': autoLockMinutes,
        'hideHomeDetails': hideHomeDetails,
        'pinSalt': pinSalt,
        'pinHash': pinHash,
        'onboardingDone': onboardingDone,
      };

  factory AgendaPreferences.fromJson(Map<String, dynamic> json) =>
      AgendaPreferences(
        displayName: (json['displayName'] as String? ?? 'Anna').trim().isEmpty
            ? 'Anna'
            : (json['displayName'] as String? ?? 'Anna').trim(),
        themeMode: AgendaThemeMode.values.firstWhere(
          (e) => e.name == json['themeMode'],
          orElse: () => AgendaThemeMode.system,
        ),
        palette: AgendaPalette.values.firstWhere(
          (e) => e.name == json['palette'],
          orElse: () => AgendaPalette.rose,
        ),
        showDailyQuote: json['showDailyQuote'] as bool? ?? true,
        startTab: StartTab.values.firstWhere(
          (e) => e.name == json['startTab'],
          orElse: () => StartTab.home,
        ),
        defaultCategory: AgendaCategory.values.firstWhere(
          (e) => e.name == json['defaultCategory'],
          orElse: () => AgendaCategory.personal,
        ),
        defaultEventMinutes:
            (json['defaultEventMinutes'] as int? ?? 60).clamp(15, 240).toInt(),
        defaultPrimaryReminder: json['defaultPrimaryReminder'] as int?,
        defaultSecondaryReminder:
            json['defaultSecondaryReminder'] as int?,
        privacyLockEnabled:
            json['privacyLockEnabled'] as bool? ?? false,
        biometricUnlock:
            json['biometricUnlock'] as bool? ?? false,
        autoLockMinutes:
            (json['autoLockMinutes'] as int? ?? 2).clamp(0, 60).toInt(),
        hideHomeDetails:
            json['hideHomeDetails'] as bool? ?? false,
        pinSalt: json['pinSalt'] as String?,
        pinHash: json['pinHash'] as String?,
        onboardingDone: json['onboardingDone'] as bool? ?? true,
      );
}

enum ItemType { appointment, task }

enum RecurrenceRule { none, daily, weekly, monthly }

extension RecurrenceRuleUi on RecurrenceRule {
  String get label => switch (this) {
        RecurrenceRule.none => 'Non ripetere',
        RecurrenceRule.daily => 'Ogni giorno',
        RecurrenceRule.weekly => 'Ogni settimana',
        RecurrenceRule.monthly => 'Ogni mese',
      };

  IconData get icon => switch (this) {
        RecurrenceRule.none => Icons.repeat_outlined,
        RecurrenceRule.daily => Icons.today_outlined,
        RecurrenceRule.weekly => Icons.view_week_outlined,
        RecurrenceRule.monthly => Icons.calendar_month_outlined,
      };
}

enum AgendaCategory {
  personal,
  study,
  work,
  health,
  couple,
  leisure,
  other,
}

extension AgendaCategoryUi on AgendaCategory {
  String get label => switch (this) {
        AgendaCategory.personal => 'Personale',
        AgendaCategory.study => 'Studio',
        AgendaCategory.work => 'Lavoro',
        AgendaCategory.health => 'Salute',
        AgendaCategory.couple => 'Noi ♡',
        AgendaCategory.leisure => 'Tempo libero',
        AgendaCategory.other => 'Altro',
      };

  IconData get icon => switch (this) {
        AgendaCategory.personal => Icons.favorite_outline,
        AgendaCategory.study => Icons.menu_book_outlined,
        AgendaCategory.work => Icons.work_outline,
        AgendaCategory.health => Icons.spa_outlined,
        AgendaCategory.couple => Icons.favorite_border,
        AgendaCategory.leisure => Icons.celebration_outlined,
        AgendaCategory.other => Icons.label_outline,
      };

  Color get color => switch (this) {
        AgendaCategory.personal => const Color(0xFFE88CA8),
        AgendaCategory.study => const Color(0xFF8F8BD8),
        AgendaCategory.work => const Color(0xFF6C9DC6),
        AgendaCategory.health => const Color(0xFF70B69A),
        AgendaCategory.couple => const Color(0xFFE07C93),
        AgendaCategory.leisure => const Color(0xFFE7A85D),
        AgendaCategory.other => const Color(0xFF9B93A6),
      };
}

class AgendaItem {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final ItemType type;
  final AgendaCategory category;
  final int? reminderMinutesBefore;
  final int? secondaryReminderMinutesBefore;
  final bool done;
  final bool pinned;

  const AgendaItem({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.type,
    this.category = AgendaCategory.personal,
    this.reminderMinutesBefore,
    this.secondaryReminderMinutesBefore,
    this.start,
    this.end,
    this.done = false,
    this.pinned = false,
  });

  AgendaItem copyWith({
    String? title,
    String? note,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    ItemType? type,
    AgendaCategory? category,
    int? reminderMinutesBefore,
    int? secondaryReminderMinutesBefore,
    bool? done,
    bool? pinned,
    bool clearTime = false,
    bool clearReminder = false,
    bool clearSecondaryReminder = false,
  }) {
    return AgendaItem(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      type: type ?? this.type,
      category: category ?? this.category,
      reminderMinutesBefore:
          clearReminder ? null : (reminderMinutesBefore ?? this.reminderMinutesBefore),
      secondaryReminderMinutesBefore: clearSecondaryReminder
          ? null
          : (secondaryReminderMinutesBefore ?? this.secondaryReminderMinutesBefore),
      start: clearTime ? null : (start ?? this.start),
      end: clearTime ? null : (end ?? this.end),
      done: done ?? this.done,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'type': type.name,
        'category': category.name,
        'reminderMinutesBefore': reminderMinutesBefore,
        'secondaryReminderMinutesBefore': secondaryReminderMinutesBefore,
        'done': done,
        'pinned': pinned,
        'start': start == null ? null : [start!.hour, start!.minute],
        'end': end == null ? null : [end!.hour, end!.minute],
      };

  factory AgendaItem.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(dynamic value) {
      if (value is List && value.length == 2) {
        return TimeOfDay(hour: value[0] as int, minute: value[1] as int);
      }
      return null;
    }

    return AgendaItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      type: ItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ItemType.appointment,
      ),
      category: AgendaCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AgendaCategory.personal,
      ),
      reminderMinutesBefore: json['reminderMinutesBefore'] as int?,
      secondaryReminderMinutesBefore:
          json['secondaryReminderMinutesBefore'] as int?,
      done: json['done'] as bool? ?? false,
      pinned: json['pinned'] as bool? ?? false,
      start: parseTime(json['start']),
      end: parseTime(json['end']),
    );
  }
}

class InboxEntry {
  final String id;
  final String text;
  final DateTime createdAt;
  final bool pinned;

  const InboxEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.pinned = false,
  });

  InboxEntry copyWith({
    String? text,
    bool? pinned,
  }) =>
      InboxEntry(
        id: id,
        text: text ?? this.text,
        createdAt: createdAt,
        pinned: pinned ?? this.pinned,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'pinned': pinned,
      };

  factory InboxEntry.fromJson(Map<String, dynamic> json) => InboxEntry(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        pinned: json['pinned'] as bool? ?? false,
      );
}

enum DayMood { great, good, neutral, low, hard }

extension DayMoodUi on DayMood {
  String get label => switch (this) {
        DayMood.great => 'Benissimo',
        DayMood.good => 'Bene',
        DayMood.neutral => 'Così così',
        DayMood.low => 'Giù',
        DayMood.hard => 'Difficile',
      };

  String get emoji => switch (this) {
        DayMood.great => '😍',
        DayMood.good => '😊',
        DayMood.neutral => '😐',
        DayMood.low => '😔',
        DayMood.hard => '😣',
      };

  Color get color => switch (this) {
        DayMood.great => const Color(0xFFE789A7),
        DayMood.good => const Color(0xFF79B697),
        DayMood.neutral => const Color(0xFFE0A85C),
        DayMood.low => const Color(0xFF8C9BC7),
        DayMood.hard => const Color(0xFF9B8A9D),
      };
}

class HabitDefinition {
  final String id;
  final String name;

  const HabitDefinition({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  factory HabitDefinition.fromJson(Map<String, dynamic> json) =>
      HabitDefinition(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
      );
}

class DayJournal {
  final String beautiful;
  final String note;
  final DayMood? mood;
  final List<String> gratitude;
  final List<String> completedHabitIds;

  const DayJournal({
    this.beautiful = '',
    this.note = '',
    this.mood,
    this.gratitude = const [],
    this.completedHabitIds = const [],
  });

  DayJournal copyWith({
    String? beautiful,
    String? note,
    DayMood? mood,
    List<String>? gratitude,
    List<String>? completedHabitIds,
    bool clearMood = false,
  }) {
    return DayJournal(
      beautiful: beautiful ?? this.beautiful,
      note: note ?? this.note,
      mood: clearMood ? null : (mood ?? this.mood),
      gratitude: gratitude ?? this.gratitude,
      completedHabitIds: completedHabitIds ?? this.completedHabitIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'beautiful': beautiful,
        'note': note,
        'mood': mood?.name,
        'gratitude': gratitude,
        'completedHabitIds': completedHabitIds,
      };

  factory DayJournal.fromJson(Map<String, dynamic> json) => DayJournal(
        beautiful: json['beautiful'] as String? ?? '',
        note: json['note'] as String? ?? '',
        mood: json['mood'] == null
            ? null
            : DayMood.values.firstWhere(
                (e) => e.name == json['mood'],
                orElse: () => DayMood.neutral,
              ),
        gratitude:
            List<String>.from(json['gratitude'] as List? ?? const []),
        completedHabitIds: List<String>.from(
          json['completedHabitIds'] as List? ?? const [],
        ),
      );
}


class WeekData {
  final String focus;
  final List<String> priorities;
  final String bestThing;
  final String reflection;

  const WeekData({
    this.focus = '',
    this.priorities = const [],
    this.bestThing = '',
    this.reflection = '',
  });

  WeekData copyWith({
    String? focus,
    List<String>? priorities,
    String? bestThing,
    String? reflection,
  }) {
    return WeekData(
      focus: focus ?? this.focus,
      priorities: priorities ?? this.priorities,
      bestThing: bestThing ?? this.bestThing,
      reflection: reflection ?? this.reflection,
    );
  }

  Map<String, dynamic> toJson() => {
        'focus': focus,
        'priorities': priorities,
        'bestThing': bestThing,
        'reflection': reflection,
      };

  factory WeekData.fromJson(Map<String, dynamic> json) => WeekData(
        focus: json['focus'] as String? ?? '',
        priorities: List<String>.from(json['priorities'] as List? ?? const []),
        bestThing: json['bestThing'] as String? ?? '',
        reflection: json['reflection'] as String? ?? '',
      );
}

class MonthlyData {
  final String intention;
  final List<String> goals;
  final List<String> books;
  final List<String> films;
  final List<String> hobbies;
  final List<String> wishes;
  final List<String> ideas;
  final String monthWord;
  final String selfCare;
  final int budgetCents;
  final List<ExpenseEntry> expenses;
  final String bestMoment;
  final String lesson;
  final String challenge;
  final String nextMonth;
  final String reflection;

  const MonthlyData({
    this.intention = '',
    this.goals = const [],
    this.books = const [],
    this.films = const [],
    this.hobbies = const [],
    this.wishes = const [],
    this.ideas = const [],
    this.monthWord = '',
    this.selfCare = '',
    this.budgetCents = 0,
    this.expenses = const [],
    this.bestMoment = '',
    this.lesson = '',
    this.challenge = '',
    this.nextMonth = '',
    this.reflection = '',
  });

  MonthlyData copyWith({
    String? intention,
    List<String>? goals,
    List<String>? books,
    List<String>? films,
    List<String>? hobbies,
    List<String>? wishes,
    List<String>? ideas,
    String? monthWord,
    String? selfCare,
    int? budgetCents,
    List<ExpenseEntry>? expenses,
    String? bestMoment,
    String? lesson,
    String? challenge,
    String? nextMonth,
    String? reflection,
  }) {
    return MonthlyData(
      intention: intention ?? this.intention,
      goals: goals ?? this.goals,
      books: books ?? this.books,
      films: films ?? this.films,
      hobbies: hobbies ?? this.hobbies,
      wishes: wishes ?? this.wishes,
      ideas: ideas ?? this.ideas,
      monthWord: monthWord ?? this.monthWord,
      selfCare: selfCare ?? this.selfCare,
      budgetCents: budgetCents ?? this.budgetCents,
      expenses: expenses ?? this.expenses,
      bestMoment: bestMoment ?? this.bestMoment,
      lesson: lesson ?? this.lesson,
      challenge: challenge ?? this.challenge,
      nextMonth: nextMonth ?? this.nextMonth,
      reflection: reflection ?? this.reflection,
    );
  }

  Map<String, dynamic> toJson() => {
        'intention': intention,
        'goals': goals,
        'books': books,
        'films': films,
        'hobbies': hobbies,
        'wishes': wishes,
        'ideas': ideas,
        'monthWord': monthWord,
        'selfCare': selfCare,
        'budgetCents': budgetCents,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'bestMoment': bestMoment,
        'lesson': lesson,
        'challenge': challenge,
        'nextMonth': nextMonth,
        'reflection': reflection,
      };

  factory MonthlyData.fromJson(Map<String, dynamic> json) => MonthlyData(
        intention: json['intention'] as String? ?? '',
        goals: List<String>.from(json['goals'] as List? ?? const []),
        books: List<String>.from(json['books'] as List? ?? const []),
        films: List<String>.from(json['films'] as List? ?? const []),
        hobbies: List<String>.from(json['hobbies'] as List? ?? const []),
        wishes: List<String>.from(json['wishes'] as List? ?? const []),
        ideas: List<String>.from(json['ideas'] as List? ?? const []),
        monthWord: json['monthWord'] as String? ?? '',
        selfCare: json['selfCare'] as String? ?? '',
        budgetCents: json['budgetCents'] as int? ?? 0,
        expenses: (json['expenses'] as List? ?? const [])
            .map((e) => ExpenseEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        bestMoment: json['bestMoment'] as String? ?? '',
        lesson: json['lesson'] as String? ?? '',
        challenge: json['challenge'] as String? ?? '',
        nextMonth: json['nextMonth'] as String? ?? '',
        reflection: json['reflection'] as String? ?? '',
      );
}

class ExpenseEntry {
  final String id;
  final int cents;
  final String category;
  final String note;
  final DateTime date;

  const ExpenseEntry({
    required this.id,
    required this.cents,
    required this.category,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'cents': cents,
        'category': category,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) => ExpenseEntry(
        id: json['id'] as String,
        cents: json['cents'] as int? ?? 0,
        category: json['category'] as String? ?? 'Altro',
        note: json['note'] as String? ?? '',
        date: DateTime.parse(json['date'] as String),
      );
}

class _LocalSyncEntity {
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;

  const _LocalSyncEntity({
    required this.entityType,
    required this.entityId,
    required this.payload,
  });

  String get localKey => '$entityType:$entityId';
}

enum SharedEntryType { appointment, task, note }

extension SharedEntryTypeUi on SharedEntryType {
  String get label => switch (this) {
        SharedEntryType.appointment => 'Appuntamento',
        SharedEntryType.task => 'Da fare',
        SharedEntryType.note => 'Nota',
      };

  IconData get icon => switch (this) {
        SharedEntryType.appointment => Icons.event_outlined,
        SharedEntryType.task => Icons.check_circle_outline,
        SharedEntryType.note => Icons.sticky_note_2_outlined,
      };
}

class SharedEntry {
  final String id;
  final SharedEntryType type;
  final String title;
  final String note;
  final DateTime date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final bool done;
  final String? updatedBy;

  const SharedEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.note,
    required this.date,
    this.start,
    this.end,
    this.done = false,
    this.updatedBy,
  });

  SharedEntry copyWith({
    SharedEntryType? type,
    String? title,
    String? note,
    DateTime? date,
    TimeOfDay? start,
    TimeOfDay? end,
    bool? done,
    String? updatedBy,
    bool clearTime = false,
  }) =>
      SharedEntry(
        id: id,
        type: type ?? this.type,
        title: title ?? this.title,
        note: note ?? this.note,
        date: date ?? this.date,
        start: clearTime ? null : (start ?? this.start),
        end: clearTime ? null : (end ?? this.end),
        done: done ?? this.done,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'note': note,
        'date': date.toIso8601String(),
        'start': start == null
            ? null
            : {'hour': start!.hour, 'minute': start!.minute},
        'end': end == null
            ? null
            : {'hour': end!.hour, 'minute': end!.minute},
        'done': done,
      };

  factory SharedEntry.fromJson(
    Map<String, dynamic> json, {
    String? updatedBy,
  }) {
    TimeOfDay? parseTime(dynamic raw) {
      if (raw is! Map) return null;
      final map = Map<String, dynamic>.from(raw);
      return TimeOfDay(
        hour: map['hour'] as int? ?? 0,
        minute: map['minute'] as int? ?? 0,
      );
    }

    return SharedEntry(
      id: json['id'] as String,
      type: SharedEntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SharedEntryType.appointment,
      ),
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ??
          DateTime.now(),
      start: parseTime(json['start']),
      end: parseTime(json['end']),
      done: json['done'] as bool? ?? false,
      updatedBy: updatedBy,
    );
  }
}

class BackupSummary {
  final DateTime exportedAt;
  final int itemCount;
  final int journalCount;
  final int monthCount;
  final int weekCount;
  final int habitCount;

  const BackupSummary({
    required this.exportedAt,
    required this.itemCount,
    required this.journalCount,
    required this.monthCount,
    required this.weekCount,
    required this.habitCount,
  });
}

class LocalBackupSnapshot {
  final String id;
  final DateTime createdAt;
  final String label;
  final Map<String, dynamic> data;

  const LocalBackupSnapshot({
    required this.id,
    required this.createdAt,
    required this.label,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'label': label,
        'data': data,
      };

  factory LocalBackupSnapshot.fromJson(Map<String, dynamic> json) =>
      LocalBackupSnapshot(
        id: json['id'] as String? ?? const Uuid().v4(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        label: json['label'] as String? ?? 'Backup automatico',
        data: Map<String, dynamic>.from(json['data'] as Map? ?? const {}),
      );
}

class AgendaStore extends ChangeNotifier {
  static const _itemsKey = 'items_v1';
  static const _journalsKey = 'journals_v1';
  static const _monthsKey = 'months_v1';
  static const _weeksKey = 'weeks_v1';
  static const _habitsKey = 'habits_v1';
  static const _snapshotsKey = 'backup_snapshots_v1';
  static const _preferencesKey = 'agenda_preferences_v1';
  static const _inboxKey = 'inbox_v1';
  static const _syncQueueKey = 'cloud_sync_queue_v1';
  static const _syncIndexKey = 'cloud_sync_index_v1';
  static const _syncOwnerKey = 'cloud_sync_owner_v1';
  static const _accountProfilesKey = 'account_profiles_v1';
  static const _activeAccountKey = 'active_account_v1';
  static const _legacyClaimedByKey = 'legacy_claimed_by_v1';
  static const _backupFormat = 'agenda_per_anna_backup';
  static const _backupSchemaVersion = 1;

  final List<AgendaItem> items = [];
  final Map<String, DayJournal> journals = {};
  final Map<String, MonthlyData> months = {};
  final Map<String, WeekData> weeks = {};
  final List<HabitDefinition> habits = [];
  final List<LocalBackupSnapshot> localSnapshots = [];
  final List<InboxEntry> inbox = [];
  final Map<String, CloudSyncOperation> _syncQueue = {};
  final Map<String, String> _syncIndex = {};
  final Set<String> _unreadableStorageKeys = {};
  AgendaPreferences preferences = const AgendaPreferences();

  Timer? _cloudSyncTimer;
  Timer? _syncDebounceTimer;
  bool _cloudSyncRunning = false;
  String? _activeAccountId;

  String? get activeAccountId => _activeAccountId;
  bool get hasStorageWarnings => _unreadableStorageKeys.isNotEmpty;

  List<String> get _workingStorageKeys => const [
        _itemsKey,
        _journalsKey,
        _monthsKey,
        _weeksKey,
        _habitsKey,
        _snapshotsKey,
        _preferencesKey,
        _inboxKey,
        _syncQueueKey,
        _syncIndexKey,
        _syncOwnerKey,
      ];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _activeAccountId = prefs.getString(_activeAccountKey);
    _unreadableStorageKeys.clear();

    items.clear();
    journals.clear();
    months.clear();
    weeks.clear();
    habits.clear();
    localSnapshots.clear();
    inbox.clear();
    _syncQueue.clear();
    _syncIndex.clear();
    preferences = const AgendaPreferences();

    T? decodeSection<T>(
      String key,
      T Function(dynamic value) parser,
    ) {
      final raw = prefs.getString(key);
      if (raw == null) return null;
      try {
        return parser(jsonDecode(raw));
      } catch (_) {
        _unreadableStorageKeys.add(key);
        return null;
      }
    }

    final parsedItems = decodeSection<List<AgendaItem>>(
      _itemsKey,
      (value) => (value as List)
          .map(
            (e) => AgendaItem.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
    if (parsedItems != null) items.addAll(parsedItems);

    final parsedJournals = decodeSection<Map<String, DayJournal>>(
      _journalsKey,
      (value) => Map<String, dynamic>.from(value as Map).map(
        (key, raw) => MapEntry(
          key,
          DayJournal.fromJson(Map<String, dynamic>.from(raw as Map)),
        ),
      ),
    );
    if (parsedJournals != null) journals.addAll(parsedJournals);

    final parsedMonths = decodeSection<Map<String, MonthlyData>>(
      _monthsKey,
      (value) => Map<String, dynamic>.from(value as Map).map(
        (key, raw) => MapEntry(
          key,
          MonthlyData.fromJson(Map<String, dynamic>.from(raw as Map)),
        ),
      ),
    );
    if (parsedMonths != null) months.addAll(parsedMonths);

    final parsedWeeks = decodeSection<Map<String, WeekData>>(
      _weeksKey,
      (value) => Map<String, dynamic>.from(value as Map).map(
        (key, raw) => MapEntry(
          key,
          WeekData.fromJson(Map<String, dynamic>.from(raw as Map)),
        ),
      ),
    );
    if (parsedWeeks != null) weeks.addAll(parsedWeeks);

    final hadHabitsKey = prefs.containsKey(_habitsKey);
    final parsedHabits = decodeSection<List<HabitDefinition>>(
      _habitsKey,
      (value) => (value as List)
          .map(
            (e) => HabitDefinition.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
    if (parsedHabits != null) habits.addAll(parsedHabits);

    final parsedSnapshots = decodeSection<List<LocalBackupSnapshot>>(
      _snapshotsKey,
      (value) => (value as List)
          .map(
            (e) => LocalBackupSnapshot.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
    if (parsedSnapshots != null) localSnapshots.addAll(parsedSnapshots);

    final parsedPreferences = decodeSection<AgendaPreferences>(
      _preferencesKey,
      (value) => AgendaPreferences.fromJson(
        Map<String, dynamic>.from(value as Map),
      ),
    );
    if (parsedPreferences != null) {
      preferences = parsedPreferences;
    } else if (!prefs.containsKey(_preferencesKey)) {
      preferences = const AgendaPreferences(onboardingDone: false);
    }

    final parsedInbox = decodeSection<List<InboxEntry>>(
      _inboxKey,
      (value) => (value as List)
          .map(
            (e) => InboxEntry.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
    if (parsedInbox != null) inbox.addAll(parsedInbox);

    final parsedQueue = decodeSection<Map<String, CloudSyncOperation>>(
      _syncQueueKey,
      (value) => Map<String, dynamic>.from(value as Map).map(
        (key, raw) => MapEntry(
          key,
          CloudSyncOperation.fromJson(
            Map<String, dynamic>.from(raw as Map),
          ),
        ),
      ),
    );
    if (parsedQueue != null) _syncQueue.addAll(parsedQueue);

    final parsedIndex = decodeSection<Map<String, String>>(
      _syncIndexKey,
      (value) => Map<String, String>.from(
        Map<String, dynamic>.from(value as Map),
      ),
    );
    if (parsedIndex != null) _syncIndex.addAll(parsedIndex);

    if (!hadHabitsKey && !_unreadableStorageKeys.contains(_habitsKey)) {
      habits.addAll(const [
        HabitDefinition(id: 'water', name: 'Bere abbastanza'),
        HabitDefinition(id: 'move', name: 'Muovermi un po’'),
        HabitDefinition(id: 'me', name: 'Tempo per me'),
      ]);
    }
  }

  Map<String, dynamic> _readAccountProfiles(SharedPreferences prefs) {
    final raw = prefs.getString(_accountProfilesKey);
    if (raw == null) return <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> _captureWorkingProfile(
    SharedPreferences prefs,
  ) {
    final result = <String, dynamic>{};
    for (final key in _workingStorageKeys) {
      final raw = prefs.getString(key);
      if (raw != null) result[key] = raw;
    }
    return result;
  }

  Future<void> _writeWorkingProfile(
    SharedPreferences prefs,
    Map<String, dynamic> profile,
  ) async {
    for (final key in _workingStorageKeys) {
      final raw = profile[key];
      if (raw is String) {
        await prefs.setString(key, raw);
      } else {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _archiveCurrentProfile(
    SharedPreferences prefs,
  ) async {
    final profiles = _readAccountProfiles(prefs);
    final scope = _activeAccountId == null
        ? 'guest'
        : 'user:$_activeAccountId';
    profiles[scope] = _captureWorkingProfile(prefs);
    await prefs.setString(_accountProfilesKey, jsonEncode(profiles));
  }

  bool _workingProfileHasUserData(SharedPreferences prefs) {
    for (final key in const [
      _itemsKey,
      _journalsKey,
      _monthsKey,
      _weeksKey,
      _habitsKey,
      _inboxKey,
    ]) {
      final raw = prefs.getString(key);
      if (raw != null && raw != '[]' && raw != '{}') return true;
    }
    return false;
  }

  Future<void> activateCloudAccount(String? accountId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_activeAccountId == accountId) {
      if (accountId != null) {
        _bindPendingOperationsTo(accountId);
        await _persistSyncMetadata(prefs);
      }
      return;
    }

    await _archiveCurrentProfile(prefs);
    final profiles = _readAccountProfiles(prefs);
    final targetScope =
        accountId == null ? 'guest' : 'user:$accountId';

    if (accountId != null &&
        profiles[targetScope] == null &&
        prefs.getString(_legacyClaimedByKey) == null &&
        _activeAccountId == null &&
        _workingProfileHasUserData(prefs)) {
      profiles[targetScope] = _captureWorkingProfile(prefs);
      profiles['guest'] = <String, dynamic>{};
      await prefs.setString(_legacyClaimedByKey, accountId);
      await prefs.setString(_accountProfilesKey, jsonEncode(profiles));
    }

    final rawTarget = profiles[targetScope];
    final target = rawTarget is Map
        ? Map<String, dynamic>.from(rawTarget)
        : <String, dynamic>{};

    await _writeWorkingProfile(prefs, target);
    _activeAccountId = accountId;
    if (accountId == null) {
      await prefs.remove(_activeAccountKey);
    } else {
      await prefs.setString(_activeAccountKey, accountId);
    }

    await load();

    if (accountId != null) {
      _activeAccountId = accountId;
      _bindPendingOperationsTo(accountId);
      await prefs.setString(_activeAccountKey, accountId);
      await _persistSyncMetadata(prefs);
    }

    notifyListeners();
  }

  void _bindPendingOperationsTo(String ownerId) {
    for (final entry in _syncQueue.entries.toList()) {
      final operation = entry.value;
      if (operation.ownerId == ownerId) continue;
      if (operation.ownerId != null && operation.ownerId != ownerId) {
        continue;
      }
      _syncQueue[entry.key] = CloudSyncOperation(
        entityType: operation.entityType,
        entityId: operation.entityId,
        payload: operation.payload,
        updatedAt: operation.updatedAt,
        deleted: operation.deleted,
        ownerId: ownerId,
      );
    }
  }

  Future<void> _save({
    bool createAutoSnapshot = true,
    bool enqueueSync = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_unreadableStorageKeys.contains(_itemsKey)) {
      await prefs.setString(
        _itemsKey,
        jsonEncode(items.map((e) => e.toJson()).toList()),
      );
    }
    if (!_unreadableStorageKeys.contains(_journalsKey)) {
      await prefs.setString(
        _journalsKey,
        jsonEncode(journals.map((k, v) => MapEntry(k, v.toJson()))),
      );
    }
    if (!_unreadableStorageKeys.contains(_monthsKey)) {
      await prefs.setString(
        _monthsKey,
        jsonEncode(months.map((k, v) => MapEntry(k, v.toJson()))),
      );
    }
    if (!_unreadableStorageKeys.contains(_weeksKey)) {
      await prefs.setString(
        _weeksKey,
        jsonEncode(weeks.map((k, v) => MapEntry(k, v.toJson()))),
      );
    }
    if (!_unreadableStorageKeys.contains(_habitsKey)) {
      await prefs.setString(
        _habitsKey,
        jsonEncode(habits.map((e) => e.toJson()).toList()),
      );
    }
    if (!_unreadableStorageKeys.contains(_preferencesKey)) {
      await prefs.setString(
        _preferencesKey,
        jsonEncode(preferences.toJson()),
      );
    }
    if (!_unreadableStorageKeys.contains(_inboxKey)) {
      await prefs.setString(
        _inboxKey,
        jsonEncode(inbox.map((e) => e.toJson()).toList()),
      );
    }

    if (createAutoSnapshot) {
      await _maybeCreateAutomaticSnapshot(prefs);
    }

    if (enqueueSync) {
      await _captureSyncChanges(prefs);
      _scheduleCloudSync();
    }
  }

  void _scheduleCloudSync() {
    final cloud = CloudSyncService.instance;
    if (!cloud.signedIn || _activeAccountId != cloud.userId) return;
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = Timer(
      const Duration(milliseconds: 900),
      () => unawaited(syncCloud()),
    );
  }

  Map<String, dynamic> _cloudPreferencesPayload() {
    return Map<String, dynamic>.from(preferences.toJson())
      ..remove('privacyLockEnabled')
      ..remove('biometricUnlock')
      ..remove('autoLockMinutes')
      ..remove('hideHomeDetails')
      ..remove('pinSalt')
      ..remove('pinHash')
      ..remove('onboardingDone');
  }

  Future<void> _queuePreferencesSync() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _cloudPreferencesPayload();
    final key = 'preferences:main';
    _syncIndex[key] = _syncPayloadHash(payload);
    _syncQueue[key] = CloudSyncOperation(
      entityType: 'preferences',
      entityId: 'main',
      payload: payload,
      updatedAt: DateTime.now(),
      ownerId: _activeAccountId,
    );
    await _persistSyncMetadata(prefs);
    _scheduleCloudSync();
  }

  Map<String, _LocalSyncEntity> _currentSyncEntities() {
    final result = <String, _LocalSyncEntity>{};

    void add(
      String type,
      String id,
      Map<String, dynamic> payload,
    ) {
      final entity = _LocalSyncEntity(
        entityType: type,
        entityId: id,
        payload: payload,
      );
      result[entity.localKey] = entity;
    }

    for (final item in items) {
      add('item', item.id, item.toJson());
    }
    for (final entry in journals.entries) {
      add('journal', entry.key, entry.value.toJson());
    }
    for (final entry in months.entries) {
      add('month', entry.key, entry.value.toJson());
    }
    for (final entry in weeks.entries) {
      add('week', entry.key, entry.value.toJson());
    }
    for (final habit in habits) {
      add('habit', habit.id, habit.toJson());
    }
    for (final entry in inbox) {
      add('inbox', entry.id, entry.toJson());
    }

    add('preferences', 'main', _cloudPreferencesPayload());

    return result;
  }

  String _syncPayloadHash(Map<String, dynamic> payload) =>
      sha256.convert(utf8.encode(jsonEncode(payload))).toString();

  Future<void> _captureSyncChanges(
    SharedPreferences prefs, {
    bool forceAll = false,
  }) async {
    final entities = _currentSyncEntities();
    final now = DateTime.now();

    for (final entry in entities.entries) {
      final hash = _syncPayloadHash(entry.value.payload);
      if (forceAll || _syncIndex[entry.key] != hash) {
        _syncQueue[entry.key] = CloudSyncOperation(
          entityType: entry.value.entityType,
          entityId: entry.value.entityId,
          payload: entry.value.payload,
          updatedAt: now,
          ownerId: _activeAccountId,
        );
      }
    }

    for (final oldKey in _syncIndex.keys.toList()) {
      if (entities.containsKey(oldKey)) continue;
      final splitAt = oldKey.indexOf(':');
      if (splitAt <= 0) continue;
      _syncQueue[oldKey] = CloudSyncOperation(
        entityType: oldKey.substring(0, splitAt),
        entityId: oldKey.substring(splitAt + 1),
        payload: null,
        updatedAt: now,
        deleted: true,
        ownerId: _activeAccountId,
      );
    }

    _replaceSyncIndex(entities);
    await _persistSyncMetadata(prefs);
  }

  void _replaceSyncIndex(Map<String, _LocalSyncEntity> entities) {
    _syncIndex
      ..clear()
      ..addEntries(
        entities.entries.map(
          (entry) => MapEntry(
            entry.key,
            _syncPayloadHash(entry.value.payload),
          ),
        ),
      );
  }

  Future<void> _persistSyncMetadata(SharedPreferences prefs) async {
    await prefs.setString(
      _syncQueueKey,
      jsonEncode(
        _syncQueue.map((key, value) => MapEntry(key, value.toJson())),
      ),
    );
    await prefs.setString(_syncIndexKey, jsonEncode(_syncIndex));
  }

  Map<String, dynamic> _backupDataPayload() => {
        'items': items.map((e) => e.toJson()).toList(),
        'journals': journals.map((k, v) => MapEntry(k, v.toJson())),
        'months': months.map((k, v) => MapEntry(k, v.toJson())),
        'weeks': weeks.map((k, v) => MapEntry(k, v.toJson())),
        'habits': habits.map((e) => e.toJson()).toList(),
        'inbox': inbox.map((e) => e.toJson()).toList(),
        'preferences': preferences.toJson(),
      };

  String createBackupJson() {
    final document = {
      'format': _backupFormat,
      'schemaVersion': _backupSchemaVersion,
      'appVersion': '0.14.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': _backupDataPayload(),
    };
    return const JsonEncoder.withIndent('  ').convert(document);
  }

  BackupSummary inspectBackup(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Il file non contiene un backup valido.');
    }

    final root = Map<String, dynamic>.from(decoded);
    if (root['format'] != _backupFormat) {
      throw const FormatException('Questo file non appartiene ad Agenda per Anna.');
    }

    final schema = root['schemaVersion'];
    if (schema is! int || schema > _backupSchemaVersion || schema < 1) {
      throw const FormatException('Versione del backup non supportata.');
    }

    final data = root['data'];
    if (data is! Map) {
      throw const FormatException('Il backup non contiene dati leggibili.');
    }

    final payload = Map<String, dynamic>.from(data);
    final exportedAt =
        DateTime.tryParse(root['exportedAt'] as String? ?? '') ??
            DateTime.now();

    return BackupSummary(
      exportedAt: exportedAt,
      itemCount: (payload['items'] as List? ?? const []).length,
      journalCount: (payload['journals'] as Map? ?? const {}).length,
      monthCount: (payload['months'] as Map? ?? const {}).length,
      weekCount: (payload['weeks'] as Map? ?? const {}).length,
      habitCount: (payload['habits'] as List? ?? const []).length,
    );
  }

  Future<void> restoreBackup(
    String raw, {
    required bool merge,
  }) async {
    final decoded = jsonDecode(raw);
    final root = Map<String, dynamic>.from(decoded as Map);
    inspectBackup(raw);

    await createLocalSnapshot(label: 'Prima del ripristino');

    final payload =
        Map<String, dynamic>.from(root['data'] as Map<String, dynamic>);

    final incomingItems = (payload['items'] as List? ?? const [])
        .map(
          (e) => AgendaItem.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final incomingJournals =
        Map<String, dynamic>.from(payload['journals'] as Map? ?? const {})
            .map(
      (k, v) => MapEntry(
        k,
        DayJournal.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
    final incomingMonths =
        Map<String, dynamic>.from(payload['months'] as Map? ?? const {}).map(
      (k, v) => MapEntry(
        k,
        MonthlyData.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
    final incomingWeeks =
        Map<String, dynamic>.from(payload['weeks'] as Map? ?? const {}).map(
      (k, v) => MapEntry(
        k,
        WeekData.fromJson(Map<String, dynamic>.from(v as Map)),
      ),
    );
    final incomingHabits = (payload['habits'] as List? ?? const [])
        .map(
          (e) => HabitDefinition.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final incomingInbox = (payload['inbox'] as List? ?? const [])
        .map(
          (e) => InboxEntry.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final incomingPreferences = payload['preferences'] is Map
        ? AgendaPreferences.fromJson(
            Map<String, dynamic>.from(payload['preferences'] as Map),
          )
        : null;

    final oldItems = [...items];

    if (merge) {
      final byId = {for (final item in items) item.id: item};
      for (final item in incomingItems) {
        byId[item.id] = item;
      }
      items
        ..clear()
        ..addAll(byId.values);

      journals.addAll(incomingJournals);
      months.addAll(incomingMonths);
      weeks.addAll(incomingWeeks);

      final habitsById = {for (final habit in habits) habit.id: habit};
      for (final habit in incomingHabits) {
        habitsById[habit.id] = habit;
      }
      habits
        ..clear()
        ..addAll(habitsById.values);

      final inboxById = {for (final entry in inbox) entry.id: entry};
      for (final entry in incomingInbox) {
        inboxById[entry.id] = entry;
      }
      inbox
        ..clear()
        ..addAll(inboxById.values);
    } else {
      items
        ..clear()
        ..addAll(incomingItems);
      journals
        ..clear()
        ..addAll(incomingJournals);
      months
        ..clear()
        ..addAll(incomingMonths);
      weeks
        ..clear()
        ..addAll(incomingWeeks);
      habits
        ..clear()
        ..addAll(incomingHabits);
      inbox
        ..clear()
        ..addAll(incomingInbox);
      if (incomingPreferences != null) {
        preferences = incomingPreferences;
      }
    }

    if (habits.isEmpty) {
      habits.addAll(const [
        HabitDefinition(id: 'water', name: 'Bere abbastanza'),
        HabitDefinition(id: 'move', name: 'Muovermi un po’'),
        HabitDefinition(id: 'me', name: 'Tempo per me'),
      ]);
    }

    for (final item in oldItems) {
      await NotificationService.instance.cancel(item.id);
      await NotificationService.instance.cancel('${item.id}:primary');
      await NotificationService.instance.cancel('${item.id}:secondary');
    }

    await _save(createAutoSnapshot: false);

    for (final item in items) {
      await _syncReminders(item);
    }

    notifyListeners();
  }

  Future<void> createLocalSnapshot({
    String label = 'Backup manuale',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    localSnapshots.insert(
      0,
      LocalBackupSnapshot(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        label: label,
        data: jsonDecode(jsonEncode(_backupDataPayload()))
            as Map<String, dynamic>,
      ),
    );
    if (localSnapshots.length > 5) {
      localSnapshots.removeRange(5, localSnapshots.length);
    }
    await _saveSnapshots(prefs);
    notifyListeners();
  }

  Future<void> _maybeCreateAutomaticSnapshot(
    SharedPreferences prefs,
  ) async {
    final now = DateTime.now();
    final shouldCreate = localSnapshots.isEmpty ||
        now.difference(localSnapshots.first.createdAt).inHours >= 6;
    if (!shouldCreate) return;

    localSnapshots.insert(
      0,
      LocalBackupSnapshot(
        id: const Uuid().v4(),
        createdAt: now,
        label: 'Backup automatico',
        data: jsonDecode(jsonEncode(_backupDataPayload()))
            as Map<String, dynamic>,
      ),
    );
    if (localSnapshots.length > 5) {
      localSnapshots.removeRange(5, localSnapshots.length);
    }
    await _saveSnapshots(prefs);
  }

  Future<void> _saveSnapshots(SharedPreferences prefs) async {
    await prefs.setString(
      _snapshotsKey,
      jsonEncode(localSnapshots.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> restoreLocalSnapshot(String id) async {
    final snapshot = localSnapshots.firstWhere((e) => e.id == id);
    final document = {
      'format': _backupFormat,
      'schemaVersion': _backupSchemaVersion,
      'appVersion': '0.14.0',
      'exportedAt': snapshot.createdAt.toIso8601String(),
      'data': snapshot.data,
    };
    await restoreBackup(jsonEncode(document), merge: false);
  }

  Future<void> deleteLocalSnapshot(String id) async {
    localSnapshots.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await _saveSnapshots(prefs);
    notifyListeners();
  }

  String createReadableExport() {
    final buffer = StringBuffer();
    final now = DateTime.now();

    buffer.writeln('AGENDA PER ANNA');
    buffer.writeln('Esportazione del ${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(now)}');
    buffer.writeln();
    buffer.writeln('============================================================');
    buffer.writeln('IMPEGNI E ATTIVITÀ');
    buffer.writeln('============================================================');

    final sortedItems = [...items]..sort((a, b) {
      final dateCompare = a.date.compareTo(b.date);
      if (dateCompare != 0) return dateCompare;
      final am = a.start == null ? 9999 : a.start!.hour * 60 + a.start!.minute;
      final bm = b.start == null ? 9999 : b.start!.hour * 60 + b.start!.minute;
      return am.compareTo(bm);
    });

    if (sortedItems.isEmpty) {
      buffer.writeln('Nessun impegno salvato.');
    } else {
      for (final item in sortedItems) {
        final date = DateFormat('d MMMM yyyy', 'it_IT').format(item.date);
        final time = item.start == null ? '' : ' · ${formatTime(item.start!)}';
        buffer.writeln('- $date$time · ${item.title}');
        buffer.writeln('  Categoria: ${item.category.label}');
        if (item.note.trim().isNotEmpty) {
          buffer.writeln('  Note: ${item.note.trim()}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('============================================================');
    buffer.writeln('DIARIO');
    buffer.writeln('============================================================');

    final journalEntries = journals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (journalEntries.isEmpty) {
      buffer.writeln('Nessuna pagina di diario salvata.');
    } else {
      for (final entry in journalEntries) {
        final date = DateTime.tryParse(entry.key);
        final journal = entry.value;
        buffer.writeln();
        buffer.writeln(
          date == null
              ? entry.key
              : DateFormat('d MMMM yyyy', 'it_IT').format(date),
        );
        if (journal.mood != null) {
          buffer.writeln('Mood: ${journal.mood!.emoji} ${journal.mood!.label}');
        }
        if (journal.gratitude.isNotEmpty) {
          buffer.writeln('Cose belle:');
          for (final value in journal.gratitude) {
            buffer.writeln('  • $value');
          }
        }
        if (journal.beautiful.trim().isNotEmpty) {
          buffer.writeln('Da ricordare: ${journal.beautiful.trim()}');
        }
        if (journal.note.trim().isNotEmpty) {
          buffer.writeln('Pensieri: ${journal.note.trim()}');
        }
      }
    }

    buffer.writeln();
    buffer.writeln('============================================================');
    buffer.writeln('PAGINE MENSILI');
    buffer.writeln('============================================================');

    final monthEntries = months.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in monthEntries) {
      final parts = entry.key.split('-');
      if (parts.length != 2) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y == null || m == null) continue;
      final data = entry.value;
      buffer.writeln();
      buffer.writeln(
        _cap(DateFormat('MMMM yyyy', 'it_IT').format(DateTime(y, m))),
      );
      if (data.monthWord.isNotEmpty) {
        buffer.writeln('Parola del mese: ${data.monthWord}');
      }
      if (data.intention.isNotEmpty) {
        buffer.writeln('Intenzione: ${data.intention}');
      }
      if (data.goals.isNotEmpty) {
        buffer.writeln('Obiettivi: ${data.goals.join(' · ')}');
      }
      if (data.books.isNotEmpty) {
        buffer.writeln('Libri: ${data.books.join(' · ')}');
      }
      if (data.films.isNotEmpty) {
        buffer.writeln('Film e serie: ${data.films.join(' · ')}');
      }
      if (data.wishes.isNotEmpty) {
        buffer.writeln('Desideri: ${data.wishes.join(' · ')}');
      }
      if (data.bestMoment.isNotEmpty) {
        buffer.writeln('Momento più bello: ${data.bestMoment}');
      }
      if (data.reflection.isNotEmpty) {
        buffer.writeln('Riflessione: ${data.reflection}');
      }
    }

    return buffer.toString();
  }

  List<AgendaItem> forDay(DateTime date) {
    final out = items.where((e) => sameDay(e.date, date)).toList();
    out.sort((a, b) {
      final am = a.start == null ? 9999 : a.start!.hour * 60 + a.start!.minute;
      final bm = b.start == null ? 9999 : b.start!.hour * 60 + b.start!.minute;
      return am.compareTo(bm);
    });
    return out;
  }

  Future<void> upsert(AgendaItem item) async {
    final index = items.indexWhere((e) => e.id == item.id);
    if (index < 0) {
      items.add(item);
    } else {
      items[index] = item;
    }
    await _save();
    await _syncReminders(item);
    notifyListeners();
  }

  Future<void> duplicateItem(AgendaItem item, {DateTime? date}) async {
    final copy = AgendaItem(
      id: const Uuid().v4(),
      title: item.title,
      note: item.note,
      date: date == null
          ? item.date
          : DateTime(date.year, date.month, date.day),
      type: item.type,
      category: item.category,
      reminderMinutesBefore: item.reminderMinutesBefore,
      secondaryReminderMinutesBefore: item.secondaryReminderMinutesBefore,
      start: item.start,
      end: item.end,
      done: false,
    );
    await upsert(copy);
  }

  Future<void> deleteItem(String id) async {
    items.removeWhere((e) => e.id == id);
    await NotificationService.instance.cancel(id);
    await NotificationService.instance.cancel('$id:primary');
    await NotificationService.instance.cancel('$id:secondary');
    await _save();
    notifyListeners();
  }

  Future<void> _syncReminders(AgendaItem item) async {
    final start = item.start;

    // Pulisce anche il vecchio ID usato dalla versione a promemoria singolo.
    await NotificationService.instance.cancel(item.id);

    if (start == null) {
      await NotificationService.instance.cancel('${item.id}:primary');
      await NotificationService.instance.cancel('${item.id}:secondary');
      return;
    }

    final eventTime = DateTime(
      item.date.year,
      item.date.month,
      item.date.day,
      start.hour,
      start.minute,
    );

    Future<void> syncOne(String suffix, int? minutes) async {
      final stableId = '${item.id}:$suffix';
      if (minutes == null) {
        await NotificationService.instance.cancel(stableId);
        return;
      }

      final when = eventTime.subtract(Duration(minutes: minutes));
      await NotificationService.instance.schedule(
        stableId: stableId,
        title: item.title,
        body: minutes == 0
            ? 'È il momento di iniziare.'
            : _reminderBody(minutes, item.title),
        when: when,
      );
    }

    await syncOne('primary', item.reminderMinutesBefore);
    await syncOne('secondary', item.secondaryReminderMinutesBefore);
  }

  String _reminderBody(int minutes, String title) {
    if (minutes == 1440) return 'Domani: $title';
    if (minutes == 120) return 'Tra 2 ore: $title';
    if (minutes == 60) return 'Tra 1 ora: $title';
    return 'Tra $minutes minuti: $title';
  }

  Future<void> toggle(String id) async {
    final i = items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    items[i] = items[i].copyWith(done: !items[i].done);
    await _save();
    notifyListeners();
  }

  DayJournal journal(DateTime date) => journals[dateKey(date)] ?? const DayJournal();

  Future<void> saveJournal(DateTime date, DayJournal journal) async {
    journals[dateKey(date)] = journal;
    await _save();
    notifyListeners();
  }

  Future<void> initializeCloudSync() async {
    _cloudSyncTimer?.cancel();

    final cloud = CloudSyncService.instance;
    await activateCloudAccount(cloud.signedIn ? cloud.userId : null);

    if (cloud.signedIn) {
      await flushSharedPendingOperations();
      await syncCloud(preferRemoteOnFirstSync: true);
    }

    // Remote changes still need an occasional pull, but idle devices should
    // not rewrite the whole archive every 45 seconds.
    _cloudSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) {
        if (CloudSyncService.instance.signedIn) {
          unawaited(syncCloud());
          unawaited(flushSharedPendingOperations());
        }
      },
    );
  }

  Future<void> handleAppResumed() async {
    final cloud = CloudSyncService.instance;
    if (!cloud.initialized) {
      await cloud.initialize();
    }

    await activateCloudAccount(cloud.signedIn ? cloud.userId : null);

    if (cloud.signedIn) {
      await flushSharedPendingOperations();
      await syncCloud();
    }
  }

  Future<void> syncCloud({
    bool preferRemoteOnFirstSync = false,
  }) async {
    final cloud = CloudSyncService.instance;
    if (!cloud.configured || !cloud.initialized || !cloud.signedIn) return;
    if (_cloudSyncRunning) return;

    final ownerId = cloud.userId!;
    if (_activeAccountId != ownerId) {
      await activateCloudAccount(ownerId);
    }
    if (_activeAccountId != ownerId) return;

    final sessionEpoch = cloud.sessionEpoch;
    _cloudSyncRunning = true;
    cloud.markSyncStarted();

    try {
      final prefs = await SharedPreferences.getInstance();
      final previousOwner = prefs.getString(_syncOwnerKey);
      final firstSyncForOwner = previousOwner != ownerId;

      if (firstSyncForOwner && _syncIndex.isEmpty) {
        await _captureSyncChanges(
          prefs,
          forceAll: true,
        );
        _bindPendingOperationsTo(ownerId);
      }

      final remote = await cloud.pullPrivateRecords();

      if (cloud.sessionEpoch != sessionEpoch ||
          cloud.userId != ownerId ||
          _activeAccountId != ownerId) {
        return;
      }

      var remoteChanged = false;
      for (final record in remote) {
        final localOp = _syncQueue[record.localKey];
        final remoteWins = preferRemoteOnFirstSync && firstSyncForOwner
            ? true
            : localOp == null ||
                !localOp.updatedAt.isAfter(record.clientUpdatedAt);

        if (!remoteWins) continue;

        final changed = await _applyRemoteRecord(record);
        remoteChanged = remoteChanged || changed;
        _syncQueue.remove(record.localKey);
      }

      if (remoteChanged) {
        final entitiesAfterPull = _currentSyncEntities();
        _replaceSyncIndex(entitiesAfterPull);
        await _save(
          createAutoSnapshot: false,
          enqueueSync: false,
        );
      }

      if (cloud.sessionEpoch != sessionEpoch ||
          cloud.userId != ownerId ||
          _activeAccountId != ownerId) {
        return;
      }

      final pendingSnapshot =
          Map<String, CloudSyncOperation>.from(_syncQueue)
            ..removeWhere(
              (_, operation) =>
                  operation.ownerId != null &&
                  operation.ownerId != ownerId,
            );

      await cloud.pushPrivateOperations(pendingSnapshot.values);

      if (cloud.sessionEpoch != sessionEpoch ||
          cloud.userId != ownerId ||
          _activeAccountId != ownerId) {
        return;
      }

      for (final entry in pendingSnapshot.entries) {
        final current = _syncQueue[entry.key];
        if (current != null &&
            current.updatedAt == entry.value.updatedAt &&
            current.ownerId == entry.value.ownerId) {
          _syncQueue.remove(entry.key);
        }
      }

      await prefs.setString(_syncOwnerKey, ownerId);
      await _persistSyncMetadata(prefs);

      cloud.markSyncSuccess();
      if (remoteChanged || pendingSnapshot.isNotEmpty) {
        notifyListeners();
      }
    } catch (error) {
      cloud.markSyncError(error);
    } finally {
      _cloudSyncRunning = false;
    }
  }

  Future<bool> _applyRemoteRecord(CloudRemoteRecord record) async {
    if (record.deletedAt != null) {
      switch (record.entityType) {
        case 'item':
          final existed = items.any((e) => e.id == record.entityId);
          if (!existed) return false;
          items.removeWhere((e) => e.id == record.entityId);
          await NotificationService.instance.cancel(record.entityId);
          await NotificationService.instance
              .cancel('${record.entityId}:primary');
          await NotificationService.instance
              .cancel('${record.entityId}:secondary');
          return true;
        case 'journal':
          return journals.remove(record.entityId) != null;
        case 'month':
          return months.remove(record.entityId) != null;
        case 'week':
          return weeks.remove(record.entityId) != null;
        case 'habit':
          final before = habits.length;
          habits.removeWhere((e) => e.id == record.entityId);
          return habits.length != before;
        case 'inbox':
          final before = inbox.length;
          inbox.removeWhere((e) => e.id == record.entityId);
          return inbox.length != before;
        case 'preferences':
          return false;
      }
    }

    final payload = record.payload;
    if (payload == null) return false;

    switch (record.entityType) {
      case 'item':
        final item = AgendaItem.fromJson(payload);
        final index = items.indexWhere((e) => e.id == item.id);
        if (index >= 0 &&
            _syncPayloadHash(items[index].toJson()) ==
                _syncPayloadHash(item.toJson())) {
          return false;
        }
        if (index < 0) {
          items.add(item);
        } else {
          items[index] = item;
        }
        await _syncReminders(item);
        return true;
      case 'journal':
        final incoming = DayJournal.fromJson(payload);
        final current = journals[record.entityId];
        if (current != null &&
            _syncPayloadHash(current.toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        journals[record.entityId] = incoming;
        return true;
      case 'month':
        final incoming = MonthlyData.fromJson(payload);
        final current = months[record.entityId];
        if (current != null &&
            _syncPayloadHash(current.toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        months[record.entityId] = incoming;
        return true;
      case 'week':
        final incoming = WeekData.fromJson(payload);
        final current = weeks[record.entityId];
        if (current != null &&
            _syncPayloadHash(current.toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        weeks[record.entityId] = incoming;
        return true;
      case 'habit':
        final incoming = HabitDefinition.fromJson(payload);
        final index = habits.indexWhere((e) => e.id == incoming.id);
        if (index >= 0 &&
            _syncPayloadHash(habits[index].toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        if (index < 0) {
          habits.add(incoming);
        } else {
          habits[index] = incoming;
        }
        return true;
      case 'inbox':
        final incoming = InboxEntry.fromJson(payload);
        final index = inbox.indexWhere((e) => e.id == incoming.id);
        if (index >= 0 &&
            _syncPayloadHash(inbox[index].toJson()) ==
                _syncPayloadHash(incoming.toJson())) {
          return false;
        }
        if (index < 0) {
          inbox.add(incoming);
        } else {
          inbox[index] = incoming;
        }
        return true;
      case 'preferences':
        if (_syncPayloadHash(_cloudPreferencesPayload()) ==
            _syncPayloadHash(payload)) {
          return false;
        }
        preferences = preferences.copyWith(
          displayName: payload['displayName'] as String?,
          themeMode: AgendaThemeMode.values.firstWhere(
            (e) => e.name == payload['themeMode'],
            orElse: () => preferences.themeMode,
          ),
          palette: AgendaPalette.values.firstWhere(
            (e) => e.name == payload['palette'],
            orElse: () => preferences.palette,
          ),
          showDailyQuote:
              payload['showDailyQuote'] as bool? ??
                  preferences.showDailyQuote,
          startTab: StartTab.values.firstWhere(
            (e) => e.name == payload['startTab'],
            orElse: () => preferences.startTab,
          ),
          defaultCategory: AgendaCategory.values.firstWhere(
            (e) => e.name == payload['defaultCategory'],
            orElse: () => preferences.defaultCategory,
          ),
          defaultEventMinutes:
              (payload['defaultEventMinutes'] as int?) ??
                  preferences.defaultEventMinutes,
          defaultPrimaryReminder:
              payload['defaultPrimaryReminder'] as int?,
          defaultSecondaryReminder:
              payload['defaultSecondaryReminder'] as int?,
          clearPrimaryReminder:
              payload['defaultPrimaryReminder'] == null,
          clearSecondaryReminder:
              payload['defaultSecondaryReminder'] == null,
        );
        return true;
    }
  }

  int get pendingCloudChanges => _syncQueue.length;

  Future<void> addInboxEntry(String text) async {
    final value = text.trim();
    if (value.isEmpty) return;
    inbox.insert(
      0,
      InboxEntry(
        id: const Uuid().v4(),
        text: value,
        createdAt: DateTime.now(),
      ),
    );
    await _save();
    notifyListeners();
  }

  Future<void> deleteInboxEntry(String id) async {
    inbox.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> toggleInboxPinned(String id) async {
    final index = inbox.indexWhere((e) => e.id == id);
    if (index < 0) return;
    inbox[index] = inbox[index].copyWith(pinned: !inbox[index].pinned);
    await _save();
    notifyListeners();
  }

  Future<void> toggleItemPinned(String id) async {
    final index = items.indexWhere((e) => e.id == id);
    if (index < 0) return;
    items[index] = items[index].copyWith(pinned: !items[index].pinned);
    await _save();
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    final normalized = pin.trim();
    if (normalized.length < 4) {
      throw const FormatException('Il PIN deve avere almeno 4 cifre.');
    }
    final saltBytes = List<int>.generate(
      16,
      (_) => Random.secure().nextInt(256),
    );
    final salt = base64UrlEncode(saltBytes);
    final hash = _derivePinHash(normalized, salt);
    await savePreferences(
      preferences.copyWith(
        pinSalt: salt,
        pinHash: hash,
        privacyLockEnabled: true,
      ),
    );
  }

  bool verifyPin(String pin) {
    final salt = preferences.pinSalt;
    final expected = preferences.pinHash;
    if (salt == null || expected == null) return false;
    return _derivePinHash(pin.trim(), salt) == expected;
  }

  Future<void> savePreferences(AgendaPreferences value) async {
    preferences = value;
    final prefs = await SharedPreferences.getInstance();
    if (!_unreadableStorageKeys.contains(_preferencesKey)) {
      await prefs.setString(
        _preferencesKey,
        jsonEncode(preferences.toJson()),
      );
    }
    await _queuePreferencesSync();
    notifyListeners();
  }

  Future<void> resetPreferences() async {
    await savePreferences(const AgendaPreferences());
  }

  Future<void> addHabit(String name) async {
    final value = name.trim();
    if (value.isEmpty) return;
    habits.add(HabitDefinition(id: const Uuid().v4(), name: value));
    await _save();
    notifyListeners();
  }

  Future<void> removeHabit(String id) async {
    habits.removeWhere((e) => e.id == id);
    for (final entry in journals.entries.toList()) {
      final journal = entry.value;
      if (journal.completedHabitIds.contains(id)) {
        journals[entry.key] = journal.copyWith(
          completedHabitIds: journal.completedHabitIds
              .where((habitId) => habitId != id)
              .toList(),
        );
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> toggleHabit(DateTime date, String habitId) async {
    final current = journal(date);
    final completed = [...current.completedHabitIds];
    if (completed.contains(habitId)) {
      completed.remove(habitId);
    } else {
      completed.add(habitId);
    }
    journals[dateKey(date)] = current.copyWith(completedHabitIds: completed);
    await _save();
    notifyListeners();
  }

  MonthlyData month(int year, int month) => months[monthKey(year, month)] ?? const MonthlyData();

  Future<void> saveMonth(int year, int month, MonthlyData value) async {
    months[monthKey(year, month)] = value;
    await _save();
    notifyListeners();
  }

  WeekData week(DateTime anyDay) {
    final monday = mondayOf(anyDay);
    return weeks[dateKey(monday)] ?? const WeekData();
  }

  Future<void> saveWeek(DateTime anyDay, WeekData value) async {
    final monday = mondayOf(anyDay);
    weeks[dateKey(monday)] = value;
    await _save();
    notifyListeners();
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String monthKey(int y, int m) => '$y-${m.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _cloudSyncTimer?.cancel();
    _syncDebounceTimer?.cancel();
    super.dispose();
  }
}

class MainShell extends StatefulWidget {
  final AgendaStore store;
  const MainShell({super.key, required this.store});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.store.preferences.startTab.index;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(store: widget.store),
      CalendarScreen(store: widget.store),
      WeekScreen(store: widget.store),
      PlannerScreen(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Mese'),
          NavigationDestination(icon: Icon(Icons.view_week_outlined), label: 'Settimana'),
          NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Oggi'),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final AgendaStore store;
  const HomeScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final today = store.forDay(now);
        final upcoming = store.items
            .where((e) {
              if (e.done) return false;
              final start = e.start;
              if (start == null) return false;
              final at = DateTime(
                e.date.year,
                e.date.month,
                e.date.day,
                start.hour,
                start.minute,
              );
              return at.isAfter(now);
            })
            .toList()
          ..sort((a, b) {
            final ad = DateTime(
              a.date.year,
              a.date.month,
              a.date.day,
              a.start!.hour,
              a.start!.minute,
            );
            final bd = DateTime(
              b.date.year,
              b.date.month,
              b.date.day,
              b.start!.hour,
              b.start!.minute,
            );
            return ad.compareTo(bd);
          });
        final pendingTasks = store.items
            .where((e) => e.type == ItemType.task && !e.done)
            .length;
        final pinnedItems = store.items.where((e) => e.pinned).toList();
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(context, store),
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi'),
          ),
          appBar: AppBar(
            title: Text(
              'Agenda per ${store.preferences.displayName}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Cerca',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'Inbox',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InboxScreen(store: store),
                  ),
                ),
                icon: Badge(
                  isLabelVisible: store.inbox.isNotEmpty,
                  label: Text('${store.inbox.length}'),
                  child: const Icon(Icons.inbox_outlined),
                ),
              ),
              IconButton(
                tooltip: 'Archivio',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArchiveScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.inventory_2_outlined),
              ),
              IconButton(
                tooltip: 'Backup',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BackupScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.backup_outlined),
              ),
              IconButton(
                tooltip: 'Noi',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SharedSpaceHubScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.favorite_outline),
              ),
              IconButton(
                tooltip: 'Cloud',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CloudAccountScreen(store: store),
                  ),
                ),
                icon: AnimatedBuilder(
                  animation: CloudSyncService.instance,
                  builder: (context, _) {
                    final cloud = CloudSyncService.instance;
                    final icon = !cloud.configured
                        ? Icons.cloud_off_outlined
                        : cloud.state == CloudConnectionState.syncing
                            ? Icons.sync
                            : cloud.signedIn
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_outlined;
                    return Icon(icon);
                  },
                ),
              ),
              IconButton(
                tooltip: 'Impostazioni',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(store: store),
                  ),
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE4EC), Color(0xFFF0E8FF)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cap(DateFormat('EEEE d MMMM', 'it_IT').format(now)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      store.preferences.showDailyQuote
                          ? _dailyQuote(now).$1
                          : 'Ciao ${store.preferences.displayName} ♡',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.preferences.showDailyQuote
                          ? _dailyQuote(now).$2
                          : 'Questa è la tua pagina di oggi.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _HomeFocusCard(
                next: upcoming.isEmpty ? null : upcoming.first,
                pendingTasks: pendingTasks,
                inboxCount: store.inbox.length,
                hideDetails: store.preferences.hideHomeDetails,
                onOpenNext: upcoming.isEmpty
                    ? null
                    : () => openItemEditor(
                          context,
                          store,
                          upcoming.first.date,
                          existing: upcoming.first,
                        ),
                onOpenInbox: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InboxScreen(store: store),
                  ),
                ),
              ),
              if (pinnedItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionTitle('Fissati'),
                const SizedBox(height: 10),
                ...pinnedItems.take(3).map(
                      (e) => EventTile(
                        store: store,
                        item: e,
                        compact: true,
                        hideDetails: store.preferences.hideHomeDetails,
                      ),
                    ),
              ],
              const SizedBox(height: 24),
              const SectionTitle('Oggi'),
              const SizedBox(height: 10),
              if (today.isEmpty)
                const SimpleCard(child: Text('Nessun impegno per oggi.'))
              else
                ...today.take(5).map(
                  (e) => EventTile(
                    store: store,
                    item: e,
                    hideDetails: store.preferences.hideHomeDetails,
                  ),
                ),
              const SizedBox(height: 14),
              _TodayWellbeingCard(store: store, date: now),
              const SizedBox(height: 24),
              const SectionTitle('La mia agenda'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: NavigationCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Il mio mese',
                      subtitle: 'Obiettivi, idee e budget',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MonthScreen(store: store)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: NavigationCard(
                      icon: Icons.insights_outlined,
                      title: 'Il mio anno',
                      subtitle: 'Ricordi e progressi',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => YearScreen(store: store)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _showQuickCapture(
  BuildContext context,
  AgendaStore store,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Wrap(
        children: [
          const ListTile(
            title: Text(
              'Cattura veloce',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text('Aggiungi senza interrompere quello che stai facendo.'),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.sticky_note_2_outlined),
            ),
            title: const Text('Nota veloce'),
            subtitle: const Text('Finisce nell’Inbox, da sistemare dopo.'),
            onTap: () => Navigator.pop(sheetContext, 'note'),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.check_circle_outline),
            ),
            title: const Text('Attività'),
            subtitle: const Text('Crea subito una cosa da fare.'),
            onTap: () => Navigator.pop(sheetContext, 'task'),
          ),
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.event_outlined),
            ),
            title: const Text('Appuntamento'),
            subtitle: const Text('Apri il modulo evento di oggi.'),
            onTap: () => Navigator.pop(sheetContext, 'event'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || action == null) return;

  if (action == 'note') {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nota veloce'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Scrivi al volo...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      await store.addInboxEntry(value);
    }
    return;
  }

  await openItemEditor(
    context,
    store,
    DateTime.now(),
    initialType: action == 'task' ? ItemType.task : ItemType.appointment,
  );
}

class _HomeFocusCard extends StatelessWidget {
  final AgendaItem? next;
  final int pendingTasks;
  final int inboxCount;
  final bool hideDetails;
  final VoidCallback? onOpenNext;
  final VoidCallback onOpenInbox;

  const _HomeFocusCard({
    required this.next,
    required this.pendingTasks,
    required this.inboxCount,
    required this.hideDetails,
    required this.onOpenNext,
    required this.onOpenInbox,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nextText = next == null
        ? 'Nessun appuntamento in arrivo'
        : hideDetails
            ? 'Prossimo impegno programmato'
            : '${DateFormat('EEE d MMM', 'it_IT').format(next!.date)} · '
                '${formatTime(next!.start!)} · ${next!.title}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A colpo d’occhio',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onOpenNext,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.schedule_outlined, color: scheme.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      nextText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (onOpenNext != null) const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: '$pendingTasks da fare',
              ),
              ActionChip(
                avatar: const Icon(Icons.inbox_outlined, size: 17),
                label: Text('$inboxCount in Inbox'),
                onPressed: onOpenInbox,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InboxScreen extends StatelessWidget {
  final AgendaStore store;

  const InboxScreen({super.key, required this.store});

  Future<void> _convertToTask(
    BuildContext context,
    InboxEntry entry,
  ) async {
    final item = AgendaItem(
      id: const Uuid().v4(),
      title: entry.text,
      note: '',
      date: DateTime.now(),
      type: ItemType.task,
      category: store.preferences.defaultCategory,
    );
    await store.upsert(item);
    await store.deleteInboxEntry(entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota trasformata in attività.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final entries = [...store.inbox]
          ..sort((a, b) {
            if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
            return b.createdAt.compareTo(a.createdAt);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Inbox',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showQuickCapture(context, store),
            icon: const Icon(Icons.add),
            label: const Text('Cattura'),
          ),
          body: entries.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Qui finiranno le idee e le note catturate al volo.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.fromLTRB(
                          14,
                          8,
                          6,
                          8,
                        ),
                        leading: Icon(
                          entry.pinned
                              ? Icons.push_pin
                              : Icons.sticky_note_2_outlined,
                        ),
                        title: Text(entry.text),
                        subtitle: Text(
                          DateFormat(
                            'd MMM, HH:mm',
                            'it_IT',
                          ).format(entry.createdAt),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'pin') {
                              await store.toggleInboxPinned(entry.id);
                            } else if (value == 'task') {
                              await _convertToTask(context, entry);
                            } else if (value == 'delete') {
                              await store.deleteInboxEntry(entry.id);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'pin',
                              child: Text(
                                entry.pinned ? 'Togli dai fissati' : 'Fissa',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'task',
                              child: Text('Trasforma in attività'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Elimina'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _TodayWellbeingCard extends StatelessWidget {
  final AgendaStore store;
  final DateTime date;

  const _TodayWellbeingCard({
    required this.store,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final journal = store.journal(date);
    final totalHabits = store.habits.length;
    final doneHabits = journal.completedHabitIds
        .where((id) => store.habits.any((habit) => habit.id == id))
        .length;
    final gratitudeCount = journal.gratitude.length.clamp(0, 3);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0F5), Color(0xFFF4F0FF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              shape: BoxShape.circle,
            ),
            child: Text(
              journal.mood?.emoji ?? '♡',
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journal.mood == null
                      ? 'Come sta andando la giornata?'
                      : 'Oggi: ${journal.mood!.label}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      totalHabits == 0
                          ? 'Nessuna abitudine'
                          : '$doneHabits/$totalHabits abitudini',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '$gratitudeCount/3 cose belle',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.favorite_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

enum _SearchHitType { event, journal, month }

class _SearchHit {
  final _SearchHitType type;
  final String title;
  final String subtitle;
  final DateTime date;
  final AgendaItem? item;

  const _SearchHit({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    this.item,
  });
}

class SearchScreen extends StatefulWidget {
  final AgendaStore store;

  const SearchScreen({super.key, required this.store});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';
  AgendaCategory? category;

  List<_SearchHit> _results() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final hits = <_SearchHit>[];

    for (final item in widget.store.items) {
      if (category != null && item.category != category) continue;
      final haystack = [
        item.title,
        item.note,
        item.category.label,
        DateFormat('d MMMM yyyy', 'it_IT').format(item.date),
      ].join(' ').toLowerCase();

      if (haystack.contains(q)) {
        hits.add(
          _SearchHit(
            type: _SearchHitType.event,
            title: item.title,
            subtitle:
                '${DateFormat('d MMMM yyyy', 'it_IT').format(item.date)} · ${item.category.label}',
            date: item.date,
            item: item,
          ),
        );
      }
    }

    if (category == null) {
      for (final entry in widget.store.journals.entries) {
        final date = DateTime.tryParse(entry.key);
        if (date == null) continue;
        final journal = entry.value;
        final haystack = [
          journal.beautiful,
          journal.note,
          ...journal.gratitude,
          journal.mood?.label ?? '',
        ].join(' ').toLowerCase();

        if (haystack.contains(q)) {
          hits.add(
            _SearchHit(
              type: _SearchHitType.journal,
              title: journal.beautiful.trim().isNotEmpty
                  ? journal.beautiful.trim()
                  : 'Diario del ${DateFormat('d MMMM', 'it_IT').format(date)}',
              subtitle:
                  'Diario · ${DateFormat('d MMMM yyyy', 'it_IT').format(date)}',
              date: date,
            ),
          );
        }
      }

      for (final entry in widget.store.months.entries) {
        final parts = entry.key.split('-');
        if (parts.length != 2) continue;
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year == null || month == null) continue;
        final data = entry.value;
        final haystack = [
          data.intention,
          data.monthWord,
          data.selfCare,
          ...data.goals,
          ...data.books,
          ...data.films,
          ...data.hobbies,
          ...data.wishes,
          ...data.ideas,
          data.bestMoment,
          data.lesson,
          data.challenge,
          data.nextMonth,
          data.reflection,
        ].join(' ').toLowerCase();

        if (haystack.contains(q)) {
          final date = DateTime(year, month);
          hits.add(
            _SearchHit(
              type: _SearchHitType.month,
              title:
                  _cap(DateFormat('MMMM yyyy', 'it_IT').format(date)),
              subtitle: data.intention.trim().isEmpty
                  ? 'Pagina del mese'
                  : data.intention.trim(),
              date: date,
            ),
          );
        }
      }
    }

    hits.sort((a, b) => b.date.compareTo(a.date));
    return hits;
  }

  @override
  Widget build(BuildContext context) {
    final results = _results();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cerca nell’agenda',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: InputDecoration(
                hintText: 'Cerca appuntamenti, note, ricordi...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    selected: category == null,
                    label: const Text('Tutto'),
                    onSelected: (_) => setState(() => category = null),
                  ),
                ),
                ...AgendaCategory.values.map(
                  (value) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      selected: category == value,
                      avatar: Icon(
                        value.icon,
                        size: 16,
                        color: value.color,
                      ),
                      label: Text(value.label),
                      onSelected: (_) => setState(() {
                        category = category == value ? null : value;
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: query.trim().isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Scrivi qualcosa: i risultati compariranno mentre digiti.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : results.isEmpty
                    ? const Center(child: Text('Nessun risultato.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
                        itemCount: results.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final hit = results[index];
                          final icon = switch (hit.type) {
                            _SearchHitType.event => Icons.event_outlined,
                            _SearchHitType.journal => Icons.menu_book_outlined,
                            _SearchHitType.month =>
                              Icons.calendar_month_outlined,
                          };

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(child: Icon(icon)),
                              title: Text(
                                hit.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                hit.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: () async {
                                if (hit.type == _SearchHitType.event) {
                                  await openItemEditor(
                                    context,
                                    widget.store,
                                    hit.date,
                                    existing: hit.item,
                                  );
                                } else if (hit.type ==
                                    _SearchHitType.journal) {
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlannerScreen(
                                        store: widget.store,
                                        initialDate: hit.date,
                                      ),
                                    ),
                                  );
                                } else {
                                  if (!context.mounted) return;
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MonthScreen(
                                        store: widget.store,
                                        initialMonth: hit.date,
                                      ),
                                    ),
                                  );
                                }
                                if (mounted) setState(() {});
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class ArchiveScreen extends StatelessWidget {
  final AgendaStore store;

  const ArchiveScreen({super.key, required this.store});

  List<DateTime> _months() {
    final keys = <String>{};

    for (final item in store.items) {
      keys.add(AgendaStore.monthKey(item.date.year, item.date.month));
    }
    for (final key in store.journals.keys) {
      if (key.length >= 7) keys.add(key.substring(0, 7));
    }
    keys.addAll(store.months.keys);

    final months = <DateTime>[];
    for (final key in keys) {
      final parts = key.split('-');
      if (parts.length != 2) continue;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year != null && month != null) {
        months.add(DateTime(year, month));
      }
    }
    months.sort((a, b) => b.compareTo(a));
    return months;
  }

  @override
  Widget build(BuildContext context) {
    final months = _months();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Archivio',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: months.isEmpty
          ? const Center(child: Text('L’archivio è ancora vuoto.'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
              itemCount: months.length,
              separatorBuilder: (_, __) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final month = months[index];
                final data = store.month(month.year, month.month);
                final events = store.items
                    .where(
                      (e) =>
                          e.date.year == month.year &&
                          e.date.month == month.month,
                    )
                    .length;
                final prefix =
                    '${month.year}-${month.month.toString().padLeft(2, '0')}-';
                final journalDays = store.journals.keys
                    .where((key) => key.startsWith(prefix))
                    .length;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      child: Icon(Icons.auto_stories_outlined),
                    ),
                    title: Text(
                      _cap(
                        DateFormat('MMMM yyyy', 'it_IT').format(month),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        '$events impegni',
                        '$journalDays giorni raccontati',
                        if (data.goals.isNotEmpty)
                          '${data.goals.length} obiettivi',
                      ].join(' · '),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MonthScreen(
                          store: store,
                          initialMonth: month,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class BackupScreen extends StatefulWidget {
  final AgendaStore store;

  const BackupScreen({super.key, required this.store});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool busy = false;

  String _timestampFileName(String extension) {
    final stamp = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
    return 'Agenda-per-Anna_backup_$stamp.$extension';
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> _exportBackup() async {
    setState(() => busy = true);
    try {
      final ok = await BackupFileService.instance.saveJsonBackup(
        json: widget.store.createBackupJson(),
        fileName: _timestampFileName('json'),
      );
      _message(
        ok
            ? 'Backup completo salvato.'
            : 'Salvataggio annullato o non riuscito.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _exportReadable() async {
    setState(() => busy = true);
    try {
      final ok = await BackupFileService.instance.saveTextExport(
        text: widget.store.createReadableExport(),
        fileName: _timestampFileName('txt'),
      );
      _message(
        ok
            ? 'Copia leggibile esportata.'
            : 'Esportazione annullata o non riuscita.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _importBackup() async {
    setState(() => busy = true);
    String? raw;
    try {
      raw = await BackupFileService.instance.pickJsonBackup();
    } finally {
      if (mounted) setState(() => busy = false);
    }

    if (raw == null || !mounted) return;

    BackupSummary summary;
    try {
      summary = widget.store.inspectBackup(raw);
    } catch (error) {
      _message(
        error is FormatException
            ? error.message.toString()
            : 'Il file selezionato non è un backup valido.',
      );
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ripristinare questo backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creato il ${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(summary.exportedAt)}',
            ),
            const SizedBox(height: 12),
            Text('• ${summary.itemCount} impegni e attività'),
            Text('• ${summary.journalCount} giorni di diario'),
            Text('• ${summary.monthCount} pagine mensili'),
            Text('• ${summary.weekCount} settimane'),
            Text('• ${summary.habitCount} abitudini'),
            const SizedBox(height: 14),
            const Text(
              'Prima del ripristino verrà creato automaticamente un backup locale di sicurezza.',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, 'merge'),
            child: const Text('Unisci'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, 'replace'),
            child: const Text('Sostituisci tutto'),
          ),
        ],
      ),
    );

    if (action == null || !mounted) return;

    if (action == 'replace') {
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Conferma sostituzione'),
              content: const Text(
                'I dati attuali verranno sostituiti da quelli del backup. '
                'Potrai tornare indietro usando il backup locale creato prima del ripristino.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Ripristina'),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }

    setState(() => busy = true);
    try {
      await widget.store.restoreBackup(
        raw,
        merge: action == 'merge',
      );
      _message(
        action == 'merge'
            ? 'Backup unito ai dati presenti.'
            : 'Backup ripristinato correttamente.',
      );
    } catch (_) {
      _message('Ripristino non riuscito. I dati attuali non sono stati eliminati.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _restoreSnapshot(LocalBackupSnapshot snapshot) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ripristinare questo backup locale?'),
            content: Text(
              '${snapshot.label}\n'
              '${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(snapshot.createdAt)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ripristina'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => busy = true);
    try {
      await widget.store.restoreLocalSnapshot(snapshot.id);
      _message('Backup locale ripristinato.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final snapshots = widget.store.localSnapshots;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Backup e dati',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 50),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFE7EF),
                          Color(0xFFF1ECFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, size: 30),
                        SizedBox(height: 10),
                        Text(
                          'I ricordi restano tuoi',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Crea una copia completa dell’agenda e conservala dove preferisci. '
                          'Il file JSON può ripristinare l’app; il TXT è pensato per essere letto.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BackupActionCard(
                    icon: Icons.save_alt_outlined,
                    title: 'Crea backup completo',
                    subtitle:
                        'Salva appuntamenti, diario, mesi, settimane, abitudini e budget in un file .json.',
                    buttonLabel: 'Salva backup',
                    onPressed: busy ? null : _exportBackup,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.restore_outlined,
                    title: 'Ripristina da file',
                    subtitle:
                        'Importa un backup precedente. Puoi unire i dati oppure sostituire tutto.',
                    buttonLabel: 'Scegli backup',
                    onPressed: busy ? null : _importBackup,
                  ),
                  const SizedBox(height: 10),
                  _BackupActionCard(
                    icon: Icons.description_outlined,
                    title: 'Esporta copia leggibile',
                    subtitle:
                        'Crea un file .txt con impegni, diario e pagine mensili da conservare o stampare.',
                    buttonLabel: 'Esporta TXT',
                    onPressed: busy ? null : _exportReadable,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Backup locali di sicurezza',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Crea backup locale',
                        onPressed: busy
                            ? null
                            : () => widget.store.createLocalSnapshot(),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  Text(
                    'L’app conserva fino a 5 copie locali e ne crea una automaticamente circa ogni 6 ore di utilizzo. '
                    'Queste copie restano sul dispositivo e vengono perse se l’app viene disinstallata: '
                    'per una copia davvero sicura usa anche “Crea backup completo”.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  if (snapshots.isEmpty)
                    const SimpleCard(
                      child: Text('Nessun backup locale disponibile.'),
                    )
                  else
                    ...snapshots.map(
                      (snapshot) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.history),
                          ),
                          title: Text(
                            snapshot.label,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'd MMMM yyyy, HH:mm',
                              'it_IT',
                            ).format(snapshot.createdAt),
                          ),
                          onTap: busy
                              ? null
                              : () => _restoreSnapshot(snapshot),
                          trailing: IconButton(
                            tooltip: 'Elimina backup',
                            onPressed: busy
                                ? null
                                : () => widget.store
                                    .deleteLocalSnapshot(snapshot.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              if (busy)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white54,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _BackupActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback? onPressed;

  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 10),
                FilledButton.tonal(
                  onPressed: onPressed,
                  child: Text(buttonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final AgendaStore store;

  const SettingsScreen({super.key, required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController nameController =
      TextEditingController(text: widget.store.preferences.displayName);

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final value = nameController.text.trim();
    await widget.store.savePreferences(
      widget.store.preferences.copyWith(
        displayName: value.isEmpty ? 'Anna' : value,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nome aggiornato.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _configurePin() async {
    final first = TextEditingController();
    final second = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Imposta PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: first,
              autofocus: true,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'PIN',
                hintText: 'Almeno 4 cifre',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: second,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Ripeti PIN',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final a = first.text.trim();
              final b = second.text.trim();
              if (a.length < 4 || a != b) return;
              Navigator.pop(dialogContext, a);
            },
            child: const Text('Salva PIN'),
          ),
        ],
      ),
    );
    first.dispose();
    second.dispose();
    if (value == null) return;

    try {
      await widget.store.setPin(value);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN impostato e blocco attivato.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN non valido.')),
      );
    }
  }

  Future<bool> _deviceSupportsBiometrics() async {
    if (kIsWeb) return false;
    try {
      final auth = LocalAuthentication();
      return await auth.isDeviceSupported() && await auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<void> _reset() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Ripristinare le impostazioni?'),
            content: const Text(
              'Verranno ripristinati tema, colore e valori predefiniti. '
              'Appuntamenti, diario e altri dati non verranno toccati.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Ripristina'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await widget.store.resetPreferences();
    nameController.text = widget.store.preferences.displayName;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final prefs = widget.store.preferences;
        final primary = prefs.defaultPrimaryReminder ?? -1;
        final secondary = prefs.defaultSecondaryReminder ?? -1;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Impostazioni',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 50),
            children: [
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'La mia agenda',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        prefixIcon: Icon(Icons.favorite_outline),
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: _saveName,
                        child: const Text('Salva nome'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aspetto',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AgendaThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: AgendaThemeMode.system,
                          label: Text('Sistema'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: AgendaThemeMode.light,
                          label: Text('Chiaro'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: AgendaThemeMode.dark,
                          label: Text('Scuro'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {prefs.themeMode},
                      onSelectionChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(themeMode: value.first),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Colore dell’agenda',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: AgendaPalette.values.map((palette) {
                        final selected = prefs.palette == palette;
                        return ChoiceChip(
                          selected: selected,
                          avatar: CircleAvatar(
                            radius: 8,
                            backgroundColor: palette.seed,
                          ),
                          label: Text(palette.label),
                          onSelected: (_) =>
                              widget.store.savePreferences(
                            prefs.copyWith(palette: palette),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avvio e Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<StartTab>(
                      initialValue: prefs.startTab,
                      decoration: const InputDecoration(
                        labelText: 'Apri l’app su',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      items: StartTab.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        widget.store.savePreferences(
                          prefs.copyWith(startTab: value),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Frase positiva del giorno'),
                      subtitle: const Text(
                        'Mostra la frase nella testata della Home.',
                      ),
                      value: prefs.showDailyQuote,
                      onChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(showDailyQuote: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nuovi impegni',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Questi valori vengono proposti automaticamente quando crei un nuovo elemento.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<AgendaCategory>(
                      initialValue: prefs.defaultCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoria predefinita',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      items: AgendaCategory.values
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    value.icon,
                                    color: value.color,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(value.label),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        widget.store.savePreferences(
                          prefs.copyWith(defaultCategory: value),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.timelapse_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Durata appuntamento: ${prefs.defaultEventMinutes} min',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      min: 15,
                      max: 180,
                      divisions: 11,
                      value: prefs.defaultEventMinutes
                          .clamp(15, 180)
                          .toDouble(),
                      label: '${prefs.defaultEventMinutes} min',
                      onChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(
                          defaultEventMinutes:
                              (value / 15).round() * 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      key: ValueKey('primary-$primary'),
                      initialValue: primary,
                      decoration: const InputDecoration(
                        labelText: 'Promemoria predefinito 1',
                        prefixIcon:
                            Icon(Icons.notifications_none_outlined),
                      ),
                      items: _reminderMenuItems,
                      onChanged: (value) {
                        final minutes = value ?? -1;
                        widget.store.savePreferences(
                          prefs.copyWith(
                            defaultPrimaryReminder:
                                minutes < 0 ? null : minutes,
                            clearPrimaryReminder: minutes < 0,
                            clearSecondaryReminder:
                                minutes >= 0 && minutes == secondary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      key: ValueKey('secondary-$secondary-$primary'),
                      initialValue: secondary,
                      decoration: const InputDecoration(
                        labelText: 'Promemoria predefinito 2',
                        prefixIcon: Icon(Icons.add_alert_outlined),
                      ),
                      items: _reminderMenuItems,
                      onChanged: (value) {
                        final minutes = value ?? -1;
                        widget.store.savePreferences(
                          prefs.copyWith(
                            defaultSecondaryReminder:
                                minutes < 0 || minutes == primary
                                    ? null
                                    : minutes,
                            clearSecondaryReminder:
                                minutes < 0 || minutes == primary,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Privacy',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Proteggi l’agenda quando il telefono passa ad altre app o resta inattivo.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    if (prefs.pinHash == null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: _configurePin,
                          icon: const Icon(Icons.pin_outlined),
                          label: const Text('Imposta PIN'),
                        ),
                      )
                    else ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Blocca Agenda'),
                        subtitle: const Text(
                          'Richiede PIN o biometria per riaprire l’app.',
                        ),
                        value: prefs.privacyLockEnabled,
                        onChanged: (value) =>
                            widget.store.savePreferences(
                          prefs.copyWith(privacyLockEnabled: value),
                        ),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.pin_outlined),
                        title: const Text('Cambia PIN'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _configurePin,
                      ),
                    ],
                    if (prefs.pinHash != null) ...[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Sblocco biometrico'),
                        subtitle: const Text(
                          kIsWeb
                              ? 'Non disponibile sul web.'
                              : 'Usa impronta o riconoscimento biometrico del dispositivo.',
                        ),
                        value: prefs.biometricUnlock,
                        onChanged: prefs.privacyLockEnabled
                            ? (value) async {
                                if (value &&
                                    !await _deviceSupportsBiometrics()) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Biometria non disponibile su questo dispositivo.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                await widget.store.savePreferences(
                                  prefs.copyWith(
                                    biometricUnlock: value,
                                  ),
                                );
                              }
                            : null,
                      ),
                      DropdownButtonFormField<int>(
                        initialValue: prefs.autoLockMinutes,
                        decoration: const InputDecoration(
                          labelText: 'Blocco automatico',
                          prefixIcon: Icon(Icons.timer_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('Subito'),
                          ),
                          DropdownMenuItem(
                            value: 1,
                            child: Text('Dopo 1 minuto'),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Text('Dopo 2 minuti'),
                          ),
                          DropdownMenuItem(
                            value: 5,
                            child: Text('Dopo 5 minuti'),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child: Text('Dopo 15 minuti'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          widget.store.savePreferences(
                            prefs.copyWith(autoLockMinutes: value),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Nascondi dettagli in Home'),
                      subtitle: const Text(
                        'Mostra indicatori generici invece del titolo del prossimo impegno.',
                      ),
                      value: prefs.hideHomeDetails,
                      onChanged: (value) =>
                          widget.store.savePreferences(
                        prefs.copyWith(hideHomeDetails: value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dati',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cloud_outlined),
                      title: const Text('Account e sincronizzazione'),
                      subtitle: const Text(
                        'Sincronizza l’agenda personale fra i tuoi dispositivi.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CloudAccountScreen(store: widget.store),
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.backup_outlined),
                      title: const Text('Backup e ripristino'),
                      subtitle: const Text(
                        'Esporta, importa o recupera una copia locale.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BackupScreen(store: widget.store),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Ripristina impostazioni predefinite'),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Agenda per Anna · v0.13',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SharedSpaceHubScreen extends StatefulWidget {
  final AgendaStore store;

  const SharedSpaceHubScreen({super.key, required this.store});

  @override
  State<SharedSpaceHubScreen> createState() => _SharedSpaceHubScreenState();
}

class _SharedSpaceHubScreenState extends State<SharedSpaceHubScreen> {
  bool loading = true;
  List<SharedSpace> spaces = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final cloud = CloudSyncService.instance;
    if (!cloud.signedIn) {
      if (mounted) setState(() => loading = false);
      return;
    }
    try {
      final result = await cloud.listSharedSpaces();
      if (mounted) {
        setState(() {
          spaces = result;
          loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _createSpace() async {
    final controller = TextEditingController(text: 'Noi ♡');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Crea uno spazio condiviso'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome dello spazio',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Crea'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;

    setState(() => loading = true);
    try {
      await CloudSyncService.instance.createSharedSpace(name: name);
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      _message('Impossibile creare lo spazio: $error');
    }
  }

  Future<void> _joinSpace() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Collegati con un codice'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          maxLength: 8,
          decoration: const InputDecoration(
            labelText: 'Codice invito',
            hintText: 'Es. A1B2C3D4',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.text.trim().toUpperCase(),
            ),
            child: const Text('Collegati'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty) return;

    setState(() => loading = true);
    try {
      await CloudSyncService.instance.joinSharedSpace(code);
      await _reload();
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _message('Codice non valido, già usato o scaduto.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloud = CloudSyncService.instance;
    return AnimatedBuilder(
      animation: cloud,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Noi ♡',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            actions: [
              if (cloud.signedIn)
                IconButton(
                  tooltip: 'Aggiorna',
                  onPressed: loading ? null : _reload,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          body: !cloud.signedIn
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.favorite_outline, size: 60),
                          const SizedBox(height: 16),
                          const Text(
                            'Uno spazio solo per voi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Accedi al cloud per creare o raggiungere uno spazio condiviso. '
                            'La tua agenda personale resterà separata.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CloudAccountScreen(
                                  store: widget.store,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.cloud_outlined),
                            label: const Text('Account e sincronizzazione'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFFFE4EC),
                                Color(0xFFF0E8FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.favorite_outline, size: 30),
                              SizedBox(height: 10),
                              Text(
                                'Spazio condiviso',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Qui compaiono solo gli elementi che scegliete di condividere. '
                                'Diario, mood, note private e agenda personale restano privati.',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (spaces.isEmpty)
                          SimpleCard(
                            child: Column(
                              children: [
                                const Text(
                                  'Non sei ancora collegato a nessuno spazio.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _createSpace,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Crea il nostro spazio'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _joinSpace,
                                    icon: const Icon(Icons.link),
                                    label: const Text('Inserisci un codice'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          ...spaces.map(
                            (space) => Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(
                                    space.isOwner
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                  ),
                                ),
                                title: Text(
                                  space.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  space.isOwner
                                      ? 'Creato da te'
                                      : 'Spazio condiviso',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SharedSpaceScreen(
                                      store: widget.store,
                                      space: space,
                                    ),
                                  ),
                                ).then((_) => _reload()),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          OutlinedButton.icon(
                            onPressed: _joinSpace,
                            icon: const Icon(Icons.link),
                            label: const Text('Collegati a un altro spazio'),
                          ),
                        ],
                      ],
                    ),
        );
      },
    );
  }
}

class SharedSpaceScreen extends StatefulWidget {
  final AgendaStore store;
  final SharedSpace space;

  const SharedSpaceScreen({
    super.key,
    required this.store,
    required this.space,
  });

  @override
  State<SharedSpaceScreen> createState() => _SharedSpaceScreenState();
}

class _SharedSpaceScreenState extends State<SharedSpaceScreen> {
  bool loading = true;
  List<SharedEntry> entries = [];
  DateTime selected = DateTime.now();

  String get _cacheKey => 'shared_cache_${widget.space.id}';
  String get _pendingKey => 'shared_pending_${widget.space.id}';

  @override
  void initState() {
    super.initState();
    _loadCachedThenRefresh();
  }

  Future<void> _loadCachedThenRefresh() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      try {
        entries = (jsonDecode(raw) as List)
            .map(
              (e) => SharedEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      } catch (_) {}
    }
    if (mounted) setState(() => loading = false);
    await _refresh();
  }

  Future<void> _saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<Map<String, dynamic>>> _loadPending() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _savePending(
    List<Map<String, dynamic>> pending,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingKey, jsonEncode(pending));
  }

  Future<void> _enqueueSharedUpsert(SharedEntry entry) async {
    final pending = await _loadPending();
    pending.removeWhere((e) => e['entityId'] == entry.id);
    pending.add({
      'action': 'upsert',
      'entityId': entry.id,
      'payload': entry.toJson(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _savePending(pending);
  }

  Future<void> _enqueueSharedDelete(String id) async {
    final pending = await _loadPending();
    pending.removeWhere((e) => e['entityId'] == id);
    pending.add({
      'action': 'delete',
      'entityId': id,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _savePending(pending);
  }

  Future<void> _flushPending() async {
    if (!CloudSyncService.instance.signedIn) return;
    final pending = await _loadPending();
    if (pending.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];
    for (final op in pending) {
      try {
        if (op['action'] == 'delete') {
          await CloudSyncService.instance.deleteSharedRecord(
            spaceId: widget.space.id,
            entityType: 'shared_entry',
            entityId: op['entityId'] as String,
          );
        } else {
          await CloudSyncService.instance.upsertSharedRecord(
            spaceId: widget.space.id,
            entityType: 'shared_entry',
            entityId: op['entityId'] as String,
            payload: Map<String, dynamic>.from(op['payload'] as Map),
            updatedAt: DateTime.tryParse(op['updatedAt'] as String? ?? ''),
          );
        }
      } catch (_) {
        remaining.add(op);
      }
    }
    await _savePending(remaining);
  }

  Future<void> _refresh() async {
    if (!CloudSyncService.instance.signedIn) return;
    if (mounted) setState(() => loading = true);
    try {
      await _flushPending();
      final records =
          await CloudSyncService.instance.pullSharedRecords(widget.space.id);
      final next = <SharedEntry>[];
      for (final record in records) {
        if (record.deletedAt != null ||
            record.entityType != 'shared_entry' ||
            record.payload == null) {
          continue;
        }
        next.add(
          SharedEntry.fromJson(
            record.payload!,
            updatedBy: record.updatedBy,
          ),
        );
      }
      final pending = await _loadPending();
      for (final op in pending) {
        final id = op['entityId'] as String;
        next.removeWhere((e) => e.id == id);
        if (op['action'] == 'upsert' && op['payload'] is Map) {
          next.add(
            SharedEntry.fromJson(
              Map<String, dynamic>.from(op['payload'] as Map),
            ),
          );
        }
      }

      next.sort((a, b) {
        final date = a.date.compareTo(b.date);
        if (date != 0) return date;
        final am = a.start == null ? 0 : a.start!.hour * 60 + a.start!.minute;
        final bm = b.start == null ? 0 : b.start!.hour * 60 + b.start!.minute;
        return am.compareTo(bm);
      });
      entries = next;
      await _saveCache();
    } catch (_) {
      _message('Impossibile aggiornare ora. Mostro l’ultima copia disponibile.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<SharedEntry> get _selectedEntries => entries
      .where((e) => AgendaStore.sameDay(e.date, selected))
      .toList();

  Future<void> _edit([SharedEntry? existing]) async {
    if (!CloudSyncService.instance.signedIn) {
      _message('Serve una connessione all’account cloud per modificare lo spazio.');
      return;
    }

    final result = await _openSharedEntryEditor(
      context,
      initialDate: selected,
      existing: existing,
    );
    if (result == null) return;

    final index = entries.indexWhere((e) => e.id == result.id);
    setState(() {
      if (index < 0) {
        entries.add(result);
      } else {
        entries[index] = result;
      }
    });
    await _saveCache();

    await _enqueueSharedUpsert(result);
    await _refresh();
    final pending = await _loadPending();
    if (pending.any((e) => e['entityId'] == result.id)) {
      _message('Modifica salvata: verrà sincronizzata appena possibile.');
    }
  }

  Future<void> _toggleDone(SharedEntry entry) async {
    final updated = entry.copyWith(done: !entry.done);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      setState(() => entries[index] = updated);
      await _saveCache();
    }
    await _enqueueSharedUpsert(updated);
    await _flushPending();
  }

  Future<void> _delete(SharedEntry entry) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare dallo spazio condiviso?'),
            content: Text(entry.title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    setState(() => entries.removeWhere((e) => e.id == entry.id));
    await _saveCache();
    await _enqueueSharedDelete(entry.id);
    await _flushPending();
  }

  Future<void> _invite() async {
    try {
      final code =
          await CloudSyncService.instance.createSpaceInvite(widget.space.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Codice per collegarsi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Condividi questo codice con la persona che vuoi invitare. '
                'È valido per 24 ore e può essere usato una sola volta.',
              ),
              const SizedBox(height: 18),
              SelectableText(
                code,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      );
    } catch (_) {
      _message('Non è stato possibile creare il codice invito.');
    }
  }

  Future<void> _leaveOrDelete() async {
    final owner = widget.space.isOwner;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(owner ? 'Eliminare lo spazio?' : 'Lasciare lo spazio?'),
            content: Text(
              owner
                  ? 'Lo spazio e tutti i contenuti condivisi verranno eliminati per tutti.'
                  : 'Non vedrai più questo spazio, ma i tuoi dati personali non verranno toccati.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(owner ? 'Elimina' : 'Lascia'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    try {
      if (owner) {
        await CloudSyncService.instance.deleteSharedSpace(widget.space.id);
      } else {
        await CloudSyncService.instance.leaveSharedSpace(widget.space.id);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_pendingKey);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _message('Operazione non riuscita.');
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayEntries = _selectedEntries;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.space.name,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (widget.space.isOwner)
            IconButton(
              tooltip: 'Invita',
              onPressed: _invite,
              icon: const Icon(Icons.person_add_alt_1_outlined),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'refresh') _refresh();
              if (value == 'leave') _leaveOrDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Text('Aggiorna'),
              ),
              PopupMenuItem(
                value: 'leave',
                child: Text(
                  widget.space.isOwner
                      ? 'Elimina spazio'
                      : 'Lascia spazio',
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Condividi'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Questo spazio è condiviso. Tutto il resto dell’agenda rimane personale.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TableCalendar<SharedEntry>(
              locale: 'it_IT',
              firstDay: DateTime(2020),
              lastDay: DateTime(2040),
              focusedDay: selected,
              selectedDayPredicate: (day) =>
                  AgendaStore.sameDay(day, selected),
              eventLoader: (day) => entries
                  .where((e) => AgendaStore.sameDay(e.date, day))
                  .toList(),
              onDaySelected: (day, _) => setState(() => selected = day),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 16),
            SectionTitle(
              _cap(DateFormat('EEEE d MMMM', 'it_IT').format(selected)),
            ),
            const SizedBox(height: 10),
            if (loading && entries.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (dayEntries.isEmpty)
              const SimpleCard(
                child: Text('Niente di condiviso per questo giorno.'),
              )
            else
              ...dayEntries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    leading: entry.type == SharedEntryType.task
                        ? Checkbox(
                            value: entry.done,
                            onChanged: (_) => _toggleDone(entry),
                          )
                        : CircleAvatar(
                            child: Icon(entry.type.icon),
                          ),
                    title: Text(
                      entry.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        decoration: entry.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (entry.start != null) formatTime(entry.start!),
                        if (entry.note.isNotEmpty) entry.note,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _edit(entry),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') _edit(entry);
                        if (value == 'delete') _delete(entry);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('Modifica'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Elimina'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Future<SharedEntry?> _openSharedEntryEditor(
  BuildContext context, {
  required DateTime initialDate,
  SharedEntry? existing,
}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  var type = existing?.type ?? SharedEntryType.appointment;
  var date = existing?.date ?? initialDate;
  var start = existing?.start;
  var end = existing?.end;

  final result = await showDialog<SharedEntry>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: Text(
          existing == null ? 'Condividi qualcosa' : 'Modifica elemento',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<SharedEntryType>(
                segments: SharedEntryType.values
                    .map(
                      (value) => ButtonSegment(
                        value: value,
                        icon: Icon(value.icon),
                        label: Text(value.label),
                      ),
                    )
                    .toList(),
                selected: {type},
                onSelectionChanged: (value) =>
                    setLocal(() => type = value.first),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: title,
                autofocus: existing == null,
                decoration: const InputDecoration(labelText: 'Titolo'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Nota'),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text(
                  DateFormat('d MMMM yyyy', 'it_IT').format(date),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2040),
                  );
                  if (picked != null) setLocal(() => date = picked);
                },
              ),
              if (type != SharedEntryType.note)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(
                    start == null ? 'Senza orario' : formatTime(start!),
                  ),
                  trailing: start == null
                      ? null
                      : IconButton(
                          onPressed: () => setLocal(() {
                            start = null;
                            end = null;
                          }),
                          icon: const Icon(Icons.close),
                        ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: start ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setLocal(() {
                        start = picked;
                        end ??= _timePlusMinutes(picked, 60);
                      });
                    }
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              final value = title.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(
                dialogContext,
                SharedEntry(
                  id: existing?.id ?? const Uuid().v4(),
                  type: type,
                  title: value,
                  note: note.text.trim(),
                  date: date,
                  start: type == SharedEntryType.note ? null : start,
                  end: type == SharedEntryType.note ? null : end,
                  done: existing?.done ?? false,
                ),
              );
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    ),
  );

  title.dispose();
  note.dispose();
  return result;
}

class CloudAccountScreen extends StatefulWidget {
  final AgendaStore store;

  const CloudAccountScreen({
    super.key,
    required this.store,
  });

  @override
  State<CloudAccountScreen> createState() => _CloudAccountScreenState();
}

class _CloudAccountScreenState extends State<CloudAccountScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;
  bool createMode = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  String _stateLabel(CloudConnectionState state) => switch (state) {
        CloudConnectionState.disabled => 'Cloud non configurato',
        CloudConnectionState.initializing => 'Connessione...',
        CloudConnectionState.signedOut => 'Non connesso',
        CloudConnectionState.syncing => 'Sincronizzazione...',
        CloudConnectionState.synced => 'Sincronizzato',
        CloudConnectionState.error => 'Errore di sincronizzazione',
      };

  IconData _stateIcon(CloudConnectionState state) => switch (state) {
        CloudConnectionState.disabled => Icons.cloud_off_outlined,
        CloudConnectionState.initializing => Icons.hourglass_top,
        CloudConnectionState.signedOut => Icons.cloud_outlined,
        CloudConnectionState.syncing => Icons.sync,
        CloudConnectionState.synced => Icons.cloud_done_outlined,
        CloudConnectionState.error => Icons.cloud_off,
      };

  Future<void> _submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (email.isEmpty || password.length < 6) {
      _message('Inserisci email e una password di almeno 6 caratteri.');
      return;
    }

    setState(() => busy = true);
    try {
      final cloud = CloudSyncService.instance;
      if (createMode) {
        await cloud.signUp(email: email, password: password);
        if (!cloud.signedIn) {
          _message(
            'Account creato. Controlla la tua email per confermare l’accesso.',
          );
          return;
        }
      } else {
        await cloud.signIn(email: email, password: password);
      }

      await widget.store.activateCloudAccount(cloud.userId);
      await widget.store.syncCloud(preferRemoteOnFirstSync: true);
      await widget.store.flushSharedPendingOperations();
      _message('Account connesso e sincronizzazione avviata.');
    } catch (_) {
      _message(
        CloudSyncService.instance.lastError ??
            'Accesso non riuscito. Controlla i dati inseriti.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => busy = true);
    try {
      await widget.store.syncCloud();
      final cloud = CloudSyncService.instance;
      if (cloud.state == CloudConnectionState.error) {
        _message(cloud.lastError ?? 'Sincronizzazione non riuscita.');
      } else {
        _message('Agenda sincronizzata.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => busy = true);
    try {
      await CloudSyncService.instance.signOut();
      await widget.store.activateCloudAccount(null);
      _message(
        'Account disconnesso. I dati dell’account restano salvati sul dispositivo ma non sono più mostrati.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cloud = CloudSyncService.instance;

    return AnimatedBuilder(
      animation: cloud,
      builder: (context, _) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Account e sincronizzazione',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 50),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.75),
                        Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.75),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _stateIcon(cloud.state),
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _stateLabel(cloud.state),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cloud.signedIn
                            ? 'La tua agenda personale può restare allineata su Android, iPhone e Web.'
                            : 'Accedi con lo stesso account sui tuoi dispositivi per ritrovare la stessa agenda personale.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (!cloud.configured)
                  SimpleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cloud pronto, ma non ancora collegato',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Questa build non contiene ancora le credenziali del progetto Supabase. '
                          'L’app continua a funzionare completamente offline e nessun dato viene perso.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'La struttura di sincronizzazione e il database sono già predisposti anche per il futuro Spazio condiviso.',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  )
                else if (!cloud.signedIn)
                  SimpleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          createMode ? 'Crea account' : 'Accedi',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          autofillHints: createMode
                              ? const [AutofillHints.newPassword]
                              : const [AutofillHints.password],
                          onSubmitted: (_) => busy ? null : _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ? null : _submit,
                            icon: Icon(
                              createMode
                                  ? Icons.person_add_outlined
                                  : Icons.login,
                            ),
                            label: Text(
                              createMode ? 'Crea account' : 'Accedi',
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: TextButton(
                            onPressed: busy
                                ? null
                                : () => setState(
                                      () => createMode = !createMode,
                                    ),
                            child: Text(
                              createMode
                                  ? 'Ho già un account'
                                  : 'Crea un nuovo account',
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  SimpleCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Il mio account',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.person_outline),
                          ),
                          title: Text(cloud.email ?? 'Account'),
                          subtitle: Text(
                            cloud.lastSyncAt == null
                                ? 'Nessuna sincronizzazione completata'
                                : 'Ultimo sync: ${DateFormat('d MMM, HH:mm', 'it_IT').format(cloud.lastSyncAt!)}',
                          ),
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.sync_outlined),
                          title: const Text('Modifiche in attesa'),
                          trailing: Text(
                            '${widget.store.pendingCloudChanges}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: busy ||
                                    cloud.state ==
                                        CloudConnectionState.syncing
                                ? null
                                : _syncNow,
                            icon: const Icon(Icons.sync),
                            label: const Text('Sincronizza ora'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _signOut,
                            icon: const Icon(Icons.logout),
                            label: const Text('Disconnetti account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SimpleCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Come funziona',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• L’app continua a salvare prima di tutto sul dispositivo.\n'
                        '• Le modifiche vengono messe in coda anche senza Internet.\n'
                        '• Quando il cloud torna disponibile, vengono sincronizzati solo gli elementi cambiati.\n'
                        '• Diario, appuntamenti, task, mesi, settimane, abitudini, Inbox e preferenze personali restano separati dagli spazi condivisi futuri.',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.people_outline),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'v0.16: lo Spazio condiviso userà la stessa infrastruttura, ma i contenuti condivisi resteranno separati dalla tua agenda privata.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  final AgendaStore store;
  const CalendarScreen({super.key, required this.store});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selected = DateTime.now();
  DateTime focused = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final events = widget.store.forDay(selected);
        return Scaffold(
          appBar: AppBar(title: const Text('Calendario', style: TextStyle(fontWeight: FontWeight.w800))),
          floatingActionButton: FloatingActionButton(
            onPressed: () => openItemEditor(context, widget.store, selected),
            child: const Icon(Icons.add),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: TableCalendar<AgendaItem>(
                    locale: 'it_IT',
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2040),
                    focusedDay: focused,
                    selectedDayPredicate: (d) => isSameDay(d, selected),
                    eventLoader: widget.store.forDay,
                    onDaySelected: (s, f) => setState(() {
                      selected = s;
                      focused = f;
                    }),
                    onPageChanged: (f) => focused = f,
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SectionTitle(_cap(DateFormat('EEEE d MMMM', 'it_IT').format(selected))),
              const SizedBox(height: 10),
              if (events.isEmpty)
                const SimpleCard(child: Text('Nessun impegno.'))
              else
                ...events.map((e) => EventTile(store: widget.store, item: e)),
            ],
          ),
        );
      },
    );
  }
}

class PlannerScreen extends StatefulWidget {
  final AgendaStore store;
  final DateTime? initialDate;

  const PlannerScreen({
    super.key,
    required this.store,
    this.initialDate,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime day;

  @override
  void initState() {
    super.initState();
    day = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final events = widget.store.forDay(day);
        final tasks = events.where((e) => e.type == ItemType.task).toList();
        final allDay = events
            .where((e) => e.type == ItemType.appointment && e.start == null)
            .toList();
        final timed = events
            .where((e) => e.type == ItemType.appointment && e.start != null)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('La mia giornata',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                Text(
                  _cap(DateFormat('EEEE d MMMM', 'it_IT').format(day)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              if (!AgendaStore.sameDay(day, DateTime.now()))
                TextButton(
                  onPressed: () => setState(() => day = DateTime.now()),
                  child: const Text('Oggi'),
                ),
              IconButton(
                onPressed: () => openItemEditor(context, widget.store, day),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          body: Column(
            children: [
              DateStrip(
                selected: day,
                onSelected: (d) => setState(() => day = d),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                  children: [
                    _DayOpeningCard(date: day),
                    if (tasks.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _DaySmallSection(
                        title: 'Da fare',
                        icon: Icons.check_circle_outline,
                        child: Column(
                          children: tasks
                              .map((e) => EventTile(
                                    store: widget.store,
                                    item: e,
                                    compact: true,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    if (allDay.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _DaySmallSection(
                        title: 'Tutto il giorno',
                        icon: Icons.event_outlined,
                        child: Column(
                          children: allDay
                              .map((e) => EventTile(
                                    store: widget.store,
                                    item: e,
                                    compact: true,
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    const SectionTitle('La mia giornata'),
                    const SizedBox(height: 8),
                    _TimelineHint(eventCount: timed.length),
                    const SizedBox(height: 10),
                    DayTimeline(
                      date: day,
                      events: timed,
                      store: widget.store,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 22),
                    JournalEditor(store: widget.store, date: day),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayOpeningCard extends StatelessWidget {
  final DateTime date;
  const _DayOpeningCard({required this.date});

  @override
  Widget build(BuildContext context) {
    final quote = _dailyQuote(date);
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEAF0), Color(0xFFF5F0FF)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  quote.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(quote.$2, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySmallSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _DaySmallSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TimelineHint extends StatelessWidget {
  final int eventCount;

  const _TimelineHint({required this.eventCount});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 17, color: scheme.primary),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              eventCount == 0
                  ? 'Tocca un orario libero per aggiungere il primo impegno.'
                  : 'Tocca uno spazio libero per aggiungere · tocca un impegno per modificarlo.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (eventCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$eventCount',
                style: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimelinePlacement {
  final AgendaItem item;
  final int lane;
  final int laneCount;

  const _TimelinePlacement({
    required this.item,
    required this.lane,
    required this.laneCount,
  });
}

class DayTimeline extends StatelessWidget {
  final DateTime date;
  final List<AgendaItem> events;
  final AgendaStore store;
  final VoidCallback onChanged;

  const DayTimeline({
    super.key,
    required this.date,
    required this.events,
    required this.store,
    required this.onChanged,
  });

  static const int startHour = 6;
  static const int endHour = 24;
  static const double hourHeight = 74;
  static const double timeColumnWidth = 54;

  @override
  Widget build(BuildContext context) {
    final totalHeight = (endHour - startHour) * hourHeight;
    final placements = _placements(events);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: totalHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) =>
                      _createAtPosition(context, details.localPosition.dy),
                  child: CustomPaint(
                    painter: _TimelinePainter(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      textColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              ...placements.map(
                (placement) => _eventBlock(
                  context,
                  placement,
                  constraints.maxWidth,
                ),
              ),
              if (AgendaStore.sameDay(date, DateTime.now()))
                _currentTimeIndicator(context),
            ],
          ),
        );
      },
    );
  }

  List<_TimelinePlacement> _placements(List<AgendaItem> source) {
    final sorted = [...source]
      ..sort((a, b) => _startMinutes(a).compareTo(_startMinutes(b)));

    final result = <_TimelinePlacement>[];
    var index = 0;

    while (index < sorted.length) {
      final group = <AgendaItem>[];
      var groupEnd = _endMinutes(sorted[index]);
      group.add(sorted[index]);
      index++;

      while (index < sorted.length &&
          _startMinutes(sorted[index]) < groupEnd) {
        final item = sorted[index];
        group.add(item);
        groupEnd = groupEnd < _endMinutes(item)
            ? _endMinutes(item)
            : groupEnd;
        index++;
      }

      final laneEnds = <int>[];
      final laneForItem = <AgendaItem, int>{};

      for (final item in group) {
        final start = _startMinutes(item);
        var lane = laneEnds.indexWhere((end) => end <= start);
        if (lane == -1) {
          lane = laneEnds.length;
          laneEnds.add(_endMinutes(item));
        } else {
          laneEnds[lane] = _endMinutes(item);
        }
        laneForItem[item] = lane;
      }

      final count = laneEnds.length.clamp(1, 99);
      for (final item in group) {
        result.add(
          _TimelinePlacement(
            item: item,
            lane: laneForItem[item] ?? 0,
            laneCount: count,
          ),
        );
      }
    }

    return result;
  }

  int _startMinutes(AgendaItem item) {
    final start = item.start!;
    return start.hour * 60 + start.minute;
  }

  int _endMinutes(AgendaItem item) {
    final start = _startMinutes(item);
    final end = item.end;
    if (end == null) return start + 60;
    final result = end.hour * 60 + end.minute;
    return result <= start ? start + 15 : result;
  }

  Widget _eventBlock(
    BuildContext context,
    _TimelinePlacement placement,
    double maxWidth,
  ) {
    final event = placement.item;
    final start = event.start!;
    final startMinutes = _startMinutes(event);
    final lower = startHour * 60;
    final upper = endHour * 60;

    if (startMinutes < lower || startMinutes >= upper) {
      return const SizedBox.shrink();
    }

    final endMinutes =
        _endMinutes(event).clamp(startMinutes + 15, upper);
    final top = ((startMinutes - lower) / 60) * hourHeight;
    final remainingHeight = max(1.0, totalHeightFromTop(top));
    final naturalHeight =
        ((endMinutes - startMinutes) / 60) * hourHeight;
    final minimumVisibleHeight = min(36.0, remainingHeight);
    final height = naturalHeight.clamp(
      minimumVisibleHeight,
      remainingHeight,
    );

    const gap = 5.0;
    final contentWidth = maxWidth - timeColumnWidth - 16;
    final laneWidth =
        (contentWidth - gap * (placement.laneCount - 1)) /
            placement.laneCount;
    final left = timeColumnWidth +
        8 +
        placement.lane * (laneWidth + gap);

    final base = event.category.color;
    final background = Color.alphaBlend(
      base.withValues(alpha: 0.16),
      Theme.of(context).colorScheme.surface,
    );

    return Positioned(
      top: top + 2,
      left: left,
      width: laneWidth,
      height: max(1.0, height - 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await openItemEditor(
              context,
              store,
              date,
              existing: event,
            );
            onChanged();
          },
          onLongPress: () async {
            await _showAgendaItemActions(context, store, event);
            onChanged();
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: placement.laneCount > 2 ? 6 : 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: base.withValues(alpha: 0.55)),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  offset: Offset(0, 2),
                  color: Color(0x12000000),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (placement.laneCount <= 2)
                        Row(
                          children: [
                            Icon(event.category.icon, size: 13, color: base),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.category.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: base,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      Text(
                        event.title,
                        maxLines: height < 58 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: placement.laneCount > 2 ? 11 : 13,
                        ),
                      ),
                      if (height >= 52)
                        Text(
                          event.end == null
                              ? formatTime(start)
                              : '${formatTime(start)} – ${formatTime(event.end!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: placement.laneCount > 2 ? 9 : 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (height >= 82 &&
                          placement.laneCount <= 2 &&
                          event.note.trim().isNotEmpty)
                        Text(
                          event.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _currentTimeIndicator(BuildContext context) {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final lower = startHour * 60;
    final upper = endHour * 60;

    if (minutes < lower || minutes >= upper) {
      return const SizedBox.shrink();
    }

    final top = ((minutes - lower) / 60) * hourHeight;
    return Positioned(
      top: top,
      left: timeColumnWidth - 3,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                color: Color(0xFFE14F7A),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                color: const Color(0xFFE14F7A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAtPosition(
    BuildContext context,
    double y,
  ) async {
    var minutes =
        startHour * 60 + ((y / hourHeight) * 60).round();
    minutes = ((minutes / 15).round() * 15).clamp(
      startHour * 60,
      endHour * 60 - 15,
    );

    await openItemEditor(
      context,
      store,
      date,
      initialTime: TimeOfDay(
        hour: minutes ~/ 60,
        minute: minutes % 60,
      ),
    );
    onChanged();
  }

  double totalHeightFromTop(double top) {
    final total = (endHour - startHour) * hourHeight;
    return total - top;
  }
}

class _TimelinePainter extends CustomPainter {
  final Color color;
  final Color textColor;

  _TimelinePainter({required this.color, required this.textColor});

  @override
  void paint(Canvas canvas, Size size) {
    final fullPaint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final halfPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    for (int hour = DayTimeline.startHour; hour <= DayTimeline.endHour; hour++) {
      final y = (hour - DayTimeline.startHour) * DayTimeline.hourHeight;
      canvas.drawLine(
        Offset(DayTimeline.timeColumnWidth, y),
        Offset(size.width, y),
        fullPaint,
      );

      if (hour < DayTimeline.endHour) {
        final half = y + DayTimeline.hourHeight / 2;
        canvas.drawLine(
          Offset(DayTimeline.timeColumnWidth, half),
          Offset(size.width, half),
          halfPaint,
        );
      }

      if (hour < DayTimeline.endHour) {
        final painter = TextPainter(
          text: TextSpan(
            text: '${hour.toString().padLeft(2, '0')}:00',
            style: TextStyle(
              color: textColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout(maxWidth: DayTimeline.timeColumnWidth - 8);

        painter.paint(
          canvas,
          Offset(
            DayTimeline.timeColumnWidth - painter.width - 8,
            y + 6,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.textColor != textColor;
  }
}

class WeekScreen extends StatefulWidget {
  final AgendaStore store;
  const WeekScreen({super.key, required this.store});

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late DateTime start = mondayOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final data = widget.store.week(start);
        final end = addCivilDays(start, 6);
        final events = <AgendaItem>[
          for (int i = 0; i < 7; i++) ...widget.store.forDay(addCivilDays(start, i)),
        ];
        final completedTasks = events.where((e) => e.type == ItemType.task && e.done).length;
        final totalTasks = events.where((e) => e.type == ItemType.task).length;
        final beautifulThings = <String>[
          for (int i = 0; i < 7; i++)
            if (widget.store.journal(addCivilDays(start, i)).beautiful.trim().isNotEmpty)
              widget.store.journal(addCivilDays(start, i)).beautiful.trim(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('La mia settimana', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Settimana precedente',
                onPressed: () => setState(() => start = addCivilDays(start, -7)),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Questa settimana',
                onPressed: () => setState(() => start = mondayOf(DateTime.now())),
                icon: const Icon(Icons.today_outlined),
              ),
              IconButton(
                tooltip: 'Settimana successiva',
                onPressed: () => setState(() => start = addCivilDays(start, 7)),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
            children: [
              _WeekHero(
                start: start,
                end: end,
                eventCount: events.length,
                completedTasks: completedTasks,
                totalTasks: totalTasks,
              ),
              const SizedBox(height: 14),
              WeekFocusCard(
                key: ValueKey('week-focus-${AgendaStore.dateKey(start)}'),
                data: data,
                onSave: (value) => widget.store.saveWeek(start, value),
              ),
              const SizedBox(height: 14),
              WeekPrioritiesCard(
                key: ValueKey('week-priorities-${AgendaStore.dateKey(start)}'),
                data: data,
                onSave: (value) => widget.store.saveWeek(start, value),
              ),
              const SizedBox(height: 18),
              const SectionTitle('I 7 giorni'),
              const SizedBox(height: 10),
              for (int i = 0; i < 7; i++) ...[
                _WeekDayCard(
                  day: addCivilDays(start, i),
                  store: widget.store,
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              WeekMemoryCard(
                key: ValueKey('week-memory-${AgendaStore.dateKey(start)}'),
                data: data,
                autoMemories: beautifulThings,
                onSave: (value) => widget.store.saveWeek(start, value),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeekHero extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final int eventCount;
  final int completedTasks;
  final int totalTasks;

  const _WeekHero({
    required this.start,
    required this.end,
    required this.eventCount,
    required this.completedTasks,
    required this.totalTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE5ED), Color(0xFFEDE8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('d MMM', 'it_IT').format(start)} – ${DateFormat('d MMM yyyy', 'it_IT').format(end)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Una settimana alla volta',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(icon: Icons.event_outlined, text: '$eventCount impegni'),
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: totalTasks == 0 ? 'Nessun task' : '$completedTasks / $totalTasks task',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class WeekFocusCard extends StatefulWidget {
  final WeekData data;
  final ValueChanged<WeekData> onSave;
  const WeekFocusCard({super.key, required this.data, required this.onSave});

  @override
  State<WeekFocusCard> createState() => _WeekFocusCardState();
}

class _WeekFocusCardState extends State<WeekFocusCard> {
  late final TextEditingController controller =
      TextEditingController(text: widget.data.focus);

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.center_focus_strong_outlined),
              SizedBox(width: 8),
              Text('Focus della settimana', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Qual è la cosa più importante di questa settimana?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => widget.onSave(widget.data.copyWith(focus: controller.text.trim())),
              child: const Text('Salva focus'),
            ),
          ),
        ],
      ),
    );
  }
}

class WeekPrioritiesCard extends StatelessWidget {
  final WeekData data;
  final ValueChanged<WeekData> onSave;
  const WeekPrioritiesCard({super.key, required this.data, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Priorità della settimana',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final value = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Nuova priorità'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'Es. Finire la tesi'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, controller.text.trim()),
                          child: const Text('Aggiungi'),
                        ),
                      ],
                    ),
                  );
                  if (value != null && value.isNotEmpty) {
                    onSave(data.copyWith(priorities: [...data.priorities, value]));
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (data.priorities.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Aggiungi fino a poche cose davvero importanti, senza riempire troppo la settimana.'),
            )
          else
            ...data.priorities.asMap().entries.map(
                  (entry) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      child: Text('${entry.key + 1}', style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(entry.value),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        final copy = [...data.priorities]..removeAt(entry.key);
                        onSave(data.copyWith(priorities: copy));
                      },
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  final DateTime day;
  final AgendaStore store;
  const _WeekDayCard({required this.day, required this.store});

  @override
  Widget build(BuildContext context) {
    final items = store.forDay(day);
    final journal = store.journal(day);
    final isToday = AgendaStore.sameDay(day, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.55)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: isToday ? Theme.of(context).colorScheme.onPrimary : null,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _cap(DateFormat('EEEE', 'it_IT').format(day)),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ),
              IconButton(
                onPressed: () => openItemEditor(context, store, day),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Nessun impegno'),
            )
          else ...[
            const SizedBox(height: 8),
            ...items.take(4).map((item) => EventTile(store: store, item: item, compact: true)),
            if (items.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('+ ${items.length - 4} altri'),
              ),
          ],
          if (journal.beautiful.trim().isNotEmpty) ...[
            const Divider(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite_outline, size: 17),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    journal.beautiful,
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class WeekMemoryCard extends StatefulWidget {
  final WeekData data;
  final List<String> autoMemories;
  final ValueChanged<WeekData> onSave;

  const WeekMemoryCard({
    super.key,
    required this.data,
    required this.autoMemories,
    required this.onSave,
  });

  @override
  State<WeekMemoryCard> createState() => _WeekMemoryCardState();
}

class _WeekMemoryCardState extends State<WeekMemoryCard> {
  late final TextEditingController best =
      TextEditingController(text: widget.data.bestThing);
  late final TextEditingController reflection =
      TextEditingController(text: widget.data.reflection);

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('La mia settimana ♡',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          if (widget.autoMemories.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Cose belle annotate nei giorni',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            ...widget.autoMemories.map(
              (memory) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('♡  '),
                    Expanded(child: Text(memory)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: best,
            decoration: const InputDecoration(
              labelText: 'La cosa più bella della settimana',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reflection,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Come è andata questa settimana?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => widget.onSave(
                widget.data.copyWith(
                  bestThing: best.text.trim(),
                  reflection: reflection.text.trim(),
                ),
              ),
              child: const Text('Salva settimana'),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthScreen extends StatefulWidget {
  final AgendaStore store;
  final DateTime? initialMonth;

  const MonthScreen({
    super.key,
    required this.store,
    this.initialMonth,
  });

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  late DateTime selected;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMonth ?? DateTime.now();
    selected = DateTime(initial.year, initial.month);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final data = widget.store.month(selected.year, selected.month);
        final spent = data.expenses.fold<int>(0, (a, b) => a + b.cents);
        return Scaffold(
          appBar: AppBar(
            title: Text(_cap(DateFormat('MMMM yyyy', 'it_IT').format(selected)),
                style: const TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month - 1)), icon: const Icon(Icons.chevron_left)),
              IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month + 1)), icon: const Icon(Icons.chevron_right)),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
            children: [
              MonthOpeningHero(
                month: selected,
                data: data,
                eventCount: widget.store.items
                    .where((e) => e.date.year == selected.year && e.date.month == selected.month)
                    .length,
              ),
              const SizedBox(height: 14),
              MonthOpeningJournalCard(
                key: ValueKey('month-opening-${selected.year}-${selected.month}'),
                data: data,
                onSave: (value) => widget.store.saveMonth(
                  selected.year,
                  selected.month,
                  value,
                ),
              ),
              const SizedBox(height: 12),
              _MonthWellbeingCard(store: widget.store, month: selected),
              const SizedBox(height: 12),
              MonthTextCard(
                key: ValueKey('month-intention-${selected.year}-${selected.month}'),
                title: 'Questo mese voglio...',
                initial: data.intention,
                onSave: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(intention: v)),
              ),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Obiettivi', items: data.goals, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(goals: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Libri', items: data.books, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(books: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Film e serie', items: data.films, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(films: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Hobby', items: data.hobbies, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(hobbies: v))),
              const SizedBox(height: 12),
              MonthlyListCard(title: 'Desideri', items: data.wishes, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(wishes: v))),
              const SizedBox(height: 12),
              MonthIdeasBoard(
                ideas: data.ideas,
                onChange: (v) => widget.store.saveMonth(
                  selected.year,
                  selected.month,
                  data.copyWith(ideas: v),
                ),
              ),
              const SizedBox(height: 12),
              BudgetCard(
                data: data,
                spentCents: spent,
                onSave: (v) => widget.store.saveMonth(selected.year, selected.month, v),
              ),
              const SizedBox(height: 12),
              ClosingMonthCard(
                key: ValueKey('month-closing-${selected.year}-${selected.month}'),
                data: data,
                onSave: (v) => widget.store.saveMonth(selected.year, selected.month, v),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthWellbeingCard extends StatelessWidget {
  final AgendaStore store;
  final DateTime month;

  const _MonthWellbeingCard({
    required this.store,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    final prefix =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-';
    final journals = store.journals.entries
        .where((entry) => entry.key.startsWith(prefix))
        .map((entry) => entry.value)
        .toList();

    final moodDays = journals.where((j) => j.mood != null).toList();
    final gratitudeCount =
        journals.fold<int>(0, (sum, j) => sum + j.gratitude.length);
    final completedHabits = journals.fold<int>(
      0,
      (sum, j) => sum + j.completedHabitIds.length,
    );

    DayMood? mostCommonMood;
    if (moodDays.isNotEmpty) {
      final counts = <DayMood, int>{};
      for (final journal in moodDays) {
        final value = journal.mood!;
        counts[value] = (counts[value] ?? 0) + 1;
      }
      mostCommonMood = counts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_outline),
              SizedBox(width: 8),
              Text(
                'Il mese, visto da me',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Un piccolo riepilogo delle giornate che hai raccontato.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.mood_outlined,
                text: '${moodDays.length} giorni con mood',
              ),
              _MiniPill(
                icon: Icons.auto_awesome_outlined,
                text: '$gratitudeCount cose belle',
              ),
              _MiniPill(
                icon: Icons.check_circle_outline,
                text: '$completedHabits abitudini fatte',
              ),
            ],
          ),
          if (mostCommonMood != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: mostCommonMood.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    mostCommonMood.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mood più presente: ${mostCommonMood.label}',
                      style: TextStyle(
                        color: mostCommonMood.color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MonthOpeningHero extends StatelessWidget {
  final DateTime month;
  final MonthlyData data;
  final int eventCount;

  const MonthOpeningHero({
    super.key,
    required this.month,
    required this.data,
    required this.eventCount,
  });

  @override
  Widget build(BuildContext context) {
    final spent = data.expenses.fold<int>(0, (sum, item) => sum + item.cents);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE2EB), Color(0xFFFFF4E8), Color(0xFFEDE7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _cap(DateFormat('MMMM', 'it_IT').format(month)),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            _monthPhrase(month.month),
            style: const TextStyle(fontSize: 14),
          ),
          if (data.monthWord.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Parola del mese: ${data.monthWord}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(icon: Icons.event_outlined, text: '$eventCount impegni'),
              _MiniPill(icon: Icons.flag_outlined, text: '${data.goals.length} obiettivi'),
              _MiniPill(icon: Icons.lightbulb_outline, text: '${data.ideas.length} idee'),
              _MiniPill(icon: Icons.wallet_outlined, text: money(spent)),
            ],
          ),
        ],
      ),
    );
  }
}

class MonthOpeningJournalCard extends StatefulWidget {
  final MonthlyData data;
  final ValueChanged<MonthlyData> onSave;

  const MonthOpeningJournalCard({
    super.key,
    required this.data,
    required this.onSave,
  });

  @override
  State<MonthOpeningJournalCard> createState() =>
      _MonthOpeningJournalCardState();
}

class _MonthOpeningJournalCardState
    extends State<MonthOpeningJournalCard> {
  late final TextEditingController word =
      TextEditingController(text: widget.data.monthWord);
  late final TextEditingController selfCare =
      TextEditingController(text: widget.data.selfCare);

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_outlined),
              SizedBox(width: 8),
              Text(
                'Apertura del mese',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Una piccola pagina per dare un tono al mese prima di riempirlo.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: word,
            decoration: const InputDecoration(
              labelText: 'La parola del mese',
              hintText: 'Es. calma, coraggio, leggerezza...',
              prefixIcon: Icon(Icons.text_fields_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: selfCare,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Come voglio prendermi cura di me',
              hintText: 'Una piccola attenzione concreta...',
              prefixIcon: Icon(Icons.spa_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.bookmark_added_outlined),
              onPressed: () => widget.onSave(
                widget.data.copyWith(
                  monthWord: word.text.trim(),
                  selfCare: selfCare.text.trim(),
                ),
              ),
              label: const Text('Salva apertura del mese'),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthIdeasBoard extends StatelessWidget {
  final List<String> ideas;
  final ValueChanged<List<String>> onChange;

  const MonthIdeasBoard({
    super.key,
    required this.ideas,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Idee del mese',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('Posti, ricette, film, cose da provare e piccoli desideri.',
                        style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final value = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Nuova idea'),
                      content: TextField(
                        controller: controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Es. Fare una passeggiata al lago',
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, controller.text.trim()),
                          child: const Text('Aggiungi'),
                        ),
                      ],
                    ),
                  );
                  if (value != null && value.isNotEmpty) onChange([...ideas, value]);
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ideas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'Qui può diventare la piccola “rivista” del mese: aggiungi qualcosa che ti piacerebbe fare, vedere, leggere o provare.',
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ideas.asMap().entries.map((entry) {
                final icons = [
                  Icons.place_outlined,
                  Icons.restaurant_outlined,
                  Icons.movie_outlined,
                  Icons.local_florist_outlined,
                  Icons.auto_awesome_outlined,
                ];
                return InputChip(
                  avatar: Icon(icons[entry.key % icons.length], size: 17),
                  label: Text(entry.value),
                  onDeleted: () {
                    final copy = [...ideas]..removeAt(entry.key);
                    onChange(copy);
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class YearScreen extends StatefulWidget {
  final AgendaStore store;
  const YearScreen({super.key, required this.store});

  @override
  State<YearScreen> createState() => _YearScreenState();
}

class _YearScreenState extends State<YearScreen> {
  int year = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        int expenses = 0;
        int goals = 0;
        int memories = 0;
        for (int m = 1; m <= 12; m++) {
          final data = widget.store.month(year, m);
          expenses += data.expenses.fold<int>(0, (a, b) => a + b.cents);
          goals += data.goals.length;
        }
        memories = widget.store.journals.entries.where((e) {
          final d = DateTime.tryParse(e.key);
          return d?.year == year && e.value.beautiful.trim().isNotEmpty;
        }).length;

        return Scaffold(
          appBar: AppBar(title: const Text('Il mio anno', style: TextStyle(fontWeight: FontWeight.w800))),
          body: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(onPressed: () => setState(() => year--), icon: const Icon(Icons.chevron_left)),
                  Text('$year', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => setState(() => year++), icon: const Icon(Icons.chevron_right)),
                ],
              ),
              const SizedBox(height: 20),
              StatCard(icon: Icons.flag_outlined, title: 'Obiettivi inseriti', value: '$goals'),
              const SizedBox(height: 10),
              StatCard(icon: Icons.favorite_outline, title: 'Giorni con un bel ricordo', value: '$memories'),
              const SizedBox(height: 10),
              StatCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Spese registrate',
                value: money(expenses),
              ),

              const SizedBox(height: 22),
              const SectionTitle('I miei 12 mesi'),
              const SizedBox(height: 10),
              for (int month = 1; month <= 12; month++) ...[
                YearMonthSnapshot(
                  year: year,
                  month: month,
                  data: widget.store.month(year, month),
                  memoryCount: widget.store.journals.entries.where((entry) {
                    final date = DateTime.tryParse(entry.key);
                    return date?.year == year &&
                        date?.month == month &&
                        entry.value.beautiful.trim().isNotEmpty;
                  }).length,
                ),
                const SizedBox(height: 9),
              ],
            ],
          ),
        );
      },
    );
  }
}

class YearMonthSnapshot extends StatelessWidget {
  final int year;
  final int month;
  final MonthlyData data;
  final int memoryCount;

  const YearMonthSnapshot({
    super.key,
    required this.year,
    required this.month,
    required this.data,
    required this.memoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final spent = data.expenses.fold<int>(0, (sum, item) => sum + item.cents);
    final hasStory = data.bestMoment.trim().isNotEmpty ||
        data.reflection.trim().isNotEmpty ||
        memoryCount > 0 ||
        data.goals.isNotEmpty ||
        spent > 0;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: hasStory
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.28)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              _cap(DateFormat('MMM', 'it_IT').format(DateTime(year, month))),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          Expanded(
            child: hasStory
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data.bestMoment.trim().isNotEmpty)
                        Text(
                          '♡ ${data.bestMoment}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      Text(
                        '${data.goals.length} obiettivi · $memoryCount ricordi · ${money(spent)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                : Text(
                    'Ancora da scrivere',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAgendaItemActions(
  BuildContext context,
  AgendaStore store,
  AgendaItem item,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Modifica'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.content_copy_outlined),
            title: const Text('Duplica'),
            subtitle: const Text('Crea una copia nello stesso giorno'),
            onTap: () => Navigator.pop(context, 'duplicate'),
          ),
          ListTile(
            leading: Icon(
              item.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(
              item.pinned ? 'Togli dai fissati' : 'Fissa in Home',
            ),
            onTap: () => Navigator.pop(context, 'pin'),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Elimina',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    ),
  );

  if (action == 'edit' && context.mounted) {
    await openItemEditor(context, store, item.date, existing: item);
  } else if (action == 'duplicate') {
    await store.duplicateItem(item);
  } else if (action == 'pin') {
    await store.toggleItemPinned(item.id);
  } else if (action == 'delete' && context.mounted) {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminare questo elemento?'),
            content: Text(item.title),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) await store.deleteItem(item.id);
  }
}

class EventTile extends StatelessWidget {
  final AgendaStore store;
  final AgendaItem item;
  final bool compact;
  final bool hideDetails;

  const EventTile({
    super.key,
    required this.store,
    required this.item,
    this.compact = false,
    this.hideDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.category.color;
    final timeText = item.start == null
        ? (item.type == ItemType.task ? 'Da fare' : 'Tutto il giorno')
        : '${formatTime(item.start!)}'
            '${item.end == null ? '' : ' – ${formatTime(item.end!)}'}';

    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: ListTile(
        dense: compact,
        contentPadding: EdgeInsets.only(
          left: compact ? 10 : 12,
          right: compact ? 4 : 8,
        ),
        leading: item.type == ItemType.task
            ? Checkbox(
                value: item.done,
                activeColor: color,
                onChanged: (_) => store.toggle(item.id),
              )
            : CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.16),
                foregroundColor: color,
                child: Icon(item.category.icon),
              ),
        title: Text(
          hideDetails ? 'Contenuto nascosto' : item.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: item.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Wrap(
          spacing: 7,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(timeText),
            Text(
              item.category.label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            if (item.pinned)
              Icon(
                Icons.push_pin,
                size: 14,
                color: color,
              ),
            if (item.reminderMinutesBefore != null ||
                item.secondaryReminderMinutesBefore != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  if (item.reminderMinutesBefore != null &&
                      item.secondaryReminderMinutesBefore != null) ...[
                    const SizedBox(width: 2),
                    Text(
                      '2',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
        onTap: () =>
            openItemEditor(context, store, item.date, existing: item),
        trailing: IconButton(
          tooltip: 'Azioni',
          onPressed: () => _showAgendaItemActions(context, store, item),
          icon: const Icon(Icons.more_horiz),
        ),
      ),
    );
  }
}

class JournalEditor extends StatefulWidget {
  final AgendaStore store;
  final DateTime date;
  const JournalEditor({super.key, required this.store, required this.date});

  @override
  State<JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<JournalEditor> {
  late TextEditingController beautiful;
  late TextEditingController note;
  late List<TextEditingController> gratitude;
  DayMood? mood;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant JournalEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!AgendaStore.sameDay(oldWidget.date, widget.date)) {
      _disposeControllers();
      _load();
    }
  }

  void _load() {
    final j = widget.store.journal(widget.date);
    beautiful = TextEditingController(text: j.beautiful);
    note = TextEditingController(text: j.note);
    mood = j.mood;
    gratitude = List.generate(
      3,
      (index) => TextEditingController(
        text: index < j.gratitude.length ? j.gratitude[index] : '',
      ),
    );
  }

  void _disposeControllers() {
    beautiful.dispose();
    note.dispose();
    for (final controller in gratitude) {
      controller.dispose();
    }
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _save() async {
    final current = widget.store.journal(widget.date);
    await widget.store.saveJournal(
      widget.date,
      current.copyWith(
        beautiful: beautiful.text.trim(),
        note: note.text.trim(),
        mood: mood,
        clearMood: mood == null,
        gratitude: gratitude
            .map((controller) => controller.text.trim())
            .where((value) => value.isNotEmpty)
            .toList(),
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giornata salvata ♡'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _addHabit() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nuova abitudine'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Es. Leggere 20 minuti',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null && value.isNotEmpty) {
      await widget.store.addHabit(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journal = widget.store.journal(widget.date);
    final completed = journal.completedHabitIds;
    final habits = widget.store.habits;

    return Column(
      children: [
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Come ti senti oggi?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: DayMood.values.map((value) {
                  final selected = mood == value;
                  return ChoiceChip(
                    selected: selected,
                    selectedColor: value.color.withValues(alpha: 0.18),
                    avatar: Text(
                      value.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    label: Text(value.label),
                    labelStyle: TextStyle(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      color: selected ? value.color : null,
                    ),
                    onSelected: (_) => setState(() {
                      mood = selected ? null : value;
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tre cose belle di oggi ♡',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 5),
              Text(
                'Anche piccole: qualcosa che ti ha fatto sorridere, stare bene o sentire grata.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ...gratitude.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: entry.value,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      prefixIcon: Center(
                        widthFactor: 1,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      hintText: entry.key == 0
                          ? 'Una cosa bella...'
                          : 'Un altro piccolo momento...',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
              TextField(
                controller: beautiful,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Il momento che voglio ricordare',
                  hintText: 'Quello che vorresti rileggere tra qualche mese...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Le mie abitudini',
                      style:
                          TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Aggiungi abitudine',
                    onPressed: _addHabit,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              if (habits.isEmpty)
                const Text('Aggiungi una piccola abitudine da seguire.')
              else
                ...habits.map(
                  (habit) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: completed.contains(habit.id),
                    title: Text(habit.name),
                    secondary: Icon(
                      completed.contains(habit.id)
                          ? Icons.auto_awesome
                          : Icons.radio_button_unchecked,
                      color: completed.contains(habit.id)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    onChanged: (_) =>
                        widget.store.toggleHabit(widget.date, habit.id),
                    controlAffinity: ListTileControlAffinity.trailing,
                  ),
                ),
              if (habits.isNotEmpty) ...[
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      final selected = await showModalBottomSheet<String>(
                        context: context,
                        showDragHandle: true,
                        builder: (sheetContext) => SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              const ListTile(
                                title: Text(
                                  'Gestisci abitudini',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              ...habits.map(
                                (habit) => ListTile(
                                  title: Text(habit.name),
                                  trailing:
                                      const Icon(Icons.delete_outline),
                                  onTap: () =>
                                      Navigator.pop(sheetContext, habit.id),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (selected != null) {
                        await widget.store.removeHabit(selected);
                      }
                    },
                    icon: const Icon(Icons.tune),
                    label: const Text('Gestisci'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pensieri e note',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Scrivi quello che vuoi ricordare...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.favorite_outline),
                  label: const Text('Salva la mia giornata'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MonthTextCard extends StatefulWidget {
  final String title;
  final String initial;
  final ValueChanged<String> onSave;
  const MonthTextCard({super.key, required this.title, required this.initial, required this.onSave});

  @override
  State<MonthTextCard> createState() => _MonthTextCardState();
}

class _MonthTextCardState extends State<MonthTextCard> {
  late final TextEditingController c = TextEditingController(text: widget.initial);

  @override
  Widget build(BuildContext context) => SimpleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 10),
            TextField(controller: c, minLines: 3, maxLines: 5),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => widget.onSave(c.text.trim()), child: const Text('Salva'))),
          ],
        ),
      );
}

class MonthlyListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final ValueChanged<List<String>> onChange;
  const MonthlyListCard({super.key, required this.title, required this.items, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18))),
              IconButton(
                onPressed: () async {
                  final c = TextEditingController();
                  final value = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Aggiungi a $title'),
                      content: TextField(controller: c, autofocus: true),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                        FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Aggiungi')),
                      ],
                    ),
                  );
                  if (value != null && value.isNotEmpty) onChange([...items, value]);
                },
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          if (items.isEmpty)
            const Text('Nessun elemento ancora.')
          else
            ...items.asMap().entries.map((entry) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      final copy = [...items]..removeAt(entry.key);
                      onChange(copy);
                    },
                  ),
                )),
        ],
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final MonthlyData data;
  final int spentCents;
  final ValueChanged<MonthlyData> onSave;
  const BudgetCard({super.key, required this.data, required this.spentCents, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final remaining = data.budgetCents - spentCents;
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Budget del mese', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: MoneyBox(label: 'Budget', value: money(data.budgetCents))),
              const SizedBox(width: 8),
              Expanded(child: MoneyBox(label: 'Speso', value: money(spentCents))),
              const SizedBox(width: 8),
              Expanded(child: MoneyBox(label: 'Rimane', value: money(remaining))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final c = TextEditingController(text: (data.budgetCents / 100).toStringAsFixed(2));
                    final v = await showDialog<String>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Imposta budget'),
                        content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
                          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('Salva')),
                        ],
                      ),
                    );
                    final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                    if (d != null) onSave(data.copyWith(budgetCents: (d * 100).round()));
                  },
                  child: const Text('Budget'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    final amount = TextEditingController();
                    final note = TextEditingController();
                    String category = 'Altro';
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setLocal) => AlertDialog(
                          title: const Text('Nuova spesa'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Importo')),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: category,
                                  items: const ['Cibo', 'Casa', 'Salute', 'Shopping', 'Trasporti', 'Svago', 'Regali', 'Altro']
                                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                      .toList(),
                                  onChanged: (v) => setLocal(() => category = v ?? 'Altro'),
                                ),
                                const SizedBox(height: 8),
                                TextField(controller: note, decoration: const InputDecoration(labelText: 'Nota')),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aggiungi')),
                          ],
                        ),
                      ),
                    );
                    if (ok != true) return;
                    final d = double.tryParse(amount.text.replaceAll(',', '.'));
                    if (d == null || d <= 0) return;
                    final expense = ExpenseEntry(
                      id: const Uuid().v4(),
                      cents: (d * 100).round(),
                      category: category,
                      note: note.text.trim(),
                      date: DateTime.now(),
                    );
                    onSave(data.copyWith(expenses: [...data.expenses, expense]));
                  },
                  child: const Text('Spesa'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ClosingMonthCard extends StatefulWidget {
  final MonthlyData data;
  final ValueChanged<MonthlyData> onSave;

  const ClosingMonthCard({
    super.key,
    required this.data,
    required this.onSave,
  });

  @override
  State<ClosingMonthCard> createState() => _ClosingMonthCardState();
}

class _ClosingMonthCardState extends State<ClosingMonthCard> {
  late final TextEditingController best =
      TextEditingController(text: widget.data.bestMoment);
  late final TextEditingController lesson =
      TextEditingController(text: widget.data.lesson);
  late final TextEditingController challenge =
      TextEditingController(text: widget.data.challenge);
  late final TextEditingController nextMonth =
      TextEditingController(text: widget.data.nextMonth);
  late final TextEditingController reflection =
      TextEditingController(text: widget.data.reflection);

  @override
  Widget build(BuildContext context) {
    final spent = widget.data.expenses
        .fold<int>(0, (sum, item) => sum + item.cents);
    final remaining = widget.data.budgetCents - spent;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8EDFF), Color(0xFFFFF2F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.nights_stay_outlined),
              SizedBox(width: 8),
              Text(
                'Chiusura del mese',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Fermati un momento prima di voltare pagina.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                icon: Icons.flag_outlined,
                text: '${widget.data.goals.length} obiettivi',
              ),
              _MiniPill(
                icon: Icons.receipt_long_outlined,
                text: 'Speso ${money(spent)}',
              ),
              if (widget.data.budgetCents > 0)
                _MiniPill(
                  icon: Icons.savings_outlined,
                  text: 'Rimane ${money(remaining)}',
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: best,
            decoration: const InputDecoration(
              labelText: 'Il momento più bello',
              prefixIcon: Icon(Icons.favorite_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: challenge,
            decoration: const InputDecoration(
              labelText: 'La cosa più difficile',
              prefixIcon: Icon(Icons.trending_up_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: lesson,
            decoration: const InputDecoration(
              labelText: 'Cosa ho imparato',
              prefixIcon: Icon(Icons.lightbulb_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reflection,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Com’è andato davvero questo mese?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nextMonth,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Cosa voglio portare nel prossimo mese',
              prefixIcon: Icon(Icons.arrow_forward_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.favorite_outline),
              onPressed: () => widget.onSave(
                widget.data.copyWith(
                  bestMoment: best.text.trim(),
                  lesson: lesson.text.trim(),
                  challenge: challenge.text.trim(),
                  nextMonth: nextMonth.text.trim(),
                  reflection: reflection.text.trim(),
                ),
              ),
              label: const Text('Chiudi e salva il mese'),
            ),
          ),
        ],
      ),
    );
  }
}

class DateStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  const DateStrip({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      7,
      (i) => addCivilDays(selected, i - 3),
    );
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final d = dates[i];
          final active = AgendaStore.sameDay(d, selected);
          return InkWell(
            onTap: () => onSelected(d),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 54,
              decoration: BoxDecoration(
                color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE', 'it_IT').format(d).substring(0, 2).toUpperCase(),
                      style: TextStyle(fontSize: 11, color: active ? Theme.of(context).colorScheme.onPrimary : null)),
                  const SizedBox(height: 4),
                  Text('${d.day}',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: active ? Theme.of(context).colorScheme.onPrimary : null)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const NavigationCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon),
                const SizedBox(height: 18),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800));
}

class SimpleCard extends StatelessWidget {
  final Widget child;
  const SimpleCard({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: child,
        ),
      );
}

class MoneyBox extends StatelessWidget {
  final String label;
  final String value;
  const MoneyBox({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 3),
            FittedBox(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      );
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const StatCard({super.key, required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) => SimpleCard(
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700))),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
      );
}

Future<void> openItemEditor(
  BuildContext context,
  AgendaStore store,
  DateTime initialDate, {
  TimeOfDay? initialTime,
  ItemType? initialType,
  AgendaItem? existing,
}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  DateTime date = existing?.date ?? initialDate;
  TimeOfDay? start = existing?.start ?? initialTime;
  TimeOfDay? end = existing?.end ??
      (start == null
          ? null
          : _timePlusMinutes(
              start,
              store.preferences.defaultEventMinutes,
            ));
  ItemType type = existing?.type ?? initialType ?? ItemType.appointment;
  AgendaCategory category =
      existing?.category ?? store.preferences.defaultCategory;
  int primaryReminder = existing == null
      ? (store.preferences.defaultPrimaryReminder ?? -1)
      : (existing.reminderMinutesBefore ?? -1);
  int secondaryReminder = existing == null
      ? (store.preferences.defaultSecondaryReminder ?? -1)
      : (existing.secondaryReminderMinutesBefore ?? -1);
  RecurrenceRule recurrence = RecurrenceRule.none;
  int recurrenceCount = 4;

  AgendaItem buildItem({
    required String id,
    required DateTime itemDate,
    bool done = false,
    bool pinned = false,
  }) {
    return AgendaItem(
      id: id,
      title: title.text.trim(),
      note: note.text.trim(),
      date: DateTime(itemDate.year, itemDate.month, itemDate.day),
      type: type,
      category: category,
      reminderMinutesBefore:
          start == null || primaryReminder < 0 ? null : primaryReminder,
      secondaryReminderMinutesBefore:
          start == null || secondaryReminder < 0 ? null : secondaryReminder,
      start: start,
      end: type == ItemType.task ? null : end,
      done: done,
      pinned: pinned,
    );
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setLocal) => Container(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        existing == null ? 'Aggiungi alla giornata' : 'Modifica',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (existing != null)
                      IconButton.filledTonal(
                        tooltip: 'Duplica',
                        onPressed: () async {
                          final t = title.text.trim();
                          if (t.isEmpty) return;
                          await store.upsert(
                            buildItem(
                              id: const Uuid().v4(),
                              itemDate: date,
                            ),
                          );
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                        },
                        icon: const Icon(Icons.content_copy_outlined),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SegmentedButton<ItemType>(
                  segments: const [
                    ButtonSegment(
                      value: ItemType.appointment,
                      label: Text('Appuntamento'),
                      icon: Icon(Icons.event_outlined),
                    ),
                    ButtonSegment(
                      value: ItemType.task,
                      label: Text('Da fare'),
                      icon: Icon(Icons.check_circle_outline),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setLocal(() => type = v.first),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: title,
                  autofocus: existing == null,
                  decoration: const InputDecoration(
                    labelText: 'Titolo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Categoria',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: AgendaCategory.values.map((value) {
                    final active = category == value;
                    return ChoiceChip(
                      selected: active,
                      avatar: Icon(
                        value.icon,
                        size: 17,
                        color: active ? Colors.white : value.color,
                      ),
                      label: Text(value.label),
                      selectedColor: value.color,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : null,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setLocal(() => category = value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(
                    DateFormat('d MMMM yyyy', 'it_IT').format(date),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2040),
                    );
                    if (picked != null) setLocal(() => date = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(
                    start == null ? 'Senza orario' : formatTime(start!),
                  ),
                  trailing: start == null
                      ? null
                      : IconButton(
                          onPressed: () => setLocal(() {
                            start = null;
                            end = null;
                            primaryReminder = -1;
                            secondaryReminder = -1;
                          }),
                          icon: const Icon(Icons.close),
                        ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: start ?? TimeOfDay.now(),
                    );
                    if (picked != null) {
                      setLocal(() {
                        start = picked;
                        end ??= _timePlusMinutes(
                          picked,
                          store.preferences.defaultEventMinutes,
                        );
                      });
                    }
                  },
                ),
                if (start != null && type == ItemType.appointment)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timelapse_outlined),
                    title: Text(
                      end == null ? 'Ora fine' : formatTime(end!),
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: end ?? start!,
                      );
                      if (picked != null) setLocal(() => end = picked);
                    },
                  ),
                if (start != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: primaryReminder,
                          decoration: const InputDecoration(
                            labelText: 'Promemoria 1',
                            prefixIcon:
                                Icon(Icons.notifications_none_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _reminderMenuItems,
                          onChanged: (value) => setLocal(() {
                            primaryReminder = value ?? -1;
                            if (secondaryReminder == primaryReminder) {
                              secondaryReminder = -1;
                            }
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: secondaryReminder,
                          decoration: const InputDecoration(
                            labelText: 'Promemoria 2',
                            prefixIcon:
                                Icon(Icons.add_alert_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _reminderMenuItems,
                          onChanged: (value) => setLocal(() {
                            secondaryReminder = value ?? -1;
                            if (secondaryReminder == primaryReminder) {
                              secondaryReminder = -1;
                            }
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Puoi impostare fino a due promemoria diversi per lo stesso impegno.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  'Ripeti',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: RecurrenceRule.values.map((value) {
                    return ChoiceChip(
                      selected: recurrence == value,
                      avatar: Icon(value.icon, size: 17),
                      label: Text(value.label),
                      onSelected: (_) =>
                          setLocal(() => recurrence = value),
                    );
                  }).toList(),
                ),
                if (recurrence != RecurrenceRule.none) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.repeat),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$recurrenceCount occorrenze totali',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: recurrenceCount.toDouble(),
                    min: 2,
                    max: 20,
                    divisions: 18,
                    label: recurrenceCount.toString(),
                    onChanged: (value) =>
                        setLocal(() => recurrenceCount = value.round()),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (existing != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await store.deleteItem(existing.id);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          label: const Text('Elimina'),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check),
                        onPressed: () async {
                          final t = title.text.trim();
                          if (t.isEmpty) return;

                          final base = buildItem(
                            id: existing?.id ?? const Uuid().v4(),
                            itemDate: date,
                            done: existing?.done ?? false,
                            pinned: existing?.pinned ?? false,
                          );
                          await store.upsert(base);

                          if (recurrence != RecurrenceRule.none) {
                            for (var i = 1; i < recurrenceCount; i++) {
                              final nextDate =
                                  _recurrenceDate(date, recurrence, i);
                              await store.upsert(
                                buildItem(
                                  id: const Uuid().v4(),
                                  itemDate: nextDate,
                                ),
                              );
                            }
                          }

                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                        },
                        label: Text(
                          recurrence == RecurrenceRule.none
                              ? 'Salva'
                              : 'Salva serie',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

const List<DropdownMenuItem<int>> _reminderMenuItems = [
  DropdownMenuItem(value: -1, child: Text('Nessuno')),
  DropdownMenuItem(value: 0, child: Text('All’ora')),
  DropdownMenuItem(value: 10, child: Text('10 min prima')),
  DropdownMenuItem(value: 30, child: Text('30 min prima')),
  DropdownMenuItem(value: 60, child: Text('1 ora prima')),
  DropdownMenuItem(value: 120, child: Text('2 ore prima')),
  DropdownMenuItem(value: 1440, child: Text('1 giorno prima')),
];

DateTime _recurrenceDate(
  DateTime start,
  RecurrenceRule rule,
  int offset,
) {
  switch (rule) {
    case RecurrenceRule.none:
      return start;
    case RecurrenceRule.daily:
      return addCivilDays(start, offset);
    case RecurrenceRule.weekly:
      return addCivilDays(start, 7 * offset);
    case RecurrenceRule.monthly:
      final firstOfTarget = DateTime(start.year, start.month + offset, 1);
      final lastDay = DateTime(
        firstOfTarget.year,
        firstOfTarget.month + 1,
        0,
      ).day;
      final day = start.day.clamp(1, lastDay).toInt();
      return DateTime(firstOfTarget.year, firstOfTarget.month, day);
  }
}

const _positiveQuotes = <(String, String)>[
  ('Una cosa alla volta ♡', 'Non serve fare tutto oggi. Basta iniziare da qualcosa che conta.'),
  ('Fai spazio alle cose belle', 'Anche una giornata piena può contenere un momento solo tuo.'),
  ('Non devi correre sempre', 'La costanza vale più della fretta.'),
  ('Oggi merita una pagina nuova', 'Puoi decidere cosa portare con te e cosa lasciare andare.'),
  ('Piccoli passi, grandi cambiamenti', 'Le cose importanti crescono un giorno alla volta.'),
  ('Ricordati anche di te', 'Tra tutte le cose da fare, lascia uno spazio per stare bene.'),
  ('Va bene cambiare programma', 'Un’agenda serve a sostenerti, non a metterti pressione.'),
  ('Celebra quello che funziona', 'Non aspettare solo i grandi traguardi per essere fiera di te.'),
];

(String, String) _dailyQuote(DateTime date) {
  final start = DateTime(date.year, 1, 1);
  final dayOfYear = date.difference(start).inDays;
  return _positiveQuotes[dayOfYear % _positiveQuotes.length];
}

String _monthPhrase(int month) {
  const phrases = [
    '',
    'Un inizio leggero, senza pretendere tutto subito.',
    'Coltiva ciò che vuoi vedere crescere.',
    'Lascia entrare un po’ di primavera anche nei programmi.',
    'Fai spazio alle novità.',
    'Scegli ciò che ti fa stare bene.',
    'Porta con te solo quello che serve.',
    'Più luce, più tempo per respirare.',
    'Rallenta abbastanza da ricordarti le giornate.',
    'Riparti dalle cose essenziali.',
    'Raccogli ciò che hai costruito.',
    'Proteggi il tuo tempo e le tue energie.',
    'Chiudi l’anno ricordando anche le cose belle.',
  ];
  return phrases[month.clamp(1, 12)];
}

DateTime addCivilDays(DateTime date, int days) {
  final noon = DateTime(date.year, date.month, date.day, 12);
  final shifted = DateTime(noon.year, noon.month, noon.day + days, 12);
  return DateTime(shifted.year, shifted.month, shifted.day);
}

DateTime mondayOf(DateTime d) {
  final n = DateTime(d.year, d.month, d.day);
  return addCivilDays(n, -(n.weekday - 1));
}

TimeOfDay _timePlusMinutes(TimeOfDay start, int minutes) {
  final total = (start.hour * 60 + start.minute + minutes).clamp(0, 1439);
  return TimeOfDay(
    hour: total ~/ 60,
    minute: total % 60,
  );
}

String _derivePinHash(String pin, String salt) {
  List<int> bytes = utf8.encode('$salt:$pin');
  for (var i = 0; i < 25000; i++) {
    bytes = sha256.convert(bytes).bytes;
  }
  return base64UrlEncode(bytes);
}

String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String money(int cents) => NumberFormat.currency(locale: 'it_IT', symbol: '€').format(cents / 100);

String _cap(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
