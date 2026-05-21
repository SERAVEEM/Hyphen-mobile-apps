import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_manager.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final OrderManager _orderManager = OrderManager();
  String _activeTab = 'All'; // 'All', 'Processing', 'Shipping', 'Disputed'

  @override
  void initState() {
    super.initState();
    _orderManager.addListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    _orderManager.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatVal(double val) {
    final buffer = StringBuffer('Rp ');
    final priceStr = val.toInt().toString();
    final len = priceStr.length;
    for (int i = 0; i < len; i++) {
      buffer.write(priceStr[i]);
      if ((len - i - 1) % 3 == 0 && i != len - 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  List<OrderItem> get _filteredOrders {
    final allOrders = _orderManager.orders;
    if (_activeTab == 'All') {
      return allOrders;
    } else if (_activeTab == 'Processing') {
      return allOrders.where((o) => o.status == OrderStatus.processing).toList();
    } else if (_activeTab == 'Shipping') {
      return allOrders.where((o) => o.status == OrderStatus.shipping).toList();
    } else if (_activeTab == 'Disputed') {
      return allOrders.where((o) => o.status == OrderStatus.disputed).toList();
    }
    return [];
  }

  int get _disputedCount {
    return _orderManager.orders.where((o) => o.status == OrderStatus.disputed).length;
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'HYPEN.',
          style: GoogleFonts.plusJakartaSans(
            color: brandBrown,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Screen Header title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Text(
                'Order History',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Custom Tab Bar Row
            _buildCustomTabBar(brandBrown),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

            // Orders list view
            Expanded(
              child: _buildOrdersList(brandBrown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar(Color brandBrown) {
    final tabs = ['All', 'Processing', 'Shipping', 'Disputed'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _activeTab == tab;
          final isDisputed = tab == 'Disputed';
          final disputedCount = _disputedCount;

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeTab = tab;
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              margin: const EdgeInsets.only(right: 24.0),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? brandBrown : Colors.transparent,
                    width: 2.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    tab,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.black : Colors.black45,
                    ),
                  ),
                  if (isDisputed && disputedCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFC62828),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          '$disputedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersList(Color brandBrown) {
    final list = _filteredOrders;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Belum ada transaksi di kategori $_activeTab.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final order = list[index];
        return _buildOrderCard(order, brandBrown);
      },
    );
  }

  Widget _buildOrderCard(OrderItem order, Color brandBrown) {
    // Determine colors and labels based on order status
    Color badgeColor;
    Color dotColor;
    String statusLabel;

    switch (order.status) {
      case OrderStatus.processing:
        badgeColor = brandBrown.withValues(alpha: 0.08);
        dotColor = brandBrown;
        statusLabel = 'Processing';
        break;
      case OrderStatus.shipping:
        badgeColor = const Color(0xFFE8F5E9);
        dotColor = const Color(0xFF2E7D32);
        statusLabel = 'Shipped';
        break;
      case OrderStatus.disputed:
        badgeColor = const Color(0xFFFFEBEE);
        dotColor = const Color(0xFFC62828);
        statusLabel = 'Disputed';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F3F3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              order.product.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade100,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_outlined, color: Colors.black38),
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Right: Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID
                Text(
                  order.orderId,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),

                // Brand (Eleanor Vance etc.)
                Text(
                  order.product.brand,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),

                // Product Title
                Text(
                  order.product.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),

                // Row: Price & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatVal(order.price * order.quantity),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: dotColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
