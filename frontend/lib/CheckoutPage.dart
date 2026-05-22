import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';
import 'PaymentPage.dart';

// Address model
class AddressInfo {
  final String name;
  final String phone;
  final String fullAddress;

  AddressInfo({
    required this.name,
    required this.phone,
    required this.fullAddress,
  });
}

// Courier option model representing RajaOngkir outputs
class CourierOption {
  final String serviceName; // JTR, REG, OKE, YES
  final String courierName; // JNE Express
  final double price;
  final String etd; // Estimated Time of Delivery

  CourierOption({
    required this.serviceName,
    required this.courierName,
    required this.price,
    required this.etd,
  });
}

// Payment Option model
class PaymentOption {
  final String name;
  final String type; // QRIS, BCA, STRIPE

  PaymentOption({
    required this.name,
    required this.type,
  });
}

class CheckoutPage extends StatefulWidget {
  final List<CartItem> checkoutItems;

  const CheckoutPage({super.key, required this.checkoutItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  AddressInfo? _address;
  final Map<String, CourierOption> _selectedCouriers = {};
  PaymentOption? _selectedPayment;

  // Mock list of courier options (RajaOngkir preparation)
  final List<CourierOption> _courierOptions = [
    CourierOption(courierName: 'JNE Express', serviceName: 'JNE Oke', price: 12000.0, etd: '3-4'),
    CourierOption(courierName: 'JNE Express', serviceName: 'JNE Reguler', price: 18000.0, etd: '2-3'),
    CourierOption(courierName: 'JNE Express', serviceName: 'JNE YES', price: 28000.0, etd: '1'),
  ];

  // Group items by brand/seller
  Map<String, List<CartItem>> get _groupedItems {
    final Map<String, List<CartItem>> groups = {};
    for (var item in widget.checkoutItems) {
      groups.putIfAbsent(item.product.brand, () => []).add(item);
    }
    return groups;
  }

  // Calculate pricing summary
  double get _subtotal {
    return widget.checkoutItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get _shippingFee {
    return _selectedCouriers.values.fold(0.0, (sum, courier) => sum + courier.price);
  }

  double get _serviceFee => _address != null ? 2000.0 : 0.0;
  double get _total => _subtotal + _shippingFee + _serviceFee;

  // Helper string formatter
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

  @override
  void initState() {
    super.initState();
    // Default JNE Reguler for each brand group
    final groups = _groupedItems;
    for (var brand in groups.keys) {
      _selectedCouriers[brand] = _courierOptions[1]; // JNE Reguler
    }
    // Default payment method is QRIS
    _selectedPayment = PaymentOption(name: 'QRIS', type: 'QRIS');

    // Clear SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    final hasAddress = _address != null;

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
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Section (Alamat) - Rendered at top
                    _buildAddressSection(brandBrown),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    // Grouped Items and Shipping Selection per brand
                    _buildGroupedItemsAndShipping(brandBrown),

                    // Payment Method Section (Pembayaran)
                    _buildPaymentMethodSection(brandBrown),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),

                    // Price Section (Harga)
                    _buildPriceSection(hasAddress),
                  ],
                ),
              ),
            ),

            // Checkout / Payment action panel at the bottom
            _buildBottomPanel(brandBrown),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(Color brandBrown) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alamat',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          if (_address == null)
            InkWell(
              onTap: _openPengisianForm,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.black87, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Tambah alamat',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Untuk opsi & biaya pengiriman',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _address!.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _address!.phone,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _address!.fullAddress,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.black87, size: 20),
                    onPressed: _openPengisianForm,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupedItemsAndShipping(Color brandBrown) {
    final groups = _groupedItems;
    final hasAddress = _address != null;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final brand = groups.keys.elementAt(index);
        final brandItems = groups[brand]!;
        final selectedCourier = _selectedCouriers[brand];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Header
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      brand.substring(0, brand.length > 2 ? 2 : brand.length).toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: brandBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    brand.toLowerCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Brand Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              itemCount: brandItems.length,
              itemBuilder: (context, idx) {
                final item = brandItems[idx];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          item.product.imageUrl,
                          height: 70,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.size} · ${item.product.condition}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatVal(item.product.price)}  x ${item.quantity}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatVal(item.product.price * item.quantity),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Courier Selection for this Brand
            if (hasAddress)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: InkWell(
                  onTap: () => _openCourierSelector(brand),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        _buildJneLogo(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCourier != null
                                    ? '${selectedCourier.courierName} (${selectedCourier.serviceName})'
                                    : 'Pilih Pengiriman',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedCourier != null
                                    ? 'Estimasi tiba ${selectedCourier.etd} hari · ${_formatVal(selectedCourier.price)}'
                                    : 'Tekan untuk memilih kurir',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_right, color: Colors.black54, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Divider(height: 16, thickness: 1, color: Color(0xFFEEEEEE)),
            ),
          ],
        );
      },
    );
  }

  void _openCourierSelector(String brand) {
    ScaffoldMessenger.of(context).clearSnackBars();
    const Color brandBrown = Color(0xFF8C7355);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Pengiriman - ${brand.toUpperCase()}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _courierOptions.length,
                  itemBuilder: (context, index) {
                    final courier = _courierOptions[index];
                    final isSelected = _selectedCouriers[brand]?.serviceName == courier.serviceName;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCouriers[brand] = courier;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? brandBrown : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildJneLogo(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${courier.courierName} (${courier.serviceName})',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Estimasi tiba ${courier.etd} hari · ${_formatVal(courier.price)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: brandBrown, size: 20)
                            else
                              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodSection(Color brandBrown) {
    final isSelected = _selectedPayment != null;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metode Pembayaran',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _openPaymentSelector,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isSelected
                  ? Row(
                      children: [
                        _buildPaymentLogo(_selectedPayment!.type),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _selectedPayment!.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_right, color: Colors.black54, size: 20),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add, color: Colors.black87, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Pilih Metode Pembayaran',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPaymentSelector() {
    ScaffoldMessenger.of(context).clearSnackBars();
    const Color brandBrown = Color(0xFF8C7355);
    final List<PaymentOption> paymentOptions = [
      PaymentOption(name: 'QRIS', type: 'QRIS'),
      PaymentOption(name: 'BCA Virtual Account', type: 'BCA'),
      PaymentOption(name: 'Credit Card / Stripe', type: 'STRIPE'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Metode Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paymentOptions.length,
                  itemBuilder: (context, index) {
                    final payment = paymentOptions[index];
                    final isSelected = _selectedPayment?.type == payment.type;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPayment = payment;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? brandBrown : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildPaymentLogo(payment.type),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                payment.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: brandBrown, size: 20)
                            else
                              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPriceSection(bool hasAddress) {
    final int totalItems = widget.checkoutItems.fold(0, (sum, item) => sum + item.quantity);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Harga',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriceRow('$totalItems Item', _formatVal(_subtotal)),
          const SizedBox(height: 8),
          _buildPriceRow(
            'Pengiriman',
            _selectedCouriers.isNotEmpty ? _formatVal(_shippingFee) : '-',
            valueColor: _selectedCouriers.isNotEmpty ? Colors.black : Colors.grey,
          ),
          if (hasAddress) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Biaya Layanan', _formatVal(_serviceFee)),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color valueColor = Colors.black}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(Color brandBrown) {
    final readyToPay = _address != null && _selectedCouriers.length == _groupedItems.length && _selectedPayment != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: Row(
        children: [
          // Total price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Total Pembayaran',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatVal(_total),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          // Pay Button
          Expanded(
            child: ElevatedButton(
              onPressed: readyToPay ? _navigateToPayment : _openPengisianForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: readyToPay ? brandBrown : Colors.grey.shade300,
                foregroundColor: readyToPay ? Colors.white : Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: readyToPay ? 4 : 0,
              ),
              child: Text(
                readyToPay ? 'Bayar sekarang' : 'Pilih Alamat',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment() {
    if (_address == null || _selectedCouriers.length != _groupedItems.length || _selectedPayment == null) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          checkoutItems: widget.checkoutItems,
          totalPrice: _total,
          selectedPayment: _selectedPayment!,
        ),
      ),
    );
  }

  void _openPengisianForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutPengisianPage(
          initialAddress: _address,
        ),
      ),
    );

    if (result != null && result is AddressInfo) {
      setState(() {
        _address = result;
      });
    }
  }

  Widget _buildJneLogo() {
    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.blue.shade900,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'JNE',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
          Container(
            height: 3,
            width: 32,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLogo(String type) {
    Color bgColor = Colors.black;
    String label = '';
    switch (type) {
      case 'QRIS':
        bgColor = Colors.blue.shade800;
        label = 'QRIS';
        break;
      case 'BCA':
        bgColor = Colors.blue.shade600;
        label = 'BCA';
        break;
      case 'STRIPE':
        bgColor = const Color(0xFF635BFF);
        label = 'stripe';
        break;
    }

    return Container(
      width: 48,
      height: 32,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Checkout Page - Pengisian (Address Form Screen Only)
// ─────────────────────────────────────────────────────────────────────────────

class CheckoutPengisianPage extends StatefulWidget {
  final AddressInfo? initialAddress;

  const CheckoutPengisianPage({
    super.key,
    this.initialAddress,
  });

  @override
  State<CheckoutPengisianPage> createState() => _CheckoutPengisianPageState();
}

class _CheckoutPengisianPageState extends State<CheckoutPengisianPage> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _nameController.text = widget.initialAddress!.name;
      _phoneController.text = widget.initialAddress!.phone;
      _addressController.text = widget.initialAddress!.fullAddress;
    } else {
      // Default placeholder address
      _nameController.text = 'Alvin Cihuy';
      _phoneController.text = '+62 812-3456-7890';
      _addressController.text = 'Jalan Sandang No D5B, RT 1/RW 11, Palmerah, Kota Jakarta Barat, DKI Jakarta, ID 11480';
    }

    // Clear SnackBar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Section
                    Text(
                      'Alamat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Nama Penerima',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
                              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14),
                            decoration: InputDecoration(
                              labelText: 'Nomor Telepon',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
                              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade300)),
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            maxLines: 3,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
                            decoration: InputDecoration(
                              labelText: 'Alamat Lengkap',
                              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.black54),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Save details button at the bottom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
              ),
              child: ElevatedButton(
                onPressed: _saveAndReturn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandBrown,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Simpan Alamat',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAndReturn() {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Harap lengkapi semua input data pengisian.'),
        ),
      );
      return;
    }

    final address = AddressInfo(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      fullAddress: _addressController.text.trim(),
    );

    Navigator.pop(context, address);
  }
}
