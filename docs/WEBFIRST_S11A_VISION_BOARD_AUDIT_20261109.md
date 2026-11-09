# Anna's Diary — S11-A Vision Board audit / source-backed design

Date: 2026-11-09. Read-only S11-A audit completed in Chat before S11-B.
This is a repository-side summary of the full audit report delivered to the
user as `ANNA_DIARY_S11A_AUDIT_VISION_BOARD_2026-11-09.txt`; it is not a new
implementation, test or device certification.

## Pinned authority
- Factory: `App-Factory-Core@d4ed1185d36d419228fba6b57a979cde308bd321`;
  Master v27 ACTIVE; Golden Index v29 and Registry v2.
- Anna: `Agenda-per-Anna@0b49de46d43f4747c5cf9425d460f2fc2c7e6cd4`.
- Notes donor: `Notes-Ecosistema@42efc5b91fc01ef6e40e9a5d61ab8d1d05f9f41c`.
- Research: `Idee-app-Archivi-riferimenti/15-VISION-BOARD`, 39 unique
  references and 28 candidate extractions on 08/11; research only.

## Verified by scoped source reading, not by running this audit
- `lib/src/diary/diary_sketchbook.dart`: finite 3:4 Sketchbook, existing
  pen/shape/lasso/selection, photos and text, page navigation, zoom/pan,
  page-scoped undo/redo and explicit Save with PNG export.
- `lib/src/domain_models.dart`: `DiarySketchPage`, `DiarySketchStroke`,
  `DiarySketchTextElement`, `DiarySketchImageElement`, `DiaryBlock`.
- `lib/src/diary/diary_components.dart`: a sketch block is created or
  updated through `AgendaStore.saveJournal` after the editor confirms.
- `lib/src/agenda_store.dart` and `lib/src/lifecycle_domain.dart`:
  media references, local/portable sketch pages, trash/restore.
- `lib/src/diary/diary_templates.dart`: preexisting diary *text* presets;
  no persistent original visual templates at the S11-A baseline.

## Architecture decision
Implement a personal, optional, private Vision Board as an additive subtype
of existing `DiaryBlockType.sketch` using its canonical `DiarySketchPage`
payload, existing MediaAssetStore and journal writer. Do **not** replace
the editor with Notes Whiteboard or the Draft Golden Infinite Canvas. Do
not create a separate database, cloud path, general task planner or auto-share.

## Risks to gate in the implementation phases
- Original sketch data must decode without a migration; new board subtype
  must round-trip through existing JSON and preserve backup/trash semantics.
- A→B→A account switches must invalidate open editor commits, not just
  compare final account ID.
- Missing media during portable export must fail closed or report loss, never
  claim an image-preserving export that silently dropped it.
- Undo of resize/page delete and unsaved editor dismissal require targeted
  hardening in S11-C, not a blanket claim from existing undo/redo.
- Physical PWA, accessibility, performance, backup/restore real files and
  offline Web have no new verification from this audit.

## Candidate donors, not promoted components
Notes visual_documents/whiteboard code; Draft Factory Infinite Canvas/Ink,
Media Asset Store, Backup/Recovery, Entity Lifecycle and Shell/Responsive
contracts; ImageCanvas MIT Swift geometry; react-easy-crop MIT geometry;
Excalidraw MIT scene patterns. No code/assets from these donors are copied
by S11-B, no license or GOLDEN promotion is implied.
