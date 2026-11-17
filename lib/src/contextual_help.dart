
part of '../main.dart';

/// On-demand education, separate from first-run onboarding, capture writers,
/// privacy permissions, local settings, cloud, and personal content.
enum AnnaContextHelpSection { create, sharedHub, sharedSpace, memories, more }

class AnnaContextHelpTopic {
  const AnnaContextHelpTopic({
    required this.id,
    required this.icon,
    required this.title,
  });

  final String id;
  final IconData icon;
  final String title;
}

// Topic IDs intentionally match the actual canonical Unified Capture actions.
// Additional sections are small, stable top-level guides; nested routes follow
// in a future bounded step and must not silently expose hidden modules.
const Map<AnnaContextHelpSection, List<String>> _annaContextHelpSections = {
  AnnaContextHelpSection.sharedHub: [
    'hubSpaces', 'hubInvite', 'hubJoin', 'hubAvatar', 'hubSync',
  ],
  AnnaContextHelpSection.sharedSpace: [
    'spaceCreate', 'spaceInteractions', 'spaceMembers', 'spaceMemories',
    'spaceUtilities', 'spacePrivacy',
  ],
  AnnaContextHelpSection.memories: [
    'memoriesForYou', 'memoriesTimeline', 'memoriesBrowse',
    'memoriesFind', 'memoriesOrganize',
  ],
  AnnaContextHelpSection.more: [
    'moreSearch', 'moreInbox', 'moreExplore',
    'moreVault', 'moreData', 'moreSettings',
  ],
};

const Map<String, IconData> _annaContextHelpIcons = {
  'date': Icons.event_available_outlined,
  'text': Icons.edit_note_outlined,
  'photo': Icons.photo_camera_back_outlined,
  'task': Icons.check_circle_outline,
  'taskFromText': Icons.auto_awesome_motion_outlined,
  'checklistFromNote': Icons.playlist_add_check_outlined,
  'voice': Icons.mic_none_outlined,
  'sketch': Icons.draw_outlined,
  'visionBoard': Icons.dashboard_customize_outlined,
  'inbox': Icons.inbox_outlined,
  'event': Icons.event_outlined,
  'birthday': Icons.cake_outlined,
  'person': Icons.person_add_alt_1_outlined,
  'templates': Icons.library_books_outlined,
  'hubSpaces': Icons.groups_outlined,
  'hubInvite': Icons.person_add_alt_1_outlined,
  'hubJoin': Icons.qr_code_scanner_outlined,
  'hubAvatar': Icons.photo_camera_outlined,
  'hubSync': Icons.sync_outlined,
  'spaceCreate': Icons.add_circle_outline,
  'spaceInteractions': Icons.favorite_border,
  'spaceMembers': Icons.group_outlined,
  'spaceMemories': Icons.photo_library_outlined,
  'spaceUtilities': Icons.shopping_cart_outlined,
  'spacePrivacy': Icons.lock_outline,
  'memoriesForYou': Icons.auto_awesome_outlined,
  'memoriesTimeline': Icons.view_stream_outlined,
  'memoriesBrowse': Icons.calendar_month_outlined,
  'memoriesFind': Icons.search_outlined,
  'memoriesOrganize': Icons.collections_bookmark_outlined,
  'moreSearch': Icons.search,
  'moreInbox': Icons.inbox_outlined,
  'moreExplore': Icons.apps_outlined,
  'moreVault': Icons.lock_person_outlined,
  'moreData': Icons.backup_outlined,
  'moreSettings': Icons.settings_outlined,
};

const Map<String, Map<String, List<String>>> _annaContextHelpArticles = {
  // TOPIC_ENTRIES
};

const Map<String, Map<AnnaContextHelpSection, List<String>>>
    _annaContextHelpHeaders = {
    'it': {
    AnnaContextHelpSection.create: ["Guida a Crea+", "SCEGLI COSA CONSERVARE", "Dalla nota veloce alla vision board: apri ogni voce per conoscere passaggi, risultati e limiti."],
    AnnaContextHelpSection.sharedHub: ["Guida allo Spazio condiviso", "NOI, INSIEME", "Crea e gestisci spazi, invita persone e controlla cosa viene sincronizzato."],
    AnnaContextHelpSection.sharedSpace: ["Guida a questo spazio", "CONTENUTI CONDIVISI", "Scopri come aggiungere contenuti, gestire le interazioni e proteggere i dati."],
    AnnaContextHelpSection.memories: ["Guida ai Ricordi", "IL TUO DIARIO NEL TEMPO", "Ritrova momenti importanti, esplora la cronologia e organizza ciò che hai conservato."],
    AnnaContextHelpSection.more: ["Guida ad Altro", "TUTTO AL SUO POSTO", "Questa schermata raccoglie strumenti, impostazioni e funzioni accessorie."],
  },
  'en': {
    AnnaContextHelpSection.create: ["Create+ guide", "CHOOSE WHAT TO KEEP", "From a quick note to a vision board: open each topic for steps, outcomes and limits."],
    AnnaContextHelpSection.sharedHub: ["Shared spaces guide", "TOGETHER", "Create spaces, invite people and understand what is synced."],
    AnnaContextHelpSection.sharedSpace: ["This space guide", "SHARED CONTENT", "Learn to add items, manage interactions and protect your data."],
    AnnaContextHelpSection.memories: ["Memories guide", "YOUR DIARY OVER TIME", "Find important moments, explore the timeline and organize what you kept."],
    AnnaContextHelpSection.more: ["More guide", "EVERYTHING IN ITS PLACE", "Find tools, settings and supporting features on this page."],
  },
  'es': {
    AnnaContextHelpSection.create: ["Guía de Crea+", "ELIGE QUÉ GUARDAR", "De notas rápidas a tableros de visión: consulta los pasos y sus límites."],
    AnnaContextHelpSection.sharedHub: ["Guía de espacio compartido", "JUNTOS", "Crea espacios, invita a otros y controla la sincronización."],
    AnnaContextHelpSection.sharedSpace: ["Guía de este espacio", "CONTENIDO COMPARTIDO", "Aprende a añadir contenido, gestionar interacciones y proteger datos."],
    AnnaContextHelpSection.memories: ["Guía de recuerdos", "TU DIARIO CON EL TIEMPO", "Encuentra momentos, explora la cronología y organiza recuerdos."],
    AnnaContextHelpSection.more: ["Guía de Más", "TODO EN SU SITIO", "Encuentra herramientas, ajustes y funciones adicionales."],
  },
  'fr': {
    AnnaContextHelpSection.create: ["Guide Créer+", "CHOISIS QUOI GARDER", "De la note rapide au tableau de vision : étapes, résultats et limites."],
    AnnaContextHelpSection.sharedHub: ["Guide des espaces partagés", "ENSEMBLE", "Crée des espaces, invite des membres et comprends la synchronisation."],
    AnnaContextHelpSection.sharedSpace: ["Guide de cet espace", "CONTENU PARTAGÉ", "Ajoute du contenu, gère les interactions et protège tes données."],
    AnnaContextHelpSection.memories: ["Guide des souvenirs", "TON JOURNAL AU FIL DU TEMPS", "Retrouve tes moments, explore la chronologie et organise tes souvenirs."],
    AnnaContextHelpSection.more: ["Guide Autre", "TOUT À SA PLACE", "Retrouve outils, réglages et fonctionnalités complémentaires."],
  },
  'pt': {
    AnnaContextHelpSection.create: ["Guia Criar+", "ESCOLHE O QUE GUARDAR", "De notas rápidas a quadros de visão: passos, resultados e limites."],
    AnnaContextHelpSection.sharedHub: ["Guia dos espaços partilhados", "JUNTOS", "Cria espaços, convida pessoas e compreende a sincronização."],
    AnnaContextHelpSection.sharedSpace: ["Guia deste espaço", "CONTEÚDO PARTILHADO", "Adiciona conteúdos, gere interações e protege os teus dados."],
    AnnaContextHelpSection.memories: ["Guia das memórias", "O TEU DIÁRIO NO TEMPO", "Encontra momentos, percorre a cronologia e organiza memórias."],
    AnnaContextHelpSection.more: ["Guia Mais", "TUDO NO SEU LUGAR", "Encontra ferramentas, definições e funcionalidades adicionais."],
  },
};

const Map<String, Map<String, String>> _annaContextHelpUi = {
    'it': {"button": "Apri la guida a questa schermata", "step": "Passaggi", "tip": "Da sapere", "footer": "Le guide spiegano le funzioni: non salvano né modificano contenuti.", "close": "Chiudi"},
  'en': {"button": "Open this screen's guide", "step": "Steps", "tip": "Good to know", "footer": "Guides explain features; they do not save or change your content.", "close": "Close"},
  'es': {"button": "Abrir la guía de esta pantalla", "step": "Pasos", "tip": "Importante", "footer": "Las guías explican funciones; no guardan ni modifican contenido.", "close": "Cerrar"},
  'fr': {"button": "Ouvrir le guide de cet écran", "step": "Étapes", "tip": "À savoir", "footer": "Les guides expliquent les fonctions sans modifier tes contenus.", "close": "Fermer"},
  'pt': {"button": "Abrir o guia deste ecrã", "step": "Passos", "tip": "A saber", "footer": "Os guias explicam as funções; não alteram nem guardam conteúdo.", "close": "Fechar"},
};

String _annaHelpLanguage(String value) =>
    _annaContextHelpArticles.containsKey(value) ? value : 'en';

List<String> _annaHelpArticle(String language, String id) =>
    _annaContextHelpArticles[_annaHelpLanguage(language)]?[id] ??
    _annaContextHelpArticles['en']![id]!;

String _annaHelpUi(String language, String id) =>
    _annaContextHelpUi[_annaHelpLanguage(language)]?[id] ??
    _annaContextHelpUi['en']![id]!;

class AnnaContextHelpButton extends StatelessWidget {
  const AnnaContextHelpButton({
    super.key,
    required this.section,
    this.captureActions = const <AnnaContextHelpTopic>[],
  });

  final AnnaContextHelpSection section;
  final List<AnnaContextHelpTopic> captureActions;

  @override
  Widget build(BuildContext context) => IconButton(
    key: ValueKey<String>('context-help-${section.name}'),
    tooltip: _annaHelpUi(AnnaStrings.of(context).languageCode, 'button'),
    icon: const Icon(Icons.info_outline_rounded),
    onPressed: () => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AnnaContextHelpScreen(
          section: section,
          captureActions: captureActions,
        ),
      ),
    ),
  );
}

class AnnaContextHelpScreen extends StatefulWidget {
  const AnnaContextHelpScreen({
    super.key,
    required this.section,
    this.captureActions = const <AnnaContextHelpTopic>[],
  });

  final AnnaContextHelpSection section;
  final List<AnnaContextHelpTopic> captureActions;

  @override
  State<AnnaContextHelpScreen> createState() => _AnnaContextHelpScreenState();
}

class _AnnaContextHelpScreenState extends State<AnnaContextHelpScreen> {
  String? _expanded;

  List<AnnaContextHelpTopic> _visibleTopics(String language) {
    if (widget.section == AnnaContextHelpSection.create) {
      // A hidden Vision Board (or any future disabled action) is not
      // advertised as available. The selected date is always explained.
      return <AnnaContextHelpTopic>[
        AnnaContextHelpTopic(
          id: 'date',
          icon: Icons.event_available_outlined,
          title: _annaHelpArticle(language, 'date')[0],
        ),
        ...widget.captureActions,
      ];
    }
    return <AnnaContextHelpTopic>[
      for (final id in _annaContextHelpSections[widget.section]!)
        AnnaContextHelpTopic(
          id: id,
          icon: _annaContextHelpIcons[id]!,
          title: _annaHelpArticle(language, id)[0],
        ),
    ];
  }

  Widget _article(
    BuildContext context,
    AnnaContextHelpTopic topic,
    List<String> copy,
    bool organic,
  ) {
    final ink = AnnaEditorialColors.of(context).ink;
    final muted = AnnaEditorialColors.of(context).mutedInk;
    final expanded = _expanded == topic.id;
    final lang = AnnaStrings.of(context).languageCode;
    final contents = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          identifier: 'context-help-topic-${topic.id}',
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(
              () => _expanded = expanded ? null : topic.id,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 13,
              ),
              child: Row(
                children: [
                  Icon(topic.icon, color: AnnaEditorialColors.of(context).accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: organic
                          ? AnnaJournalTypography.editorial(context, size: 18)
                          : Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(copy[1], style: TextStyle(color: ink, height: 1.5)),
                const SizedBox(height: 15),
                Text(
                  _annaHelpUi(lang, 'step'),
                  style: TextStyle(
                    color: muted, fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 9),
                for (var index = 2; index <= 3; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AnnaEditorialColors.of(context).quiet,
                          child: Text(
                            '${index - 1}',
                            style: TextStyle(fontSize: 12, color: ink),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            copy[index],
                            style: TextStyle(color: ink, height: 1.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (copy[4].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: muted, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${_annaHelpUi(lang, 'tip')}: ${copy[4]}',
                            style: TextStyle(color: muted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: organic
          ? AnnaOrganicPaperSurface(padding: EdgeInsets.zero, child: contents)
          : Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: contents,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = _annaHelpLanguage(AnnaStrings.of(context).languageCode);
    final header = _annaContextHelpHeaders[language]![widget.section]!;
    final topics = _visibleTopics(language);
    final organic = AnnaOrganicPastel.enabled(context);
    final palette = AnnaEditorialColors.of(context);
    final expanded = _expanded ?? (topics.isEmpty ? null : topics.first.id);
    if (_expanded == null && expanded != null) {
      // Only the initial state is expanded. No persistence or mutations.
      _expanded = expanded;
    }
    return Scaffold(
      backgroundColor: organic ? palette.canvas : null,
      appBar: AppBar(
        title: Text(
          header[0],
          style: organic
              ? AnnaJournalTypography.editorial(context, size: 22)
              : null,
        ),
        backgroundColor: organic ? palette.canvas : null,
        surfaceTintColor: organic ? Colors.transparent : null,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: ValueKey<String>('context-help-page-${widget.section.name}'),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                AnnaEditorialHeader(
                  eyebrow: header[1],
                  title: header[0],
                  subtitle: header[2],
                ),
                const SizedBox(height: 20),
                for (final topic in topics)
                  _article(
                    context,
                    topic,
                    _annaHelpArticle(language, topic.id),
                    organic,
                  ),
                const SizedBox(height: 10),
                Text(
                  _annaHelpUi(language, 'footer'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.mutedInk),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
