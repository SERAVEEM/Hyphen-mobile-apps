import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordStep1Page extends StatefulWidget {
  const ResetPasswordStep1Page({super.key});

  @override
  State<ResetPasswordStep1Page> createState() => _ResetPasswordStep1PageState();
}

class _ResetPasswordStep1PageState extends State<ResetPasswordStep1Page> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendCode() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate sending OTP code
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // Navigate to Step 2
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordStep2Page(
              email: _emailController.text.trim(),
            ),
          ),
        );
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
                  Center(
                    child: Text(
                      'RESET PASSWORD',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'STEP 1 OF 2: REQUEST OTP CODE',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Enter your registered email address below. We will send a 4-digit code to verify your identity.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email Input Field
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
                    decoration: InputDecoration(
                      hintText: 'name@example.com',
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
                    ),
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
                  const SizedBox(height: 36),

                  // Send Code Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendCode,
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
                            'Send Verification Code',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ResetPasswordStep2Page extends StatefulWidget {
  final String email;
  const ResetPasswordStep2Page({super.key, required this.email});

  @override
  State<ResetPasswordStep2Page> createState() => _ResetPasswordStep2PageState();
}

class _ResetPasswordStep2PageState extends State<ResetPasswordStep2Page> {
  final _formKey = GlobalKey<FormState>();
  final _otpControllers = List.generate(4, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(4, (_) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() {
    // Validate OTP entries
    bool otpValid = true;
    for (var controller in _otpControllers) {
      if (controller.text.isEmpty) {
        otpValid = false;
        break;
      }
    }

    if (!otpValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out the full 4-digit code.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate API call to reset password
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });

        // Show elegant success dialog
        _showSuccessDialog();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        const Color brandBrown = Color(0xFF8C7355);
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brandBrown.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: brandBrown,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Password Reset Success',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your password has been successfully updated. You can now log in using your new credentials.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white60,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Pop dialog, pop Step 2, pop Step 1 to return to Login
                    Navigator.of(context).pop(); // dialog
                    Navigator.of(context).pop(); // Step 2
                    Navigator.of(context).pop(); // Step 1
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Back to Sign In',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
                  Center(
                    child: Text(
                      'VERIFY CODE',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'STEP 2 OF 2: RESET PASSWORD',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Please enter the 4-digit code sent to\n${widget.email}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // 4-Digit Code Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (index) {
                      return SizedBox(
                        width: 56,
                        height: 64,
                        child: TextFormField(
                          controller: _otpControllers[index],
                          focusNode: _otpFocusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLength: 1,
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: brandBrown, width: 1.5),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              if (index < 3) {
                                _otpFocusNodes[index + 1].requestFocus();
                              } else {
                                _otpFocusNodes[index].unfocus();
                              }
                            } else {
                              if (index > 0) {
                                _otpFocusNodes[index - 1].requestFocus();
                              }
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 36),

                  // New Password Field
                  Text(
                    'New Password',
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
                        return 'Please enter your new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm New Password Field
                  Text(
                    'Confirm New Password',
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
                    decoration: _getInputDecoration('Repeat your new password', isPassword: true, isObscured: _obscureConfirmPassword, onToggleObscure: () {
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

                  // Reset Password Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
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
                            'Reset Password',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
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
