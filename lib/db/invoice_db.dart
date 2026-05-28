import 'package:sembast/sembast.dart';
import 'sembast_database_factory.dart';
import 'db_path_provider.dart';

class InvoiceDatabase {
  static final InvoiceDatabase instance = InvoiceDatabase._init();
  static Database? _db;
  InvoiceDatabase._init();

  final _invoiceStore = intMapStoreFactory.store('invoices');
  final _itemStore = intMapStoreFactory.store('invoice_items');

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _openDatabase('invoices.db');
    return _db!;
  }

  Future<Database> _openDatabase(String dbName) async {
    final dbPath = await getDatabasePath(dbName);
    return await getDatabaseFactory().openDatabase(dbPath);
  }

  Future<int> insertInvoice(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) async {
    final database = await db;
    return await database.transaction<int>((txn) async {
      final invoiceRecord = Map<String, dynamic>.from(invoice)..remove('id');
      final id = await _invoiceStore.add(txn, invoiceRecord);
      for (final it in items) {
        final item = Map<String, dynamic>.from(it)
          ..remove('id')
          ..['invoice_id'] = id;
        await _itemStore.add(txn, item);
      }
      return id;
    });
  }

  Future<Map<String, dynamic>?> getInvoiceByNumber(String invoiceNumber) async {
    final database = await db;
    final finder = Finder(filter: Filter.equals('invoice_number', invoiceNumber), limit: 1);
    final invoiceRecords = await _invoiceStore.find(database, finder: finder);
    if (invoiceRecords.isEmpty) return null;
    final invoice = Map<String, dynamic>.from(invoiceRecords.first.value);
    invoice['id'] = invoiceRecords.first.key;
    final items = await _itemStore.find(database,
        finder: Finder(filter: Filter.equals('invoice_id', invoice['id'])));
    invoice['items'] = items
        .map((record) => {...record.value, 'id': record.key})
        .toList();
    return invoice;
  }

  Future<Map<String, dynamic>?> getInvoice(int id) async {
    final database = await db;
    final invoiceRecord = await _invoiceStore.record(id).getSnapshot(database);
    if (invoiceRecord == null) return null;
    final invoice = Map<String, dynamic>.from(invoiceRecord.value);
    invoice['id'] = invoiceRecord.key;
    final items = await _itemStore.find(database,
        finder: Finder(filter: Filter.equals('invoice_id', id)));
    invoice['items'] = items
        .map((record) => {...record.value, 'id': record.key})
        .toList();
    return invoice;
  }

  Future<List<Map<String, dynamic>>> getAllInvoices() async {
    final database = await db;
    final records = await _invoiceStore.find(database,
        finder: Finder(sortOrders: [SortOrder('date', false)]));
    return records
        .map((record) => {...record.value, 'id': record.key})
        .toList();
  }

  Future<void> close() async {
    final database = await db;
    await database.close();
  }
}
