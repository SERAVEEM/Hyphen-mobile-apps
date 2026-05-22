import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';
import 'CheckoutPage.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartManager _cartManager = CartManager();
  final Set<CartItem> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    _cartManager.addListener(_onCartChanged);
    // Initialize selected items with all items in the cart
    _selectedItems.addAll(_cartManager.items);
    // Clear any active SnackBars
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void dispose() {
    _cartManager.removeListener(_onCartChanged);
    super.dispose();
  }

  void _onCartChanged() {
    if (mounted) {
      setState(() {
        // Sync selected items with current items in cart (remove any that were deleted)
        final currentSet = _cartManager.items.toSet();
        _selectedItems.retainAll(currentSet);
      });
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

  // Group items by brand/seller
  Map<String, List<CartItem>> _getGroupedItems(List<CartItem> items) {
    final Map<String, List<CartItem>> groups = {};
    for (var item in items) {
      groups.putIfAbsent(item.product.brand, () => []).add(item);
    }
    return groups;
  }

  // Mock seller rating and initials based on brand
  Map<String, String> _getSellerDetails(String brand) {
    switch (brand.toLowerCase()) {
      case 'nike':
        return {'rating': '4.8 (120)', 'initials': 'NK'};
      case 'eiger':
        return {'rating': '4.7 (45)', 'initials': 'EG'};
      case 'adidas':
        return {'rating': '4.9 (89)', 'initials': 'AD'};
      case 'puma':
        return {'rating': '4.6 (38)', 'initials': 'PM'};
      default:
        return {'rating': '4.7 (16)', 'initials': brand.substring(0, brand.length > 2 ? 2 : brand.length).toUpperCase()};
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    final items = _cartManager.items;
    final groupedItems = _getGroupedItems(items);

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
        child: items.isEmpty
            ? _buildEmptyState(brandBrown)
            : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 16, bottom: 24),
                itemCount: groupedItems.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 32,
                  thickness: 8,
                  color: Color(0xFFF6F6F6),
                ),
                itemBuilder: (context, index) {
                  final brand = groupedItems.keys.elementAt(index);
                  final sellerItems = groupedItems[brand]!;
                  return _buildSellerGroup(brand, sellerItems, brandBrown);
                },
              ),
      ),
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // Select All checkbox
                    Checkbox(
                      value: _selectedItems.length == items.length && items.isNotEmpty,
                      activeColor: brandBrown,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedItems.addAll(items);
                          } else {
                            _selectedItems.clear();
                          }
                        });
                      },
                    ),
                    Text(
                      'Semua',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    // Total Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatVal(_selectedItems.fold(
                              0.0, (sum, item) => sum + (item.product.price * item.quantity))),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: brandBrown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Checkout Button
                    ElevatedButton(
                      onPressed: _selectedItems.isEmpty
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    checkoutItems: _selectedItems.toList(),
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBrown,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.black38,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _selectedItems.isEmpty ? 0 : 4,
                        shadowColor: brandBrown.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'Checkout (${_selectedItems.length})',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSellerGroup(String brand, List<CartItem> sellerItems, Color brandBrown) {
    final sellerDetails = _getSellerDetails(brand);
    final bool isAllSelected = sellerItems.every((item) => _selectedItems.contains(item));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seller Profile Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isAllSelected,
                  activeColor: brandBrown,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedItems.addAll(sellerItems);
                      } else {
                        _selectedItems.removeAll(sellerItems);
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  sellerDetails['initials']!,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: brandBrown,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name & Rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.toLowerCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 11, color: Color(0xFFD4AF37)),
                      const SizedBox(width: 2),
                      Text(
                        sellerDetails['rating']!,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Horizontal items view
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: sellerItems.length + 1, // Add 1 for the dotted card
            itemBuilder: (context, index) {
              if (index < sellerItems.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: _buildProductCard(sellerItems[index]),
                );
              } else {
                return _buildDottedCard();
              }
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildProductCard(CartItem item) {
    return Container(
      width: 145,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Product image with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              item.product.imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          // Dark gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          // Info overlay at the bottom
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.product.formattedPrice,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.size} • ${item.product.condition}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
          // Checkbox & Quantity badge at top left
          Positioned(
            top: 6,
            left: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.white,
                  ),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _selectedItems.contains(item),
                      activeColor: Colors.black,
                      checkColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedItems.add(item);
                          } else {
                            _selectedItems.remove(item);
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.quantity}x',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Delete button at top right
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.close, color: Colors.white, size: 14),
                onPressed: () {
                  _cartManager.removeItem(item.product.id, item.size);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedCard() {
    return Container(
      width: 145,
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: CustomPaint(
        painter: DashedBorderPainter(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: const Icon(Icons.add, color: Colors.black54, size: 20),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Gabung item, bayar ongkir sekali',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color brandBrown) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 80.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 110,
              width: 110,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F3F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Keranjang Belanja Kosong',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Temukan fashion items yang menakjubkan di katalog kami dan isi keranjang belanjaanmu!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Mulai Belanja',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter to draw dashed border for "+ Gabung item" card
class DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = 12.0;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );
    final Path path = Path()..addRRect(rrect);

    // Draw dashed lines
    final Path dashPath = Path();
    double dashWidth = 6.0;
    double dashSpace = 4.0;
    double distance = 0.0;

    for (var metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

