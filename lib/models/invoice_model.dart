class InvoiceModel {
  final int? id;
  final String customer_name; // يجب أن يطابق تماماً اسم العمود في Supabase
  final String invoice_number;
  final DateTime created_at;

  InvoiceModel({
    this.id,
    required this.customer_name,
    required this.invoice_number,
    required this.created_at,
  });

  // تحويل البيانات من قاعدة البيانات (Map) إلى كائن (Object)
  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    int? parsedId;
    final rawId = map['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId);
    }
    return InvoiceModel(
      id: parsedId,
      customer_name: map['customer_name'] as String? ?? '',
      invoice_number: map['invoice_number'] as String? ?? '',
      created_at: DateTime.parse(map['created_at'] as String),
    );
  }

  // تحويل البيانات من كائن (Object) إلى (Map) لإرسالها لقاعدة البيانات
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'customer_name': customer_name,
      'invoice_number': invoice_number,
      'created_at': created_at.toIso8601String(),
    };
  }
}
