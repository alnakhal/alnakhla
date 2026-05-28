import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../db/invoice_db.dart';

final _supabase = Supabase.instance.client;

String _normalizeNumberString(String value) {
  return value.trim().replaceAll(RegExp(r'[٬،٫]'), '.');
}

double _parseNumber(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(_normalizeNumberString(value)) ?? 0;
  return 0;
}

Map<String, dynamic> _normalizeInvoiceItem(Map<String, dynamic> item) {
  return {
    if (item.containsKey('id') && item['id'] != null) 'id': item['id'],
    'description': item['description']?.toString() ?? '',
    'quantity': _parseNumber(item['quantity']),
    'unit_price': _parseNumber(item['unit_price']),
    'tax': _parseNumber(item['tax']),
    'total': _parseNumber(item['total']),
    'note': item['note']?.toString(),
  };
}

Map<String, dynamic> _normalizeInvoice(Map<String, dynamic> invoice) {
  return {
    'invoice_number': invoice['invoice_number']?.toString(),
    'customer_id': invoice['customer_id'],
    'customer_name': invoice['customer_name']?.toString() ?? '',
    'date': invoice['date']?.toString(),
    'due_date': invoice['due_date']?.toString(),
    'subtotal': _parseNumber(invoice['subtotal']),
    'tax': _parseNumber(invoice['tax']),
    'discount': _parseNumber(invoice['discount']),
    'total': _parseNumber(invoice['total']),
    'status': invoice['status']?.toString() ?? 'draft',
    'notes': invoice['notes']?.toString(),
  };
}

/// Push a local invoice (map) and its items to Supabase.
Future<bool> pushInvoiceToSupabase(Map<String, dynamic> invoice, List<Map<String, dynamic>> items) async {
  final user = _supabase.auth.currentUser;
  if (user == null) return false;
  try {
    final invMap = _normalizeInvoice(Map<String, dynamic>.from(invoice));
    invMap['user_id'] = user.id;
    // Insert invoice
    final res = await _supabase.from('invoices').insert(invMap).select('id').maybeSingle();
    int? remoteId;
    try {
      if (res is Map<String, dynamic>) {
        final idValue = res['id'];
        if (idValue is int) {
          remoteId = idValue;
        } else if (idValue is String) {
          remoteId = int.tryParse(idValue);
        }
      }
    } catch (_) {
      // ignore
    }
    // Insert items referencing remote invoice id if available
    for (final it in items) {
      final m = _normalizeInvoiceItem(Map<String, dynamic>.from(it));
      m['user_id'] = user.id;
      if (remoteId != null) m['invoice_id'] = remoteId;
      await _supabase.from('invoice_items').insert(m);
    }
    return true;
  } catch (e) {
    _logDebug('Supabase push failed: $e');
    return false;
  }
}

/// Pull invoices for the current user from Supabase and insert locally if missing.
Future<void> pullInvoicesFromSupabase() async {
  final user = _supabase.auth.currentUser;
  if (user == null) return;
  try {
    final res = await _supabase.from('invoices').select().eq('user_id', user.id) as List<dynamic>;
    for (final r in res) {
      final Map<String, dynamic> inv = Map<String, dynamic>.from(r as Map<String, dynamic>);
      final invoiceNumber = inv['invoice_number']?.toString();
      if (invoiceNumber == null) continue;
      final exists = await InvoiceDatabase.instance.getInvoiceByNumber(invoiceNumber);
      if (exists != null) continue; // skip existing

      // fetch items for this remote invoice if remote id exists
      List<Map<String, dynamic>> items = [];
      try {
        final remoteId = inv['id'];
        if (remoteId != null) {
          final its = await _supabase.from('invoice_items').select().eq('invoice_id', remoteId) as List<dynamic>;
          items = its.map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>)).toList();
        }
      } catch (_) {}

      // prepare local invoice map
      final local = {
        'invoice_number': invoiceNumber,
        'customer_id': inv['customer_id'],
        'customer_name': inv['customer_name'],
        'date': inv['date'] ?? DateTime.now().toIso8601String(),
        'due_date': inv['due_date'],
        'status': inv['status'] ?? 'sent',
        'subtotal': inv['subtotal'] ?? 0,
        'tax': inv['tax'] ?? 0,
        'discount': inv['discount'] ?? 0,
        'total': inv['total'] ?? 0,
        'notes': inv['notes'],
      };
      await InvoiceDatabase.instance.insertInvoice(local, items);
    }
  } catch (e) {
    _logDebug('Supabase pull failed: $e');
  }
}

void _logDebug(String? s) => log(s ?? '');
