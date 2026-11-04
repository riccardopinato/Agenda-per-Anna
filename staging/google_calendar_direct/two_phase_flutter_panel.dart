// STAGING ONLY — opt-in QA panel, not imported by production lib/ routes.
// No calendar writes. All provider tokens remain on Supabase staging backend.
import 'package:flutter/material.dart';
import 'two_phase_flutter_client.dart';

class GcalStagingTestPanel extends StatefulWidget {
  final GcalTwoPhaseFlutterStagingClient client;
  const GcalStagingTestPanel({super.key, required this.client});

  @override
  State<GcalStagingTestPanel> createState() => _GcalStagingTestPanelState();
}

class _GcalStagingTestPanelState extends State<GcalStagingTestPanel> {
  bool _busy = false;
  GcalStagePreview? _preview;
  String _message = 'Collegamento Google Calendar di test non avviato.';
  String? _error;

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; });
    try {
      await action();
    } on GcalStageClientException catch (error) {
      if (mounted) setState(() { _error = error.kind.name; });
    } catch (_) {
      if (mounted) setState(() { _error = 'requestRejected'; });
    } finally {
      if (mounted) setState(() { _busy = false; });
    }
  }

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
          if (_preview != null && !_preview!.waiting) ...[
            const SizedBox(height: 10),
            SelectableText('Google: ${_preview!.verifiedEmail ?? 'email non verificata'}'),
            const Text('Conferma solo se riconosci l’account visualizzato.'),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text('Operazione non riuscita: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
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
