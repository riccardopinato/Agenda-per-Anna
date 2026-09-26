part of '../../main.dart';

class DiaryTemplatePreset {
  final String id;
  final String title;
  final String description;
  final String seedText;
  final List<String> tags;
  final String mediaHint;

  const DiaryTemplatePreset({
    required this.id,
    required this.title,
    required this.description,
    required this.seedText,
    this.tags = const [],
    this.mediaHint = '',
  });

  IconData get icon => switch (id) {
        'morning' => Icons.wb_sunny_outlined,
        'evening' => Icons.nightlight_outlined,
        'gratitude' => Icons.favorite_outline,
        'travel' => Icons.luggage_outlined,
        'special_day' => Icons.celebration_outlined,
        'reflection' => Icons.self_improvement_outlined,
        _ => Icons.auto_stories_outlined,
      };
}

const diaryTemplatePresets = <DiaryTemplatePreset>[
  DiaryTemplatePreset(
    id: 'morning',
    title: 'Mattino',
    description: 'Intenzione, energia e priorità della giornata.',
    seedText: 'Routine del mattino\n\n'
        '☐ Come mi sento adesso?\n'
        '☐ Cosa voglio proteggere oggi?\n'
        '☐ La cosa più importante da fare\n'
        '☐ Un gesto gentile verso di me\n\n'
        'Spazio libero:',
    tags: ['routine', 'mattino'],
  ),
  DiaryTemplatePreset(
    id: 'evening',
    title: 'Sera',
    description: 'Chiudi la giornata e lascia andare ciò che non serve.',
    seedText: 'Routine della sera\n\n'
        '☐ La cosa migliore di oggi\n'
        '☐ Cosa mi ha stancato?\n'
        '☐ Cosa ho imparato?\n'
        '☐ Cosa voglio ricordare domani?\n\n'
        'Pensiero finale:',
    tags: ['routine', 'sera'],
  ),
  DiaryTemplatePreset(
    id: 'gratitude',
    title: 'Gratitudine',
    description: 'Tre cose concrete da conservare della giornata.',
    seedText: 'Gratitudine\n\n'
        '♡ 1. \n'
        '♡ 2. \n'
        '♡ 3. \n\n'
        'Perché una di queste cose è stata importante per me:',
    tags: ['gratitudine'],
  ),
  DiaryTemplatePreset(
    id: 'travel',
    title: 'Viaggio',
    description: 'Luoghi, momenti, dettagli e ricordi da non perdere.',
    seedText: 'Diario di viaggio\n\n'
        '☐ Dove sono stato/a?\n'
        '☐ Il momento più bello\n'
        '☐ Una cosa che mi ha sorpreso\n'
        '☐ Un posto o sapore da ricordare\n'
        '☐ Cosa rifarei domani?\n\n'
        'Appunti:',
    tags: ['viaggio'],
    mediaHint: 'Aggiungi foto o una nota vocale per completare il ricordo.',
  ),
  DiaryTemplatePreset(
    id: 'special_day',
    title: 'Giorno speciale',
    description: 'Per compleanni, anniversari e giornate importanti.',
    seedText: 'Giorno speciale\n\n'
        '☐ Perché oggi è importante?\n'
        '☐ Con chi ero?\n'
        '☐ Il momento che voglio ricordare\n'
        '☐ Una frase o un dettaglio da conservare\n\n'
        'Come mi sono sentito/a:',
    tags: ['giorno-speciale'],
    mediaHint: 'Foto e voce restano disponibili nello stesso diario.',
  ),
  DiaryTemplatePreset(
    id: 'reflection',
    title: 'Riflessione',
    description: 'Uno spazio più profondo per mettere ordine nei pensieri.',
    seedText: 'Riflessione\n\n'
        'Cosa è successo?\n\n'
        'Cosa ho provato?\n\n'
        'Di cosa avevo bisogno?\n\n'
        'Cosa posso portare con me da questa esperienza?\n\n'
        'Un piccolo passo concreto:',
    tags: ['riflessione'],
  ),
];

extension DiaryTemplatesAgendaStore on AgendaStore {
  Future<DiaryBlock> applyDiaryTemplate(
    DateTime date,
    DiaryTemplatePreset preset, {
    DateTime? createdAt,
  }) async {
    final now = createdAt ?? DateTime.now();
    final block = DiaryBlock(
      id: const Uuid().v4(),
      type: DiaryBlockType.note,
      createdAt: now,
      text: preset.seedText,
      tags: normalizeOrganizationTags(preset.tags),
    );
    final current = journal(date);
    await saveJournal(
      date,
      current.copyWith(blocks: [...current.blocks, block]),
    );
    return block;
  }
}

Future<DiaryTemplatePreset?> showDiaryTemplatePicker(
  BuildContext context,
) {
  return showModalBottomSheet<DiaryTemplatePreset>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
        children: [
          const ListTile(
            title: Text(
              'Modelli di diario',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            subtitle: Text(
              'Inseriscono una traccia modificabile. Foto, voce, sketch, tag e persone restano disponibili normalmente.',
            ),
          ),
          ...diaryTemplatePresets.map(
            (preset) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(preset.icon)),
                title: Text(
                  preset.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  [
                    preset.description,
                    if (preset.mediaHint.isNotEmpty) preset.mediaHint,
                  ].join(' '),
                ),
                trailing: const Icon(Icons.add),
                onTap: () => Navigator.pop(sheetContext, preset),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
