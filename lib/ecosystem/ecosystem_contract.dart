abstract final class EcosystemContract {
  static const protocolName = 'OpenAI App Ecosystem Bridge';
  static const schemaVersion = 1;
  static const localTransportVersion = 1;
  static const bridgeIdPrefix = 'ecosystem:v1';
  static const clipboardPrefix = 'ECOSYSTEM_BRIDGE_V1:';
  static const maxLocalPayloadCharacters = 24576;

  static const canonicalAppIds = <String>{
    'wonderlog',
    'annas_diary',
    'notes',
    'trailpath',
  };
}
