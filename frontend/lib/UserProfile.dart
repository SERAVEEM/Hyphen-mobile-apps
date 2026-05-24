import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'EditProfilePage.dart';
import 'OrderHistoryPage.dart';
import 'SellerProductsPage.dart';
import 'auth_manager.dart';
import 'login.dart';

class UserProfile extends StatelessWidget {
  final VoidCallback? onJualPressed;
  const UserProfile({super.key, this.onJualPressed});

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    return ListenableBuilder(
      listenable: AuthManager(),
      builder: (context, child) {
        final auth = AuthManager();
        if (!auth.isLoggedIn) {
          return _buildLoggedOutPlaceholder(context, brandBrown);
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUserCard(context, auth.userName),
              const SizedBox(height: 20),

              _buildJualBanner(context),
              const SizedBox(height: 20),

              _buildMenuItem(
                icon: Icons.receipt_long_outlined,
                title: 'Order History',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildMenuItem(
                icon: Icons.storefront_outlined,
                title: 'Seller Dashboard',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SellerProductsPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildMenuItem(
                icon: Icons.share_outlined,
                title: 'Share',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share link copied!')),
                  );
                },
              ),
              const SizedBox(height: 16),

              _buildGroupedMenu(
                items: [
                  _GroupedItemData(
                    icon: Icons.help_outline,
                    title: 'Help',
                    onTap: () {},
                  ),
                  _GroupedItemData(
                    icon: Icons.headset_mic_outlined,
                    title: 'Support',
                    onTap: () {},
                  ),
                ],
              ),
              
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserCard(BuildContext context, String userName) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EditProfilePage(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFF3F3F3),
              backgroundImage: AssetImage('assets/images/user_avatar.png'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lihat profil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black26,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedOutPlaceholder(BuildContext context, Color brandBrown) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF6F6F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_circle_outlined,
                color: brandBrown,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Sign In Required',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Log in or register to view your profile details, check order history, and access the seller dashboard.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.black54,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
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
                'Sign In / Register',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJualBanner(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/images/banner_sweater.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mulai jual bajumu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Baju tidak terpakai\ndapat jadi cuan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: onJualPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    elevation: 0,
                  ),
                  child: Text(
                    'Jual',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black26,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedMenu({required List<_GroupedItemData> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: index == 0
                    ? const BorderRadius.vertical(top: Radius.circular(20))
                    : index == items.length - 1
                        ? const BorderRadius.vertical(bottom: Radius.circular(20))
                        : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Row(
                    children: [
                      Icon(item.icon, color: Colors.black, size: 22),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Colors.black26,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
              if (index < items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF5F5F5),
                  indent: 20,
                  endIndent: 20,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _GroupedItemData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _GroupedItemData({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
