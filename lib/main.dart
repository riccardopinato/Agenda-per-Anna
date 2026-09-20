import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

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
  });
}

class AgendaApp extends StatelessWidget {
  final AgendaStore store;
  const AgendaApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE98FAA),
      brightness: Brightness.light,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Agenda per Anna',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFFFFAFC),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: MainShell(store: store),
    );
  }
}

enum ItemType { appointment, task }

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
  final bool done;

  const AgendaItem({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.type,
    this.category = AgendaCategory.personal,
    this.reminderMinutesBefore,
    this.start,
    this.end,
    this.done = false,
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
    bool? done,
    bool clearTime = false,
    bool clearReminder = false,
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
      start: clearTime ? null : (start ?? this.start),
      end: clearTime ? null : (end ?? this.end),
      done: done ?? this.done,
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
        'done': done,
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
      done: json['done'] as bool? ?? false,
      start: parseTime(json['start']),
      end: parseTime(json['end']),
    );
  }
}

class DayJournal {
  final String beautiful;
  final String note;
  const DayJournal({this.beautiful = '', this.note = ''});

  Map<String, dynamic> toJson() => {'beautiful': beautiful, 'note': note};

  factory DayJournal.fromJson(Map<String, dynamic> json) => DayJournal(
        beautiful: json['beautiful'] as String? ?? '',
        note: json['note'] as String? ?? '',
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

class AgendaStore extends ChangeNotifier {
  static const _itemsKey = 'items_v1';
  static const _journalsKey = 'journals_v1';
  static const _monthsKey = 'months_v1';
  static const _weeksKey = 'weeks_v1';

  final List<AgendaItem> items = [];
  final Map<String, DayJournal> journals = {};
  final Map<String, MonthlyData> months = {};
  final Map<String, WeekData> weeks = {};

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_itemsKey);
      if (raw != null) {
        items
          ..clear()
          ..addAll((jsonDecode(raw) as List).map(
            (e) => AgendaItem.fromJson(Map<String, dynamic>.from(e as Map)),
          ));
      }
      final jr = prefs.getString(_journalsKey);
      if (jr != null) {
        final map = Map<String, dynamic>.from(jsonDecode(jr) as Map);
        journals
          ..clear()
          ..addAll(map.map((k, v) => MapEntry(
                k,
                DayJournal.fromJson(Map<String, dynamic>.from(v as Map)),
              )));
      }
      final mr = prefs.getString(_monthsKey);
      if (mr != null) {
        final map = Map<String, dynamic>.from(jsonDecode(mr) as Map);
        months
          ..clear()
          ..addAll(map.map((k, v) => MapEntry(
                k,
                MonthlyData.fromJson(Map<String, dynamic>.from(v as Map)),
              )));
      }

      final wr = prefs.getString(_weeksKey);
      if (wr != null) {
        final map = Map<String, dynamic>.from(jsonDecode(wr) as Map);
        weeks
          ..clear()
          ..addAll(map.map((k, v) => MapEntry(
                k,
                WeekData.fromJson(Map<String, dynamic>.from(v as Map)),
              )));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_itemsKey, jsonEncode(items.map((e) => e.toJson()).toList()));
    await prefs.setString(
      _journalsKey,
      jsonEncode(journals.map((k, v) => MapEntry(k, v.toJson()))),
    );
    await prefs.setString(
      _monthsKey,
      jsonEncode(months.map((k, v) => MapEntry(k, v.toJson()))),
    );
    await prefs.setString(
      _weeksKey,
      jsonEncode(weeks.map((k, v) => MapEntry(k, v.toJson()))),
    );
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
    await _syncReminder(item);
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    items.removeWhere((e) => e.id == id);
    await NotificationService.instance.cancel(id);
    await _save();
    notifyListeners();
  }

  Future<void> _syncReminder(AgendaItem item) async {
    final minutes = item.reminderMinutesBefore;
    final start = item.start;
    if (minutes == null || start == null) {
      await NotificationService.instance.cancel(item.id);
      return;
    }

    final eventTime = DateTime(
      item.date.year,
      item.date.month,
      item.date.day,
      start.hour,
      start.minute,
    );
    final when = eventTime.subtract(Duration(minutes: minutes));

    await NotificationService.instance.schedule(
      stableId: item.id,
      title: item.title,
      body: minutes == 0
          ? 'È il momento di iniziare.'
          : 'Tra $minutes minuti: ${item.title}',
      when: when,
    );
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
}

class MainShell extends StatefulWidget {
  final AgendaStore store;
  const MainShell({super.key, required this.store});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

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
        return Scaffold(
          appBar: AppBar(title: const Text('Agenda per Anna', style: TextStyle(fontWeight: FontWeight.w800))),
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
                    Text(_cap(DateFormat('EEEE d MMMM', 'it_IT').format(now)),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(_dailyQuote(now).$1,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(_dailyQuote(now).$2),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionTitle('Oggi'),
              const SizedBox(height: 10),
              if (today.isEmpty)
                const SimpleCard(child: Text('Nessun impegno per oggi.'))
              else
                ...today.take(5).map((e) => EventTile(store: store, item: e)),
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
  const PlannerScreen({super.key, required this.store});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  DateTime day = DateTime.now();

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
    final height = (((endMinutes - startMinutes) / 60) * hourHeight)
        .clamp(36.0, totalHeightFromTop(top));

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
      height: height - 4,
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
        final end = start.add(const Duration(days: 6));
        final events = <AgendaItem>[
          for (int i = 0; i < 7; i++) ...widget.store.forDay(start.add(Duration(days: i))),
        ];
        final completedTasks = events.where((e) => e.type == ItemType.task && e.done).length;
        final totalTasks = events.where((e) => e.type == ItemType.task).length;
        final beautifulThings = <String>[
          for (int i = 0; i < 7; i++)
            if (widget.store.journal(start.add(Duration(days: i))).beautiful.trim().isNotEmpty)
              widget.store.journal(start.add(Duration(days: i))).beautiful.trim(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('La mia settimana', style: TextStyle(fontWeight: FontWeight.w800)),
            actions: [
              IconButton(
                tooltip: 'Settimana precedente',
                onPressed: () => setState(() => start = start.subtract(const Duration(days: 7))),
                icon: const Icon(Icons.chevron_left),
              ),
              IconButton(
                tooltip: 'Questa settimana',
                onPressed: () => setState(() => start = mondayOf(DateTime.now())),
                icon: const Icon(Icons.today_outlined),
              ),
              IconButton(
                tooltip: 'Settimana successiva',
                onPressed: () => setState(() => start = start.add(const Duration(days: 7))),
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
                  day: start.add(Duration(days: i)),
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
  const MonthScreen({super.key, required this.store});

  @override
  State<MonthScreen> createState() => _MonthScreenState();
}

class _MonthScreenState extends State<MonthScreen> {
  late DateTime selected = DateTime(DateTime.now().year, DateTime.now().month);

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

class EventTile extends StatelessWidget {
  final AgendaStore store;
  final AgendaItem item;
  final bool compact;

  const EventTile({
    super.key,
    required this.store,
    required this.item,
    this.compact = false,
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
          item.title,
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
            if (item.reminderMinutesBefore != null)
              Icon(
                Icons.notifications_active_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          ],
        ),
        onTap: () =>
            openItemEditor(context, store, item.date, existing: item),
        trailing: IconButton(
          onPressed: () => store.deleteItem(item.id),
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class HourRow extends StatelessWidget {
  final int hour;
  final List<AgendaItem> items;
  final VoidCallback onTap;
  final AgendaStore store;

  const HourRow({
    super.key,
    required this.hour,
    required this.items,
    required this.onTap,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 54,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${hour.toString().padLeft(2, '0')}:00', textAlign: TextAlign.right),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: items.isEmpty
                    ? const SizedBox(height: 60)
                    : Column(children: items.map((e) => EventTile(store: store, item: e, compact: true)).toList()),
              ),
            ),
          ],
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant JournalEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!AgendaStore.sameDay(oldWidget.date, widget.date)) _load();
  }

  void _load() {
    final j = widget.store.journal(widget.date);
    beautiful = TextEditingController(text: j.beautiful);
    note = TextEditingController(text: j.note);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Una cosa bella di oggi ♡', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 10),
              TextField(controller: beautiful, maxLines: 2, decoration: const InputDecoration(hintText: 'Qualcosa che ti ha fatto sorridere...')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SimpleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pensieri e note', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 10),
              TextField(controller: note, minLines: 4, maxLines: 8, decoration: const InputDecoration(hintText: 'Scrivi quello che vuoi ricordare...')),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => widget.store.saveJournal(
                    widget.date,
                    DayJournal(beautiful: beautiful.text.trim(), note: note.text.trim()),
                  ),
                  child: const Text('Salva giornata'),
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
    final dates = List.generate(7, (i) => selected.add(Duration(days: i - 3)));
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
  AgendaItem? existing,
}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final note = TextEditingController(text: existing?.note ?? '');
  DateTime date = existing?.date ?? initialDate;
  TimeOfDay? start = existing?.start ?? initialTime;
  TimeOfDay? end = existing?.end ??
      (start == null
          ? null
          : TimeOfDay(
              hour: (start.hour + 1).clamp(0, 23),
              minute: start.minute,
            ));
  ItemType type = existing?.type ?? ItemType.appointment;
  AgendaCategory category = existing?.category ?? AgendaCategory.personal;
  int reminderChoice = existing?.reminderMinutesBefore ?? -1;

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
                Text(
                  existing == null ? 'Aggiungi alla giornata' : 'Modifica',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
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
                            reminderChoice = -1;
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
                        end ??= TimeOfDay(
                          hour: (picked.hour + 1).clamp(0, 23),
                          minute: picked.minute,
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
                  DropdownButtonFormField<int>(
                    initialValue: reminderChoice,
                    decoration: const InputDecoration(
                      labelText: 'Promemoria',
                      prefixIcon: Icon(Icons.notifications_none_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: -1, child: Text('Nessun promemoria')),
                      DropdownMenuItem(value: 0, child: Text('All’ora dell’evento')),
                      DropdownMenuItem(value: 10, child: Text('10 minuti prima')),
                      DropdownMenuItem(value: 30, child: Text('30 minuti prima')),
                      DropdownMenuItem(value: 60, child: Text('1 ora prima')),
                      DropdownMenuItem(value: 1440, child: Text('1 giorno prima')),
                    ],
                    onChanged: (value) =>
                        setLocal(() => reminderChoice = value ?? -1),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Il promemoria viene salvato sul dispositivo. Sul web la disponibilità dipende dal browser.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    onPressed: () async {
                      final t = title.text.trim();
                      if (t.isEmpty) return;

                      await store.upsert(
                        AgendaItem(
                          id: existing?.id ?? const Uuid().v4(),
                          title: t,
                          note: note.text.trim(),
                          date: DateTime(date.year, date.month, date.day),
                          type: type,
                          category: category,
                          reminderMinutesBefore:
                              start == null || reminderChoice < 0
                                  ? null
                                  : reminderChoice,
                          start: start,
                          end: type == ItemType.task ? null : end,
                          done: existing?.done ?? false,
                        ),
                      );

                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    label: const Text('Salva'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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

DateTime mondayOf(DateTime d) {
  final n = DateTime(d.year, d.month, d.day);
  return n.subtract(Duration(days: n.weekday - 1));
}

String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String money(int cents) => NumberFormat.currency(locale: 'it_IT', symbol: '€').format(cents / 100);

String _cap(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
