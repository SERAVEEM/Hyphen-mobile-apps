import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_manager.dart';
import 'mock_products.dart';

class SellPage extends StatefulWidget {
  final VoidCallback? onUploadSuccess;
  final bool showAppBar;

  const SellPage({
    super.key,
    this.onUploadSuccess,
    this.showAppBar = true,
  });

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  String? _selectedImagePath;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'Pilih Kategori';
  double? _enteredPrice;
  String _selectedSize = 'M';
  String _selectedCondition = 'Sangat Baik';

  final List<Map<String, String>> _mockPhotos = [
    {'path': 'assets/images/PreFall.png', 'name': 'Velvet Shirt'},
    {'path': 'assets/images/jacket_product.png', 'name': 'Puffer Jacket'},
    {'path': 'assets/images/cat_daily.png', 'name': 'Knit Sweater'},
    {'path': 'assets/images/cat_formal.png', 'name': 'Wool Trench Coat'},
    {'path': 'assets/images/slide1.png', 'name': 'Varsity Jacket'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Foto Baju',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _mockPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = _mockPhotos[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImagePath = photo['path'];
                          // Pre-fill name if empty
                          if (_nameController.text.isEmpty) {
                            _nameController.text = photo['name']!;
                          }
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.asset(
                            photo['path']!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCategoryPicker() {
    const Color brandBrown = Color(0xFF8C7355);
    showModalBottomSheet(
      context: context,
      backgroundColor: brandBrown,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final categories = ['Pria', 'Wanita', 'Daily', 'Formal'];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ...categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        cat,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showPriceInputDialog() {
    final controller = TextEditingController(
      text: _enteredPrice != null ? _enteredPrice!.toInt().toString() : '',
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Input Harga (Rp)',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.plusJakartaSans(color: Colors.black),
          decoration: const InputDecoration(
            hintText: 'cth. 250000',
            hintStyle: TextStyle(color: Colors.black38),
            prefixText: 'Rp ',
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black26),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(color: Colors.black54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              final parsed = double.tryParse(controller.text);
              if (parsed != null) {
                setState(() {
                  _enteredPrice = parsed;
                });
              }
              Navigator.pop(context);
            },
            child: Text(
              'Simpan',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showConditionPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        final conditions = ['Sangat Baik', 'Baik', 'Cukup Baik'];
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Kondisi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ...conditions.map((cond) => ListTile(
                    title: Text(
                      cond,
                      style: GoogleFonts.plusJakartaSans(color: Colors.black87),
                    ),
                    trailing: _selectedCondition == cond
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedCondition = cond;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showSizePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (context) {
        final sizes = ['S', 'M', 'L', 'XL'];
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Pilih Ukuran',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ...sizes.map((s) => ListTile(
                    title: Text(
                      s,
                      style: GoogleFonts.plusJakartaSans(color: Colors.black87),
                    ),
                    trailing: _selectedSize == s
                        ? const Icon(Icons.check, color: Colors.black)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedSize = s;
                      });
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _uploadProduct() {
    if (_selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tambahkan foto baju terlebih dahulu.')),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nama baju.')),
      );
      return;
    }
    if (_selectedCategory == 'Pilih Kategori') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori.')),
      );
      return;
    }
    if (_enteredPrice == null || _enteredPrice! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan harga yang valid.')),
      );
      return;
    }

    final newProduct = Product(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      title: _nameController.text.trim(),
      brand: 'Alex Rivera', // Seller's name
      price: _enteredPrice!,
      imageUrl: _selectedImagePath!,
      size: _selectedSize,
      condition: _selectedCondition,
      category: _selectedCategory,
      isVerified: false,
    );

    // Save to global state
    ProductManager().addProduct(newProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${newProduct.title}" berhasil diupload!')),
    );

    if (widget.onUploadSuccess != null) {
      widget.onUploadSuccess!();
    } else {
      // Default behavior if opened as modal
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    )
                  : IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () {},
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
              actions: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                  onPressed: () {},
                ),
              ],
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo Uploader Box
            Center(
              child: GestureDetector(
                onTap: _showPhotoPicker,
                child: Container(
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _selectedImagePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            _selectedImagePath!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 28, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              '+ Tambah Foto',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tips Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF3F3F3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips untuk foto',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pastikan foto menampilkan baju secara utuh dengan latar yang bersih',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black45,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form container matching Figma card style
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF3F3F3)),
              ),
              child: Column(
                children: [
                  // Nama baju
                  _buildFormTextRow(
                    label: 'Nama baju',
                    hint: 'cth. Black Jeans',
                    controller: _nameController,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                  // Description
                  _buildFormTextRow(
                    label: 'Description',
                    hint: 'cth. Tidak ada kerusakan/noda, Ukuran M',
                    controller: _descController,
                    maxLines: 3,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                  // Kategori
                  _buildFormSelectorRow(
                    label: 'Kategori',
                    value: _selectedCategory,
                    onTap: _showCategoryPicker,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                  // Ukuran (Dynamic extension for data integrity)
                  _buildFormSelectorRow(
                    label: 'Ukuran',
                    value: _selectedSize,
                    onTap: _showSizePicker,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                  // Kondisi (Dynamic extension for data integrity)
                  _buildFormSelectorRow(
                    label: 'Kondisi',
                    value: _selectedCondition,
                    onTap: _showConditionPicker,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                  // Harga
                  _buildFormSelectorRow(
                    label: 'Harga',
                    value: _enteredPrice != null
                        ? 'Rp ${_enteredPrice!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}'
                        : 'Pilih Harga',
                    onTap: _showPriceInputDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Upload Button
            ElevatedButton(
              onPressed: _uploadProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: brandBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Upload',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFormTextRow({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.black38,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSelectorRow({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != 'Pilih Kategori' && value != 'Pilih Harga';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasValue ? Colors.black87 : Colors.black38,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
