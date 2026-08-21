import 'package:sembast/sembast.dart';
import '../models/customer_order_model.dart';
import 'sembast_database_factory_io.dart'
    if (dart.library.html) 'sembast_database_factory_web.dart';

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
    return databaseFactory.openDatabase(dbName);
  }

  final _orderStore = intMapStoreFactory.store('customer_orders');

  Future<int> insertOrder(CustomerOrderModel order) async {
    final db = await database;
    return await _orderStore.add(db, order.toMap());
  }

  Future<void> updateOrderDetails({
    required int id,
    required String address,
    required String landmark,
    required String notes,
    required String receiptNumber,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String deliveryResult,
  }) async {
    if (!['pending', 'received', 'returned'].contains(deliveryResult)) {
      throw ArgumentError('نتيجة تسليم غير صالحة: $deliveryResult');
    }
    final db = await database;
    await _orderStore.record(id).update(db, {
      'customer_address': address,
      'customer_landmark': landmark,
      'notes': notes.isEmpty ? null : notes,
      'receipt_number': receiptNumber.isEmpty ? null : receiptNumber,
      'items': items,
      'total_amount': totalAmount,
      'delivery_result': deliveryResult,
      'updated_at': DateTime.now().toIso8601String(),
    });
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
    final finder = Finder(
      filter: Filter.equals('order_number', orderNumber),
      limit: 1,
    );
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
    return records.map((record) {
      final map = Map<String, dynamic>.from(record.value);
      map['id'] = record.key;
      return CustomerOrderModel.fromMap(map);
    }).toList();
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
