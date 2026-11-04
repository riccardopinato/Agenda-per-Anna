// STAGING ONLY — opt-in QA panel, not imported by production lib/ routes.
// No calendar writes. All provider tokens remain on Supabase staging backend.
import 'package:flutter/material.dart';
import 'two_phase_flutter_client.dart';

String gcalQaErrorMessage(GcalStageClientFault fault) => switch (fault) {
  GcalStageClientFault.stagingLocked =>
    'Il collegamento Google Calendar non è ancora abilitato nello staging. '
    'Il blocco di sicurezza è attivo: non è un problema del tuo account.',
  GcalStageClientFault.authenticationRequired =>
    'La sessione Anna’s Diary non è valida o è scaduta. Accedi nuovamente.',
  GcalStageClientFault.requestRejected =>
    'Richiesta non completata. Verifica la connessione oppure la '
    'configurazione del backend di test.',
  GcalStageClientFault.expired =>
    'La richiesta Google è scaduta. Avvia un nuovo collegamento.',
  GcalStageClientFault.accountChanged =>
    'Hai cambiato account Anna’s Diary. Riavvia il collegamento.',
  GcalStageClientFault.failedToOpenBrowser =>
    'Impossibile aprire il browser per il consenso Google.',
  GcalStageClientFault.previewRequired =>
    'Verifica l’account Google prima di confermare.',
  _ => 'Operazione di prova non completata: ${fault.name}.',
};

class GcalStagingTestPanel extends StatefulWidget {
  final GcalTwoPhaseFlutterStagingClient client;
  const GcalStagingTestPanel({super.key, required this.client});

  @override
  State<GcalStagingTestPanel> createState() => _GcalStagingTestPanelState();
}

class _GcalStagingTestPanelState extends State<GcalStagingTestPanel> {
  bool _busy = false;
  GcalStagePreview? _preview;
  List<GcalStageConnection> _connections = const [];
  List<GcalStageCalendar> _calendars = const [];
  String _message = 'Collegamento Google Calendar di test non avviato.';
  String? _error;
  bool _expectedLocked = false;

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; _expectedLocked = false; });
    try {
      await action();
    } on GcalStageClientException catch (error) {
      if (mounted) {
        setState(() {
          _error = gcalQaErrorMessage(error.kind);
          _expectedLocked = error.kind == GcalStageClientFault.stagingLocked;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = gcalQaErrorMessage(GcalStageClientFault.requestRejected);
        });
      }
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

  Future<void> _recover() => _perform(() async {
    final connections = await widget.client.recoverConnections();
    if (!mounted) return;
    setState(() {
      _connections = connections;
      _message = connections.isEmpty
          ? 'Nessun account Google Calendar collegato in staging.'
          : 'Collegamenti trovati. Seleziona un account per scollegarlo.';
    });
  });

  Future<void> _start() => _perform(() async {
    await widget.client.begin();
    if (!mounted) return;
    setState(() {
      _preview = null;
      _message = 'Browser Google aperto. Dopo il consenso torna qui e verifica.';
    });
  });

  Future<void> _check() => _perform(() async {
    final preview = await widget.client.preview();
    if (!mounted) return;
    setState(() {
      _preview = preview;
      _message = preview.waiting
          ? 'Risposta Google non ancora ricevuta. Puoi riprovare.'
          : 'Verifica l’identità Google prima di confermare.';
    });
  });

  Future<bool> _ask(String question) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Conferma esplicita'),
            content: Text(question),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annulla')),
              FilledButton(onPressed: () => Navigator.pop(context, true),
                  child: const Text('Conferma')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirm() async {
    final preview = _preview;
    if (preview == null || preview.waiting || preview.googleSubject == null) {
      return;
    }
    if (!await _ask('Collegare l’account Google visualizzato ad Anna’s Diary di test? '
        'Nessun evento verrà esportato automaticamente.')) {
      return;
    }
    await _perform(() async {
      await widget.client.confirm(explicitConfirmation: true);
      if (!mounted) return;
      setState(() {
        _preview = null;
        _message = 'Account Google collegato in staging. Scritture disattivate.';
      });
    });
  }

  Future<void> _readCalendars() => _perform(() async {
    final result = await widget.client.readCalendars();
    if (!mounted) return;
    setState(() {
      _calendars = result;
      _message = result.isEmpty
          ? 'Google Calendar risponde correttamente: nessun calendario visibile.'
          : 'Lettura Google Calendar riuscita: ${result.length} calendari trovati.';
    });
  });

  Future<void> _disconnect() async {
    if (!await _ask('Scollegare l’account Google Calendar di test? '
        'Gli eventi Google già esistenti non verranno cancellati.')) {
      return;
    }
    await _perform(() async {
      final result = await widget.client.disconnect(explicitConfirmation: true);
      if (!mounted) return;
      setState(() {
        _preview = null;
        _connections = const [];
        _calendars = const [];
        _message = result.providerRevoked == true
            ? 'Scollegato e revoca Google confermata.'
            : 'Scollegato localmente. Revoca Google non verificata: '
              'controlla le autorizzazioni del tuo account.';
      });
    });
  }

  @override
  void dispose() {
    widget.client.clearForAccountSwitch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Google Calendar — STAGING',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Solo collegamento OAuth di prova. '
              'Nessuna scrittura nel calendario.'),
          const SizedBox(height: 12),
          Text(_message),
          if (_connections.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final connection in _connections)
              TextButton(
                onPressed: _busy ? null : () => setState(
                    () => widget.client.selectConnection(connection.googleSubject)),
                child: Text(connection.verifiedEmail ?? connection.googleSubject),
              ),
          ],
          if (_calendars.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Calendari Google — sola lettura',
                style: TextStyle(fontWeight: FontWeight.w600)),
            for (final calendar in _calendars)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(calendar.primary
                    ? Icons.event_available_outlined
                    : Icons.event_note_outlined),
                title: Text(calendar.name),
                subtitle: Text(calendar.accessRole),
              ),
          ],
          if (_preview != null && !_preview!.waiting) ...[
            const SizedBox(height: 10),
            SelectableText('Google: ${_preview!.verifiedEmail ?? 'email non verificata'}'),
            const Text('Conferma solo se riconosci l’account visualizzato.'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: _expectedLocked
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (!widget.client.awaitingGoogleConsent)
              OutlinedButton(
                onPressed: _busy ? null : _recover,
                child: const Text('Verifica collegamenti salvati'),
              ),
            if (!widget.client.awaitingGoogleConsent &&
                !widget.client.connectedThisSession)
              FilledButton(
                onPressed: _busy ? null : _start,
                child: const Text('Collega Google Calendar'),
              ),
            if (widget.client.awaitingGoogleConsent)
              OutlinedButton(
                onPressed: _busy ? null : _check,
                child: const Text('Verifica risposta Google'),
              ),
            if (_preview != null && !_preview!.waiting)
              FilledButton(
                onPressed: _busy ? null : _confirm,
                child: const Text('Conferma collegamento'),
              ),
            if (widget.client.connectedThisSession)
              FilledButton.tonal(
                onPressed: _busy ? null : _readCalendars,
                child: const Text('Leggi calendari Google'),
              ),
            if (widget.client.connectedThisSession)
              OutlinedButton(
                onPressed: _busy ? null : _disconnect,
                child: const Text('Scollega'),
              ),
          ]),
        ],
      ),
    ),
  );
}
