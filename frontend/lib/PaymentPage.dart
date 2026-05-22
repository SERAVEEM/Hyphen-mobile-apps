import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';
import 'CheckoutPage.dart'; // import PaymentOption
import 'order_manager.dart';

class PaymentPage extends StatefulWidget {
  final List<CartItem> checkoutItems;
  final double totalPrice;
  final PaymentOption selectedPayment;

  const PaymentPage({
    super.key,
    required this.checkoutItems,
    required this.totalPrice,
    required this.selectedPayment,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _step = 1; // Step 1: Payment Input/QRIS, Step 2: Congratulations
  bool _isProcessing = false;
  late String _orderId;

  // Countdown timer variables
  late Timer _timer;
  int _secondsRemaining = 15 * 60; // 15 minutes

  // Stripe Form Controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Generate random order ID
    final random = Random();
    final idNum = random.nextInt(90000) + 10000;
    _orderId = '#BTR-$idNum';

    // Clear SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });

    // Start timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        // Handle timeout
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waktu pembayaran habis. Transaksi dibatalkan.')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  String get _timerString {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Formatting price string
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

  void _processPayment() {
    setState(() {
      _isProcessing = true;
    });

    // Simulate server side request for Stripe / QRIS settlement
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _step = 2; // Transition to Congratulations
      });

      // Add order details to OrderManager
      OrderManager().addOrderFromCheckout(_orderId, widget.checkoutItems);

      // Clear purchased items from Cart
      final cartManager = CartManager();
      for (var item in widget.checkoutItems) {
        cartManager.removeItem(item.product.id, item.size);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    if (_step == 2) {
      return _buildCongratulationsScreen(brandBrown);
    }

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
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Dynamic payment detail based on type
                        if (widget.selectedPayment.type == 'QRIS')
                          _buildQrisSection()
                        else if (widget.selectedPayment.type == 'BCA')
                          _buildBcaSection()
                        else if (widget.selectedPayment.type == 'STRIPE')
                          _buildStripeSection(),

                        const SizedBox(height: 32),

                        // Total Price Display
                        Text(
                          _formatVal(widget.totalPrice),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: brandBrown,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Countdown warning box
                        _buildTimerAlertBox(brandBrown),
                      ],
                    ),
                  ),
                ),
                // Payment bottom CTA button
                _buildBottomButton(brandBrown),
              ],
            ),
            if (_isProcessing) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerAlertBox(Color brandBrown) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brandBrown.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brandBrown.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: brandBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Selesaikan pembayaran dalam '),
                      TextSpan(
                        text: _timerString,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const TextSpan(text: ' menit, jika tidak pesanan Anda akan dibatalkan otomatis.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(Color brandBrown) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: ElevatedButton(
        onPressed: _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBrown,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: brandBrown.withValues(alpha: 0.3),
        ),
        child: Text(
          'Bayar sekarang',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // QRIS Payment Page View
  Widget _buildQrisSection() {
    return Column(
      children: [
        Text(
          'QRIS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        // Mock QR Code Box (looks extremely premium)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100, width: 1.5),
          ),
          child: Column(
            children: [
              // Stylized QR code grid pattern using custom widgets
              SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: QrCodePainter(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // BCA Virtual Account View
  Widget _buildBcaSection() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade600,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            'BCA',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Virtual Account',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '8830 1234 5678 9012',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.black54),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor Virtual Account disalin.')),
                  );
                },
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Stripe Credit Card View
  Widget _buildStripeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF635BFF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'stripe',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Credit Card checkout',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Nomor Kartu',
                  labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54),
                  suffixIcon: const Icon(Icons.credit_card, color: Colors.black54),
                  border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _expiryController,
                      keyboardType: TextInputType.datetime,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'Valid Thru (MM/YY)',
                        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: TextField(
                      controller: _cvcController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: 'CVV / CVC',
                        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.black54),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Payment Page 2: Congratulations Success Landing
  Widget _buildCongratulationsScreen(Color brandBrown) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Clean look, no back button on success
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
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
            onPressed: () {
              // Pop to HomePage
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Shield Checkmark Logo (Bronze style)
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: brandBrown.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: brandBrown.withValues(alpha: 0.3), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.verified_user_outlined,
                    color: brandBrown,
                    size: 72,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Congratulations Header
              Text(
                'Congratulations',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: brandBrown,
                ),
              ),
              const SizedBox(height: 12),

              // Order detail
              Text(
                'Thank you for your purchase. Your order ID is $_orderId',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Total Paid
              Text(
                _formatVal(widget.totalPrice),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: brandBrown,
                ),
              ),
              const SizedBox(height: 32),

              // Alert Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brandBrown.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: brandBrown, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your order has been successfully paid. Please check your order details in the "Orders" menu.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: brandBrown,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Home and Pesanan actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Pop all routes back to home page
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Home',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // In high fidelity ecommerce, show orders. For now, pop back to home page
                        // and show a nice snackbar confirmation
                        Navigator.popUntil(context, (route) => route.isFirst);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Menampilkan detail pesanan untuk order $_orderId'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Pesanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8C7355)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memverifikasi Pembayaran...',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Painter to draw a high-fidelity visual mock QR Code
class QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Drawing the outer 3 large positional squares
    void drawPositionSquare(double x, double y, double sz) {
      // Outer black square
      canvas.drawRect(Rect.fromLTWH(x, y, sz, sz), blackPaint);
      // Inner white square
      canvas.drawRect(Rect.fromLTWH(x + sz / 7, y + sz / 7, sz * 5 / 7, sz * 5 / 7), Paint()..color = Colors.white);
      // Center black square
      canvas.drawRect(Rect.fromLTWH(x + sz * 2 / 7, y + sz * 2 / 7, sz * 3 / 7, sz * 3 / 7), blackPaint);
    }

    final double posSz = size.width * 0.28; // Size of corner squares
    drawPositionSquare(0, 0, posSz); // Top-left
    drawPositionSquare(size.width - posSz, 0, posSz); // Top-right
    drawPositionSquare(0, size.height - posSz, posSz); // Bottom-left

    // Draw random tiny blocks to simulate real QR Code data
    final random = Random(42); // Seeded for deterministic blocks
    final int gridCount = 21;
    final double blockSz = size.width / gridCount;

    for (int r = 0; r < gridCount; r++) {
      for (int c = 0; c < gridCount; c++) {
        // Skip corner spaces
        bool inTopLeft = r < 7 && c < 7;
        bool inTopRight = r < 7 && c >= gridCount - 7;
        bool inBottomLeft = r >= gridCount - 7 && c < 7;
        if (inTopLeft || inTopRight || inBottomLeft) continue;

        // Draw random black pixels
        if (random.nextDouble() > 0.45) {
          canvas.drawRect(
            Rect.fromLTWH(c * blockSz, r * blockSz, blockSz, blockSz),
            blackPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
