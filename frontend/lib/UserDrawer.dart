import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_manager.dart';
import 'login.dart';

class UserDrawer extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTabSelected;

  const UserDrawer({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF5C4A37);

    return Drawer(
      backgroundColor: darkBrown,
      child: SafeArea(
        child: ListenableBuilder(
          listenable: AuthManager(),
          builder: (context, child) {
            final auth = AuthManager();
            return Column(
              children: [
                const SizedBox(height: 32),
                // Drawer Header Logo
                Text(
                  'HYPEN.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  auth.isLoggedIn ? 'WELCOME, ${auth.userName.toUpperCase()}' : 'PREMIUM STORE',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Menu Cards List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildDrawerCard(context, Icons.home_outlined, 'Homepage', 0),
                      _buildDrawerCard(context, Icons.search, 'Search Products', 1),
                      _buildDrawerCard(context, Icons.add_circle_outline, 'Sell / Jual', 2),
                      _buildDrawerCard(context, Icons.mail_outline, 'Inbox', 3),
                      _buildDrawerCard(context, Icons.person_outline, 'Profile', 4),
                      const SizedBox(height: 40),
                      
                      // Dynamic Auth Card
                      _buildAuthCard(context, auth),
                    ],
                  ),
                ),

                // Footer Info
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Text(
                    'v1.0.0 (Hypen Client)',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white30,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawerCard(BuildContext context, IconData icon, String title, int tabIndex) {
    final isSelected = tabIndex == currentTab;
    const Color brandBrown = Color(0xFF8C7355);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTabSelected(tabIndex);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? brandBrown : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context, AuthManager auth) {
    const Color brandBrown = Color(0xFF8C7355);

    if (auth.isLoggedIn) {
      // Authenticated state -> Show red "Log Out" card
      return GestureDetector(
        onTap: () {
          Navigator.pop(context); // Close drawer
          auth.logout();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil keluar dari akun.'),
              duration: Duration(milliseconds: 1500),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.red.shade900.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade800.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout, color: Colors.redAccent, size: 22),
              const SizedBox(width: 16),
              Text(
                'Log Out',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.redAccent, size: 18),
            ],
          ),
        ),
      );
    } else {
      // Unauthenticated state -> Show brandBrown "Log In" card
      return GestureDetector(
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: brandBrown.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brandBrown.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.login, color: brandBrown, size: 22),
              const SizedBox(width: 16),
              Text(
                'Log In / Register',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: brandBrown, size: 18),
            ],
          ),
        ),
      );
    }
  }
}
