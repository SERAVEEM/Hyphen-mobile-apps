import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mock_products.dart';
import 'cart_helper.dart';

class SearchResultsPage extends StatefulWidget {
  final String? initialQuery;
  final String? initialBrand;
  final String? initialCategory;

  const SearchResultsPage({
    super.key,
    this.initialQuery,
    this.initialBrand,
    this.initialCategory,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  
  String? _currentQuery;
  String? _selectedBrand;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.initialQuery;
    _selectedBrand = widget.initialBrand;
    _selectedCategory = widget.initialCategory;

    _searchController = TextEditingController(text: _currentQuery);
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Product> get _filteredProducts {
    return mockProducts.where((product) {
      // 1. Partial Text Match
      final query = _currentQuery?.toLowerCase().trim() ?? '';
      final matchesQuery = query.isEmpty ||
          product.title.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);

      // 2. Brand Match
      final matchesBrand = _selectedBrand == null ||
          product.brand.toLowerCase() == _selectedBrand!.toLowerCase();

      // 3. Category Match
      final matchesCategory = _selectedCategory == null ||
          product.category.toLowerCase() == _selectedCategory!.toLowerCase();

      return matchesQuery && matchesBrand && matchesCategory;
    }).toList();
  }

  void _clearAllFilters() {
    setState(() {
      _currentQuery = null;
      _selectedBrand = null;
      _selectedCategory = null;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }

  void _removeBrandFilter() {
    setState(() {
      _selectedBrand = null;
    });
  }

  void _removeCategoryFilter() {
    setState(() {
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    final results = _filteredProducts;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          // Search Input Bar
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3F3),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (val) {
                      setState(() {
                        _currentQuery = val.isEmpty ? null : val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari items dan seller',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _searchController.clear();
                        _currentQuery = null;
                      });
                    },
                    child: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Filters indicator
            _buildActiveFiltersBar(brandBrown),

            // Main Results view
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: results.isEmpty
                    ? _buildEmptyState(brandBrown)
                    : _buildProductsGrid(results),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBar(Color brandBrown) {
    final hasBrand = _selectedBrand != null;
    final hasCategory = _selectedCategory != null;
    final hasQuery = _currentQuery != null && _currentQuery!.isNotEmpty;

    if (!hasBrand && !hasCategory && !hasQuery) {
      // Show default quick brands suggestions instead of an empty space
      final suggestions = ['Adidas', 'Nike', 'Eiger', 'Puma'];
      return Container(
        height: 50,
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final brand = suggestions[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                label: Text(brand),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                backgroundColor: const Color(0xFFF3F3F3),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () {
                  setState(() {
                    _selectedBrand = brand;
                  });
                },
              ),
            );
          },
        ),
      );
    }

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        children: [
          if (hasQuery)
            _buildFilterChip('Kata kunci: "$_currentQuery"', () {
              setState(() {
                _currentQuery = null;
                _searchController.clear();
              });
            }, brandBrown),
          if (hasBrand)
            _buildFilterChip('Brand: $_selectedBrand', _removeBrandFilter, brandBrown),
          if (hasCategory)
            _buildFilterChip('Kategori: $_selectedCategory', _removeCategoryFilter, brandBrown),
          
          // Clear all button
          if ((hasBrand ? 1 : 0) + (hasCategory ? 1 : 0) + (hasQuery ? 1 : 0) > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ActionChip(
                label: Text(
                  'Hapus Semua',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade700,
                  ),
                ),
                backgroundColor: Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: _clearAllFilters,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InputChip(
        label: Text(label),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        backgroundColor: activeColor,
        deleteIconColor: Colors.white,
        onDeleted: onDeleted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    return GridView.builder(
      key: const ValueKey('results_grid'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.58, // Match the visual aspect ratio of feed cards
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildResultCard(product);
      },
    );
  }

  Widget _buildResultCard(Product product) {
    return GestureDetector(
      onTap: () => CartHelper.showSizeSelector(context, product),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image with favorite overlay
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.size} · ${product.condition}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.brand,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            product.formattedPrice,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color brandBrown) {
    return SingleChildScrollView(
      key: const ValueKey('empty_state'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Tidak ada hasil ditemukan',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba ubah kata kunci pencarian Anda atau hapus filter untuk menemukan produk.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearAllFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Reset Pencarian & Filter',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Show recommendations even when empty
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rekomendasi Untukmu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: mockProducts.length > 5 ? 5 : mockProducts.length,
                itemBuilder: (context, index) {
                  final product = mockProducts[index];
                  return GestureDetector(
                    onTap: () => CartHelper.showSizeSelector(context, product),
                    child: Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                product.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            product.formattedPrice,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: brandBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
