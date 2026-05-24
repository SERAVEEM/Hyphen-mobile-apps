import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_manager.dart';
import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate network request
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        AuthManager().register(
          _nameController.text.trim(),
          _emailController.text.trim(),
        );
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pendaftaran berhasil! Selamat datang, ${AuthManager().userName}!'),
            backgroundColor: const Color(0xFF8C7355),
            duration: const Duration(seconds: 2),
          ),
        );
        
        Navigator.pop(context); // Close registration view
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandBrown = Color(0xFF8C7355);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Title
                  Center(
                    child: Text(
                      'HYPEN.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'CREATE A NEW ACCOUNT',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Full Name Field
                  Text(
                    'Full Name',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    decoration: _getInputDecoration('Alex Rivera'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  Text(
                    'Email Address',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    decoration: _getInputDecoration('name@example.com'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Text(
                    'Password',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    decoration: _getInputDecoration('Min. 6 characters', isPassword: true, isObscured: _obscurePassword, onToggleObscure: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    }),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  Text(
                    'Confirm Password',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white),
                    decoration: _getInputDecoration('Repeat your password', isPassword: true, isObscured: _obscureConfirmPassword, onToggleObscure: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    }),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 36),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandBrown,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: brandBrown.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Sign Up',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                  const SizedBox(height: 40),

                  // Footer: Login navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginPage()),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.plusJakartaSans(
                            color: brandBrown,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(String hint, {bool isPassword = false, bool isObscured = false, VoidCallback? onToggleObscure}) {
    const Color brandBrown = Color(0xFF8C7355);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: brandBrown, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      suffixIcon: isPassword
          ? IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: Colors.white54,
                size: 20,
              ),
              onPressed: onToggleObscure,
            )
          : null,
    );
  }
}
