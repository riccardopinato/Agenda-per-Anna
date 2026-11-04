// Dedicated Anna's Diary Google Calendar QA entry, never compiled into
// production unless ANNA_GCAL_STAGING_QA=true is explicitly set at build time.
// OAuth is backend-gated. This UI does not request Calendar write access.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'two_phase_flutter_panel.dart';
import 'two_phase_flutter_transport.dart';

class AnnaGcalQaScreen extends StatefulWidget {
  const AnnaGcalQaScreen({
    super.key,
    required this.signedIn,
    required this.signInWithGoogle,
  });

  final bool Function() signedIn;
  final Future<void> Function() signInWithGoogle;

  @override
  State<AnnaGcalQaScreen> createState() => _AnnaGcalQaScreenState();
}

class _AnnaGcalQaScreenState extends State<AnnaGcalQaScreen> {
  late final http.Client _http = http.Client();
  late final _client = createGcalStagingClient(httpClient: _http);
  late final _serverProbe =
      GcalStagingEdgeTransport.forStaging(_http).probeServer;
  bool _busySignIn = false;
  String? _signInMessage;

  Future<void> _signIn() async {
    if (_busySignIn) return;
    setState(() => _busySignIn = true);
    try {
      await widget.signInWithGoogle();
      if (!mounted) return;
      setState(() => _signInMessage =
          'Accedi nell’app con Google, poi torna qui e verifica i collegamenti.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _signInMessage =
          'Accesso non riuscito. Riprova dalla schermata Account.');
    } finally {
      if (mounted) setState(() => _busySignIn = false);
    }
  }

  @override
  void dispose() {
    _client.clearForAccountSwitch();
    _http.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Google Calendar · QA')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Anna’s Diary — collaudo STAGING',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 6),
              const Text(
                'Collegamento Google Calendar in ambiente di test. '
                'Non vengono creati, modificati o eliminati eventi Google.',
              ),
              const SizedBox(height: 14),
              if (!widget.signedIn()) ...[
                const Text('Per usare il collegamento devi prima '
                    'accedere al tuo account Anna’s Diary.'),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _busySignIn ? null : _signIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Accedi con Google ad Anna’s Diary'),
                ),
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined),
                    SizedBox(width: 8),
                    Expanded(child: Text('Sessione Anna’s Diary presente')),
                  ],
                ),
              ],
              if (_signInMessage != null) ...[
                const SizedBox(height: 8),
                Text(_signInMessage!),
              ],
              const SizedBox(height: 16),
              GcalStagingTestPanel(client: _client, serverProbe: _serverProbe),
              const SizedBox(height: 12),
              const Text(
                'Se il backend restituisce STAGING_NOT_ACTIVATED o 503, '
                'il blocco di sicurezza è ancora attivo. '
                'Questa build non abilita OAuth senza autorizzazione separata.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
}
