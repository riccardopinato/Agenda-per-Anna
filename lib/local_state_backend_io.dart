import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';

const bool _integrationTestPersistentStorage =
    bool.fromEnvironment('ANNAS_DIARY_INTEGRATION_TEST');

bool get localStateBackendIsTest =>
    Platform.environment['FLUTTER_TEST'] == 'true' &&
    !_integrationTestPersistentStorage;

Future<Database> openLocalStateDatabase() async {
  if (localStateBackendIsTest) {
    return openNewInMemoryDatabase();
  }

  final directory = await getApplicationSupportDirectory();
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final path =
      '${directory.path}${Platform.pathSeparator}annas_diary_state.db';
  return databaseFactoryIo.openDatabase(path, version: 1);
}
