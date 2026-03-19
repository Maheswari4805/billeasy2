import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/bill.dart';

class DatabaseService {
  static const String _productsBox = 'products';
  static const String _billsBox = 'bills';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(BillItemAdapter());
    Hive.registerAdapter(BillAdapter());
    await Hive.openBox<Product>(_productsBox);
    await Hive.openBox<Bill>(_billsBox);
  }

  // Products
  static Box<Product> get productsBox => Hive.box<Product>(_productsBox);
  static Box<Bill> get billsBox => Hive.box<Bill>(_billsBox);

  static List<Product> getAllProducts() => productsBox.values.toList();

  static Product? getProductByBarcode(String barcode) {
    try {
      return productsBox.values.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveProduct(Product product) async {
    await productsBox.put(product.id, product);
  }

  static Future<void> deleteProduct(String id) async {
    await productsBox.delete(id);
  }

  // Bills
  static List<Bill> getAllBills() =>
      billsBox.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static Future<void> saveBill(Bill bill) async {
    await billsBox.put(bill.id, bill);
  }

  static Future<void> deleteBill(String id) async {
    await billsBox.delete(id);
  }

  static double getTodayRevenue() {
    final now = DateTime.now();
    return billsBox.values
        .where((b) =>
            b.createdAt.year == now.year &&
            b.createdAt.month == now.month &&
            b.createdAt.day == now.day)
        .fold(0, (sum, b) => sum + b.grandTotal);
  }

  static int getTodayBillCount() {
    final now = DateTime.now();
    return billsBox.values
        .where((b) =>
            b.createdAt.year == now.year &&
            b.createdAt.month == now.month &&
            b.createdAt.day == now.day)
        .length;
  }
}
