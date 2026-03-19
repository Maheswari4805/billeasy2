import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/bill.dart';
import '../services/app_theme.dart';

class BillDetailScreen extends StatelessWidget {
  final Bill bill;
  const BillDetailScreen({super.key, required this.bill});

  final currencyFormat = const NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Bill #${bill.id.substring(0, 8).toUpperCase()}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () => _printBill(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _printBill(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Success banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 40),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bill Generated!',
                          style: GoogleFonts.googleSans(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('Payment received successfully',
                          style: GoogleFonts.googleSans(color: Colors.white70, fontSize: 13)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Receipt Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE8EAED))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.receipt, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text('BillEasy',
                            style: GoogleFonts.googleSans(
                                fontSize: 20, fontWeight: FontWeight.w700)),
                        Text(
                          DateFormat('MMM d, yyyy • h:mm a').format(bill.createdAt),
                          style: GoogleFonts.googleSans(
                              color: const Color(0xFF5F6368), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 28),

                  // Customer info
                  _infoRow('Customer', bill.customerName),
                  _infoRow('Payment', bill.paymentMethod),
                  _infoRow('Bill ID', '#${bill.id.substring(0, 8).toUpperCase()}'),
                  const Divider(height: 24),

                  // Items
                  Text('Items',
                      style: GoogleFonts.googleSans(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 12),
                  ...bill.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName,
                                  style: GoogleFonts.googleSans(
                                      fontSize: 14, fontWeight: FontWeight.w500)),
                              Text('${item.quantity} × ${currencyFormat.format(item.price)}',
                                  style: GoogleFonts.googleSans(
                                      fontSize: 12, color: const Color(0xFF5F6368))),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormat.format(item.total),
                          style: GoogleFonts.googleSans(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )),
                  const Divider(),

                  // Totals
                  _totalRow('Subtotal', currencyFormat.format(bill.subtotal)),
                  if (bill.discount > 0)
                    _totalRow(
                        'Discount (${bill.discount.toInt()}%)',
                        '- ${currencyFormat.format(bill.discountAmount)}',
                        color: AppTheme.error),
                  if (bill.tax > 0)
                    _totalRow(
                        'Tax (${bill.tax.toInt()}%)',
                        '+ ${currencyFormat.format(bill.taxAmount)}'),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Grand Total',
                          style: GoogleFonts.googleSans(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(
                        currencyFormat.format(bill.grandTotal),
                        style: GoogleFonts.googleSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.add),
                    label: const Text('New Bill'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _printBill(context),
                    icon: const Icon(Icons.print),
                    label: const Text('Print Receipt'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.googleSans(color: const Color(0xFF5F6368), fontSize: 13)),
          Text(value, style: GoogleFonts.googleSans(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.googleSans(color: const Color(0xFF5F6368), fontSize: 13)),
          Text(value,
              style: GoogleFonts.googleSans(
                  fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _printBill(BuildContext context) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('BillEasy',
                      style: pw.TextStyle(
                          fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Receipt'),
                  pw.SizedBox(height: 4),
                  pw.Text(DateFormat('MMM d, yyyy h:mm a').format(bill.createdAt)),
                ],
              ),
            ),
            pw.Divider(),
            pw.Text('Customer: ${bill.customerName}'),
            pw.Text('Payment: ${bill.paymentMethod}'),
            pw.Divider(),
            pw.Text('Items:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            ...bill.items.map((item) => pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('${item.productName} x${item.quantity}'),
                pw.Text('\$${item.total.toStringAsFixed(2)}'),
              ],
            )),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('\$${bill.grandTotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}
