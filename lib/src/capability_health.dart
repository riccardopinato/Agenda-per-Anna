part of '../main.dart';

/// CAP-0077. Permission != capability != runtime delivery.
enum CapabilityHealthState {
  unsupported, unknown, permissionRequired, unavailable, degraded, available
}

CapabilityHealthState assessCapability({
  required bool supported,
  required bool? permissionGranted,
  required bool? serviceAvailable,
  bool? configured = true,
  bool error = false,
}) {
  if (!supported) return CapabilityHealthState.unsupported;
  if (permissionGranted == false) return CapabilityHealthState.permissionRequired;
  if (permissionGranted == null || serviceAvailable == null || configured == null) {
    return CapabilityHealthState.unknown;
  }
  if (!serviceAvailable) return CapabilityHealthState.unavailable;
  if (error || !configured) return CapabilityHealthState.degraded;
  return CapabilityHealthState.available;
}

class CapabilityHealthCheck {
  const CapabilityHealthCheck(this.key, this.state, this.explanation);
  final String key;
  final CapabilityHealthState state;
  final String explanation;
}

/// No permission prompts, exports, writes or persistent capability cache.
Future<List<CapabilityHealthCheck>> inspectAnnaCapabilities() async {
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  if (!android) {
    return [
      for (final key in ['notifications','reminders','push','calendarRead','calendarWrite'])
        CapabilityHealthCheck(key, CapabilityHealthState.unsupported, 'nativeOnly'),
    ];
  }
  final checks = <CapabilityHealthCheck>[];
  try {
    final status = await NotificationService.instance.health();
    checks.add(CapabilityHealthCheck(
      'notifications',
      assessCapability(
        supported: true,
        permissionGranted: status.notificationsEnabled,
        serviceAvailable: status.available,
        error: status.lastError != null,
      ),
      status.lastError == null ? 'notDelivered' : 'checkFailed',
    ));
    checks.add(CapabilityHealthCheck(
      'reminders',
      assessCapability(
        supported: true,
        permissionGranted: status.notificationsEnabled,
        serviceAvailable: status.available,
        configured: status.reminderChannelEnabled,
        error: status.lastError != null,
      ),
      !status.reminderChannelEnabled ? 'channelDisabled'
        : !status.exactAlarmsEnabled ? 'exactFallback' : 'notDelivered',
    ));
  } catch (_) {
    for (final key in ['notifications', 'reminders']) {
      checks.add(CapabilityHealthCheck(key, CapabilityHealthState.unknown, 'checkFailed'));
    }
  }
  // A token is not proof that the remote push was delivered. The existing
  // notification diagnostics owns the explicit online receipt test.
  checks.add(CapabilityHealthCheck(
    'push',
    PushNotificationService.instance.configured
      ? CapabilityHealthState.unknown : CapabilityHealthState.unavailable,
    'pushUnknown',
  ));

  final calendar = ExternalCalendarService.instance;
  try {
    final status = await calendar.refreshStatus();
    checks.add(CapabilityHealthCheck(
      'calendarRead',
      assessCapability(
        supported: status.supported,
        permissionGranted: status.permissionGranted,
        serviceAvailable: status.error == null,
        configured: calendar.enabled && calendar.selectedCalendarIds.isNotEmpty,
        error: status.error != null,
      ),
      status.error == null ? 'optional' : 'checkFailed',
    ));
  } catch (_) {
    checks.add(const CapabilityHealthCheck(
      'calendarRead', CapabilityHealthState.unknown, 'checkFailed',
    ));
  }
  final sync = AndroidCalendarSyncService.instance;
  try {
    await sync.refreshPermission();
    checks.add(CapabilityHealthCheck(
      'calendarWrite',
      assessCapability(
        supported: sync.supported,
        permissionGranted: sync.writePermissionGranted,
        serviceAvailable: sync.error == null,
        configured: sync.loaded && sync.enabled && sync.calendarId != null,
        error: sync.error != null,
      ),
      sync.error == null ? 'syncUnknown' : 'checkFailed',
    ));
  } catch (_) {
    checks.add(const CapabilityHealthCheck(
      'calendarWrite', CapabilityHealthState.unknown, 'checkFailed',
    ));
  }
  return checks;
}

String capabilityHealthCopy(String languageCode, String key) {
  const strings = <String, List<String>>{
    "title": ["Permission & service diagnostics","Diagnostica permessi e servizi","Diagnóstico de permisos y servicios","Diagnostic des autorisations et services","Diagnóstico de permissões e serviços"],
    "intro": ["Read-only check. A permission is not proof of delivery. No new access is requested.","Controllo in sola lettura: un permesso non prova la consegna. Nessuna nuova autorizzazione richiesta.","Comprobación sin solicitar permisos; el acceso no garantiza la entrega.","Vérification sans demander d’autorisation ; l’accès ne prouve pas la réception.","Verificação sem solicitar acesso; permissão não garante entrega."],
    "refresh": ["Check again","Ricontrolla","Comprobar","Revérifier","Verificar"],
    "unknown": ["Not verified","Da verificare","Sin verificar","Non vérifié","Não verificado"],
    "unsupported": ["Unsupported","Non supportato","No disponible","Non disponible","Não suportado"],
    "permissionRequired": ["Permission required","Serve autorizzazione","Permiso requerido","Autorisation requise","Permissão necessária"],
    "unavailable": ["Service unavailable","Servizio non disponibile","Servicio no disponible","Service indisponible","Serviço indisponível"],
    "degraded": ["Needs attention","Da controllare","Requiere atención","À vérifier","Requer atenção"],
    "available": ["Available; delivery unverified","Disponibile; consegna non verificata","Disponible; entrega no verificada","Disponible ; réception non vérifiée","Disponível; entrega não verificada"],
    "notifications": ["Android notifications","Notifiche Android","Notificaciones Android","Notifications Android","Notificações Android"],
    "reminders": ["Reminders channel","Canale Promemoria","Canal de recordatorios","Canal des rappels","Canal de lembretes"],
    "push": ["Shared-space push","Push Noi ♡","Push del espacio compartido","Push espace partagé","Push espaço partilhado"],
    "calendarRead": ["Device calendar access","Accesso calendario dispositivo","Acceso al calendario","Accès au calendrier","Acesso ao calendário"],
    "calendarWrite": ["Device calendar export","Esportazione calendario dispositivo","Exportar al calendario","Export calendrier","Exportar para calendário"],
    "notDelivered": ["Enabled/configured does not confirm reception.","Attivazione o configurazione non confermano la ricezione.","Configurado no confirma recepción.","Configuration ne confirme pas la réception.","Configuração não confirma receção."],
    "checkFailed": ["Inspection failed; no success inferred.","Verifica non riuscita: nessun esito positivo presunto.","Falló la verificación.","Vérification échouée.","Falha na verificação."],
    "exactFallback": ["Exact alarms unavailable; scheduling may be approximate.","Sveglie precise assenti: orario dei promemoria potenzialmente approssimato.","Alarmas exactas no disponibles.","Alarmes exactes indisponibles.","Alarmes exatos indisponíveis."],
    "channelDisabled": ["Reminder channel disabled in Android settings.","Canale Promemoria disattivato nelle impostazioni Android.","Canal desactivado en Android.","Canal désactivé dans Android.","Canal desativado no Android."],
    "pushUnknown": ["Test reception in notification settings; token registration is not delivery.","Verifica la ricezione nelle impostazioni Notifiche: il token non prova la consegna.","Comprueba la recepción en ajustes.","Vérifiez la réception dans les réglages.","Teste a receção nas definições."],
    "optional": ["Optional calendar integration may be disabled.","L’integrazione calendario può essere disattivata per scelta.","La integración opcional puede estar desactivada.","L’intégration facultative peut être désactivée.","A integração opcional pode estar desligada."],
    "syncUnknown": ["Only local export status is known; external sync is unverified.","È noto solo lo stato locale dell’esportazione, non la consegna esterna.","Solo se conoce la exportación local.","Seul l’export local est connu.","Só o estado da exportação local é conhecido."],
    "nativeOnly": ["Android-only diagnostics; use the existing Web/iOS controls.","Diagnostica solo Android: usa i controlli Web/iOS già presenti.","Diagnóstico solo Android.","Diagnostic Android uniquement.","Diagnóstico apenas Android."],
    "notificationSettings": ["Notification settings","Impostazioni notifiche","Ajustes de notificaciones","Réglages notifications","Definições notificações"],
    "calendarSettings": ["Calendar settings","Impostazioni calendario","Ajustes de calendario","Réglages calendrier","Definições calendário"],
  };
  final index = switch (languageCode) {
    'it' => 1, 'es' => 2, 'fr' => 3, 'pt' => 4, _ => 0,
  };
  return strings[key]![index];
}

class CapabilityHealthScreen extends StatefulWidget {
  const CapabilityHealthScreen({super.key, required this.store});
  final AgendaStore store;
  @override
  State<CapabilityHealthScreen> createState() => _CapabilityHealthScreenState();
}

class _CapabilityHealthScreenState extends State<CapabilityHealthScreen>
    with WidgetsBindingObserver {
  List<CapabilityHealthCheck>? _checks;
  bool _busy = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _generation++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (_busy) return;
    final generation = ++_generation;
    setState(() => _busy = true);
    List<CapabilityHealthCheck> results;
    try {
      results = await inspectAnnaCapabilities();
    } catch (_) {
      results = const [];
    }
    if (!mounted || generation != _generation) return;
    setState(() {
      _checks = results;
      _busy = false;
    });
  }

  Future<void> _openCalendar() async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => AndroidCalendarSyncSettingsScreen(store: widget.store),
    ));
    if (mounted) unawaited(_refresh());
  }

  @override
  Widget build(BuildContext context) {
    final code = AnnaStrings.of(context).languageCode;
    String t(String key) => capabilityHealthCopy(code, key);
    return Scaffold(
      appBar: AppBar(title: Text(t('title'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(t('intro')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('capability-health-refresh'),
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh_outlined),
            label: Text(t('refresh')),
          ),
          if (_busy) const LinearProgressIndicator(),
          for (final check in _checks ?? const <CapabilityHealthCheck>[]) ...[
            const Divider(),
            Semantics(
              identifier: 'capability-health-' + check.key,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(check.state == CapabilityHealthState.available
                    ? Icons.info_outline : Icons.warning_amber_outlined),
                title: Text(t(check.key)),
                subtitle: Text(
                  t(check.state.name) + '\n' + t(check.explanation),
                ),
              ),
            ),
          ],
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const ValueKey('capability-health-open-notifications'),
              onPressed: () async {
                await NotificationService.instance.openSystemSettings();
                if (mounted) unawaited(_refresh());
              },
              icon: const Icon(Icons.notifications_outlined),
              label: Text(t('notificationSettings')),
            ),
            OutlinedButton.icon(
              key: const ValueKey('capability-health-open-calendar'),
              onPressed: _openCalendar,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(t('calendarSettings')),
            ),
          ],
        ],
      ),
    );
  }
}
