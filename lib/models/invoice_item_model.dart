class InvoiceItemModel {
  int? id;
  String description;
  double quantity;
  double unitPrice;
  double tax;
  String? note;

  InvoiceItemModel({this.id, required this.description, required this.quantity, required this.unitPrice, this.tax = 0, this.note})
      : assert(description.isNotEmpty);

  double get total => (quantity * unitPrice) + tax;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'description': description,
        'quantity': quantity,
        'unit_price': unitPrice,
        'tax': tax,
        'total': total,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  factory InvoiceItemModel.fromMap(Map<String, dynamic> m) {
    int? parsedId;
    final rawId = m['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId);
    }
    return InvoiceItemModel(
      id: parsedId,
      description: m['description']?.toString() ?? '',
      quantity: (m['quantity'] is num) ? (m['quantity'] as num).toDouble() : double.tryParse(m['quantity']?.toString() ?? '0') ?? 0,
      unitPrice: (m['unit_price'] is num) ? (m['unit_price'] as num).toDouble() : double.tryParse(m['unit_price']?.toString() ?? '0') ?? 0,
      tax: (m['tax'] is num) ? (m['tax'] as num).toDouble() : double.tryParse(m['tax']?.toString() ?? '0') ?? 0,
      note: m['note']?.toString(),
    );
  }
}
