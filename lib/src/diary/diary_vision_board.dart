part of '../../main.dart';

/// S11-B: private personal Vision Board foundation on the existing Sketchbook.
/// Presets contain only original geometric frames; no third-party images,
/// quotes, personal goals, cloud providers, new editor, or persistence layer.
class VisionBoardFrame {
  const VisionBoardFrame(this.x, this.y, this.width, this.height);

  final double x;
  final double y;
  final double width;
  final double height;

  bool get isValid => x >= 0 && y >= 0 && width > 0 && height > 0 &&
      x + width <= 1.000001 && y + height <= 1.000001;
}

class VisionBoardPreset {
  const VisionBoardPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.frames,
    this.paper = DiarySketchPaper.plain,
  });

  final String id;
  final String title;
  final String description;
  final List<VisionBoardFrame> frames;
  final DiarySketchPaper paper;

  IconData get icon => switch (id) {
        'dreams' => Icons.auto_awesome_outlined,
        'journeys' => Icons.flight_takeoff_outlined,
        'home' => Icons.home_outlined,
        'together' => Icons.favorite_border,
        'goals' => Icons.flag_outlined,
        _ => Icons.crop_portrait_outlined,
      };

  DiarySketchPage createPage({required String pageId}) {
    if (frames.any((frame) => !frame.isValid)) {
      throw const FormatException('Invalid vision board layout');
    }
    final frameColor = switch (id) {
      'dreams' => 0xFFE7A8BA,
      'journeys' => 0xFFA7BFC9,
      'home' => 0xFFCAA990,
      'together' => 0xFFE6A8B2,
      'goals' => 0xFFA6B6A0,
      _ => 0xFFB7A5BC,
    };
    return DiarySketchPage(
      id: pageId,
      paper: paper,
      strokes: [
        for (final frame in frames)
          DiarySketchStroke(
            tool: DiarySketchTool.rectangle,
            colorValue: frameColor,
            width: 2,
            points: [
              DiarySketchPoint(frame.x, frame.y),
              DiarySketchPoint(
                frame.x + frame.width, frame.y + frame.height,
              ),
            ],
          ),
      ],
    );
  }
}

/// Original, language-complete templates. IDs and geometry never depend on
/// locale; each page starts with empty visual frames (not user media).
List<VisionBoardPreset> visionBoardPresetsFor(AnnaStrings strings) {
  String copy({
    required String en,
    required String it,
    required String es,
    required String fr,
    required String pt,
  }) => switch (strings.languageCode) {
        'it' => it,
        'es' => es,
        'fr' => fr,
        'pt' => pt,
        _ => en,
      };

  return [
    VisionBoardPreset(
      id: 'blank',
      title: copy(en: 'Blank canvas', it: 'Tela vuota',
          es: 'Lienzo vacío', fr: 'Toile vierge', pt: 'Tela em branco'),
      description: copy(en: 'Start with an empty personal page',
          it: 'Inizia con una pagina personale vuota',
          es: 'Empieza con una página personal vacía',
          fr: 'Commencez avec une page personnelle vierge',
          pt: 'Comece com uma página pessoal vazia'),
      frames: const [],
    ),
    VisionBoardPreset(
      id: 'dreams',
      title: copy(en: 'My dreams', it: 'I miei sogni',
          es: 'Mis sueños', fr: 'Mes rêves', pt: 'Os meus sonhos'),
      description: copy(en: 'Three spaces for future inspirations',
          it: 'Tre spazi per ispirazioni future',
          es: 'Tres espacios para inspiraciones futuras',
          fr: 'Trois espaces pour les inspirations futures',
          pt: 'Três espaços para inspirações futuras'),
      frames: const [
        VisionBoardFrame(0.08, 0.10, 0.38, 0.36),
        VisionBoardFrame(0.54, 0.10, 0.38, 0.36),
        VisionBoardFrame(0.08, 0.54, 0.84, 0.36),
      ],
    ),
    VisionBoardPreset(
      id: 'journeys',
      title: copy(en: 'Places to discover', it: 'Luoghi da scoprire',
          es: 'Lugares por descubrir', fr: 'Lieux à découvrir',
          pt: 'Lugares a descobrir'),
      description: copy(en: 'One panoramic and two portrait spaces',
          it: 'Uno spazio panoramico e due verticali',
          es: 'Un espacio panorámico y dos verticales',
          fr: 'Un espace panoramique et deux portraits',
          pt: 'Um espaço panorâmico e dois verticais'),
      frames: const [
        VisionBoardFrame(0.08, 0.10, 0.84, 0.32),
        VisionBoardFrame(0.08, 0.50, 0.38, 0.40),
        VisionBoardFrame(0.54, 0.50, 0.38, 0.40),
      ],
    ),
    VisionBoardPreset(
      id: 'home',
      title: copy(en: 'A place of my own', it: 'Un posto tutto mio',
          es: 'Un lugar propio', fr: 'Un lieu à moi',
          pt: 'Um lugar só meu'),
      description: copy(en: 'A calm frame for a future home',
          it: 'Una cornice semplice per una casa futura',
          es: 'Un marco sereno para un futuro hogar',
          fr: 'Un cadre doux pour un futur chez-soi',
          pt: 'Uma moldura serena para uma futura casa'),
      frames: const [
        VisionBoardFrame(0.10, 0.14, 0.80, 0.66),
      ],
    ),
    VisionBoardPreset(
      id: 'together',
      title: copy(en: 'Moments together', it: 'Momenti insieme',
          es: 'Momentos juntos', fr: 'Moments ensemble',
          pt: 'Momentos juntos'),
      description: copy(en: 'Spaces for memories and shared wishes',
          it: 'Spazi per ricordi e desideri condivisi',
          es: 'Espacios para recuerdos y deseos compartidos',
          fr: 'Espaces pour souvenirs et souhaits partagés',
          pt: 'Espaços para memórias e desejos partilhados'),
      frames: const [
        VisionBoardFrame(0.08, 0.12, 0.84, 0.34),
        VisionBoardFrame(0.08, 0.54, 0.38, 0.34),
        VisionBoardFrame(0.54, 0.54, 0.38, 0.34),
      ],
    ),
    VisionBoardPreset(
      id: 'goals',
      title: copy(en: 'Small steps, big dreams',
          it: 'Piccoli passi, grandi sogni',
          es: 'Pequeños pasos, grandes sueños',
          fr: 'Petits pas, grands rêves',
          pt: 'Pequenos passos, grandes sonhos'),
      description: copy(en: 'Four empty spaces for personal intentions',
          it: 'Quattro spazi vuoti per intenzioni personali',
          es: 'Cuatro espacios vacíos para intenciones personales',
          fr: 'Quatre espaces vides pour les intentions personnelles',
          pt: 'Quatro espaços vazios para intenções pessoais'),
      frames: const [
        VisionBoardFrame(0.08, 0.10, 0.38, 0.36),
        VisionBoardFrame(0.54, 0.10, 0.38, 0.36),
        VisionBoardFrame(0.08, 0.54, 0.38, 0.36),
        VisionBoardFrame(0.54, 0.54, 0.38, 0.36),
      ],
    ),
  ];
}

abstract final class VisionBoardFoundation {
  /// Create only an in-memory draft; showing a picker never writes data.
  static DiaryBlock draft(
    VisionBoardPreset preset, {
    required DateTime createdAt,
    String? title,
  }) {
    final chosenTitle = (title ?? preset.title).trim();
    if (chosenTitle.isEmpty || chosenTitle.length > 120) {
      throw const FormatException('Invalid vision board title');
    }
    return DiaryBlock(
      id: const Uuid().v4(),
      type: DiaryBlockType.sketch,
      creativeSubtype: DiaryCreativeSubtype.visionBoard,
      createdAt: createdAt,
      text: chosenTitle,
      pages: [preset.createPage(pageId: const Uuid().v4())],
    );
  }

  /// Duplicate content with fresh identities. Media *references* remain
  /// canonical, while private people/memory links are not copied implicitly.
  static DiaryBlock duplicate(DiaryBlock source, {required DateTime createdAt}) {
    if (!source.isPersonalVisionBoard) {
      throw ArgumentError.value(source.type, 'source', 'Not a vision board');
    }
    if (source.pages.isEmpty || source.pages.length > 64) {
      throw const FormatException('Invalid vision board page count');
    }
    return DiaryBlock(
      id: const Uuid().v4(),
      type: DiaryBlockType.sketch,
      creativeSubtype: DiaryCreativeSubtype.visionBoard,
      createdAt: createdAt,
      text: source.text,
      tags: List<String>.of(source.tags),
      pages: [
        for (final page in source.pages)
          DiarySketchPage(
            id: const Uuid().v4(),
            paper: page.paper,
            strokes: [
              for (final stroke in page.strokes)
                DiarySketchStroke(
                  tool: stroke.tool,
                  colorValue: stroke.colorValue,
                  width: stroke.width,
                  points: [
                    for (final point in stroke.points)
                      DiarySketchPoint(point.x, point.y),
                  ],
                ),
            ],
            textElements: [
              for (final element in page.textElements)
                DiarySketchTextElement(
                  id: const Uuid().v4(),
                  text: element.text,
                  x: element.x, y: element.y,
                  fontSize: element.fontSize,
                  colorValue: element.colorValue,
                ),
            ],
            imageElements: [
              for (final element in page.imageElements)
                DiarySketchImageElement(
                  id: const Uuid().v4(),
                  mediaAssetId: element.mediaAssetId,
                  imageBase64: element.imageBase64,
                  x: element.x, y: element.y,
                  width: element.width, height: element.height,
                ),
            ],
          ),
      ],
    );
  }

  /// Projection of the existing private diary. Never reads shared or Vault
  /// data, and does not claim runtime/cloud sync or offline reliability.
  static List<DiaryBlockReference> personalBoards(AgendaStore store) {
    if (!store.entryScopeReady ||
        store.agendaContentFilter == AgendaContentFilter.sharedOnly) {
      return const <DiaryBlockReference>[];
    }
    final boards = <DiaryBlockReference>[];
    for (final entry in store.journals.entries) {
      final day = DateTime.tryParse(entry.key);
      if (day == null) continue;
      for (final block in entry.value.blocks) {
        if (block.isPersonalVisionBoard && !block.archived) {
          boards.add(DiaryBlockReference(date: day, block: block));
        }
      }
    }
    boards.sort((a, b) {
      final dayCompare = b.date.compareTo(a.date);
      if (dayCompare != 0) return dayCompare;
      final createdCompare = b.block.createdAt.compareTo(a.block.createdAt);
      if (createdCompare != 0) return createdCompare;
      return a.block.id.compareTo(b.block.id);
    });
    return List<DiaryBlockReference>.unmodifiable(boards);
  }

  /// Explicit, account-guarded insert into the existing journal writer.
  /// Never overwrite an existing block. Missing media fails closed rather
  /// than creating an apparently valid but incomplete editable board.
  static Future<bool> saveDraft(
    AgendaStore store,
    DateTime date,
    DiaryBlock draft, {
    required Cap0160TagEditGuard scopeGuard,
  }) async {
    if (!scopeGuard.isCurrent || !store.entryScopeReady ||
        store.agendaContentFilter == AgendaContentFilter.sharedOnly ||
        !draft.isPersonalVisionBoard ||
        draft.pages.isEmpty || draft.pages.length > 64) {
      return false;
    }
    for (final page in draft.pages) {
      for (final image in page.imageElements) {
        if (image.mediaAssetId.isNotEmpty) {
          if (await MediaAssetStore.instance.read(image.mediaAssetId) == null) {
            return false;
          }
        } else if (image.imageBase64.isNotEmpty) {
          try {
            base64Decode(image.imageBase64);
          } catch (_) {
            return false;
          }
        } else {
          return false;
        }
        if (!scopeGuard.isCurrent) return false;
      }
    }
    final current = store.journal(date);
    if (current.blocks.any((block) => block.id == draft.id) ||
        !scopeGuard.isCurrent) {
      return false;
    }
    try {
      await store.saveJournal(
        date,
        current.copyWith(blocks: [...current.blocks, draft]),
        scopeGuard: scopeGuard,
      );
      return scopeGuard.isCurrent;
    } on Cap0160ScopeChanged {
      return false;
    }
  }
}

/// Reusable read-only preset picker for S11-C. No save or auto-sharing.
Future<VisionBoardPreset?> showVisionBoardPresetPicker(BuildContext context) {
  final presets = visionBoardPresetsFor(AnnaStrings.of(context));
  return showModalBottomSheet<VisionBoardPreset>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Text(
              switch (AnnaStrings.of(sheetContext).languageCode) {
                'it' => 'Scegli una Vision Board',
                'es' => 'Elige una Vision Board',
                'fr' => 'Choisir une Vision Board',
                'pt' => 'Escolha uma Vision Board',
                _ => 'Choose a Vision Board',
              },
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...presets.map((preset) => Card(
                  child: ListTile(
                    leading: SizedBox(
                      width: 54,
                      height: 72,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: DiarySketchPagePreview(
                          page: preset.createPage(
                            pageId: 'vision-preview-${preset.id}',
                          ),
                        ),
                      ),
                    ),
                    title: Text(preset.title),
                    subtitle: Text(preset.description),
                    trailing: Icon(preset.icon),
                    onTap: () => Navigator.pop(sheetContext, preset),
                  ),
                )),
          ],
        ),
      ),
    ),
  );
}

enum VisionBoardCollageStyle { template, grid, cascade }

/// S11-C: pure geometry on existing sketch-image records. No bitmap
/// transformations, duplicate media store, network provider or image copies.
/// The template layout reads S11-B original rectangle frames when available.
abstract final class VisionBoardCollage {
  static List<VisionBoardFrame> _templateFrames(DiarySketchPage page) {
    final frames = <VisionBoardFrame>[];
    for (final stroke in page.strokes) {
      if (stroke.tool != DiarySketchTool.rectangle ||
          stroke.points.length != 2) continue;
      final a = stroke.points[0], b = stroke.points[1];
      final x = min(a.x, b.x), y = min(a.y, b.y);
      final frame = VisionBoardFrame(
        x, y, (a.x - b.x).abs(), (a.y - b.y).abs(),
      );
      if (frame.isValid) frames.add(frame);
    }
    return frames;
  }

  static List<VisionBoardFrame> _grid(int count) {
    if (count == 0) return const [];
    final columns = count == 1 ? 1 : 2;
    final rows = (count / columns).ceil();
    const padding = 0.07;
    const gap = 0.035;
    final width = (1 - padding * 2 - (columns - 1) * gap) / columns;
    final height = (1 - padding * 2 - (rows - 1) * gap) / rows;
    return [
      for (var i = 0; i < count; i++)
        VisionBoardFrame(
          padding + (i % columns) * (width + gap),
          padding + (i ~/ columns) * (height + gap),
          width, height,
        ),
    ];
  }

  static List<VisionBoardFrame> _cascade(int count) {
    if (count > 8) return _grid(count); // avoid unreadably overlapped media
    return [
      for (var i = 0; i < count; i++)
        VisionBoardFrame(
          0.08 + (i % 3) * 0.18,
          0.09 + i * (0.60 / max(count, 1)),
          0.52, 0.35,
        ),
    ];
  }

  static DiarySketchPage arrange(
    DiarySketchPage page,
    VisionBoardCollageStyle style,
  ) {
    final images = page.imageElements;
    if (images.isEmpty) return page;
    final templates = _templateFrames(page);
    final frames = switch (style) {
      VisionBoardCollageStyle.template
          when templates.isNotEmpty && images.length <= templates.length =>
        templates,
      VisionBoardCollageStyle.cascade => _cascade(images.length),
      _ => _grid(images.length),
    };
    return page.copyWith(imageElements: [
      for (var i = 0; i < images.length; i++)
        images[i].copyWith(
          x: frames[i].x,
          y: frames[i].y,
          width: frames[i].width,
          height: frames[i].height,
        ),
    ]);
  }
}

class VisionBoardHistoryEntry {
  const VisionBoardHistoryEntry(this.pages, this.pageIndex);

  final List<DiarySketchPage> pages;
  final int pageIndex;
}

abstract final class VisionBoardUiCopy {
  static String add(AnnaStrings s) => s._pick(
    en: 'Vision Board', it: 'Vision Board', es: 'Vision Board',
    fr: 'Vision Board', pt: 'Vision Board',
  );
  static String editor(AnnaStrings s) => s._pick(
    en: 'My Vision Board', it: 'La mia Vision Board',
    es: 'Mi Vision Board', fr: 'Ma Vision Board', pt: 'A minha Vision Board',
  );
  static String arrange(AnnaStrings s) => s._pick(
    en: 'Collage layout', it: 'Disponi il collage',
    es: 'Diseño del collage', fr: 'Disposition du collage',
    pt: 'Organizar colagem',
  );
  static String template(AnnaStrings s) => s._pick(
    en: 'Template frames', it: 'Cornici del modello',
    es: 'Marcos del modelo', fr: 'Cadres du modèle',
    pt: 'Molduras do modelo',
  );
  static String grid(AnnaStrings s) => s._pick(
    en: 'Grid', it: 'Griglia', es: 'Cuadrícula', fr: 'Grille',
    pt: 'Grelha',
  );
  static String cascade(AnnaStrings s) => s._pick(
    en: 'Cascade', it: 'Cascata', es: 'Cascada', fr: 'Cascade',
    pt: 'Cascata',
  );
  static String discardTitle(AnnaStrings s) => s._pick(
    en: 'Discard changes?', it: 'Scartare le modifiche?',
    es: '¿Descartar cambios?', fr: 'Ignorer les modifications ?',
    pt: 'Descartar alterações?',
  );
  static String discardDetail(AnnaStrings s) => s._pick(
    en: 'Your changes have not been saved.',
    it: 'Le modifiche non sono state salvate.',
    es: 'Los cambios no se han guardado.',
    fr: 'Vos modifications ne sont pas enregistrées.',
    pt: 'As alterações não foram guardadas.',
  );
  static String discard(AnnaStrings s) => s._pick(
    en: 'Discard', it: 'Scarta', es: 'Descartar',
    fr: 'Ignorer', pt: 'Descartar',
  );
  static String keep(AnnaStrings s) => s._pick(
    en: 'Keep editing', it: 'Continua a modificare',
    es: 'Seguir editando', fr: 'Continuer à modifier',
    pt: 'Continuar a editar',
  );
  static String saveError(AnnaStrings s) => s._pick(
    en: 'Unable to save. Your draft is still open.',
    it: 'Salvataggio non riuscito. La bozza è ancora aperta.',
    es: 'No se ha podido guardar. El borrador sigue abierto.',
    fr: 'Enregistrement impossible. Le brouillon reste ouvert.',
    pt: 'Não foi possível guardar. O rascunho continua aberto.',
  );
  static String needImages(AnnaStrings s) => s._pick(
    en: 'Add a photo to create a collage.',
    it: 'Aggiungi una foto per creare un collage.',
    es: 'Añade una foto para crear un collage.',
    fr: 'Ajoutez une photo pour créer un collage.',
    pt: 'Adicione uma foto para criar uma colagem.',
  );
}

/// Guarded edit of a saved private board. Rejects stale references and media,
/// including writes from an editor that survived A→B→A.
Future<bool> saveExistingPrivateVisionBoard(
  AgendaStore store,
  DateTime date,
  DiaryBlock source,
  List<DiarySketchPage> pages, {
  required Cap0160TagEditGuard scopeGuard,
}) async {
  if (!scopeGuard.isCurrent || !source.isPersonalVisionBoard ||
      source.archived || pages.isEmpty || pages.length > 64) {
    return false;
  }
  for (final page in pages) {
    for (final image in page.imageElements) {
      if (image.mediaAssetId.isNotEmpty) {
        if (await MediaAssetStore.instance.read(image.mediaAssetId) == null) {
          return false;
        }
      } else if (image.imageBase64.isNotEmpty) {
        try {
          base64Decode(image.imageBase64);
        } catch (_) {
          return false;
        }
      } else {
        return false;
      }
      if (!scopeGuard.isCurrent) return false;
    }
  }
  if (!scopeGuard.isCurrent) return false;
  final current = store.journal(date);
  final index = current.blocks.indexWhere((block) => block.id == source.id);
  if (index < 0 || !identical(current.blocks[index], source)) return false;
  final blocks = [...current.blocks];
  blocks[index] = source.copyWith(pages: pages);
  try {
    await store.saveJournal(
      date, current.copyWith(blocks: blocks), scopeGuard: scopeGuard,
    );
    return scopeGuard.isCurrent;
  } on Cap0160ScopeChanged {
    return false;
  }
}
