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

List<DiaryTemplatePreset> diaryTemplatePresetsFor(AnnaStrings strings) =>
    <DiaryTemplatePreset>[
      DiaryTemplatePreset(
        id: 'morning',
        title: strings.d3('templateMorningTitle'),
        description: strings.d3('templateMorningDesc'),
        seedText: strings.d3('templateMorningSeed'),
        tags: ['routine', strings.d3('templateMorningTitle').toLowerCase()],
      ),
      DiaryTemplatePreset(
        id: 'evening',
        title: strings.d3('templateEveningTitle'),
        description: strings.d3('templateEveningDesc'),
        seedText: strings.d3('templateEveningSeed'),
        tags: ['routine', strings.d3('templateEveningTitle').toLowerCase()],
      ),
      DiaryTemplatePreset(
        id: 'gratitude',
        title: strings.d3('templateGratitudeTitle'),
        description: strings.d3('templateGratitudeDesc'),
        seedText: strings.d3('templateGratitudeSeed'),
        tags: [strings.d3('templateGratitudeTitle').toLowerCase()],
      ),
      DiaryTemplatePreset(
        id: 'travel',
        title: strings.d3('templateTravelTitle'),
        description: strings.d3('templateTravelDesc'),
        seedText: strings.d3('templateTravelSeed'),
        tags: [strings.d3('templateTravelTitle').toLowerCase()],
        mediaHint: strings.d3('templateTravelMedia'),
      ),
      DiaryTemplatePreset(
        id: 'special_day',
        title: strings.d3('templateSpecialTitle'),
        description: strings.d3('templateSpecialDesc'),
        seedText: strings.d3('templateSpecialSeed'),
        tags: [strings.d3('templateSpecialTitle').toLowerCase()],
        mediaHint: strings.d3('templateSpecialMedia'),
      ),
      DiaryTemplatePreset(
        id: 'reflection',
        title: strings.d3('templateReflectionTitle'),
        description: strings.d3('templateReflectionDesc'),
        seedText: strings.d3('templateReflectionSeed'),
        tags: [strings.d3('templateReflectionTitle').toLowerCase()],
      ),
    ];

List<DiaryTemplatePreset> get diaryTemplatePresets =>
    diaryTemplatePresetsFor(const AnnaStrings('en'));
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
          ListTile(
            title: Text(
              AnnaStrings.of(sheetContext).d3('templatePickerTitle'),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
            ),
            subtitle: Text(
              AnnaStrings.of(sheetContext).d3('templatePickerSubtitle'),
            ),
          ),
          ...diaryTemplatePresetsFor(AnnaStrings.of(sheetContext)).map(
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
