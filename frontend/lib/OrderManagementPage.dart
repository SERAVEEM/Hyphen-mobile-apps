import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_manager.dart';
import 'OrderDetailSellerPage.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return const Color(0xFF8C7355); // Brand Brown/Beige
      case OrderStatus.shipping:
        return const Color(0xFF4CAF50); // Green
      case OrderStatus.disputed:
        return const Color(0xFFE53935); // Red
    }
  }

  Color _getStatusBgColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return const Color(0xFFF9F6F0);
      case OrderStatus.shipping:
        return const Color(0xFFE8F5E9);
      case OrderStatus.disputed:
        return const Color(0xFFFFEBEE);
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return '• Processing';
      case OrderStatus.shipping:
        return '• Shipped';
      case OrderStatus.disputed:
        return '• Disputed';
    }
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: OrderManager(),
        builder: (context, child) {
          final allOrders = OrderManager().orders;
          final processingOrders = allOrders.where((o) => o.status == OrderStatus.processing).toList();
          final shippingOrders = allOrders.where((o) => o.status == OrderStatus.shipping).toList();
          final disputedOrders = allOrders.where((o) => o.status == OrderStatus.disputed).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HYPEN.',
                      style: GoogleFonts.plusJakartaSans(
                        color: brandBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order Management',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // TabBar section
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: brandBrown,
                indicatorWeight: 2.5,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black38,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: [
                  const Tab(text: 'All'),
                  const Tab(text: 'Processing'),
                  const Tab(text: 'Shipping'),
                  Tab(
                    child: Row(
                      children: [
                        const Text('Disputed'),
                        if (disputedOrders.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFC62828), // Bold red
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${disputedOrders.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF3F3F3)),

              // TabBar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderList(allOrders),
                    _buildOrderList(processingOrders),
                    _buildOrderList(shippingOrders),
                    _buildOrderList(disputedOrders),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(List<OrderItem> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada pesanan.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black38,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isDisputed = order.status == OrderStatus.disputed;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailSellerPage(orderId: order.orderId),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: isDisputed
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFF3F3F3),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Item Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      order.product.imageUrl,
                      width: 90,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 90,
                        height: 110,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Order Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID & Disputed label
                        Text(
                          isDisputed
                              ? '${order.orderId} • DISPUTED'
                              : order.orderId,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDisputed ? const Color(0xFFC62828) : Colors.black45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Customer Name (corresponds to brand property in mock Product)
                        Text(
                          order.product.brand,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Product Title
                        Text(
                          order.product.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        // Price & Status Badge row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.product.formattedPrice,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(order.status),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                _getStatusText(order.status),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _getStatusColor(order.status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
