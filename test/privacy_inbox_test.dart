import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agenda_per_anna/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('PIN can be configured and verified', () async {
    final store = AgendaStore();

    await store.setPin('1234');

    expect(store.preferences.privacyLockEnabled, isTrue);
    expect(store.preferences.pinHash, isNotNull);
    expect(store.preferences.pinSalt, isNotNull);
    expect(store.verifyPin('1234'), isTrue);
    expect(store.verifyPin('0000'), isFalse);
  });

  test('quick inbox entries can be pinned and persisted in backup', () async {
    final store = AgendaStore();

    await store.addInboxEntry('Prenotare il ristorante');
    expect(store.inbox, hasLength(1));

    final id = store.inbox.single.id;
    await store.toggleInboxPinned(id);
    expect(store.inbox.single.pinned, isTrue);

    final backup = await store.createBackupJson();

    final restored = AgendaStore();
    await restored.restoreBackup(backup, merge: false);

    expect(restored.inbox, hasLength(1));
    expect(restored.inbox.single.text, 'Prenotare il ristorante');
    expect(restored.inbox.single.pinned, isTrue);
  });

  test('agenda items preserve pinned state', () async {
    final store = AgendaStore();
    final item = AgendaItem(
      id: 'item-1',
      title: 'Visita',
      note: '',
      date: DateTime(2026, 9, 21),
      type: ItemType.appointment,
      start: const TimeOfDay(hour: 10, minute: 0),
    );

    await store.upsert(item);
    await store.toggleItemPinned(item.id);

    expect(store.items.single.pinned, isTrue);

    final restored = AgendaItem.fromJson(store.items.single.toJson());
    expect(restored.pinned, isTrue);
  });

  test('fresh install can keep onboarding state in preferences', () {
    const prefs = AgendaPreferences(onboardingDone: false);
    final restored = AgendaPreferences.fromJson(prefs.toJson());

    expect(restored.onboardingDone, isFalse);
  });
}
