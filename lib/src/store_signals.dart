part of '../main.dart';

/// Granular UI invalidation channels.
///
/// AgendaStore intentionally remains the compatibility facade while the UI
/// listens only to the domains it renders. This keeps data/persistence APIs
/// stable and prevents unrelated mutations from rebuilding every main screen.
class AgendaStoreSignals {
  final ValueNotifier<int> agenda = ValueNotifier<int>(0);
  final ValueNotifier<int> journal = ValueNotifier<int>(0);
  final ValueNotifier<int> planning = ValueNotifier<int>(0);
  final ValueNotifier<int> shared = ValueNotifier<int>(0);
  final ValueNotifier<int> inbox = ValueNotifier<int>(0);
  final ValueNotifier<int> settings = ValueNotifier<int>(0);
  final ValueNotifier<int> backup = ValueNotifier<int>(0);
  final ValueNotifier<int> account = ValueNotifier<int>(0);

  void bumpAgenda() => agenda.value++;
  void bumpJournal() => journal.value++;
  void bumpPlanning() => planning.value++;
  void bumpShared() => shared.value++;
  void bumpInbox() => inbox.value++;
  void bumpSettings() => settings.value++;
  void bumpBackup() => backup.value++;
  void bumpAccount() => account.value++;

  void bumpAll() {
    bumpAgenda();
    bumpJournal();
    bumpPlanning();
    bumpShared();
    bumpInbox();
    bumpSettings();
    bumpBackup();
    bumpAccount();
  }

  void dispose() {
    agenda.dispose();
    journal.dispose();
    planning.dispose();
    shared.dispose();
    inbox.dispose();
    settings.dispose();
    backup.dispose();
    account.dispose();
  }
}
