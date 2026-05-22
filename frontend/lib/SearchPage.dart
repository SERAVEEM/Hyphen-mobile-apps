import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SearchResultsPage.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  String? _selectedBrand;

  final List<String> _brands = [
    'Adidas',
    'Nike',
    'New Balance',
    'Onitsuka Tiger',
    'Polo Ralph',
    'Fila',
    'Puma',
    'Eiger',
    'Aero Street',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onBrandTap(String brand) {
    _navigateToSearchResults(brand: brand);
  }

  void _navigateToSearchResults({String? query, String? brand, String? category}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsPage(
          initialQuery: query,
          initialBrand: brand,
          initialCategory: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Search Bar Input
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          _navigateToSearchResults(query: val.trim());
                        }
                      },
                      onChanged: (val) {
                        setState(() {
                          if (val.isEmpty) {
                            _selectedBrand = null;
                          } else {
                            // Check if value matches any brand to highlight it
                            final matchedBrand = _brands.firstWhere(
                              (brand) => brand.toLowerCase() == val.trim().toLowerCase(),
                              orElse: () => '',
                            );
                            _selectedBrand = matchedBrand.isNotEmpty ? matchedBrand : null;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari items dan seller',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.grey.shade500,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _searchController.clear();
                          _selectedBrand = null;
                        });
                      },
                      child: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Categories Title
            Text(
              'Categories',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // 2b. Categories Grid (2x2)
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildCategoryCard('Wanita', 'assets/images/cat_wanita.png'),
                _buildCategoryCard('Pria', 'assets/images/cat_pria.png'),
                _buildCategoryCard('Formal', 'assets/images/cat_formal.png'),
                _buildCategoryCard('Daily', 'assets/images/cat_daily.png'),
              ],
            ),
            const SizedBox(height: 4),

            // 3. Brand For You Title
            Text(
              'Brand For You',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // 3b. Brand Pills (Horizontal 2 Rows)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: _brands.sublist(0, (_brands.length / 2).ceil()).map((brand) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildBrandPill(brand, brandBrown),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: _brands.sublist((_brands.length / 2).ceil()).map((brand) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildBrandPill(brand, brandBrown),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 4. For You Title
            Text(
              'For You',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),

            // 4b. Staggered dual column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    children: [
                      _buildMasonryCard('assets/images/foryou_tall.png', 280),
                      const SizedBox(height: 12),
                      _buildMasonryCard('assets/images/slide1.png', 180),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right Column
                Expanded(
                  child: Column(
                    children: [
                      _buildMasonryCard('assets/images/foryou_purse.png', 180),
                      const SizedBox(height: 12),
                      _buildMasonryCard('assets/images/PreFall.png', 280),
                    ],
                  ),
                ),
              ],
            ),
            // Extra bottom spacing to clear navbar overlap
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String label, String imagePath) {
    return GestureDetector(
      onTap: () => _navigateToSearchResults(category: label),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasonryCard(String imagePath, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        imagePath,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildBrandPill(String brand, Color brandBrown) {
    final isSelected = _selectedBrand == brand;
    return GestureDetector(
      onTap: () => _onBrandTap(brand),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? brandBrown : Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          brand,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
