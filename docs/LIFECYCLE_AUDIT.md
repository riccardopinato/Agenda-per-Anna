# Lifecycle Audit

Anna's Diary uses one explicit lifecycle policy for every user-creatable data class.

## Private first-class content

These entities use the account-scoped Trash contract:

| Entity | Delete | Restore | Permanent purge | Cascade / side effects |
| --- | --- | --- | --- | --- |
| Agenda item | Trash | Yes | Yes | Android/Web reminders cancelled on delete and recreated on restore |
| Diary block | Trash | Yes | Yes | Media references remain protected while recoverable |
| Day journal | Trash | Yes | Yes | Media references remain protected while recoverable |
| Month page | Trash | Yes | Yes | Restore is conflict-safe |
| Week page | Trash | Yes | Yes | Restore is conflict-safe |
| Habit | Trash | Yes | Yes | Completion links are recoverable; permanent purge scrubs live and trashed journals |
| Birthday | Trash | Yes | Yes | Reminder cancelled/restored; permanent purge clears person links |
| Person | Trash | Yes | Yes | Diary links survive while recoverable; permanent purge removes orphan tags |
| Inbox entry | Trash | Yes | Yes | Account-scoped persistence and sync |

Trash keeps historical versions instead of collapsing them by logical key. Restore never overwrites an active entity with the same identity. For day/week/month content this means a user can keep multiple deleted versions and explicitly choose which one to restore.

## Embedded private content

Goals, weekly priorities, monthly lists, expenses, gratitude rows and sketch elements are embedded inside their parent page rather than synced as independent entities. Their lifecycle is therefore owned by that parent page. Deleting the full day/week/month page remains recoverable through Trash.

Sketch selection/page edits remain editor-level operations; deleting the diary Sketch block itself is recoverable through Trash.

## Shared Noi ♡ content

Shared data intentionally does not enter the private Trash:

- shared entries use server tombstones and the offline shared-operation queue;
- shared comments/reactions use the shared interaction queue and server authorization;
- deleting a shared space is an owner-only destructive action for all members;
- leaving a shared space removes only the current member;
- shared media is deleted with its shared entry/space or by the media-maintenance path.

This preserves collaboration ownership semantics and avoids creating private recoverable copies of data that belongs to multiple accounts.

## Private Vault

Vault entries are local-only encrypted data. Their delete action is intentionally permanent and requires explicit confirmation. The Vault is excluded from ordinary sync, search, backup and Trash so sensitive content is not duplicated into a second recoverable store.

## Utility artifacts

Local safety snapshots/backups are recovery artifacts rather than primary user content. They can be deleted directly. Permanent Trash purge creates a local safety snapshot before destructive removal unless the caller explicitly disables it for controlled test/internal flows.

## Account lifecycle

Sign-out preserves the account-scoped local profile so signing back in can recover offline data. Full account erasure is a separate server-side lifecycle operation because Supabase Auth deletion requires privileged server execution and Storage ownership cleanup. It is intentionally not simulated client-side.
