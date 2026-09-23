import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

bool get localStateBackendIsTest => false;

Future<Database> openLocalStateDatabase() =>
    databaseFactoryWeb.openDatabase('annas_diary_state_v1', version: 1);
