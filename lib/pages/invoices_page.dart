import 'package:flutter/material.dart';
import '../db/invoice_db.dart';
import 'invoice_create_page.dart';
import '../sync/invoice_sync.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  late Future<List<Map<String, dynamic>>> _invoicesFuture;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
    // pull remote invoices and refresh
    pullInvoicesFromSupabase().then((_) => setState(() => _loadInvoices()));
  }

  void _loadInvoices() {
    _invoicesFuture = InvoiceDatabase.instance.getAllInvoices();
  }

  Future<void> _addSampleInvoice() async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const InvoiceCreatePage()));
    if (created == true) setState(() => _loadInvoices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفواتير')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _invoicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('خطأ: ${snapshot.error}'));
          final invoices = snapshot.data ?? [];
          if (invoices.isEmpty) return Center(child: Text('لا توجد فواتير بعد'));
          return ListView.builder(
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final inv = invoices[index];
              return ListTile(
                title: Text(inv['invoice_number']?.toString() ?? ''),
                subtitle: Text(inv['customer_name']?.toString() ?? ''),
                trailing: Text((inv['total'] ?? 0).toString()),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSampleInvoice,
        child: const Icon(Icons.add),
        tooltip: 'أضف فاتورة',
      ),
    );
  }
}
