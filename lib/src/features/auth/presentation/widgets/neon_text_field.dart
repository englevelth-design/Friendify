import 'package:flutter/material.dart';

class NeonTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool isPassword;
  final IconData? icon;
  final bool isNumber;
  final bool isDarkTheme;

  const NeonTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.icon,
    this.isNumber = false,
    this.isDarkTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final labelColor = isDarkTheme ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6);
    final fillColor = isDarkTheme ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final borderColor = isDarkTheme ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: textColor), 
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor),
        prefixIcon: icon != null ? Icon(icon, color: const Color(0xFFD4FF00)) : null,
        filled: true,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4FF00), width: 2), // Neon Green Focus
        ),
      ),
    );
  }
}
