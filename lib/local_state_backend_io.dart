import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/sembast_memory.dart';

bool get localStateBackendIsTest =>
    Platform.environment['FLUTTER_TEST'] == 'true';

Future<Database> openLocalStateDatabase() async {
  if (localStateBackendIsTest) {
    return openNewInMemoryDatabase();
  }

  Directory directory;
  try {
    directory = await getApplicationSupportDirectory();
  } catch (_) {
    directory = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}annas_diary',
    );
  }

  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final path =
      '${directory.path}${Platform.pathSeparator}annas_diary_state.db';
  return databaseFactoryIo.openDatabase(path, version: 1);
}
