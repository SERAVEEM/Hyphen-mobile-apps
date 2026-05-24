import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhotoUploaderBox extends StatelessWidget {
  final String? selectedImagePath;
  final VoidCallback onTap;

  const PhotoUploaderBox({
    super.key,
    required this.selectedImagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
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
          child: selectedImagePath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    selectedImagePath!,
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
    );
  }
}
