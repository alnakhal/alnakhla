import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import '../models/customer_order_model.dart';

class CustomerOrdersDatabase {
  static final CustomerOrdersDatabase instance = CustomerOrdersDatabase._init();
  static Database? _database;

  CustomerOrdersDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('customer_orders.db');
    return _database!;
  }

  Future<Database> _initDB(String dbName) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDocDir.path}/$dbName';
    final db = await databaseFactoryIo.openDatabase(dbPath);
    return db;
  }

  final _orderStore = intMapStoreFactory.store('customer_orders');

  Future<int> insertOrder(CustomerOrderModel order) async {
    final db = await database;
    return await _orderStore.add(db, order.toMap());
  }

  Future<void> updateOrderStatus(int id, String newStatus) async {
    final db = await database;
    final updatedMap = {
      'updated_at': DateTime.now().toIso8601String(),
      'status': newStatus,
    };
    await _orderStore.record(id).update(db, updatedMap);
  }

  Future<CustomerOrderModel?> getOrder(int id) async {
    final db = await database;
    final record = await _orderStore.record(id).getSnapshot(db);
    if (record == null) return null;
    final map = Map<String, dynamic>.from(record.value);
    map['id'] = record.key;
    return CustomerOrderModel.fromMap(map);
  }

  Future<CustomerOrderModel?> getOrderByNumber(String orderNumber) async {
    final db = await database;
    final finder = Finder(filter: Filter.equals('order_number', orderNumber), limit: 1);
    final records = await _orderStore.find(db, finder: finder);
    if (records.isEmpty) return null;
    final map = Map<String, dynamic>.from(records.first.value);
    map['id'] = records.first.key;
    return CustomerOrderModel.fromMap(map);
  }

  Future<List<CustomerOrderModel>> getAllOrders({String? filterStatus}) async {
    final db = await database;
    Finder? finder;
    if (filterStatus != null) {
      finder = Finder(
        filter: Filter.equals('status', filterStatus),
        sortOrders: [SortOrder('created_at', false)],
      );
    } else {
      finder = Finder(sortOrders: [SortOrder('created_at', false)]);
    }
    final records = await _orderStore.find(db, finder: finder);
    return records
        .map((record) {
          final map = Map<String, dynamic>.from(record.value);
          map['id'] = record.key;
          return CustomerOrderModel.fromMap(map);
        })
        .toList();
  }

  Future<void> deleteOrder(int id) async {
    final db = await database;
    await _orderStore.record(id).delete(db);
  }

  Future<void> clearAll() async {
    final db = await database;
    await _orderStore.delete(db);
  }
}
