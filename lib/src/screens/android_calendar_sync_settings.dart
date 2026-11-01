part of '../../main.dart';

String androidSyncCopy(AnnaStrings strings, String key) {
  const messages = <String, List<String>>{
    'title': ['Android calendar sync', 'Sincronizzazione calendario Android', 'Sincronización calendario Android', 'Synchronisation calendrier Android', 'Sincronização calendário Android'],
    'intro': ['Send private appointments to one writable device calendar. If it is a synced Google calendar, Android may also sync them to Google. No Google Cloud setup is needed.', 'Invia gli appuntamenti privati a un calendario scrivibile del telefono. Se è un calendario Google sincronizzato, Android può trasferirli anche su Google. Non serve configurare Google Cloud.', 'Envía citas privadas al calendario del teléfono. Android puede sincronizarlas con Google. Sin configuración de Google Cloud.', 'Envoyer les rendez-vous privés au calendrier de l’appareil. Android peut ensuite les synchroniser avec Google.', 'Envia compromissos privados para o calendário do telefone. O Android pode sincronizá-los com o Google.'],
    'access': ['Allow device calendar access', 'Autorizza accesso al calendario', 'Permitir acceso al calendario', 'Autoriser le calendrier', 'Permitir acesso ao calendário'],
    'calendar': ['Destination calendar', 'Calendario di destinazione', 'Calendario de destino', 'Calendrier de destination', 'Calendário de destino'],
    'sync': ['Sync automatically while the app is open', 'Sincronizza automaticamente quando l’app è aperta', 'Sincronizar con la app abierta', 'Synchroniser lorsque l’application est ouverte', 'Sincronizar enquanto a app está aberta'],
    'run': ['Sync now', 'Sincronizza ora', 'Sincronizar ahora', 'Synchroniser maintenant', 'Sincronizar agora'],
    'busy': ['Synchronizing…', 'Sincronizzazione in corso…', 'Sincronizando…', 'Synchronisation…', 'A sincronizar…'],
    'last': ['Last successful sync', 'Ultima sincronizzazione riuscita', 'Última sincronización correcta', 'Dernière synchronisation réussie', 'Última sincronização concluída'],
    'none': ['Not synchronized yet', 'Non ancora sincronizzato', 'Todavía no sincronizado', 'Pas encore synchronisé', 'Ainda não sincronizado'],
    'status': ['Processed / skipped appointments', 'Appuntamenti elaborati / saltati', 'Citas procesadas / omitidas', 'Rendez-vous traités / ignorés', 'Compromissos tratados / ignorados'],
    'privacy': ['Off by default. Private future appointments for the next 12 months only (maximum 200 per run). Shared appointments, notes and Vault content are excluded. Events with a start but no end are skipped. Updates are one-way, while the app is running; deleting or moving an event externally does not silently recreate it. Disabling sync does not delete previous exports.', 'Disattivata per impostazione predefinita. Solo appuntamenti privati futuri dei prossimi 12 mesi (massimo 200 per sincronizzazione). Esclusi appuntamenti condivisi, note e Cassaforte. Gli eventi con inizio ma senza fine vengono saltati. Aggiornamento unidirezionale quando l’app è attiva; se un evento viene eliminato o spostato sul calendario esterno non è ricreato automaticamente. Disattivare non cancella gli eventi già esportati.', 'Desactivada por defecto. Solo citas privadas futuras, sin notas ni contenido compartido. La desactivación no elimina las exportaciones.', 'Désactivée par défaut. Uniquement les futurs rendez-vous privés ; aucune note ni contenu partagé. La désactivation ne supprime pas les exports.', 'Desativada por predefinição. Apenas compromissos privados futuros; sem notas nem conteúdo partilhado. Desativar não apaga exportações.'],
    'unavailable': ['Available only on Android; no device calendar access on Web.', 'Disponibile solo su Android; il Web non accede ai calendari del dispositivo.', 'Solo disponible en Android.', 'Disponible uniquement sur Android.', 'Disponível apenas no Android.'],
    'choose': ['Choose a writable calendar before enabling sync.', 'Scegli un calendario scrivibile prima di attivare la sincronizzazione.', 'Elige un calendario editable.', 'Choisissez un calendrier modifiable.', 'Escolha um calendário editável.'],
    'denied': ['Calendar access is missing or denied. Enable it in Android Settings.', 'Accesso al calendario mancante o negato. Autorizzalo nelle Impostazioni Android.', 'Falta el permiso de calendario.', 'Autorisation calendrier manquante.', 'Sem permissão para o calendário.'],
    'error': ['Synchronization issue', 'Problema di sincronizzazione', 'Problema de sincronización', 'Erreur de synchronisation', 'Problema de sincronização'],
  };
  final i = switch (strings.languageCode) {
    'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0
  };
  return messages[key]![i];
}

class AndroidCalendarSyncSettingsScreen extends StatefulWidget {
  final AgendaStore store;
  const AndroidCalendarSyncSettingsScreen({super.key, required this.store});
  @override
  State<AndroidCalendarSyncSettingsScreen> createState() =>
      _AndroidCalendarSyncSettingsScreenState();
}

class _AndroidCalendarSyncSettingsScreenState
    extends State<AndroidCalendarSyncSettingsScreen> {
  final _service = AndroidCalendarSyncService.instance;
  List<ExternalCalendarInfo> _calendars = const [];
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _service.attach(widget.store);
    await _refreshCalendars();
  }

  Future<void> _refreshCalendars() async {
    final values = await _service.writableCalendars();
    if (mounted) setState(() => _calendars = values);
  }

  Future<void> _authorize() async {
    setState(() => _requesting = true);
    try {
      final external = ExternalCalendarService.instance;
      await external.initialize();
      if (!external.permissionGranted && !await external.requestAccess()) return;
      if (!await _service.requestWriteAccess()) return;
      await _refreshCalendars();
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AnnaStrings.of(context);
    return AnimatedBuilder(
      animation: _service,
      builder: (context, _) {
        final available = _service.supported;
        final selected = _calendars.any((c) => c.id == _service.calendarId)
            ? _service.calendarId : null;
        return Scaffold(
          appBar: AppBar(title: Text(androidSyncCopy(strings, 'title'))),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(androidSyncCopy(strings, 'intro')),
              const SizedBox(height: 14),
              if (!available)
                Text(androidSyncCopy(strings, 'unavailable')),
              if (available) ...[
                OutlinedButton.icon(
                  key: const ValueKey('b3-android-calendar-authorize'),
                  onPressed: _requesting ? null : _authorize,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(androidSyncCopy(strings, 'access')),
                ),
                const SizedBox(height: 10),
                Text(androidSyncCopy(strings, 'calendar')),
                DropdownButtonFormField<String>(
                  key: ValueKey('b3-calendar-${_service.calendarId ?? 'none'}'),
                  isExpanded: true,
                  initialValue: selected,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final calendar in _calendars)
                      DropdownMenuItem(
                        value: calendar.id,
                        child: Text('${calendar.name} (${calendar.accountName})',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: _service.enabled ? null : (id) {
                    if (id == null) return;
                    unawaited(_service.configure(
                        enabled: false, calendarId: id));
                  },
                ),
                if (selected == null)
                  Text(androidSyncCopy(strings, 'choose'),
                    style: Theme.of(context).textTheme.bodySmall),
                SwitchListTile.adaptive(
                  key: const ValueKey('b3-android-calendar-enabled'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(androidSyncCopy(strings, 'sync')),
                  value: _service.enabled,
                  onChanged: _requesting ||
                      (!_service.enabled && (selected == null ||
                          !_service.writePermissionGranted))
                      ? null
                      : (enabled) => unawaited(
                          _service.configure(enabled: enabled)),
                ),
                if (!_service.writePermissionGranted)
                  Text(androidSyncCopy(strings, 'denied'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error)),
                OutlinedButton.icon(
                  key: const ValueKey('b3-android-calendar-sync-now'),
                  onPressed: !_service.enabled || _service.working
                      ? null : () => unawaited(_service.reconcile()),
                  icon: const Icon(Icons.sync),
                  label: Text(androidSyncCopy(strings, 'run')),
                ),
                Text(_service.working
                    ? androidSyncCopy(strings, 'busy')
                    : "${androidSyncCopy(strings, 'last')}: ${_service.lastSuccess == null ? androidSyncCopy(strings, 'none') : DateFormat.yMd(AnnaStrings.intlLocale(context)).add_Hm().format(_service.lastSuccess!)}"),
                Text("${androidSyncCopy(strings, 'status')}: ${_service.updated} / ${_service.skipped}"),
                if (_service.error != null)
                  SelectableText(
                    '${androidSyncCopy(strings, 'error')}: ${_service.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Text(androidSyncCopy(strings, 'privacy'),
                style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
