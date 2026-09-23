import 'package:sembast/sembast.dart';

import 'local_state_backend_io.dart'
    if (dart.library.html) 'local_state_backend_web.dart' as implementation;

Future<Database> openLocalStateDatabase() =>
    implementation.openLocalStateDatabase();

bool get localStateBackendIsTest =>
    implementation.localStateBackendIsTest;
