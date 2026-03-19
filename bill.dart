import 'package:hive/hive.dart';

part 'bill.g.dart';

@HiveType(typeId: 1)
class BillItem {
  @HiveField(0)
  String productId;

  @HiveField(1)
  String productName;

  @HiveField(2)
  String barcode;

  @HiveField(3)
  double price;

  @HiveField(4)
  int quantity;

  BillItem({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;
}

@HiveType(typeId: 2)
class Bill extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  List<BillItem> items;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  double discount;

  @HiveField(4)
  double tax;

  @HiveField(5)
  String customerName;

  @HiveField(6)
  String paymentMethod;

  Bill({
    required this.id,
    required this.items,
    required this.createdAt,
    this.discount = 0,
    this.tax = 0,
    this.customerName = 'Walk-in Customer',
    this.paymentMethod = 'Cash',
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (discount / 100);
  double get taxAmount => (subtotal - discountAmount) * (tax / 100);
  double get grandTotal => subtotal - discountAmount + taxAmount;
}
