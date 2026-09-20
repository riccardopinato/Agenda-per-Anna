import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);
  final store = AgendaStore();
  await store.load();
  runApp(AgendaApp(store: store));
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

class AgendaItem {
  final String id;
  final String title;
  final String note;
  final DateTime date;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final ItemType type;
  final bool done;

  const AgendaItem({
    required this.id,
    required this.title,
    required this.note,
    required this.date,
    required this.type,
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
    bool? done,
    bool clearTime = false,
  }) {
    return AgendaItem(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      date: date ?? this.date,
      type: type ?? this.type,
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

class MonthlyData {
  final String intention;
  final List<String> goals;
  final List<String> books;
  final List<String> hobbies;
  final List<String> wishes;
  final List<String> ideas;
  final int budgetCents;
  final List<ExpenseEntry> expenses;
  final String bestMoment;
  final String lesson;
  final String reflection;

  const MonthlyData({
    this.intention = '',
    this.goals = const [],
    this.books = const [],
    this.hobbies = const [],
    this.wishes = const [],
    this.ideas = const [],
    this.budgetCents = 0,
    this.expenses = const [],
    this.bestMoment = '',
    this.lesson = '',
    this.reflection = '',
  });

  MonthlyData copyWith({
    String? intention,
    List<String>? goals,
    List<String>? books,
    List<String>? hobbies,
    List<String>? wishes,
    List<String>? ideas,
    int? budgetCents,
    List<ExpenseEntry>? expenses,
    String? bestMoment,
    String? lesson,
    String? reflection,
  }) {
    return MonthlyData(
      intention: intention ?? this.intention,
      goals: goals ?? this.goals,
      books: books ?? this.books,
      hobbies: hobbies ?? this.hobbies,
      wishes: wishes ?? this.wishes,
      ideas: ideas ?? this.ideas,
      budgetCents: budgetCents ?? this.budgetCents,
      expenses: expenses ?? this.expenses,
      bestMoment: bestMoment ?? this.bestMoment,
      lesson: lesson ?? this.lesson,
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
        'budgetCents': budgetCents,
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'bestMoment': bestMoment,
        'lesson': lesson,
        'reflection': reflection,
      };

  factory MonthlyData.fromJson(Map<String, dynamic> json) => MonthlyData(
        intention: json['intention'] as String? ?? '',
        goals: List<String>.from(json['goals'] as List? ?? const []),
        books: List<String>.from(json['books'] as List? ?? const []),
        hobbies: List<String>.from(json['hobbies'] as List? ?? const []),
        wishes: List<String>.from(json['wishes'] as List? ?? const []),
        ideas: List<String>.from(json['ideas'] as List? ?? const []),
        budgetCents: json['budgetCents'] as int? ?? 0,
        expenses: (json['expenses'] as List? ?? const [])
            .map((e) => ExpenseEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        bestMoment: json['bestMoment'] as String? ?? '',
        lesson: json['lesson'] as String? ?? '',
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

  final List<AgendaItem> items = [];
  final Map<String, DayJournal> journals = {};
  final Map<String, MonthlyData> months = {};

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
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    items.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
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
      PlannerScreen(store: widget.store),
      WeekScreen(store: widget.store),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Mese'),
          NavigationDestination(icon: Icon(Icons.today_outlined), label: 'Oggi'),
          NavigationDestination(icon: Icon(Icons.view_week_outlined), label: 'Settimana'),
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
                    const Text('Una cosa alla volta ♡',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    const Text('Organizza la giornata, lascia spazio alle cose belle e ricordati di te.'),
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
        final allDay = events.where((e) => e.start == null).toList();
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('La mia giornata', style: TextStyle(fontWeight: FontWeight.w800)),
                Text(_cap(DateFormat('EEEE d MMMM', 'it_IT').format(day)),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            actions: [
              IconButton(onPressed: () => setState(() => day = DateTime.now()), icon: const Icon(Icons.today_outlined)),
              IconButton(onPressed: () => openItemEditor(context, widget.store, day), icon: const Icon(Icons.add_circle_outline)),
            ],
          ),
          body: Column(
            children: [
              DateStrip(selected: day, onSelected: (d) => setState(() => day = d)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 110),
                  children: [
                    if (allDay.isNotEmpty) ...[
                      const SectionTitle('Senza orario'),
                      const SizedBox(height: 8),
                      ...allDay.map((e) => EventTile(store: widget.store, item: e)),
                      const SizedBox(height: 16),
                    ],
                    const SectionTitle('Timeline'),
                    const SizedBox(height: 8),
                    for (int hour = 6; hour < 24; hour++)
                      HourRow(
                        hour: hour,
                        items: events.where((e) => e.start?.hour == hour).toList(),
                        onTap: () => openItemEditor(
                          context,
                          widget.store,
                          day,
                          initialTime: TimeOfDay(hour: hour, minute: 0),
                        ),
                        store: widget.store,
                      ),
                    const SizedBox(height: 20),
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
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('La mia settimana', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(onPressed: () => setState(() => start = start.subtract(const Duration(days: 7))), icon: const Icon(Icons.chevron_left)),
            IconButton(onPressed: () => setState(() => start = start.add(const Duration(days: 7))), icon: const Icon(Icons.chevron_right)),
          ],
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
          itemCount: 7,
          itemBuilder: (context, i) {
            final day = start.add(Duration(days: i));
            final list = widget.store.forDay(day);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(_cap(DateFormat('EEEE d MMMM', 'it_IT').format(day)),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        IconButton(
                          onPressed: () => openItemEditor(context, widget.store, day),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    if (list.isEmpty)
                      const Text('Nessun impegno')
                    else
                      ...list.map((e) => EventTile(store: widget.store, item: e, compact: true)),
                  ],
                ),
              ),
            );
          },
        ),
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
              MonthTextCard(
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
              MonthlyListCard(title: 'Idee', items: data.ideas, onChange: (v) => widget.store.saveMonth(selected.year, selected.month, data.copyWith(ideas: v))),
              const SizedBox(height: 12),
              BudgetCard(
                data: data,
                spentCents: spent,
                onSave: (v) => widget.store.saveMonth(selected.year, selected.month, v),
              ),
              const SizedBox(height: 12),
              ClosingMonthCard(
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
            ],
          ),
        );
      },
    );
  }
}

class EventTile extends StatelessWidget {
  final AgendaStore store;
  final AgendaItem item;
  final bool compact;

  const EventTile({super.key, required this.store, required this.item, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: compact ? 6 : 10),
      child: ListTile(
        dense: compact,
        leading: item.type == ItemType.task
            ? Checkbox(value: item.done, onChanged: (_) => store.toggle(item.id))
            : const CircleAvatar(child: Icon(Icons.event_outlined)),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: item.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(item.start == null
            ? (item.type == ItemType.task ? 'Da fare' : 'Tutto il giorno')
            : '${formatTime(item.start!)}${item.end == null ? '' : ' – ${formatTime(item.end!)}'}'),
        onTap: () => openItemEditor(context, store, item.date, existing: item),
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

class ClosingMonthCard extends StatelessWidget {
  final MonthlyData data;
  final ValueChanged<MonthlyData> onSave;
  const ClosingMonthCard({super.key, required this.data, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final best = TextEditingController(text: data.bestMoment);
    final lesson = TextEditingController(text: data.lesson);
    final reflection = TextEditingController(text: data.reflection);
    return SimpleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chiusura del mese', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 10),
          TextField(controller: best, decoration: const InputDecoration(labelText: 'Il momento più bello')),
          const SizedBox(height: 8),
          TextField(controller: lesson, decoration: const InputDecoration(labelText: 'Cosa ho imparato')),
          const SizedBox(height: 8),
          TextField(controller: reflection, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Com’è andato questo mese?')),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => onSave(data.copyWith(
                bestMoment: best.text.trim(),
                lesson: lesson.text.trim(),
                reflection: reflection.text.trim(),
              )),
              child: const Text('Salva il mio mese'),
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
      (start == null ? null : TimeOfDay(hour: (start.hour + 1).clamp(0, 23), minute: start.minute));
  ItemType type = existing?.type ?? ItemType.appointment;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setLocal) => Container(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + MediaQuery.viewInsetsOf(context).bottom),
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
                Text(existing == null ? 'Aggiungi alla giornata' : 'Modifica',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                SegmentedButton<ItemType>(
                  segments: const [
                    ButtonSegment(value: ItemType.appointment, label: Text('Appuntamento'), icon: Icon(Icons.event_outlined)),
                    ButtonSegment(value: ItemType.task, label: Text('Da fare'), icon: Icon(Icons.check_circle_outline)),
                  ],
                  selected: {type},
                  onSelectionChanged: (v) => setLocal(() => type = v.first),
                ),
                const SizedBox(height: 14),
                TextField(controller: title, autofocus: existing == null, decoration: const InputDecoration(labelText: 'Titolo', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: note, maxLines: 3, decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(DateFormat('d MMMM yyyy', 'it_IT').format(date)),
                  onTap: () async {
                    final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2040));
                    if (picked != null) setLocal(() => date = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule_outlined),
                  title: Text(start == null ? 'Senza orario' : formatTime(start!)),
                  trailing: start == null
                      ? null
                      : IconButton(onPressed: () => setLocal(() { start = null; end = null; }), icon: const Icon(Icons.close)),
                  onTap: () async {
                    final picked = await showTimePicker(context: context, initialTime: start ?? TimeOfDay.now());
                    if (picked != null) {
                      setLocal(() {
                        start = picked;
                        end ??= TimeOfDay(hour: (picked.hour + 1).clamp(0, 23), minute: picked.minute);
                      });
                    }
                  },
                ),
                if (start != null && type == ItemType.appointment)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.timelapse_outlined),
                    title: Text(end == null ? 'Ora fine' : formatTime(end!)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: end ?? start!);
                      if (picked != null) setLocal(() => end = picked);
                    },
                  ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final t = title.text.trim();
                      if (t.isEmpty) return;
                      await store.upsert(AgendaItem(
                        id: existing?.id ?? const Uuid().v4(),
                        title: t,
                        note: note.text.trim(),
                        date: DateTime(date.year, date.month, date.day),
                        type: type,
                        start: start,
                        end: type == ItemType.task ? null : end,
                        done: existing?.done ?? false,
                      ));
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: const Text('Salva'),
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

DateTime mondayOf(DateTime d) {
  final n = DateTime(d.year, d.month, d.day);
  return n.subtract(Duration(days: n.weekday - 1));
}

String formatTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String money(int cents) => NumberFormat.currency(locale: 'it_IT', symbol: '€').format(cents / 100);

String _cap(String value) => value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
