import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/invoice_db.dart';
import '../models/invoice_item_model.dart';
import '../sync/invoice_sync.dart';

class InvoiceCreatePage extends StatefulWidget {
  const InvoiceCreatePage({super.key});

  @override
  State<InvoiceCreatePage> createState() => _InvoiceCreatePageState();
}

class _InvoiceCreatePageState extends State<InvoiceCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _invoiceNotesController = TextEditingController();
  final _discountController = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  DateTime? _dueDate;
  final List<InvoiceItemModel> _items = [];
  bool _isSaving = false;

  bool get _canSave => !_isSaving && _items.isNotEmpty && _customerNameController.text.trim().isNotEmpty;

  double get subtotal => _items.fold(0.0, (s, it) => s + (it.quantity * it.unitPrice));
  double get tax => _items.fold(0.0, (s, it) => s + it.tax);
  double get discount => double.tryParse(_discountController.text.replaceAll(RegExp(r'[٬،٫]'), '.')) ?? 0;
  double get total => (subtotal + tax - discount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _customerNameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _invoiceNotesController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  double _parseToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim().replaceAll(RegExp(r'[٬،٫]'), '.');
      return double.tryParse(normalized) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> _normalizeInvoiceItemMap(Map<String, dynamic> item) {
    return {
      if (item.containsKey('id') && item['id'] != null) 'id': item['id'],
      'description': item['description']?.toString() ?? '',
      'quantity': _parseToDouble(item['quantity']),
      'unit_price': _parseToDouble(item['unit_price']),
      'tax': _parseToDouble(item['tax']),
      'total': _parseToDouble(item['total']),
      'note': item['note']?.toString(),
    };
  }

  Future<void> _selectProduct(TextEditingController descC, TextEditingController priceC) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final result = await Supabase.instance.client.from('products').select('id,name,price,remaining_qty').eq('user_id', user.id).order('created_at', ascending: false);
    final products = <Map<String, dynamic>>[];
    try {
      final itemList = result as List<dynamic>;
      for (final item in itemList) {
        if (item is Map<String, dynamic>) {
          products.add(item);
        }
      }
    } catch (_) {}

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر منتجاً من الكتالوج'),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: products.isEmpty
              ? const Center(child: Text('لا توجد منتجات محفوظة'))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final product = products[i];
                    final name = product['name']?.toString() ?? '';
                    final price = _parseToDouble(product['price']);
                    final remainingQty = product['remaining_qty']?.toString() ?? '0';
                    return ListTile(
                      title: Text(name),
                      subtitle: Text('السعر: ${price.toStringAsFixed(2)} • الكمية المتاحة: $remainingQty'),
                      onTap: () {
                        descC.text = name;
                        priceC.text = price.toStringAsFixed(2);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  void _showItemDialog({InvoiceItemModel? item, int? index}) {
    final descC = TextEditingController(text: item?.description ?? '');
    final qtyC = TextEditingController(text: item != null ? item.quantity.toString() : '1');
    final priceC = TextEditingController(text: item != null ? item.unitPrice.toString() : '0');
    final taxC = TextEditingController(text: item != null ? item.tax.toString() : '0');
    final noteC = TextEditingController(text: item?.note ?? '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'أضف بنداً' : 'تعديل بند'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: descC, decoration: const InputDecoration(labelText: 'الوصف')),
            TextField(controller: qtyC, decoration: const InputDecoration(labelText: 'الكمية'), keyboardType: TextInputType.number),
            TextField(controller: priceC, decoration: const InputDecoration(labelText: 'سعر الوحدة'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: taxC, decoration: const InputDecoration(labelText: 'الضرائب'), keyboardType: TextInputType.numberWithOptions(decimal: true)),
            TextField(controller: noteC, decoration: const InputDecoration(labelText: 'ملاحظات البند')),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _selectProduct(descC, priceC),
              icon: const Icon(Icons.inventory_2),
              label: const Text('اختيار منتج من الكتالوج'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final desc = descC.text.trim();
              final qty = _parseToDouble(qtyC.text);
              final price = _parseToDouble(priceC.text);
              final tax = _parseToDouble(taxC.text);
              if (desc.isEmpty) return;
              setState(() {
                final newItem = InvoiceItemModel(description: desc, quantity: qty, unitPrice: price, tax: tax, note: noteC.text.trim());
                if (index != null && index >= 0 && index < _items.length) {
                  _items[index] = newItem;
                } else {
                  _items.add(newItem);
                }
              });
              Navigator.of(ctx).pop();
            },
            child: Text(item == null ? 'أضف' : 'حفظ التعديل'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أضف بنداً واحداً على الأقل')));
      return;
    }
    setState(() => _isSaving = true);
    final invoiceNumber = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000).toString().padLeft(3, '0')}';
    final invoice = {
      'invoice_number': invoiceNumber,
      'customer_id': null,
      'customer_name': _customerNameController.text.trim(),
      'date': _date.toIso8601String(),
      'due_date': _dueDate?.toIso8601String(),
      'subtotal': subtotal.toDouble(),
      'tax': tax.toDouble(),
      'discount': discount.toDouble(),
      'total': total.toDouble(),
      'status': 'draft',
      'notes': _invoiceNotesController.text.trim().isNotEmpty ? _invoiceNotesController.text.trim() : null,
    };
    final items = _items.map((e) => _normalizeInvoiceItemMap(e.toMap())).toList();
    try {
      await InvoiceDatabase.instance.insertInvoice(invoice, items);
      // attempt to push to Supabase (best-effort)
      try {
        await pushInvoiceToSupabase(invoice, items);
      } catch (e) {
        debugPrint('Supabase push ignored: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الفاتورة')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ عند الحفظ: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd('ar');
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء / تعديل فاتورة')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _customerNameController,
                decoration: const InputDecoration(labelText: 'اسم العميل'),
                validator: (v) => v == null || v.trim().isEmpty ? 'يرجى إدخال اسم العميل' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _invoiceNotesController,
                decoration: const InputDecoration(labelText: 'ملاحظات الفاتورة', hintText: 'اكتب ملاحظات عامة تظهر في الفاتورة'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: Text('تاريخ الفاتورة: ${dateFmt.format(_date)}')),
                  TextButton(onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime(2100));
                    if (picked != null) setState(() => _date = picked);
                  }, child: const Text('تغيير')),
                ],
              ),
              Row(
                children: [
                  Expanded(child: Text('تاريخ الاستحقاق: ${_dueDate != null ? dateFmt.format(_dueDate!) : '-'}')),
                  TextButton(onPressed: _pickDueDate, child: const Text('اختيار')), 
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(labelText: 'الخصم'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              const Text('العناصر', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: _items.isEmpty
                    ? const Center(child: Text('لا توجد عناصر'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('الوصف')),
                            DataColumn(label: Text('ملاحظات')),
                            DataColumn(label: Text('الكمية')),
                            DataColumn(label: Text('سعر الوحدة')),
                            DataColumn(label: Text('الضريبة')),
                            DataColumn(label: Text('الإجمالي')),
                            DataColumn(label: Text('إجراءات')),
                          ],
                          rows: List.generate(_items.length, (i) {
                            final it = _items[i];
                            return DataRow(cells: [
                              DataCell(SizedBox(width: 180, child: Text(it.description, overflow: TextOverflow.ellipsis))),
                              DataCell(SizedBox(width: 140, child: Text(it.note ?? '-', overflow: TextOverflow.ellipsis))),
                              DataCell(Text(it.quantity.toStringAsFixed(2))),
                              DataCell(Text(it.unitPrice.toStringAsFixed(2))),
                              DataCell(Text(it.tax.toStringAsFixed(2))),
                              DataCell(Text(it.total.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold))),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _showItemDialog(item: it, index: i),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () => setState(() => _items.removeAt(i)),
                                  ),
                                ],
                              )),
                            ]);
                          }),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('المجموع: ${subtotal.toStringAsFixed(2)}'),
                  Text('الضريبة: ${tax.toStringAsFixed(2)}'),
                  Text('الإجمالي: ${total.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 12),
              Row(children: [Expanded(child: FilledButton(onPressed: () => _showItemDialog(), child: const Text('أضف بند'))), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: _canSave ? _saveInvoice : null, child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ الفاتورة')))]),
            ],
          ),
        ),
      ),
    );
  }
}
