part of '../main.dart';

/// UI-level disclosure gate for flagged agenda previews. It reuses the
/// existing app PIN / local_auth settings and does not encrypt record data.
/// A fresh challenge is required for each flagged detail access.
Future<bool> requestSensitiveItemAccess(
  BuildContext context,
  AgendaStore store,
) async {
  final prefs = store.preferences;
  if (!prefs.privacyLockEnabled ||
      prefs.pinSalt == null ||
      prefs.pinHash == null) {
    if (!context.mounted) return false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AnnaStrings.of(dialogContext).d3('privacy_sensitive')),
        content: Text(AnnaStrings.of(dialogContext).d3('privacy_pinRequired')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AnnaStrings.of(dialogContext).close),
          ),
        ],
      ),
    );
    return false;
  }

  if (!context.mounted) return false;
  final controller = TextEditingController();
  try {
    final allowed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          bool busy = false;
          return AlertDialog(
            title: Text(AnnaStrings.of(context).d3('privacy_sensitive')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AnnaStrings.of(context).d3('privacy_enterPin')),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('privacy-sensitive-pin'),
                  controller: controller,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  decoration: const InputDecoration(labelText: 'PIN'),
                  onSubmitted: (value) {
                    if (store.verifyPin(value)) {
                      Navigator.of(context).pop(true);
                    } else {
                      controller.clear();
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AnnaStrings.of(context).cancel),
              ),
              if (prefs.biometricUnlock && !kIsWeb)
                TextButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: Text(AnnaStrings.of(context).d3('useBiometric')),
                  onPressed: () async {
                    if (busy) return;
                    busy = true;
                    try {
                      final auth = LocalAuthentication();
                      final ok = await auth.authenticate(
                        localizedReason: AnnaStrings.of(context).d3('privacy_enterPin'),
                      );
                      if (context.mounted && ok) Navigator.pop(context, true);
                    } catch (_) {
                      // Never fall back to unprotected access.
                    } finally {
                      busy = false;
                    }
                  },
                ),
              FilledButton(
                onPressed: () {
                  if (store.verifyPin(controller.text)) {
                    Navigator.pop(context, true);
                  } else {
                    controller.clear();
                  }
                },
                child: Text(AnnaStrings.of(context).d3('unlock')),
              ),
            ],
          );
        },
      ),
    );
    return allowed == true && store.entryScopeReady;
  } finally {
    // Modal route has completed; no PIN is persisted.
    controller.dispose();
  }
}

bool isMaskedAgendaEntry(UnifiedAgendaEntry entry, {bool hideAll = false}) =>
    hideAll ||
    (entry.privateItem?.isSensitive ?? false) ||
    (entry.sharedEntry?.isSensitive ?? false);
