# v1.05-A2 — Navigation IA

## Goal

Align the main navigation with Anna's Diary product identity:

**Today · Calendar · Memories · More**

The change is intentionally an information-architecture migration, not a new
data domain.

## Factory baseline

- App-Factory-Core: `4cc0b94467b94ab6fabe2c927fcc58afff49e39a`
- Master: v26.6
- Golden Index: v19

## Canonical shell

1. **Today** — the current day hub, rituals, life stream and diary.
2. **Calendar** — one destination with Month and Week modes.
3. **Memories** — the existing deterministic Diary Memories surface promoted
   to first-class navigation.
4. **More** — Search, Inbox, Explore, Personalization, Noi, Archive, Backup,
   Account/Cloud and Settings.

The A1 responsive policy remains unchanged: NavigationBar on narrow surfaces,
NavigationRail on wider Web/desktop surfaces.

## Backward compatibility

The canonical persisted `StartTab` values are now:

- `today`
- `calendar`
- `memories`
- `more`

Legacy values remain readable:

- `home` → `today`
- `month` → `calendar`
- `week` → `calendar`
- `today` → `today`

Both normal preference restore and backup restore use the same compatibility
decoder. New writes only emit canonical values.

## Memories visibility

Memories is now core navigation, so it is no longer duplicated in Explore or
shown as an optional personalization switch. The historical
`AppModule.memories` payload value is retained for backward compatibility; it
does not gate access to the primary Memories surface.

## Runtime continuity

- Web `?today=1` and `?capture=1` entry points remain valid.
- Home Widget synchronization moves with the Today surface so demoting the old
  Home dashboard does not stop widget refreshes.
- Month and Week state remain mounted within the Calendar hub.
- AppLab journeys route secondary functions through stable More semantics
  instead of the legacy Home overflow menu.

## Non-goals

A2 does not yet perform the larger Today visual consolidation, Unified Capture
redesign, Settings category IA, Memories 3.0 content redesign, Map Memories or
Year in Review.

## Acceptance

- complete Flutter analyze/test/build gates PASS;
- Web deployment PASS;
- Android size audit PASS;
- AppLab trusted runtime PASS on the exact head;
- old Home/month/week/today preference payloads restore without error;
- all secondary routes remain reachable from More;
- no persistence owner, sync schema or entitlement contract is added.
