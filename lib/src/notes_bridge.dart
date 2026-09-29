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

  String toPlainText() {
    final buffer = StringBuffer();
    buffer.writeln(title.trim().isEmpty ? 'Nota da Anna\'s Diary' : title.trim());
    buffer.writeln();

    if (body.trim().isNotEmpty) {
      buffer.writeln(body.trim());
      buffer.writeln();
    }

    buffer.writeln('---');
    buffer.writeln('Fonte: $source');
    buffer.writeln(
      'Data: ${DateFormat('d MMMM yyyy, HH:mm', 'it_IT').format(createdAt)}',
    );
    if (tags.isNotEmpty) {
      buffer.writeln('Tag: ${tags.map((tag) => '#$tag').join(' ')}');
    }
    if (people.isNotEmpty) {
      buffer.writeln('Persone: ${people.join(', ')}');
    }
    if (places.isNotEmpty) {
      buffer.writeln('Luoghi: ${places.join(', ')}');
    }
    if (mediaNotice != null && mediaNotice!.trim().isNotEmpty) {
      buffer.writeln(mediaNotice!.trim());
    }
    buffer.writeln('Importato da Anna\'s Diary · Notes Bridge Lite');
    return buffer.toString().trim();
  }
}

extension AgendaStoreNotesBridge on AgendaStore {
  NotesBridgePayload notesBridgePayloadForInbox(InboxEntry entry) =>
      NotesBridgePayload(
        title: entry.text.trim().isEmpty
            ? 'Nota Inbox'
            : _notesBridgeTitleFromText(entry.text, fallback: 'Nota Inbox'),
        body: entry.text.trim(),
        source: 'Anna\'s Diary · Inbox',
        createdAt: entry.createdAt,
        tags: List<String>.unmodifiable(entry.tags),
      );

  NotesBridgePayload notesBridgePayloadForDiary(
    DateTime date,
    DiaryBlock block,
  ) {
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
      DiaryBlockType.note => 'Nota diario',
      DiaryBlockType.photo => 'Foto diario',
      DiaryBlockType.sketch => 'Sketch diario',
      DiaryBlockType.voice => 'Nota vocale',
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
            'Nota: la foto originale resta in Anna\'s Diary e non viene copiata da Notes Bridge Lite.';
        break;
      case DiaryBlockType.voice:
        mediaNotice =
            'Nota: l’audio originale resta in Anna\'s Diary e non viene copiato da Notes Bridge Lite.';
        break;
      case DiaryBlockType.sketch:
        mediaNotice =
            'Nota: vengono copiati solo i testi dello sketch; tratti e immagini restano in Anna\'s Diary.';
        break;
    }

    final fallbackTitle =
        '$kindLabel · ${DateFormat('d MMMM yyyy', 'it_IT').format(date)}';
    final titleSource = block.text.trim().isNotEmpty
        ? block.text
        : sketchText;

    return NotesBridgePayload(
      title: _notesBridgeTitleFromText(
        titleSource,
        fallback: fallbackTitle,
      ),
      body: bodyParts.join('\n\n'),
      source: 'Anna\'s Diary · Diario',
      createdAt: block.createdAt,
      tags: List<String>.unmodifiable(block.tags),
      people: people,
      places: places,
      mediaNotice: mediaNotice,
    );
  }

  String notesBridgeTextForInbox(InboxEntry entry) =>
      notesBridgePayloadForInbox(entry).toPlainText();

  String notesBridgeTextForDiary(
    DateTime date,
    DiaryBlock block,
  ) =>
      notesBridgePayloadForDiary(date, block).toPlainText();
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
    const SnackBar(
      content: Text('Copiato per Notes.'),
      duration: Duration(seconds: 1),
    ),
  );
}
