import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String barcode;

  @HiveField(3)
  double price;

  @HiveField(4)
  String category;

  @HiveField(5)
  int stock;

  @HiveField(6)
  String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    this.category = 'General',
    this.stock = 0,
    this.imageUrl,
  });
}
