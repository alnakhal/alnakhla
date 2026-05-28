import 'package:sembast/sembast.dart';
import 'sembast_database_factory_io.dart'
    if (dart.library.html) 'sembast_database_factory_web.dart';

DatabaseFactory getDatabaseFactory() => databaseFactory;
