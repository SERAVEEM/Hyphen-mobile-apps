import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_manager.dart';

class OrderDetailSellerPage extends StatefulWidget {
  final String orderId;
  const OrderDetailSellerPage({super.key, required this.orderId});

  @override
  State<OrderDetailSellerPage> createState() => _OrderDetailSellerPageState();
}

class _OrderDetailSellerPageState extends State<OrderDetailSellerPage> {
  void _updateStatus(OrderStatus newStatus) {
    OrderManager().updateOrderStatus(widget.orderId, newStatus);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Status pesanan berhasil diperbarui ke: ${newStatus.name.toUpperCase()}')),
    );
  }

  void _resolveDispute() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Selesaikan Sengketa',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Pilih status akhir setelah menyelesaikan sengketa dengan pembeli.',
          style: GoogleFonts.plusJakartaSans(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(OrderStatus.processing);
            },
            child: Text(
              'Kembali ke Proses',
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF8C7355), fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(OrderStatus.shipping);
            },
            child: Text(
              'Kirim Pesanan',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
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
        title: Text(
          'HYPEN.',
          style: GoogleFonts.plusJakartaSans(
            color: brandBrown,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: OrderManager(),
        builder: (context, child) {
          // Find order item(s) matching orderId
          final orders = OrderManager().orders.where((o) => o.orderId == widget.orderId).toList();
          if (orders.isEmpty) {
            return Center(
              child: Text(
                'Pesanan tidak ditemukan.',
                style: GoogleFonts.plusJakartaSans(color: Colors.black45),
              ),
            );
          }

          // Use the first item for header data (order number, customer name, date)
          final order = orders.first;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Title
                Text(
                  'Order Management',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                // Main Details Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF3F3F3)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subtitle "Order Details"
                      Text(
                        'Order Details',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: brandBrown,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Order ID
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.orderId,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (order.status == OrderStatus.disputed)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'DISPUTED',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFC62828),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Placed date
                      Text(
                        'Placed on Oct 12, 2023 at 14:32', // Mocked placed date matching Figma design
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black38,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF3F3F3)),
                      const SizedBox(height: 24),

                      // Fulfillment Status Header
                      Text(
                        'Fulfillment Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: brandBrown,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Timeline
                      _buildTimeline(order.status),

                      const SizedBox(height: 32),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF3F3F3)),
                      const SizedBox(height: 24),

                      // Dynamic Action Button based on status
                      if (order.status == OrderStatus.processing)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandBrown,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => _updateStatus(OrderStatus.shipping),
                              child: Text(
                                'KIRIM PESANAN',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        )
                      else if (order.status == OrderStatus.disputed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFC62828),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              onPressed: _resolveDispute,
                              child: Text(
                                'SELESAIKAN SENGKETA',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Contact Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: brandBrown, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Menghubungi pembeli ${order.product.brand}...'),
                              ),
                            );
                          },
                          child: Text(
                            'CONTACT',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: brandBrown,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeline(OrderStatus status) {
    final bool isProcessingActive = status == OrderStatus.processing;
    final bool isProcessingDone = status == OrderStatus.shipping;
    final bool isShippingActive = status == OrderStatus.shipping;

    return Column(
      children: [
        // Step 1: Order Placed (Always completed)
        _buildTimelineStep(
          title: 'Order Placed',
          subtitle: 'Payment secured via Stripe.',
          time: 'OCT 12, 14:32',
          isCompleted: true,
          isActive: false,
          showLine: true,
        ),
        // Step 2: Processing
        _buildTimelineStep(
          title: 'Processing',
          subtitle: 'Seller is preparing the package.',
          time: 'OCT 13, 09:15',
          isCompleted: isProcessingDone,
          isActive: isProcessingActive,
          showLine: true,
        ),
        // Step 3: Shipping
        _buildTimelineStep(
          title: 'Shipping',
          subtitle: isShippingActive ? 'Package is in transit.' : 'Awaiting carrier pickup.',
          time: isShippingActive ? 'OCT 14, 11:00' : '',
          isCompleted: isShippingActive,
          isActive: false,
          showLine: false,
        ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    required bool isActive,
    required bool showLine,
  }) {
    const Color brandBrown = Color(0xFF8C7355);

    // Indicator configuration
    Widget indicator;
    if (isCompleted) {
      indicator = Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: brandBrown,
          shape: BoxShape.circle,
        ),
      );
    } else if (isActive) {
      indicator = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: brandBrown, width: 3),
        ),
        child: Center(
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: brandBrown,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    } else {
      indicator = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
        ),
      );
    }

    final Color textColor = (isCompleted || isActive) ? Colors.black : Colors.black38;
    final Color subtitleColor = (isCompleted || isActive) ? Colors.black54 : Colors.black26;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot indicator and vertical line column
        Column(
          children: [
            indicator,
            if (showLine)
              Container(
                width: 1.5,
                height: 60,
                color: isCompleted ? brandBrown : const Color(0xFFE0E0E0),
              ),
          ],
        ),
        const SizedBox(width: 20),

        // Text details column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  height: 1.3,
                ),
              ),
              if (time.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: subtitleColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
