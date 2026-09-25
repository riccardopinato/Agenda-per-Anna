Future<String> webPushHealthJson() async =>
    '{"supported":false,"secureContext":false,"installedPwa":false,"isIos":false,"permission":"unsupported","subscription":null}';

Future<String> webPushSubscribeJson(String vapidKey) async =>
    '{"ok":false,"error":"web_push_not_supported"}';

Future<String> webPushUnsubscribeJson() async =>
    '{"ok":true,"endpoint":null}';

Future<String> webPushTakeInitialSpaceJson() async =>
    '{"spaceId":null}';
