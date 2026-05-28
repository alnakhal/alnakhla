import 'db_path_provider_io.dart'
    if (dart.library.html) 'db_path_provider_web.dart';

Future<String> getDatabasePath(String dbName) => getDatabasePathImpl(dbName);
