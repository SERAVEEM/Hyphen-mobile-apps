import 'dart:ui';
import 'package:flutter/material.dart';

void main() => runApp(const HypenApp());

const Color primaryBrown = Color(0xFF856A51);

class HypenApp extends StatelessWidget {
  const HypenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HYPEN.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto', 
      ),
      home: const CategoriesScreen(),
    );
  }
}

class CategoryItem {
  final String label;
  final String imagePath;
  final Color placeholderColor;

  const CategoryItem({
    required this.label,
    required this.imagePath,
    required this.placeholderColor,
  });
}

const List<CategoryItem> categories = [
  CategoryItem(
    label: 'WINTER\nOUTFITS',
    imagePath: 'assets/images/Winter.png',
    placeholderColor: Color(0xFF7A6652),
  ),
  CategoryItem(
    label: 'SPRING\nOUTFITS',
    imagePath: 'assets/images/Spring.png',
    placeholderColor: Color(0xFF4A7C7E),
  ),
  CategoryItem(
    label: 'PRE-FALL\nOUTFITS',
    imagePath: 'assets/images/PreFall.png',
    placeholderColor: Color(0xFF3D3D3D),
  ),
];

const int _kInfiniteBase = 999999;
const int _kInitialPage = _kInfiniteBase ~/ 2;

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final PageController _pageController = PageController(
    viewportFraction: 0.8,
    initialPage: _kInitialPage,
  );

  double _currentPage = _kInitialPage.toDouble();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    if (!_pageController.hasClients) return;
    final double page = _pageController.page ?? _kInitialPage.toDouble();
    setState(() {
      _currentPage = page;
      _currentIndex = page.round() % categories.length;
    });
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false, // Membiarkan bottom nav menempel ke ujung layar bawah
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 25), // Push title lower
            _buildTitle(),
            const SizedBox(height: 55),
            _buildCarousel(),
            const Spacer(),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {},
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _menuLine(width: 24),
                const SizedBox(height: 6),
                _menuLine(width: 24),
                const SizedBox(height: 6),
                _menuLine(width: 14),
              ],
            ),
          ),
          const Text(
            'HYPEN.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: primaryBrown,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.black,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuLine({required double width}) {
    return Container(width: width, height: 2, color: Colors.black);
  }

  Widget _buildTitle() {
    return const Center(
      child: Text(
        'Categories',
        style: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Colors.black,
          letterSpacing: -1.0, // Dibuat rapat sesuai desain
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 550, // Reverted height
      child: PageView.builder(
        controller: _pageController,
        itemCount: _kInfiniteBase,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final int realIndex = index % categories.length;

          final double distance = (_currentPage - index).abs();
          final double scale = lerpDouble(1.0, 0.90, distance.clamp(0, 1))!;
          final double opacity = lerpDouble(1.0, 0.60, distance.clamp(0, 1))!;

          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: _CategoryCard(
                item: categories[realIndex],
                isActive: realIndex == _currentIndex &&
                    (index - _currentPage).abs() < 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return SizedBox(
      height: 100,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Teks WOMEN & MEN
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: _navItem(label: 'WOMEN', isActive: true),
                  ),
                ),
                const SizedBox(width: 120), // Ruang di tengah untuk hump
                Expanded(
                  child: Center(
                    child: _navItem(label: 'MEN', isActive: false),
                  ),
                ),
              ],
            ),
          ),
          // Shape Lengkungan Custom (Hump)
          Positioned(
            bottom: -15, // Ensure it fully covers the bottom gap
            left: 0,
            right: 0,
            child: SizedBox(
              height: 120, // Made the brown thing taller
              child: CustomPaint(
                painter: _BottomTabPainter(color: primaryBrown),
                child: const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 28), // Pushed icon down a bit to match the taller tab
                    child: Icon(
                      Icons.home_outlined, // Placeholder house outline
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({required String label, required bool isActive}) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.black : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem item;
  final bool isActive;

  const _CategoryCard({required this.item, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Margin bottom memberikan ruang agar tombol panah yang tumpah (overflow) tidak terpotong PageView
      margin: const EdgeInsets.only(bottom: 50, top: 10, left: 10, right: 10),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Background Card ──────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(8), // Sudut lebih tajam sesuai desain
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: item.placeholderColor),
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter, // Keep the head visible
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),

                  // Gradient Hitam Lembut
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Icon Heart
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  // Text Category Label
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 70,
                    child: Text(
                      item.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        height: 1.05, // Jarak antar baris dipersempit
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Arrow Button ──────────────────────────────
          Positioned(
            bottom: -55, // Pushed further down to keep it exactly overlapping halfway
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 110 : 90, // Circle scaled even bigger
                  height: isActive ? 110 : 90,
                  decoration: BoxDecoration(
                    color: primaryBrown,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 6), // Border putih tebal
                  ),
                  child: const Icon(
                    Icons.arrow_outward_rounded,
                    color: Colors.white,
                    size: 40, // Arrow icon scaled bigger
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CUSTOM PAINTER UNTUK BOTTOM NAVIGATION (HUMP) ──
class _BottomTabPainter extends CustomPainter {
  final Color color;

  _BottomTabPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();

    final w = size.width;
    final h = size.height;

    // Pengaturan dimensi lengkungan
    final humpWidth = 115.0; // Made the brown thing wider
    final startX = (w - humpWidth) / 2;
    final endX = startX + humpWidth;
    final bottomRadius = 45.0; // Smooth wide flare at the bottom
    
    // Top corners rounded moderately
    final topRadius = 24.0; 

    path.moveTo(0, h);
    path.lineTo(startX - bottomRadius, h);
    
    // Left concave flare
    path.quadraticBezierTo(startX, h, startX, h - bottomRadius);
    
    // Straight vertical line up
    path.lineTo(startX, topRadius);
    
    // Top-left rounded corner
    path.quadraticBezierTo(startX, 0, startX + topRadius, 0);
    
    // Flat top
    path.lineTo(endX - topRadius, 0);
    
    // Top-right rounded corner
    path.quadraticBezierTo(endX, 0, endX, topRadius);
    
    // Straight vertical line down
    path.lineTo(endX, h - bottomRadius);
    
    // Right concave flare
    path.quadraticBezierTo(endX, h, endX + bottomRadius, h);
    
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}