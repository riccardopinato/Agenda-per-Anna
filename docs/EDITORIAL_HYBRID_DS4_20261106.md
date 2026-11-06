# Anna's Diary — DS4: Editorial Hybrid Ricordi

**Date:** 6 November 2026  
**Authority:** User-approved Step 4 after the Home and docked-navigation redesign; approved mock-up #3 (Ricordi B, contemporary editorial diary).  
**Factory baseline:** `riccardopinato/App-Factory-Core@3481a8190a5db5965bb22f84832094268d05be98` (CURRENT Master v27, Golden Index v28).  
**App source base:** `riccardopinato/Agenda-per-Anna@9a96a9bdb7da164840e4ed1ed1bcc6697e597dd4`.  
**Release boundary:** source-only, version remains `1.0.0-rc.6+127`. The approved future `+128` package may bundle this with Calendar, but requires separate signed CI and owner device QA.

## Implemented UI and non-destructive reuse

1. `lib/src/diary/editorial_memories.dart` is a presentation-only part of the existing `main.dart` library, implemented as an extension on the existing memories screen state. This avoids new routes, databases, indexes, stores, cloud listeners or persistence.
2. `AnnaEditorialTodayMode.enabled` switches the same Ricordi screen between the existing Classic cards and Editorial Hybrid. Default Classic remains available and the local preference changes all redesigned screens consistently.
3. **Per te:** true anniversary memory first, authentic photo/sketch media only, meaningful note/voice fallback without a fake photograph, Lora headline, date metadata and palette-derived surface. The existing `MemoryRecallSnapshot` remains the only owner of anniversary selections, highlighted year chips, swipes, counters, deterministic resurfacing and person/place facets. `ContextualMemoryPanel` appears after the featured memory in Editorial only; Classic keeps its original order.
4. **Timeline:** real media and canonical block titles/dates in softly rounded Editorial cards; months use the same palette-derived card and Lora heading. Expand/collapse, quick year jump, person/place associations and source open navigation stay unchanged.
5. **Explore:** existing Map, Then & Now, Collections / Life Threads retain their stable semantic IDs and callbacks, with a matching Editorial card container. The existing search/filter controls and Days/Months/Years browsing remain available.
6. Palette honors rose/lilac/sage/peach/sky/custom HSV, dark/system and existing typography. No hardcoded sample memories/photos or new dependencies. No change to the Private Vault.
7. Tests cover source boundaries, unchanged canonical memory projection/routes, and a bounded 320dp large-text/dark-theme Editorial surface interaction. Existing `v105b0_memories_3_core_test.dart` covers persisted journal notes and deterministic anniversary projection. A complete Ricordi screen widget journey and Hybrid-to-Classic interaction are **NOT VERIFIED**, and must be included in later emulator/physical QA. Run exact-head Flutter analyze/all tests/Web, AppLab Source Gate and review. Only after checks may merge through protected main.

## Explicitly NOT VERIFIED
Pixel-accurate reproduction of the approved standalone visual reference, 320/390/600/840dp screenshot matrix, Android physical large-text/gesture tests, real-photo viewer transition, long archive performance, multi-account storage and actual device acceptance. CI/source PASS must not be reported as these physical checks.
