import 'package:flutter/material.dart';

// Isolated design study. No production services, account, database or network.
const previewVariant = String.fromEnvironment('EDITORIAL_VARIANT', defaultValue: 'premium');
const bool hybrid = previewVariant == 'hybrid';

void main() => runApp(const EditorialPreview());

class EditorialPreview extends StatefulWidget {
  const EditorialPreview({super.key});
  @override
  State<EditorialPreview> createState() => _EditorialPreviewState();
}

class PreviewPalette {
  const PreviewPalette(this.title, this.accent, this.soft, this.ink);
  final String title;
  final Color accent;
  final Color soft;
  final Color ink;
}

const palettes = <PreviewPalette>[
  PreviewPalette('Rose', Color(0xFFAE7584), Color(0xFFF3E3E6), Color(0xFF543A43)),
  PreviewPalette('Sage', Color(0xFF6E8977), Color(0xFFE5EEE6), Color(0xFF314439)),
  PreviewPalette('Ink', Color(0xFF60758C), Color(0xFFE5EBF2), Color(0xFF2F4152)),
];

class PreviewEntry {
  const PreviewEntry(this.kind, this.value);
  final String kind;
  final String value;
}

class _EditorialPreviewState extends State<EditorialPreview> {
  int tab = 0;
  int paletteIndex = 0;
  bool dark = false;
  final entries = <PreviewEntry>[];

  PreviewPalette get p => palettes[paletteIndex];
  Color get background => dark ? const Color(0xFF1C2023) : const Color(0xFFFCF9F7);
  Color get panel => dark ? const Color(0xFF2B3034) : const Color(0xFFFFFDFB);
  Color get tone => dark ? const Color(0xFFEDEDF0) : p.ink;
  Color get muted => dark ? const Color(0xFFBCBFC2) : const Color(0xFF877F80);
  Color get soft => dark ? const Color(0xFF353A3E) : p.soft;
  Color get stroke => dark ? const Color(0xFF444C50) : const Color(0xFFEBE2E0);

  TextStyle editorial(double size, {FontWeight weight = FontWeight.w500}) =>
      TextStyle(fontFamily: 'Lora', color: tone, fontSize: size, fontWeight: weight, height: 1.18, letterSpacing: -.5);

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: hybrid ? 'Anna Lab C - Hybrid' : 'Anna Lab B - Premium',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: false,
      fontFamily: 'Manrope',
      brightness: dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: p.accent,
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
    ),
    home: Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: Stack(children: [
          Positioned.fill(child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                key: ValueKey('page-' + tab.toString()),
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 158),
                child: page(),
              ),
            ),
          )),
          Positioned(left: 0, right: 0, bottom: 0, child: navigation()),
        ]),
      ),
    ),
  );

  Widget page() {
    if (tab == 4) return settings();
    if (tab == 1) return secondary(
      title: 'Messaggi',
      intro: 'Il tuo spazio condiviso',
      kind: 'Messaggio',
      icon: Icons.chat_bubble_outline,
    );
    if (tab == 3) return secondary(
      title: 'Ricordi',
      intro: 'Le pagine da ritrovare',
      kind: 'Pensiero',
      icon: Icons.photo_library_outlined,
    );
    return home();
  }

  Widget iconButton(IconData icon, VoidCallback callback) => InkWell(
    onTap: callback,
    borderRadius: BorderRadius.circular(30),
    child: Container(
      width: 43, height: 43,
      decoration: BoxDecoration(
        color: panel, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stroke),
      ),
      child: Icon(icon, color: tone, size: 22),
    ),
  );

  Widget header() => Row(children: [
    iconButton(Icons.person_outline, () => setState(() => tab = 4)),
    Expanded(child: Column(children: [
      Text('Anna’s Diary', style: editorial(hybrid ? 21 : 23)),
      if (!hybrid)
        Container(margin: const EdgeInsets.only(top: 6), height: 1, width: 74,
            color: p.accent.withValues(alpha: .4)),
    ])),
    iconButton(Icons.search, () => ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Questa è solo una preview offline. La ricerca reale resta nell’app principale.')),
    )),
  ]);

  Widget welcome() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Buongiorno,' : hour < 18 ? 'Buon pomeriggio,' : 'Buonasera,';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(greeting + '\nAnna', style: editorial(hybrid ? 32 : 40)),
      SizedBox(height: hybrid ? 9 : 13),
      Text(
        hybrid ? 'Uno spazio tutto tuo, oggi.' :
          'Un nuovo giorno da scrivere,\nuna nuova pagina tutta tua.',
        style: TextStyle(color: muted, fontSize: hybrid ? 14 : 16, height: 1.55),
      ),
    ]);
  }

  Widget dateLine() {
    const months = ['gennaio','febbraio','marzo','aprile','maggio','giugno',
      'luglio','agosto','settembre','ottobre','novembre','dicembre'];
    final now = DateTime.now();
    return Row(children: [
      Icon(Icons.calendar_today_outlined, color: p.accent, size: 20),
      const SizedBox(width: 12),
      Text('Oggi', style: TextStyle(color: tone, fontSize: 18, fontWeight: FontWeight.w800)),
      Flexible(child: Text(
        '  ·  ' + now.day.toString() + ' ' + months[now.month - 1],
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: muted, fontSize: 14),
      )),
    ]);
  }

  Widget card(Widget child, {Color? fill, EdgeInsetsGeometry? padding}) => Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: fill ?? panel,
      borderRadius: BorderRadius.circular(23),
      border: Border.all(color: stroke.withValues(alpha: .65)),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: dark ? .17 : .035),
          blurRadius: 19, offset: const Offset(0, 7)),
      ],
    ),
    child: child,
  );

  Widget hero() => InkWell(
    key: const ValueKey('hero-write'),
    borderRadius: BorderRadius.circular(23),
    onTap: () => createEntry('Pensiero'),
    child: card(
      SizedBox(
        height: hybrid ? 165 : 205,
        child: Stack(children: [
          Positioned(
            right: -23, top: 6, bottom: 5, width: hybrid ? 110 : 139,
            child: Transform.rotate(
              angle: .13,
              child: Container(
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: .19),
                  gradient: LinearGradient(
                    colors: [p.accent.withValues(alpha: .27), p.accent.withValues(alpha: .05)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: p.ink.withValues(alpha: .12),
                    blurRadius: 16, offset: const Offset(2, 7))],
                ),
                child: Icon(Icons.auto_stories_outlined,
                    size: 59, color: p.accent.withValues(alpha: .54)),
              ),
            ),
          ),
          Positioned.fill(child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(hybrid ? 'UN PENSIERO, OGGI' : 'IL TUO SPAZIO DI OGGI',
                style: TextStyle(color: p.accent, fontSize: 10,
                  letterSpacing: 1.8, fontWeight: FontWeight.w700)),
              Text(hybrid ? 'Racconta\nil momento' : 'Il tuo spazio\ndi oggi',
                style: editorial(hybrid ? 23 : 28)),
              Text('Scrivi pensieri,\nemozioni e idee.',
                style: TextStyle(color: muted, fontSize: hybrid ? 12 : 13, height: 1.35)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(24)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Scrivi ora', style: TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                  SizedBox(width: 9),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ]),
              ),
            ],
          )),
        ]),
      ),
      fill: dark ? panel : p.soft.withValues(alpha: .63),
      padding: EdgeInsets.all(hybrid ? 17 : 23),
    ),
  );

  Widget tile(IconData icon, String title, String subtitle, VoidCallback action) => Expanded(
    child: InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(23),
      child: card(
        SizedBox(
          height: hybrid ? 130 : 151,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: p.accent, size: 25),
            const Spacer(),
            Text(title, maxLines: 2,
              style: editorial(hybrid ? 15 : 17, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(subtitle, maxLines: 2,
              style: TextStyle(color: muted, fontSize: hybrid ? 11 : 12, height: 1.3)),
          ]),
        ),
        padding: EdgeInsets.all(hybrid ? 13 : 16),
      ),
    ),
  );

  Widget tiles() => Row(children: [
    tile(Icons.spa_outlined, 'Il tuo umore', 'Come ti senti oggi?', selectMood),
    const SizedBox(width: 12),
    tile(Icons.track_changes_outlined, 'Un piccolo obiettivo',
      'Un passo alla volta.', () => createEntry('Attività')),
  ]);

  Widget quote() => card(
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('“', style: TextStyle(color: p.accent, fontFamily: 'Lora', fontSize: 43, height: 1)),
      const SizedBox(width: 10),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Text('Anche oggi è una pagina preziosa della tua storia.',
          style: TextStyle(color: tone, fontFamily: 'Lora',
            fontStyle: FontStyle.italic, fontSize: 15, height: 1.60)),
      )),
    ]),
    fill: soft.withValues(alpha: .80),
  );

  Widget dailyOverview() {
    final count = entries.where((e) => e.kind == 'Attività').length;
    return InkWell(
      onTap: () => createEntry('Attività'),
      borderRadius: BorderRadius.circular(22),
      child: card(Row(children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.event_available_outlined, color: p.accent, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('La tua giornata', style: TextStyle(
            color: tone, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(count == 0 ? 'Ancora nessuna attività nella demo' :
            count.toString() + ' attività nella demo',
            style: TextStyle(color: muted, fontSize: 11)),
        ])),
        Icon(Icons.chevron_right, color: muted),
      ])),
    );
  }

  Widget recent() {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Creati in questa prova', style: editorial(20)),
      const SizedBox(height: 12),
      for (final e in entries.reversed.take(4)) ...[
        card(Row(children: [
          Icon(e.kind == 'Attività' ? Icons.check_circle_outline : Icons.notes,
            color: p.accent),
          const SizedBox(width: 10),
          Expanded(child: Text(e.value, maxLines: 2,
            overflow: TextOverflow.ellipsis, style: TextStyle(color: tone, fontSize: 13))),
        ]), padding: const EdgeInsets.all(13)),
        const SizedBox(height: 9),
      ],
    ]);
  }

  Widget disclaimer() => Padding(
    padding: const EdgeInsets.only(top: 25),
    child: Text(
      (hybrid ? 'C · EDITORIAL HYBRID' : 'B · EDITORIAL PREMIUM') +
        '\nDesign Lab offline • non legge né modifica i dati reali.',
      textAlign: TextAlign.center,
      style: TextStyle(color: muted, fontSize: 10, height: 1.65),
    ),
  );

  Widget home() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    header(),
    SizedBox(height: hybrid ? 27 : 50),
    welcome(),
    SizedBox(height: hybrid ? 25 : 42),
    dateLine(),
    SizedBox(height: hybrid ? 21 : 28),
    if (hybrid) ...[dailyOverview(), const SizedBox(height: 17)],
    hero(),
    SizedBox(height: hybrid ? 16 : 21),
    tiles(),
    const SizedBox(height: 20),
    if (hybrid) ...[recent(), const SizedBox(height: 18)],
    quote(),
    if (!hybrid) ...[const SizedBox(height: 22), recent()],
    disclaimer(),
  ]);

  Widget secondary({
    required String title, required String intro,
    required String kind, required IconData icon,
  }) {
    final local = entries.where((e) => e.kind == kind).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      header(),
      const SizedBox(height: 42),
      Text(title, style: editorial(35)),
      const SizedBox(height: 10),
      Text(intro, style: TextStyle(color: muted, fontSize: 15)),
      const SizedBox(height: 26),
      card(local.isEmpty
        ? Column(children: [
            const SizedBox(height: 20),
            Icon(icon, size: 43, color: p.accent),
            const SizedBox(height: 19),
            Text('Ancora nessun contenuto nella demo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 14)),
            const SizedBox(height: 20),
            action('Crea contenuto', () => createEntry(kind)),
            const SizedBox(height: 20),
          ])
        : Column(children: [
            for (final e in local) ...[
              Align(alignment: Alignment.centerLeft,
                child: Text(e.value, style: TextStyle(color: tone, fontSize: 14))),
              const Divider(height: 22),
            ],
            action('Aggiungi', () => createEntry(kind)),
          ])),
      disclaimer(),
    ]);
  }

  Widget action(String label, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 13),
      decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(24)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    ),
  );

  Widget settings() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    header(),
    const SizedBox(height: 42),
    Text('Personalizza la prova', style: editorial(30)),
    const SizedBox(height: 10),
    Text('La struttura resta premium anche senza il rosa.',
      style: TextStyle(color: muted, fontSize: 14)),
    const SizedBox(height: 24),
    card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Palette', style: TextStyle(color: tone, fontWeight: FontWeight.w700)),
      const SizedBox(height: 13),
      Row(children: List.generate(3, (i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 7),
          child: InkWell(
            key: ValueKey('palette-' + i.toString()),
            onTap: () => setState(() => paletteIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: paletteIndex == i ? soft : panel,
                border: Border.all(color: paletteIndex == i ? p.accent : stroke),
              ),
              child: Column(children: [
                CircleAvatar(radius: 13, backgroundColor: palettes[i].accent),
                const SizedBox(height: 7),
                Text(palettes[i].title, style: TextStyle(color: tone, fontSize: 11)),
              ]),
            ),
          ),
        ),
      ))),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(child: Text('Tema scuro',
          style: TextStyle(color: tone, fontWeight: FontWeight.w700))),
        Switch(
          key: const ValueKey('dark-theme'),
          activeColor: p.accent,
          value: dark, onChanged: (v) => setState(() => dark = v),
        ),
      ]),
    ])),
    const SizedBox(height: 20),
    card(Text(
      'App di confronto isolata: nessun login, Firebase, Supabase o dati condivisi. '
      'Gli elementi che crei qui servono solo a provare i controlli e vengono '
      'scartati alla chiusura dell’app.',
      style: TextStyle(color: muted, fontSize: 13, height: 1.65),
    )),
    disclaimer(),
  ]);

  Widget navigation() {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SizedBox(
          height: 110 + inset,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              top: 27, left: 8, right: 8, bottom: inset + 8,
              child: Container(
                decoration: BoxDecoration(
                  color: dark ? const Color(0xF234383D) : const Color(0xFDFDF9F8),
                  borderRadius: BorderRadius.circular(hybrid ? 26 : 35),
                  border: Border.all(color: dark ? stroke : Colors.white, width: 1.1),
                  boxShadow: [
                    BoxShadow(color: p.ink.withValues(alpha: dark ? .22 : .10),
                      blurRadius: hybrid ? 19 : 29, offset: const Offset(0, 7)),
                  ],
                ),
                child: Row(children: [
                  navItem(0, 'Oggi', Icons.calendar_today_outlined),
                  navItem(1, 'Messaggi', Icons.chat_bubble_outline),
                  const Expanded(child: SizedBox()), // True 5th slot for Create.
                  navItem(3, 'Ricordi', Icons.photo_library_outlined),
                  navItem(4, 'Altro', Icons.more_horiz),
                ]),
              ),
            ),
            Positioned(top: 0, left: 0, right: 0,
              child: Center(
                child: InkWell(
                  key: const ValueKey('nav-create'),
                  onTap: createMenu,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 74, height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        p.accent.withValues(alpha: .81), p.accent,
                      ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      border: Border.all(color: panel, width: 5),
                      boxShadow: [BoxShadow(color: p.accent.withValues(alpha: .30),
                        blurRadius: 17, offset: const Offset(0, 6))],
                    ),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add, color: Colors.white, size: 26),
                      Text('Crea', style: TextStyle(color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget navItem(int id, String name, IconData icon) => Expanded(
    child: Semantics(
      button: true, selected: tab == id, label: name,
      child: InkWell(
        key: ValueKey('nav-' + id.toString()),
        borderRadius: BorderRadius.circular(25),
        onTap: () => setState(() => tab = id),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          decoration: BoxDecoration(
            color: tab == id ? soft.withValues(alpha: .92) : Colors.transparent,
            borderRadius: BorderRadius.circular(hybrid ? 16 : 23),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: tab == id ? p.accent : muted, size: 22),
            const SizedBox(height: 5),
            FittedBox(fit: BoxFit.scaleDown,
              child: Text(name, maxLines: 1, style: TextStyle(
                color: tab == id ? tone : muted, fontSize: 11,
                fontWeight: tab == id ? FontWeight.w800 : FontWeight.w600))),
          ]),
        ),
      ),
    ),
  );

  Future<void> createMenu() async {
    final kind = await showModalBottomSheet<String>(
      context: context, backgroundColor: panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Crea qualcosa', style: editorial(24)),
            const SizedBox(height: 13),
            for (final choice in <String>['Pensiero', 'Attività', 'Appuntamento'])
              ListTile(
                title: Text(choice, style: TextStyle(color: tone)),
                leading: Icon(choice == 'Pensiero' ? Icons.edit_note :
                  choice == 'Attività' ? Icons.check_circle_outline :
                    Icons.event_outlined, color: p.accent),
                onTap: () => Navigator.pop(sheet, choice),
              ),
          ]),
        ),
      ),
    );
    if (mounted && kind != null) await createEntry(kind);
  }

  Future<void> createEntry(String kind) async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true, backgroundColor: panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(21, 23, 21,
          24 + MediaQuery.viewInsetsOf(sheet).bottom),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Nuovo ' + kind.toLowerCase(), style: editorial(23)),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('entry-input'),
              controller: controller, autofocus: true, maxLines: 3, minLines: 2,
              style: TextStyle(color: tone),
              decoration: InputDecoration(
                hintText: 'Scrivi qualcosa per provare…',
                hintStyle: TextStyle(color: muted),
                filled: true, fillColor: soft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 17),
            ElevatedButton(
              key: const ValueKey('entry-save'),
              onPressed: () => Navigator.pop(sheet, controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.accent, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 15)),
              child: const Text('Aggiungi alla demo'),
            ),
          ]),
        ),
      ),
    );
    controller.dispose();
    if (mounted && value != null && value.isNotEmpty) {
      setState(() { entries.add(PreviewEntry(kind, value)); tab = 0; });
    }
  }

  Future<void> selectMood() async {
    final value = await showModalBottomSheet<String>(
      context: context, backgroundColor: panel,
      builder: (sheet) => SafeArea(child: Column(
        mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 17),
          Text('Come ti senti?', style: editorial(24)),
          for (final mood in <String>['Serena', 'Felice', 'Stanca', 'Riflessiva'])
            ListTile(title: Text(mood, style: TextStyle(color: tone)),
              onTap: () => Navigator.pop(sheet, mood)),
          const SizedBox(height: 12),
        ],
      )),
    );
    if (mounted && value != null) setState(() => entries.add(PreviewEntry('Umore', value)));
  }
}
