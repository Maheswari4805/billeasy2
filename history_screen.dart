import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import '../models/bill.dart';
import 'bill_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Bill> _bills = [];
  final currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  void initState() {
    super.initState();
    _loadBills();
  }

  void _loadBills() {
    setState(() => _bills = DatabaseService.getAllBills());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Bill History')),
      body: _bills.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('No bills yet',
                      style: GoogleFonts.googleSans(color: const Color(0xFF5F6368))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bills.length,
              itemBuilder: (_, i) {
                final bill = _bills[i];
                // Group header by date
                final showHeader = i == 0 ||
                    !_isSameDay(bill.createdAt, _bills[i - 1].createdAt);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader) ...[
                      if (i != 0) const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _formatDate(bill.createdAt),
                          style: GoogleFonts.googleSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5F6368),
                          ),
                        ),
                      ),
                    ],
                    _buildBillCard(context, bill),
                  ],
                );
              },
            ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (_isSameDay(d, now)) return 'Today';
    if (_isSameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(d);
  }

  Widget _buildBillCard(BuildContext context, Bill bill) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BillDetailScreen(bill: bill)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE8EAED))),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.customerName,
                    style: GoogleFonts.googleSans(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${bill.items.length} items • ${DateFormat('h:mm a').format(bill.createdAt)}',
                    style: GoogleFonts.googleSans(
                        fontSize: 12, color: const Color(0xFF5F6368)),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(bill.grandTotal),
                  style: GoogleFonts.googleSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.secondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    bill.paymentMethod,
                    style: GoogleFonts.googleSans(
                        fontSize: 11, color: AppTheme.secondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
