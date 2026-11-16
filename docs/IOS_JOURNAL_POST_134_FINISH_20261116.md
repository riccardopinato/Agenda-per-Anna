# Anna's Diary — post +134 visual/product finish (16 Nov 2026)

Status: **SOURCE MERGED** via [PR #328](https://github.com/riccardopinato/Agenda-per-Anna/pull/328) at `main@2934ea9573edc68edbfc24210fbf8296ac67af49`; visual owner and physical certification **NOT VERIFIED**. No new APK/release.
Source baseline: `main@afbbb3ec5b46d1744d2f681668742fdef7723ea1`, Flutter `1.0.0-rc.6+134`.
Factory baseline: `App-Factory-Core@c5adc147046beb7024629466d10eeb799c3c2619`, Master v27 / Golden Index v29.

## Owner decision
User confirms the existing signed APK **works**: do not touch download, signing, package ID or version code solely for delivery. Advance remaining approved audit work: native Flutter editorial visual parity with Home, Memories carousel animation/visibility, responsive/a11y checks, full-checkout scan where feasible, document reality. This is an app source/layout task, not Play/production approval.

## Lane plan
1. Fix render timing, semantics and visibility of real Memories 'On this day' carousel; no hidden blank card on first visibility and no duplicate store.
2. Match Home visual hierarchy in Calendar/Impegni, Memories, More/Settings using current AnnaOrganic/AnnaEditorial tokens, preserving five locales, rose/HSV/dark, reduced motion, Classic.
3. Validate Flutter widgets and screenshots on real screen structures including empty/populated, font scaling, narrow widths. Required exact-head PR: Development checks, AppLab Source Gate, Pages, relevant screenshot/Android checks.
4. Reconcile README, Product Bible, roadmap with `+134` facts; do not replace historical evidence.
5. Register every residual audit finding and explicitly name user/device-only or provider-only gates. None may be silently marked PASS.

## Exclusions
Do not alter private Vault, persisted schema/ACL, account or shared-space ownership, Google Calendar Direct #199, Privacy V2 #215, Store/RevenueCat production, signed APK workflow. Do not upgrade version for a source-only aesthetic PR. AppLab/source PASS is not on-phone QA.

## Evidenza incrementale della prima wave

- Memoria `Per te → In questo giorno`: in modalità Journal la `PageView` ora costruisce subito il contenuto senza `AnnaMotionStagger` con opacità iniziale zero; Classic mantiene la presentazione precedente. Screenshot Flutter popolato renderizzato, con titolo reale e data, nella [visual review #43785771246](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43785771246); non certifica esperienza fisica.
- Selettore anno `AnnaOrganicJournalYearPill` (48dp, Semantics, focus, tap) solo Journal; Classic mantiene `ChoiceChip`. Calendario `+Crea` passa a `AnnaOrganicPastelAction` nella sola presentazione editoriale; rimane la stessa funzione `showUnifiedCapture` e la data selezionata canonica.
- Calendar notebook, hero Ricordi, Altro e hub Impostazioni usano `AnnaOrganicPaperSurface` con texture / gradient / paper border dell'Home anziché la generica superficie flat, laddove applicabile.
- Screenshot reali Flutter per Home, calendario month/week, Impegni, Ricordi, More e Settings: [Journal #43785771246](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43785771246), [Calendar #43785771152](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43785771152), [Organic #43785771121](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43785771121); i risultati sono visual QA con fixture sintetiche e PR merge simulation, non installazione.
- Scanner uguale alla versione canonica [catalogo@8fdc4e1f](https://github.com/riccardopinato/Idee-app-Archivi-riferimenti/blob/8fdc4e1f526d54287b52ad3433004fb4f89b7dc9/scripts/audit_flutter_antipatterns.py), snapshot in `tool/audit_flutter_antipatterns.py`; [workflow #43786278027](https://github.com/riccardopinato/Agenda-per-Anna/actions/runs/43786278027) PASS e artifact con evidenza per-file. 332 Dart, 0 skipped, 0 high confidence LEGACY_API, 257 euristiche REVIEW: 57 preferences, 134 import IO (soprattutto test), 65 eager ListView, 1 async void notification callback. Nessun fix massivo automatico: prima della modifica serve triage di file e comportamento.
- Test obbligatori della PR: Flutter analyze, full suite, browser crypto, Pages, AppLab Source Gate, screenshot differenziati, report scansione. Verificare exact-head finale dopo ogni commit.
- User attestation: APK +134 funziona, non modificare signing/download. Visual parity **OWNER ACCEPTANCE PENDING**; full physical QA distinta.

## Remaining test gates

- Reale aggiornamento telefono, dati reali, storage, backup/restore, due device, notifica recapitata, PIN/biometria, fluidità p95: **NOT VERIFIED**, non imputare a questi screenshot.
- Attribuzione dell'estetica finale Home-parity: richiede approvazione dell'utente e immagini/gesti su installazione reale.
- Aggiornare [registro residui](AUDIT_RESIDUAL_POST_134_20261116.md) quando un'area ottiene una prova specifica, senza cancellarne la storia.
