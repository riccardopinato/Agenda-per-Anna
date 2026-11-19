# Anna's Diary — Unslop UI pilot: first source review (19/11/2026)

**Status:** LIMITED_SOURCE_REVIEW / VISUAL_NOT_VERIFIED / PHYSICAL_NOT_VERIFIED; no UI code changed by this pilot.  
**Input:** `riccardopinato/Agenda-per-Anna@f84d335bac680a2b5e77031c6a2dd3684fb804e7` (`main` on intake).  
**Factory:** `App-Factory-Core@14722698bf92e80c526f5f1f211c8d694ce01fb9`, Master v27, AT-01…AT-64, [Unslop bridge](https://github.com/riccardopinato/App-Factory-Core/blob/feat/unslop-ui-64-bridge-20261119/contracts/UNSLOP_UI_ANTI_AI_64_BRIDGE_v1.md).  
**Source:** Design-App DSK-011 `felipebasurto/unslop-ui@cd891160453f26aaacc569bad96a8d10d595076d` MIT. The upstream Web regex tool is NOT a Flutter scanner; AppLab native source scanner is separately proposed.

## Product and design authority

[Product Bible](../PRODUCT_BIBLE.md) + [Roadmap](../ROADMAP.md) + [10/10 mock-up contract](../DESIGN_REVIEW_10_OF_10_20261118_INTEGRATION.md). Preserve Organic iOS Journal / pastel, Lora + Manrope, rose/HSV, Classic reversible, personal data and shared-space privacy. The ongoing finalization roadmap prohibits unrelated feature expansion; do not re-theme or flatten approved editorial elements simply to reduce U-counts.

## Inspected source and dispositions (not a whole-app scan)

| Source / observation | U / AT | Disposition | Justification |
|---|---|---|---|
| `lib/src/editorial_today_home.dart`: two equal diary/week tiles, genuine annotated-day counter from `AgendaStore` | U14 / AT-17, AT-46 | KEEP_PURPOSEFUL | Two distinct real tasks, no sample metric; existing tests verify empty records excluded |
| Editorial accent rule and illustrative icons inside those tiles | U11 / AT-09, AT-10, AT-12 | KEEP_PURPOSEFUL_PENDING_VISUAL | Journal visual identity explicitly approved; no evidence that this is a generic decorative icon tile |
| `hideDetails ? '•••' : dayCount(...)` | U6, U11 / AT-45, AT-53 | KEEP_PURPOSEFUL | Intentional privacy concealment, not fake Live/Sync status |
| `detail.isNotEmpty` guards extra copy | U3, AT-40 | KEEP_PURPOSEFUL | No default explanatory subtitle forced into both tiles |
| Localized `weekTitle`/`dayCount` (IT, ES, FR, PT, EN) | AT-44 | REVIEW_IF_COPY_CHANGED | Native locale ownership. Any future microcopy change must update all currently supported languages |

Related existing tests: `test/today_two_tile_dashboard_test.dart` and `test/editorial_hybrid_today_real_data_test.dart`. Reading their source does NOT count as rerunning the tests.

## Next evidence gates

1. Run AppLab `scripts/anti_slop_native_audit.py` in a real checkout of this exact source; persist deterministic JSON with the script SHA. No full-repo scanner run is claimed here.
2. Review all targeted 10 approved mock-ups/screen IDs with the existing real Flutter screenshot workflows and the existing source capture fixture; inspect matching Rose/HSV theme and both populated/empty states.
3. Check 320/390dp, IT/EN and longer locales, font 1.6x, light/dark and Classic. Screenshots must not show private data. Record U1..U20 decisions per screen, including PURPOSEFUL/false positives.
4. If evidence establishes a removable redundancy, make a separate bounded UI PR compatible with active visual owner branches; before/after screenshots on identical fixture. Do not edit data, Vault, sync, canonical router or write paths for this aesthetic task.
5. Native physical acceptance and Golden promotion remain NOT_VERIFIED.

**Conclusion from this sampled surface:** do **not** perform automatic subtractive editing; useful editorial structure is already differentiated from stock AI UI. This is not a verdict on the full app.
