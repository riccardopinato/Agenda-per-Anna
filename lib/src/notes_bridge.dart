part of '../main.dart';

class NotesBridgePayload {
  final String title;
  final String body;
  final String source;
  final DateTime createdAt;
  final List<String> tags;
  final List<String> people;
  final List<String> places;
  final String? mediaNotice;

  const NotesBridgePayload({
    required this.title,
    required this.body,
    required this.source,
    required this.createdAt,
    this.tags = const [],
    this.people = const [],
    this.places = const [],
    this.mediaNotice,
  });

  String toPlainText(AnnaStrings strings) {
    final buffer = StringBuffer();
    buffer.writeln(title.trim().isEmpty ? strings.d3('notesDefaultTitle') : title.trim());
    buffer.writeln();

    if (body.trim().isNotEmpty) {
      buffer.writeln(body.trim());
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln(strings.d3Format('notesSource', {'value': source}));
    buffer.writeln(
      strings.d3Format(
        'notesDate',
        {
          'value': DateFormat(
            'd MMMM yyyy, HH:mm',
            AnnaStrings.resolveLocale(Locale(strings.languageCode)).languageCode,
          ).format(createdAt),
        },
      ),
    );
    if (tags.isNotEmpty) {
      buffer.writeln('Tag: ${tags.map((tag) => '#$tag').join(' ')}');
    }
    if (people.isNotEmpty) {
      buffer.writeln(strings.d3Format('notesPeople', {'value': people.join(', ')}));
    }
    if (places.isNotEmpty) {
      buffer.writeln(strings.d3Format('notesPlaces', {'value': places.join(', ')}));
    }
    if (mediaNotice != null && mediaNotice!.trim().isNotEmpty) {
      buffer.writeln(mediaNotice!.trim());
    }
    buffer.writeln(strings.d3('notesImported'));
    return buffer.toString().trim();
  }
}

extension AgendaStoreNotesBridge on AgendaStore {
  NotesBridgePayload notesBridgePayloadForInbox(
    InboxEntry entry, {
    AnnaStrings strings = const AnnaStrings('it'),
  }) =>
      NotesBridgePayload(
        title: entry.text.trim().isEmpty
            ? strings.d3('notesInbox')
            : _notesBridgeTitleFromText(entry.text, fallback: strings.d3('notesInbox')),
        body: entry.text.trim(),
        source: 'Anna\'s Diary · Inbox',
        createdAt: entry.createdAt,
        tags: List<String>.unmodifiable(entry.tags),
      );

  NotesBridgePayload notesBridgePayloadForDiary(
    DateTime date,
    DiaryBlock block, {
    AnnaStrings strings = const AnnaStrings('it'),
  }) {
    final people = peopleForIds(block.personIds)
        .map((person) => person.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
    final places = block.places
        .map((place) => place.name.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);

    final sketchText = block.pages
        .expand((page) => page.textElements)
        .map((element) => element.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n');

    final kindLabel = switch (block.type) {
      DiaryBlockType.note => strings.d3('notesDiaryNote'),
      DiaryBlockType.photo => strings.d3('notesDiaryPhoto'),
      DiaryBlockType.sketch => strings.d3('notesDiarySketch'),
      DiaryBlockType.voice => strings.d3('notesVoice'),
    };

    final bodyParts = <String>[];
    if (block.text.trim().isNotEmpty) {
      bodyParts.add(block.text.trim());
    }
    if (sketchText.isNotEmpty &&
        !bodyParts.contains(sketchText)) {
      bodyParts.add(sketchText);
    }

    String? mediaNotice;
    switch (block.type) {
      case DiaryBlockType.note:
        break;
      case DiaryBlockType.photo:
        mediaNotice =
            strings.d3('notesPhotoNotice');
        break;
      case DiaryBlockType.voice:
        mediaNotice =
            strings.d3('notesAudioNotice');
        break;
      case DiaryBlockType.sketch:
        mediaNotice =
            strings.d3('notesSketchNotice');
        break;
    }

    final fallbackTitle =
        '$kindLabel · ${DateFormat('d MMMM yyyy', AnnaStrings.resolveLocale(Locale(strings.languageCode)).languageCode).format(date)}';
    final titleSource = block.text.trim().isNotEmpty
        ? block.text
        : sketchText;

    return NotesBridgePayload(
      title: _notesBridgeTitleFromText(
        titleSource,
        fallback: fallbackTitle,
      ),
      body: bodyParts.join('\n\n'),
      source: strings.d3('notesDiarySource'),
      createdAt: block.createdAt,
      tags: List<String>.unmodifiable(block.tags),
      people: people,
      places: places,
      mediaNotice: mediaNotice,
    );
  }

  String notesBridgeTextForInbox(
    InboxEntry entry, {
    AnnaStrings strings = const AnnaStrings('it'),
  }) =>
      notesBridgePayloadForInbox(entry, strings: strings).toPlainText(strings);

  String notesBridgeTextForDiary(
    DateTime date,
    DiaryBlock block, {
    AnnaStrings strings = const AnnaStrings('it'),
  }) =>
      notesBridgePayloadForDiary(date, block, strings: strings).toPlainText(strings);
}

String _notesBridgeTitleFromText(
  String value, {
  required String fallback,
}) {
  final normalized = value
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (normalized.isEmpty) return fallback;
  if (normalized.length <= 72) return normalized;
  return '${normalized.substring(0, 69).trimRight()}…';
}

Future<void> copyNotesBridgePayload(
  BuildContext context,
  String text,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AnnaStrings.of(context).d3('notesCopied')),
      duration: const Duration(seconds: 1),
    ),
  );
}
