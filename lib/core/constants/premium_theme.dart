import 'package:flutter/material.dart';

class AppColors {
  static const spaceBlack = Color(0xFF0B0F1A);
  static const cardDark = Color(0xFF111827);
  static const neonCyan = Color(0xFF00B8FF);
  static const electricBlue = Color(0xFF146EF5);
  static const successEmerald = Color(0xFF22C55E);
  static const textSecondary = Color(0xFF94A3B8);
  static const glassBorderDark = Color(0xFF1F2937);
  static const alertOrange = Color(0xFFF59E0B);
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  const PremiumCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.cardDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? AppColors.glassBorderDark),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))]
    ),
    child: child,
  );
}

class PremiumHeader extends StatelessWidget {
  final String title, subtitle;
  final List<Widget>? actions;
  const PremiumHeader({super.key, required this.title, required this.subtitle, this.actions});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
      if (actions != null) Row(children: actions!),
    ],
  );
}
