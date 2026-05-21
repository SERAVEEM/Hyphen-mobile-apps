import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_manager.dart';
import 'order_manager.dart';
import 'mock_products.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _currentTab = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Reports states
  String _reportsInterval = 'Daily'; // 'Daily', 'Weekly', 'Monthly'
  
  // Profile states
  String _selectedLanguage = 'English'; // 'English', 'Indonesia', 'Arabic', 'Chinese'

  // Admin Account Details
  final String _adminUsername = 'admin';
  final String _adminEmail = 'admin@hypen.com';

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    const Color darkBrown = Color(0xFF5C4A37);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFBFBF9),
      drawer: _buildAdminDrawer(darkBrown),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'HYPEN. ADMIN',
          style: GoogleFonts.plusJakartaSans(
            color: brandBrown,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildTabBody(brandBrown),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) {
            setState(() {
              _currentTab = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: brandBrown,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_user_outlined),
              activeIcon: Icon(Icons.verified_user),
              label: 'Verify',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // --- DRAWER LAYOUT ---
  Widget _buildAdminDrawer(Color bgBrown) {
    return Drawer(
      backgroundColor: bgBrown,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Drawer Header Logo
            Text(
              'HYPEN.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            Text(
              'ADMIN PORTAL',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            // Menu Cards List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildDrawerCard(Icons.dashboard_outlined, 'Dashboard', 0),
                  _buildDrawerCard(Icons.chat_bubble_outline, 'Chat Support', -1),
                  _buildDrawerCard(Icons.help_outline, 'Help Desk', -1),
                  _buildDrawerCard(Icons.support_agent, 'Technical Support', -1),
                  const SizedBox(height: 40),
                  // Log Out card
                  _buildDrawerLogOutCard(),
                ],
              ),
            ),
            // Footer Info
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Text(
                'v1.0.0 (Beta Backend Config)',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerCard(IconData icon, String title, int tabIndex) {
    final isSelected = tabIndex == _currentTab;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (tabIndex >= 0) {
          setState(() {
            _currentTab = tabIndex;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title is pending backend implementation.')),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8C7355) : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerLogOutCard() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close drawer
        Navigator.pop(context); // Exit Admin Portal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out from Admin Mode'),
            duration: Duration(milliseconds: 1000),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade800.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.redAccent, size: 22),
            const SizedBox(width: 16),
            Text(
              'Log Out',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.redAccent, size: 18),
          ],
        ),
      ),
    );
  }

  // --- TAB BODIES ---
  Widget _buildTabBody(Color brandColor) {
    switch (_currentTab) {
      case 0:
        return _buildDashboardTab(brandColor);
      case 1:
        return _buildVerificationTab(brandColor);
      case 2:
        return _buildOrdersTab(brandColor);
      case 3:
        return _buildReportsTab(brandColor);
      case 4:
        return _buildProfileTab(brandColor);
      default:
        return Center(
          child: Text('Tab under development', style: GoogleFonts.plusJakartaSans()),
        );
    }
  }

  // --- TAB 1: DASHBOARD ---
  Widget _buildDashboardTab(Color brandColor) {
    return ListenableBuilder(
      listenable: ProductManager(),
      builder: (context, child) {
        final verifiedCount = ProductManager().products.where((p) => p.isVerified).length;
        final pendingCount = ProductManager().products.where((p) => !p.isVerified).length;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back, Admin!',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Text(
                'Overview metrics of the Hypen platform.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),

              // STAT CARDS LIST
              _buildMetricCard(
                title: 'Total Users',
                value: '14,209',
                subText: '+12% growth this month',
                icon: Icons.people_outline,
                brandColor: brandColor,
              ),
              _buildMetricCard(
                title: 'Active Sellers',
                value: '342',
                subText: '+5% active this week',
                icon: Icons.storefront,
                brandColor: brandColor,
              ),
              _buildMetricCard(
                title: 'Curated Products',
                value: '$verifiedCount',
                subText: '$pendingCount pending approval',
                icon: Icons.check_circle_outline,
                brandColor: brandColor,
              ),

              const SizedBox(height: 20),
              
              // RECENT ACTIVITIES BOX
              Text(
                'Recent Activities Log',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF3F3F3)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildActivityRow(
                      time: 'Just now',
                      text: 'Product listing "Structured Leather Tote" approved automatically.',
                    ),
                    const Divider(height: 24),
                    _buildActivityRow(
                      time: '15 mins ago',
                      text: 'New seller registration verified for account "Streetwear Hub".',
                    ),
                    const Divider(height: 24),
                    _buildActivityRow(
                      time: '1 hour ago',
                      text: 'Order ORD-2023-8891 status updated to Shipping.',
                    ),
                    const Divider(height: 24),
                    _buildActivityRow(
                      time: '3 hours ago',
                      text: 'Seller "Alex Rivera" uploaded a new product for verification.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color brandColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Stack(
        children: [
          // Elegant left colored stripe
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(
              decoration: BoxDecoration(
                color: brandColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: brandColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: brandColor, size: 26),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow({required String time, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF8C7355),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.black38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: PRODUCT VERIFICATION QUEUE ---
  Widget _buildVerificationTab(Color brandColor) {
    return ListenableBuilder(
      listenable: ProductManager(),
      builder: (context, child) {
        final pendingProducts = ProductManager().products.where((p) => !p.isVerified).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Verification',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        'Review newly uploaded seller listings.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: brandColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pendingProducts.length} Pending',
                      style: GoogleFonts.plusJakartaSans(
                        color: brandColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: pendingProducts.isEmpty
                  ? _buildAllVerifiedState(brandColor)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: pendingProducts.length,
                      itemBuilder: (context, index) {
                        final product = pendingProducts[index];
                        return _buildVerificationCard(product, brandColor);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllVerifiedState(Color brandColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_outline, color: brandColor, size: 64),
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending products to verify at the moment.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(Product product, Color brandColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    product.imageUrl,
                    width: 90,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          product.category.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${product.size} · Cond: ${product.condition}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.formattedPrice,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: brandColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F3F3)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showRejectConfirmation(product);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD32F2F)),
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reject / Delete',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final verifiedProduct = product.copyWith(isVerified: true);
                      ProductManager().updateProduct(verifiedProduct);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('"${product.title}" has been verified!'),
                          backgroundColor: brandColor,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Verify & Live',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Reject & Delete Product?',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        content: Text(
          'Are you sure you want to reject and permanently delete "${product.title}" from the catalog?',
          style: GoogleFonts.plusJakartaSans(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              ProductManager().deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rejected and deleted "${product.title}"')),
              );
            },
            child: Text('Reject & Delete', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: ORDER ADMIN ---
  String _ordersFilter = 'All'; // 'All', 'Processing', 'Shipping', 'Disputed'

  Widget _buildOrdersTab(Color brandColor) {
    return ListenableBuilder(
      listenable: OrderManager(),
      builder: (context, child) {
        final orders = OrderManager().orders;
        
        // Filter orders
        final filteredOrders = orders.where((order) {
          if (_ordersFilter == 'All') return true;
          if (_ordersFilter == 'Processing') return order.status == OrderStatus.processing;
          if (_ordersFilter == 'Shipping') return order.status == OrderStatus.shipping;
          if (_ordersFilter == 'Disputed') return order.status == OrderStatus.disputed;
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Administration',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Manage all customer orders on the platform.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal status tab selector
            _buildOrdersFilterRow(brandColor),

            Expanded(
              child: filteredOrders.isEmpty
                  ? _buildEmptyOrdersState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      physics: const BouncingScrollPhysics(),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        return _buildAdminOrderCard(filteredOrders[index], brandColor);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrdersFilterRow(Color brandColor) {
    final filters = ['All', 'Processing', 'Shipping', 'Disputed'];
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == _ordersFilter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _ordersFilter = filter;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? brandColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? brandColor : const Color(0xFFECECEC),
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.plusJakartaSans(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyOrdersState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_turned_in_outlined, color: Colors.grey, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'There are no orders matching this filter.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminOrderCard(OrderItem order, Color brandColor) {
    Color statusColor = Colors.orange;
    String statusLabel = 'Processing';
    if (order.status == OrderStatus.shipping) {
      statusColor = Colors.blue;
      statusLabel = 'Shipping';
    } else if (order.status == OrderStatus.disputed) {
      statusColor = Colors.red;
      statusLabel = 'Disputed';
    }

    final priceStr = order.product.formattedPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Order Card Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderId,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F3F3)),
          // Order Card Product Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    order.product.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.product.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Size: ${order.size} · Qty: ${order.quantity}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seller: ${order.product.brand}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  priceStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Action Buttons if manageable
          if (order.status == OrderStatus.processing || order.status == OrderStatus.disputed) ...[
            const Divider(height: 1, color: Color(0xFFF3F3F3)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == OrderStatus.disputed) ...[
                    OutlinedButton(
                      onPressed: () {
                        // Action to mark processing
                        OrderManager().updateOrderStatus(order.orderId, OrderStatus.processing);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Disputed solved! Reverted back to Processing.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: brandColor),
                        foregroundColor: brandColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Resolve Dispute',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                  if (order.status == OrderStatus.processing) ...[
                    ElevatedButton(
                      onPressed: () {
                        // Action to mark shipping
                        OrderManager().updateOrderStatus(order.orderId, OrderStatus.shipping);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order marked as shipped!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Ship Item',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 4: REPORTS ---
  Widget _buildReportsTab(Color brandColor) {
    // Generate mock values based on interval (Daily, Weekly, Monthly)
    String growthText = '';
    String totalRev = '';
    String orderVol = '';
    List<double> chartHeights = [];
    List<String> chartLabels = [];

    if (_reportsInterval == 'Daily') {
      growthText = '+34 new users today';
      totalRev = 'Rp 1.450.000';
      orderVol = '8 Orders';
      chartHeights = [0.3, 0.45, 0.25, 0.6, 0.8, 0.9, 0.5];
      chartLabels = ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
    } else if (_reportsInterval == 'Weekly') {
      growthText = '+245 new users this week';
      totalRev = 'Rp 9.820.000';
      orderVol = '42 Orders';
      chartHeights = [0.55, 0.7, 0.62, 0.85, 0.9, 0.4];
      chartLabels = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
    } else { // Monthly
      growthText = '+1,120 new users this month';
      totalRev = 'Rp 41.250.000';
      orderVol = '184 Orders';
      chartHeights = [0.4, 0.5, 0.65, 0.8, 0.95, 0.85];
      chartLabels = ['Dec', 'Jan', 'Feb', 'Mar', 'Apr', 'May'];
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Performance Reports',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          Text(
            'Visual analytics of platform activity and metrics.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
          const SizedBox(height: 20),

          // Three-way Toggle (Daily, Weekly, Monthly)
          _buildIntervalToggle(brandColor),
          
          const SizedBox(height: 24),

          // Growth Stat summary card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [brandColor, brandColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Growth metrics summary',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        growthText,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Revenue: $totalRev · $orderVol',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Visual Custom Graph (Bar Chart)
          Text(
            'Revenue Growth Trend',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F3F3)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chartHeights.length, (index) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        width: 24,
                        decoration: BoxDecoration(
                          color: brandColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 140 * chartHeights[index],
                          decoration: BoxDecoration(
                            color: brandColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chartLabels[index],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 24),

          // Top Categories share breakdown
          Text(
            'Top Categories Share',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF3F3F3)),
            ),
            child: Column(
              children: [
                _buildCategoryProgressRow('Outerwear', 0.45, brandColor),
                const SizedBox(height: 14),
                _buildCategoryProgressRow('Daily (Casual)', 0.30, brandColor),
                const SizedBox(height: 14),
                _buildCategoryProgressRow('Pria', 0.15, brandColor),
                const SizedBox(height: 14),
                _buildCategoryProgressRow('Wanita', 0.10, brandColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalToggle(Color brandColor) {
    final intervals = ['Daily', 'Weekly', 'Monthly'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: intervals.map((interval) {
          final isSelected = interval == _reportsInterval;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _reportsInterval = interval;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  interval,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? brandColor : Colors.black54,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryProgressRow(String categoryName, double share, Color brandColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              categoryName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            Text(
              '${(share * 100).toInt()}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: brandColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: share,
            minHeight: 8,
            backgroundColor: brandColor.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(brandColor),
          ),
        ),
      ],
    );
  }

  // --- TAB 5: PROFILE ---
  Widget _buildProfileTab(Color brandColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile Header Box
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: brandColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: brandColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _adminUsername[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: brandColor,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _adminUsername,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _adminEmail,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PLATFORM ADMINISTRATOR',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Menu list options
          Text(
            'Settings',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black45,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          
          _buildProfileMenuRow(
            icon: Icons.edit_outlined,
            title: 'Edit Profile details',
            value: '',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile edit is locked in Dev demo.')),
              );
            },
          ),
          _buildProfileMenuRow(
            icon: Icons.language,
            title: 'Language',
            value: _selectedLanguage,
            onTap: _showLanguageSelectorSheet,
          ),
          _buildProfileMenuRow(
            icon: Icons.shield_outlined,
            title: 'Platform Security',
            value: 'SSL Connected',
            onTap: () {},
          ),
          _buildProfileMenuRow(
            icon: Icons.help_outline,
            title: 'Admin Help Documentation',
            value: '',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuRow({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F3F3)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(icon, color: Colors.black87),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value.isNotEmpty)
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.black38,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.black26),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  // Language sheet selector sheet
  void _showLanguageSelectorSheet() {
    const Color brandColor = Color(0xFF8C7355);
    final languages = ['English', 'Indonesia', 'Arabic', 'Chinese'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Select Admin Language',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ...languages.map((lang) {
                    final isSel = lang == _selectedLanguage;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        tileColor: isSel ? brandColor.withOpacity(0.08) : const Color(0xFFFBFBF9),
                        leading: Icon(
                          Icons.language,
                          color: isSel ? brandColor : Colors.grey.shade400,
                        ),
                        title: Text(
                          lang,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: isSel ? brandColor : Colors.black87,
                          ),
                        ),
                        trailing: isSel
                            ? const Icon(Icons.check, color: brandColor)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedLanguage = lang;
                          });
                          setSheetState(() {});
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Language changed to $lang'),
                              duration: const Duration(milliseconds: 600),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            );
          }
        );
      },
    );
  }
}
