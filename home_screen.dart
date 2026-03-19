import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/app_theme.dart';
import 'billing_screen.dart';
import 'products_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardTab(),
    const BillingScreen(),
    const ProductsScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'New Bill',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final currencyFormat = NumberFormat.currency(symbol: '\$');

  @override
  Widget build(BuildContext context) {
    final todayRevenue = DatabaseService.getTodayRevenue();
    final todayBills = DatabaseService.getTodayBillCount();
    final totalProducts = DatabaseService.getAllProducts().length;
    final allBills = DatabaseService.getAllBills();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'BillEasy',
                  style: GoogleFonts.googleSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: const Color(0xFF202124),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary,
                child: Text('A', style: TextStyle(color: Colors.white, fontSize: 14)),
              ),
              const SizedBox(width: 12),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Greeting
                Text(
                  _getGreeting(),
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    color: const Color(0xFF5F6368),
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: GoogleFonts.googleSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 20),

                // Revenue Card
                _buildRevenueCard(todayRevenue, todayBills),
                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Products',
                        totalProducts.toString(),
                        Icons.inventory_2,
                        AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Bills',
                        allBills.length.toString(),
                        Icons.receipt_long,
                        AppTheme.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: GoogleFonts.googleSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 12),
                _buildQuickActions(context),
                const SizedBox(height: 20),

                // Recent Bills
                if (allBills.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: GoogleFonts.googleSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF202124),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...allBills.take(5).map((bill) => _buildBillTile(bill)),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  Widget _buildRevenueCard(double revenue, int bills) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF4285F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today\'s Revenue',
            style: GoogleFonts.googleSans(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(revenue),
            style: GoogleFonts.googleSans(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                '$bills bills today',
                style: GoogleFonts.googleSans(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE8EAED))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.googleSans(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF202124),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.googleSans(
              fontSize: 13,
              color: const Color(0xFF5F6368),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionChip(
          context,
          'Scan & Bill',
          Icons.qr_code_scanner,
          AppTheme.primary,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BillingScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _buildActionChip(
          context,
          'Add Product',
          Icons.add_box_outlined,
          AppTheme.secondary,
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProductsScreen()),
          ),
        ),
        const SizedBox(width: 10),
        _buildActionChip(
          context,
          'History',
          Icons.history,
          const Color(0xFF9334E6),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HistoryScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.googleSans(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillTile(bill) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    return Container(
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.receipt, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.customerName,
                  style: GoogleFonts.googleSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF202124),
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(bill.createdAt),
                  style: GoogleFonts.googleSans(
                    fontSize: 12,
                    color: const Color(0xFF5F6368),
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(bill.grandTotal),
            style: GoogleFonts.googleSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
