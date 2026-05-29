import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<String> getDatabasePathImpl(String dbName) async {
  final dir = await getApplicationDocumentsDirectory();
  return join(dir.path, dbName);
}
