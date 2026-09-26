# Anna's Diary — Roadmap

Source of truth for the active product sequence after v0.52. The roadmap follows the project Master Prompt: REUSE-FIRST, one stable version at a time, no next-version branch before the current version passes all required quality gates and is merged to `main`.

## Active sequence

| Version | Scope | Status | Core acceptance target |
| --- | --- | --- | --- |
| v0.53 | Recurring Life Engine | In validation | Persistent recurring agenda series; scoped edit/delete; reminders, sync, backup and Trash reuse |
| v0.54 | Voice Diary | Planned | Record, persist, play and lifecycle-manage diary audio without replacing the original recording |
| v0.55 | Organization | Planned | Personal organization layer that improves findability without turning the app into a work/Notion clone |
| v0.56 | Widget | Planned | Android home-screen glance + safe ultra-quick capture using existing app data |
| v0.57 | Memories / Relationships 2.0 | Planned | Richer person-linked memories, anniversaries and “on this day” navigation |
| v0.58 | Diary 2.0 | Planned | Reusable personal diary templates and richer daily-writing flows |
| v0.59 | Search / Connections | Planned | Unified local search, filters and explicit connections between personal content |
| v0.60 | Noi ♡ 2.0 | Planned | Stronger shared memories/agenda collaboration on the existing shared-space infrastructure |
| v0.61 | Data Safety | Planned | Restore drills, backup verification, orphan checks and long-term data portability hardening |
| v0.62 | Non-AI Production Consolidation | Planned | Accessibility, performance, regression and release-quality consolidation; no AI features |

## Permanent constraints for this sequence

- No generative-AI or AI-dependent product features through v0.62.
- Anna's Diary remains primarily a personal diary / agenda; work and knowledge-management scope belongs to Notes-Ecosistema.
- Existing verified modules are reused before new infrastructure is introduced.
- User data remains offline-capable and account-isolated where applicable.
- Every new persisted entity or media type must integrate with lifecycle, backup/restore, sync rules and account erasure as applicable.
- README and this roadmap are updated in the same version that changes product behavior.
- A version is complete only after code, tests, required builds, AppLab, Android size/regression audit and documentation gates pass.

## Completed baseline

- v0.45 Lifecycle & Recovery Foundation
- v0.46 Day Hub 2.0
- v0.47 People & Relationships
- v0.48 Universal Delete & Lifecycle Audit
- v0.49 Account Erasure & Data Rights
- v0.50 Security & Production Hardening
- v0.51 CI Throughput & Gate Consolidation
- v0.52 AppLab Critical Journey Expansion

## v0.53 acceptance criteria

- A recurring series is represented persistently and survives app restart.
- Daily, weekly, monthly and yearly recurrences use civil-calendar behavior.
- Editing supports single occurrence, current-and-future and whole-series scopes.
- Deleting supports the same scopes and retains the established Trash/recovery semantics.
- Legacy one-off agenda items remain readable and unchanged.
- Existing local/cloud reminder paths remain the scheduling implementation.
- Existing private sync, backup/export and account isolation automatically include recurrence metadata through the ordinary AgendaItem payload.
- No parallel recurrence database/table is introduced.
