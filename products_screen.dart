import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> _products = [];
  String _search = '';
  final currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    setState(() => _products = DatabaseService.getAllProducts());
  }

  List<Product> get _filteredProducts => _products.where((p) {
        final q = _search.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.barcode.contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368)),
                hintStyle: GoogleFonts.googleSans(color: const Color(0xFF9AA0A6)),
              ),
            ),
          ),
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _products.isEmpty ? 'No products yet' : 'No results found',
                          style: GoogleFonts.googleSans(color: const Color(0xFF5F6368)),
                        ),
                        if (_products.isEmpty)
                          TextButton.icon(
                            onPressed: () => _showAddProductDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Product'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (_, i) => _buildProductTile(_filteredProducts[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE8EAED))),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory, color: AppTheme.primary),
        ),
        title: Text(product.name,
            style: GoogleFonts.googleSans(fontWeight: FontWeight.w500)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.barcode,
                style: GoogleFonts.googleSans(
                    fontSize: 12, color: const Color(0xFF5F6368))),
            Text(product.category,
                style: GoogleFonts.googleSans(
                    fontSize: 11, color: const Color(0xFF9AA0A6))),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currencyFormat.format(product.price),
              style: GoogleFonts.googleSans(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                fontSize: 15,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _showEditProductDialog(context, product),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                  onPressed: () => _deleteProduct(product),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Remove "${product.name}" from your inventory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              DatabaseService.deleteProduct(product.id);
              Navigator.pop(context);
              _loadProducts();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    _showProductDialog(context, null);
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    _showProductDialog(context, product);
  }

  void _showProductDialog(BuildContext context, Product? existing) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final barcodeCtrl = TextEditingController(text: existing?.barcode);
    final priceCtrl = TextEditingController(text: existing?.price.toString());
    final categoryCtrl = TextEditingController(text: existing?.category ?? 'General');
    bool isScanning = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'Add Product' : 'Edit Product',
                style: GoogleFonts.googleSans(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Product Name', prefixIcon: Icon(Icons.label_outline)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: barcodeCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Barcode', prefixIcon: Icon(Icons.qr_code)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => setDialogState(() => isScanning = !isScanning),
                    icon: const Icon(Icons.qr_code_scanner),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
                  ),
                ],
              ),
              if (isScanning) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: MobileScanner(
                      onDetect: (capture) {
                        final barcode = capture.barcodes.firstOrNull?.rawValue;
                        if (barcode != null) {
                          barcodeCtrl.text = barcode;
                          setDialogState(() => isScanning = false);
                        }
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Price', prefixIcon: Icon(Icons.attach_money)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: categoryCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final product = Product(
                      id: existing?.id ?? const Uuid().v4(),
                      name: nameCtrl.text,
                      barcode: barcodeCtrl.text,
                      price: double.tryParse(priceCtrl.text) ?? 0,
                      category: categoryCtrl.text,
                    );
                    DatabaseService.saveProduct(product);
                    Navigator.pop(ctx);
                    _loadProducts();
                  },
                  child: Text(existing == null ? 'Add Product' : 'Save Changes'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
