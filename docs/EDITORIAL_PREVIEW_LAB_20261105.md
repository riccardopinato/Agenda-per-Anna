# Anna’s Diary — Editorial Home Design Lab (5 Nov 2026)

## Goal
Evaluate the screenshot's visual grammar: spacious editorial greeting, prominent hero, modular cards, Lora + Manrope hierarchy, neutral surfaces and evenly balanced five-position bottom bar. Colors and photographs are not hard requirements.

## Independent variants
- **B — Editorial Premium:** generous spacing, larger typographic scale, faithful featured card and balanced bottom bar.
- **C — Editorial Hybrid:** compact responsive composition, same distinctive language, day summary plus functional information density.

Source: design_lab/editorial/lib/main.dart.
Compile switch: EDITORIAL_VARIANT=premium or EDITORIAL_VARIANT=hybrid.

## Data safety and build identity
- Both are standalone Flutter UI previews with different Android package IDs from the official com.riccardopinato.agenda_per_anna:
  - com.riccardopinato.anna.editorialpremium
  - com.riccardopinato.anna.editorialhybrid
- No production services, account, Firebase, Supabase, analytics, Google sign-in, RevenueCat, or private database.
- Notes, mock appointments, messages and moods created during a preview are in-memory only; these are **not real diary records** and never sync.
- These are **debug-signed** test APKs with an ephemeral CI signing key. Rebuilding later may require uninstalling the corresponding preview (never the official app).
- Official Android, pubspec, routing, cloud and data stores are unchanged.
- Neither variant is a full replacement app; visual selection precedes production integration.

## Usable interactions
- Four screens Oggi / Messaggi / Ricordi / Altro plus a centered working Crea overlay, five equally sized navigation slots.
- Create mock thought, task and appointment; select mood; navigate to preview collections.
- Three palette selectors Rose / Sage / Ink and light / dark toggling.
- The search affordance explicitly states that production search is not part of this offline preview.

## CI and distribution
Action: .github/workflows/editorial-apk-lab.yml.
Builds Android APK files for both variants, runs Flutter analyze/tests, uploads the independent installable APKs in an Actions artifact and SHA256SUMS.txt.
Experimental branch stays separate from protected main. No automatic Play/Pages deployment.

## Physical acceptance checks
Install the two previews alongside the existing Anna app. Compare the typography, vertical rhythm, cards, bar balance and create button. Test navigation, bottomsheet, keyboard, dark/colored palettes and small viewport. Actual Android usability and visual fidelity remain **NOT VERIFIED** until phone review. User's selection is required before porting to the production UI.
