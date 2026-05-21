import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'product_manager.dart';
import 'mock_products.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late String _selectedImagePath;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedCategory;
  late double _enteredPrice;
  late String _selectedSize;
  late String _selectedCondition;

  final List<Map<String, String>> _mockPhotos = [
    {'path': 'assets/images/PreFall.png', 'name': 'Velvet Shirt'},
    {'path': 'assets/images/jacket_product.png', 'name': 'Puffer Jacket'},
    {'path': 'assets/images/cat_daily.png', 'name': 'Knit Sweater'},
    {'path': 'assets/images/cat_formal.png', 'name': 'Wool Trench Coat'},
    {'path': 'assets/images/slide1.png', 'name': 'Varsity Jacket'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedImagePath = widget.product.imageUrl;
    _nameController = TextEditingController(text: widget.product.title);
    // Standard mock description since mock product objects don't store description yet
    _descController = TextEditingController(
      text: 'Bahan premium, terawat dengan sangat baik. Tanpa cacat.',
    );
    _selectedCategory = widget.product.category;
    _enteredPrice = widget.product.price;
    _selectedSize = widget.product.size;
    _selectedCondition = widget.product.condition;
  }

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
                          _selectedImagePath = photo['path']!;
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
    final controller = TextEditingController(text: _enteredPrice.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Harga (Rp)',
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

  void _saveProductChanges() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nama baju.')),
      );
      return;
    }

    final updatedProduct = Product(
      id: widget.product.id,
      title: _nameController.text.trim(),
      brand: widget.product.brand,
      price: _enteredPrice,
      imageUrl: _selectedImagePath,
      size: _selectedSize,
      condition: _selectedCondition,
      category: _selectedCategory,
      isVerified: widget.product.isVerified,
    );

    // Save to global state
    ProductManager().updateProduct(updatedProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perubahan berhasil disimpan!')),
    );

    Navigator.pop(context);
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Hapus Produk?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "${widget.product.title}"? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.plusJakartaSans(color: Colors.black87),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Delete from global state
              ProductManager().deleteProduct(widget.product.id);
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop edit screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produk berhasil dihapus!')),
              );
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.plusJakartaSans(color: Colors.white),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteProduct,
          ),
        ],
      ),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      _selectedImagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Form card container
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

                  // Ukuran
                  _buildFormSelectorRow(
                    label: 'Ukuran',
                    value: _selectedSize,
                    onTap: _showSizePicker,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                  // Kondisi
                  _buildFormSelectorRow(
                    label: 'Kondisi',
                    value: _selectedCondition,
                    onTap: _showConditionPicker,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

                  // Harga
                  _buildFormSelectorRow(
                    label: 'Harga',
                    value: 'Rp ${_enteredPrice.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    onTap: _showPriceInputDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Save Changes Button
            ElevatedButton(
              onPressed: _saveProductChanges,
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
                'Simpan Perubahan',
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
                    color: Colors.black87,
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
