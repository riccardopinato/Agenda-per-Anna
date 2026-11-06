part of '../../main.dart';

/// Presentation-only Editorial Hybrid skins for the canonical Ricordi screen.
/// No duplicate memory repository, media owner, search index or persistence.
/// This extension can use the existing screen's routes and authentic previews.
extension _EditorialMemoriesPresentation on _DiaryMemoriesScreenState {
  Widget _editorialFeaturedMemory(
    BuildContext context,
    DiaryBlockReference record,
  ) {
    final strings = AnnaStrings.of(context);
    final colors = AnnaEditorialColors.of(context);
    final block = record.block;
    final title = widget.store.diaryBlockDisplayTitle(
      block, strings: strings,
    );
    final date = DateFormat(
      'd MMMM yyyy', AnnaStrings.intlLocale(context),
    ).format(record.date);
    final authenticVisual = block.type == DiaryBlockType.sketch ||
        (block.type == DiaryBlockType.photo && block.hasPhotoMedia);
    final VoidCallback open = block.type == DiaryBlockType.photo &&
            block.hasPhotoMedia
        ? () => unawaited(_openPhoto(record))
        : () => unawaited(_openRecord(record));

    return Semantics(
      identifier: 'memories-for-you-hero',
      button: true,
      label: '$title · $date',
      child: Padding(
        padding: const EdgeInsets.only(top: AnnaDesignTokens.spaceSm),
        child: AnnaEditorialSurface(
          key: const ValueKey<String>('memories-editorial-featured'),
          tone: AnnaEditorialSurfaceTone.featured,
          padding: EdgeInsets.zero,
          onTap: open,
          semanticLabel: '$title · $date',
          child: authenticVisual
              ? SizedBox(
                  height: 282,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      block.type == DiaryBlockType.photo
                          ? Hero(
                              tag: 'v108-photo-${block.id}',
                              child: _coverPreview(context, record),
                            )
                          : _coverPreview(context, record),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.72),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        right: 22,
                        bottom: 22,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              key: const ValueKey<String>(
                                'memories-editorial-featured-title'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AnnaJournalTypography.editorial(
                                context, size: 25,
                              ).copyWith(
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              date,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 282,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(23),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          block.type == DiaryBlockType.voice
                              ? Icons.mic_none_outlined
                              : block.type == DiaryBlockType.photo
                                  ? Icons.photo_outlined
                                  : Icons.auto_stories_outlined,
                          color: colors.accent,
                          size: 32,
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: 60,
                          height: 2,
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.62),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          title,
                          key: const ValueKey<String>(
                            'memories-editorial-featured-title'),
                          style: AnnaJournalTypography.editorial(
                            context, size: 25,
                          ).copyWith(color: colors.ink, height: 1.22),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          date,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.mutedInk),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _editorialTimelineMemoryCard(
    BuildContext context,
    DiaryBlockReference record,
  ) {
    final colors = AnnaEditorialColors.of(context);
    final strings = AnnaStrings.of(context);
    final block = record.block;
    final title = widget.store.diaryBlockDisplayTitle(
      block, strings: strings,
    );
    final date = DateFormat(
      'EEEE d MMMM yyyy', AnnaStrings.intlLocale(context),
    ).format(record.date);
    final authenticVisual = block.type == DiaryBlockType.sketch ||
        (block.type == DiaryBlockType.photo && block.hasPhotoMedia);

    return Padding(
      padding: const EdgeInsets.only(bottom: AnnaDesignTokens.spaceSm),
      child: AnnaEditorialSurface(
        key: ValueKey<String>('memories-editorial-timeline-${block.id}'),
        padding: EdgeInsets.zero,
        onTap: () => block.type == DiaryBlockType.photo && block.hasPhotoMedia
            ? unawaited(_openPhoto(record))
            : unawaited(_openRecord(record)),
        semanticLabel: '$title · $date',
        child: authenticVisual
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 185,
                    width: double.infinity,
                    child: block.type == DiaryBlockType.photo
                        ? Hero(
                            tag: 'v108-photo-${block.id}',
                            child: _coverPreview(context, record),
                          )
                        : _coverPreview(context, record),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(19, 16, 19, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AnnaJournalTypography.editorial(
                            context, size: AnnaEditorialTokens.cardTitle,
                          ).copyWith(color: colors.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _cap(date),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.mutedInk),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(19),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      block.type == DiaryBlockType.voice
                          ? Icons.mic_none_outlined
                          : block.type == DiaryBlockType.photo
                              ? Icons.photo_outlined
                              : Icons.auto_stories_outlined,
                      color: colors.accent,
                      size: 27,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: AnnaJournalTypography.editorial(
                              context, size: AnnaEditorialTokens.cardTitle,
                            ).copyWith(color: colors.ink),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _cap(date),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.mutedInk),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colors.mutedInk),
                  ],
                ),
              ),
      ),
    );
  }

  /// Timeline month accordion keeps its existing expanded state and actions.
  Widget _memoryMonthSurface({required Widget child}) {
    if (AnnaEditorialTodayMode.enabled.value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: AnnaEditorialSurface(
          padding: EdgeInsets.zero,
          child: child,
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: child,
    );
  }

  Widget _memoryExploreSurface({required Widget child}) {
    if (AnnaEditorialTodayMode.enabled.value) {
      return AnnaEditorialSurface(
        key: const ValueKey<String>('memories-editorial-explore'),
        padding: EdgeInsets.zero,
        child: child,
      );
    }
    return Card(child: child);
  }
}
