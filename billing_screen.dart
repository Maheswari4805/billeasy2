import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/bill.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import 'bill_detail_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  final List<BillItem> _cartItems = [];
  bool _isScannerActive = false;
  final MobileScannerController _scannerController = MobileScannerController();
  double _discount = 0;
  double _tax = 0;
  String _customerName = 'Walk-in Customer';
  String _paymentMethod = 'Cash';
  final currencyFormat = NumberFormat.currency(symbol: '\$');
  late AnimationController _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _scanAnimation.dispose();
    super.dispose();
  }

  double get subtotal => _cartItems.fold(0, (sum, i) => sum + i.total);
  double get discountAmount => subtotal * (_discount / 100);
  double get taxAmount => (subtotal - discountAmount) * (_tax / 100);
  double get grandTotal => subtotal - discountAmount + taxAmount;

  void _onBarcodeDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode == null) return;

    HapticFeedback.mediumImpact();
    final product = DatabaseService.getProductByBarcode(barcode);

    if (product != null) {
      _addToCart(product);
      setState(() => _isScannerActive = false);
    } else {
      _showProductNotFound(barcode);
    }
  }

  void _addToCart(Product product) {
    setState(() {
      final existing = _cartItems.indexWhere((i) => i.barcode == product.barcode);
      if (existing >= 0) {
        _cartItems[existing] = BillItem(
          productId: _cartItems[existing].productId,
          productName: _cartItems[existing].productName,
          barcode: _cartItems[existing].barcode,
          price: _cartItems[existing].price,
          quantity: _cartItems[existing].quantity + 1,
        );
      } else {
        _cartItems.add(BillItem(
          productId: product.id,
          productName: product.name,
          barcode: product.barcode,
          price: product.price,
          quantity: 1,
        ));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added: ${product.name}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showProductNotFound(String barcode) {
    setState(() => _isScannerActive = false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('No product found for barcode:\n$barcode'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddProductDialog(barcode);
            },
            child: const Text('Add Product'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(String barcode) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Barcode: $barcode',
                style: const TextStyle(color: Color(0xFF5F6368))),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Product Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final product = Product(
                id: const Uuid().v4(),
                name: nameCtrl.text,
                barcode: barcode,
                price: double.tryParse(priceCtrl.text) ?? 0,
              );
              DatabaseService.saveProduct(product);
              _addToCart(product);
              Navigator.pop(ctx);
            },
            child: const Text('Save & Add'),
          ),
        ],
      ),
    );
  }

  void _saveBill() async {
    if (_cartItems.isEmpty) return;

    final bill = Bill(
      id: const Uuid().v4(),
      items: List.from(_cartItems),
      createdAt: DateTime.now(),
      discount: _discount,
      tax: _tax,
      customerName: _customerName,
      paymentMethod: _paymentMethod,
    );

    await DatabaseService.saveBill(bill);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
      );
      setState(() {
        _cartItems.clear();
        _discount = 0;
        _tax = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('New Bill'),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _cartItems.clear()),
              icon: const Icon(Icons.clear_all, size: 18),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Scanner Area
          if (_isScannerActive)
            _buildScannerView()
          else
            _buildScanButton(),

          // Cart
          Expanded(
            child: _cartItems.isEmpty
                ? _buildEmptyCart()
                : _buildCartList(),
          ),

          // Bill Summary
          if (_cartItems.isNotEmpty) _buildBillSummary(),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () => setState(() => _isScannerActive = true),
      child: Container(
        margin: const EdgeInsets.all(16),
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary.withOpacity(0.08), AppTheme.primary.withOpacity(0.03)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tap to Scan Barcode',
                  style: GoogleFonts.googleSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                Text(
                  'Scan product barcode to add to bill',
                  style: GoogleFonts.googleSans(
                    fontSize: 13,
                    color: const Color(0xFF5F6368),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
      ),
      child: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetected,
          ),
          // Scan overlay
          Center(
            child: Container(
              width: 220,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _scanAnimation,
            builder: (_, __) {
              return Positioned(
                left: (MediaQuery.of(context).size.width - 32 - 220) / 2,
                top: 65 + _scanAnimation.value * 80,
                child: Container(
                  width: 220,
                  height: 2,
                  color: AppTheme.primary.withOpacity(0.8),
                ),
              );
            },
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => setState(() => _isScannerActive = false),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Align barcode within the frame',
                style: GoogleFonts.googleSans(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Cart is empty',
            style: GoogleFonts.googleSans(
              fontSize: 16,
              color: const Color(0xFF5F6368),
            ),
          ),
          Text(
            'Scan a barcode to add products',
            style: GoogleFonts.googleSans(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _cartItems.length,
      itemBuilder: (_, index) {
        final item = _cartItems[index];
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory, color: AppTheme.primary, size: 20),
            ),
            title: Text(item.productName,
                style: GoogleFonts.googleSans(fontWeight: FontWeight.w500)),
            subtitle: Text(currencyFormat.format(item.price),
                style: GoogleFonts.googleSans(color: const Color(0xFF5F6368), fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  onPressed: () {
                    setState(() {
                      if (item.quantity > 1) {
                        _cartItems[index] = BillItem(
                          productId: item.productId,
                          productName: item.productName,
                          barcode: item.barcode,
                          price: item.price,
                          quantity: item.quantity - 1,
                        );
                      } else {
                        _cartItems.removeAt(index);
                      }
                    });
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: GoogleFonts.googleSans(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: AppTheme.primary),
                  onPressed: () {
                    setState(() {
                      _cartItems[index] = BillItem(
                        productId: item.productId,
                        productName: item.productName,
                        barcode: item.barcode,
                        price: item.price,
                        quantity: item.quantity + 1,
                      );
                    });
                  },
                ),
                Text(
                  currencyFormat.format(item.total),
                  style: GoogleFonts.googleSans(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBillSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black08, blurRadius: 12, offset: const Offset(0, -4))],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary rows
          _summaryRow('Subtotal', currencyFormat.format(subtotal)),
          _summaryRow('Discount (${_discount.toInt()}%)', '- ${currencyFormat.format(discountAmount)}'),
          _summaryRow('Tax (${_tax.toInt()}%)', '+ ${currencyFormat.format(taxAmount)}'),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.googleSans(fontSize: 16, fontWeight: FontWeight.w700)),
              Text(
                currencyFormat.format(grandTotal),
                style: GoogleFonts.googleSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveBill,
              icon: const Icon(Icons.check_circle_outline),
              label: Text('Generate Bill • ${currencyFormat.format(grandTotal)}'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.googleSans(fontSize: 13, color: const Color(0xFF5F6368))),
          Text(value, style: GoogleFonts.googleSans(fontSize: 13)),
        ],
      ),
    );
  }
}
