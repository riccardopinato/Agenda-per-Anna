# UI5 — DF-01–DF-35 approved implementation contract
Date: 2026-10-29
Authority: User's explicit design choices recorded in [PR #149](https://github.com/riccardopinato/Agenda-per-Anna/pull/149).
Status: DESIGN APPROVED; implementation tracked separately per source/PR gate.

## Baselines
- Factory: `App-Factory-Core@174a05e165076c9e4b2d61a20acd85ca6b215f12`, `CURRENT.yaml` master v27 and Golden Index v23.
- AppLab current main observed: `46816a1786820eb7c0edab7500ca950b10c7718c` (immutable consumer workflow pin is a compatibility/gate choice, not automatically rewritten).
- Follow Product Bible, current Roadmap, AGENTS.md, existing UI3 C/C/B/C/A blueprint and reference AppLab screenshots. Do not mistake a visually illustrative static mock for a pixel-verified native screenshot.

## Approved product behavior
### Navigation and Capture (DF-01–DF-07)
- Four navigable destinations: Oggi, Calendario, Ricordi, Altro. Raised central **+ Crea** is an ACTION, not a fifth navigable tab. Keep responsive NavigationRail behavior on wide screens.
- + Crea palette/HSV-sensitive solid accent + soft halo, reactive compression/expansion on tap; reduced-motion safe and subtle, haptic as appropriate. **DF-05 option C continuous living/pulsating Glow is NOT approved**; retain as later optional visual review.
- Reuse existing `showUnifiedCapture` bottom-up sheet, NOT new menu or direct note. Five visible actions: Scrivi un momento, Foto, Attività, Nota vocale, Sketch. Keep expanded `Altre opzioni`: Inbox, Appuntamento, Compleanno, Persona importante, plus Modelli. Preserve all existing functions.
- Central Crea initial date: current selected day in Calendario; TODAY in Oggi, Ricordi and Altro even when viewing another day. Expose effective date prominently and allow picker to change before action; cancellation leaves it unchanged. Route Sketch and templates to canonical diary edit/save paths, no data duplication.

### Oggi (DF-08–DF-14, DF-19–20)
- Day overview first, compact layout. Date/title and horizontal 4–5-day date strip, selected day updates whole page in place, with return-to-today.
- Impegni, Attività, Benessere summaries, then bounded upcoming commitment where meaningful; no fictional metrics, avoid multiple empty-card placeholders or competing journal composer. The + Crea action is primary.
- Under summaries, compact separate `Il tuo diario` for up to two real entries of selected day + `Vedi tutto`, and `Ricordi da rivivere` for one **real clickable teaser** with small thumbnail/type fallback. The latter opens Ricordi, without full anniversary carousel.

### Ricordi → Per te (DF-15–DF-24)
- **All full anniversary functions belong here, NOT Oggi** (DF-19 explicitly supersedes early DF-15/17 Oggi wording).
- At TOP, a single editorial featured memory at a time, swiping over **ALL individual** exact month/day memories from past years, including multiple same-day same-year entries, truthful original dates and "Un anno fa" relative labels, individual/year counts, and clickable horizontally scrollable year chips that jump to first eligible memory of year.
- If no exact anniversary exists, use authentic prior-year same-calendar-month entries with clearly labeled "[Mese] negli anni passati" fallback, never mislabel as exact anniversary.
- Beneath hero `Scelti per te` compact suggestions, up to THREE real eligible nonduplicate entries, `Vedi tutti` shown only if additional suggestions exist, expanding **in place**, not to Timeline/new page. Preserve collections, search, map, people and Then/Now and canonical memory references.

### Ricordi → Timeline (DF-25–DF-28)
- Accessible expandable/collapsible groups by month+year with counts. Initially expand the most recent month **containing** memories; others collapsed. Show no phantom months.
- Quick year selector jumps to latest actual month in selected year and expands it. Separate from anniversary year chips in Per te.
- Keep chosen year, expanded groups and scroll across memory-detail back/Per-te switching during current app session; on a fresh process launch start at newest nonempty month. No persisted UI-history store.

### Ricordi → Global search (DF-29–DF-35)
- A DEDICATED dismissible results route; don't force switch to Timeline. Initial blank-query, `Tutti` selected, subtle guidance; no recent-memories feed/history.
- Five always visible horizontally scrolling type chips: Tutti/Note/Foto/Sketch/Audio. Intersect search text with canonical type/date/place/person/Sketch text; respect privacy and archive eligibility. Compact flat list sorted by **assigned memory date descending**, full localized date below title, NO month headers.
- Tap exact matching item → open its actual content, no intermediary preview/day-only jump; Back restores query/chip/results/scroll. Closing search and reopening starts clean every time (DF-35 A).
- Zero matches: concise feedback; if type filter active show one control to reset type to `Tutti` while preserving query. If `Tutti` already active, no redundant reset. Blank query uses initial hint, not "no results".

## Implementation and acceptance
- Never alter diary storage schema, user data, privacy, sync, premium, archive/trash, or release signing as a side effect of design.
- Preserve all existing routes and flows and five-language target strings. Reuse theme and existing domain services; no new persistence layer.
- Complete in bounded changes, run Flutter analyze/tests, Web, Android size and AppLab Production Gate on exact reviewed head. Preview screenshots are illustration only until visual QA and physical device evidence exists. No Play/cross-device certification without evidence.
- Original PR #149 remains **audit-only**, with DF-35 close-out comment; implementation PR(s) hold code and validation.
