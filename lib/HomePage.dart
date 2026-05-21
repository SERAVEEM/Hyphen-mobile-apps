import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'UserProfile.dart';
import 'SearchPage.dart';
import 'CartPage.dart';
import 'cart_manager.dart';
import 'cart_helper.dart';
import 'mock_products.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
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
          ListenableBuilder(
            listenable: CartManager(),
            builder: (context, child) {
              final count = CartManager().totalQuantity;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartPage(),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _buildBody(brandBrown),
      
      // Custom Bottom Navigation Bar
      extendBody: true,
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black54,
          selectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Jual'),
            BottomNavigationBarItem(icon: Icon(Icons.mail_outline), label: 'Inbox'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Color brandBrown) {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeFeed(brandBrown);
      case 1:
        return const SearchPage();
      case 4:
        return UserProfile(
          onJualPressed: () => setState(() => _selectedIndex = 2),
        );
      default:
        return Center(
          child: Text(
            'Tab ${_selectedIndex + 1} Placeholder',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
    }
  }

  Widget _buildHomeFeed(Color brandBrown) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // For You Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'For You',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'See all',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // For You Carousel
          SizedBox(
            height: 480, // Increased height to fix overflow and push Hot Items down
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              children: [
                _buildProductCard(mockProducts[0]),
                const SizedBox(width: 16),
                _buildProductCard(mockProducts[4]),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Hot Items Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: brandBrown,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hot Items',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Hot Items Carousel
                SizedBox(
                  height: 480,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    children: [
                      _buildProductCard(mockProducts[0], onDark: true),
                      const SizedBox(width: 16),
                      _buildProductCard(mockProducts[4], onDark: true),
                    ],
                  ),
                ),
                // Space to avoid BottomNavigationBar overlapping content
                const SizedBox(height: 100), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, {bool onDark = false}) {
    final Color titleColor = onDark ? Colors.white : Colors.black;
    final Color subtitleColor = onDark ? Colors.white70 : Colors.black54;
    final Color priceColor = onDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () => CartHelper.showSizeSelector(context, product),
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Image.asset(
                product.imageUrl,
                height: 360,
                width: 280,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${product.size} · ${product.condition}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: subtitleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.formattedPrice,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w300,
                color: priceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
