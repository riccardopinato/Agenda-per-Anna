part of '../main.dart';

extension AnnaD3DomainStrings on AnnaStrings {
  String get d3StarterHabitWater => _pick(
        en: 'Drink enough water',
        it: 'Bere abbastanza',
        es: 'Beber suficiente agua',
        fr: 'Boire suffisamment',
        pt: 'Beber água suficiente',
      );

  String get d3StarterHabitMove => _pick(
        en: 'Move a little',
        it: 'Muovermi un po’',
        es: 'Moverme un poco',
        fr: 'Bouger un peu',
        pt: 'Mexer-me um pouco',
      );

  String get d3StarterHabitMe => _pick(
        en: 'Time for myself',
        it: 'Tempo per me',
        es: 'Tiempo para mí',
        fr: 'Du temps pour moi',
        pt: 'Tempo para mim',
      );

  String d3PermissionStatus(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '');
    final status = switch (normalized) {
      'authorized' => _pick(
          en: 'authorized',
          it: 'autorizzato',
          es: 'autorizado',
          fr: 'autorisée',
          pt: 'autorizada',
        ),
      'granted' => _pick(
          en: 'granted',
          it: 'concesso',
          es: 'concedido',
          fr: 'accordée',
          pt: 'concedida',
        ),
      'denied' => _pick(
          en: 'denied',
          it: 'negato',
          es: 'denegado',
          fr: 'refusée',
          pt: 'negada',
        ),
      'provisional' => _pick(
          en: 'provisional',
          it: 'provvisorio',
          es: 'provisional',
          fr: 'provisoire',
          pt: 'provisória',
        ),
      'notdetermined' || 'default' => _pick(
          en: 'not decided',
          it: 'non deciso',
          es: 'sin decidir',
          fr: 'non décidée',
          pt: 'por decidir',
        ),
      'notconfigured' => _pick(
          en: 'not configured',
          it: 'non configurato',
          es: 'no configurado',
          fr: 'non configurée',
          pt: 'não configurada',
        ),
      'unknown' || '...' => _pick(
          en: 'unknown',
          it: 'sconosciuto',
          es: 'desconocido',
          fr: 'inconnue',
          pt: 'desconhecida',
        ),
      _ => value,
    };

    return _pick(
      en: 'permission: $status',
      it: 'permesso: $status',
      es: 'permiso: $status',
      fr: 'autorisation : $status',
      pt: 'permissão: $status',
    );
  }
}
