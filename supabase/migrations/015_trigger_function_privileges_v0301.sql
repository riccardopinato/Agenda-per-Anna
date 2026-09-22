-- v0.30.1 - trigger-only helper functions are not client RPC endpoints.

revoke execute on function private.cleanup_shared_entry_interactions()
from public, anon, authenticated;

revoke execute on function private.guard_agenda_record_identity()
from public, anon, authenticated;
