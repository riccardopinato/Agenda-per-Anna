import 'dart:js_interop';

@JS('annasDiaryWebPush.health')
external JSPromise<JSString> _health();

@JS('annasDiaryWebPush.subscribe')
external JSPromise<JSString> _subscribe(JSString vapidKey);

@JS('annasDiaryWebPush.unsubscribe')
external JSPromise<JSString> _unsubscribe();

@JS('annasDiaryWebPush.takeInitialSpaceId')
external JSPromise<JSString> _takeInitialSpaceId();

Future<String> webPushHealthJson() async =>
    (await _health().toDart).toDart;

Future<String> webPushSubscribeJson(String vapidKey) async =>
    (await _subscribe(vapidKey.toJS).toDart).toDart;

Future<String> webPushUnsubscribeJson() async =>
    (await _unsubscribe().toDart).toDart;

Future<String> webPushTakeInitialSpaceJson() async =>
    (await _takeInitialSpaceId().toDart).toDart;
