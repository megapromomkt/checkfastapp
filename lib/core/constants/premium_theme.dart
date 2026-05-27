import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class AppColors {
  // Brand Colors
  static const primaryBlue = Color(0xFF0066FF);
  static const deepBlue = Color(0xFF0047B3);
  static const lightBlue = Color(0xFFE6F0FF);
  
  // Background & Surfaces
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const cardBorder = Color(0xFFE2E8F0);
  
  // Text Colors
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textOnPrimary = Colors.white;
  
  // States
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Legacy mappings (to prevent breaking code while migrating)
  static const spaceBlack = background;
  static const cardDark = surface;
  static const neonCyan = primaryBlue;
  static const electricBlue = deepBlue;
  static const glassBorderDark = cardBorder;
  static const successEmerald = success;
  static const alertOrange = warning;
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  const PremiumCard({super.key, required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final defaultPad = Responsive.isMobile(context) ? 16.0 : 24.0;
    return Container(
      padding: padding ?? EdgeInsets.all(defaultPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }
}

class PremiumHeader extends StatelessWidget {
  final String title, subtitle;
  final List<Widget>? actions;
  const PremiumHeader({super.key, required this.title, required this.subtitle, this.actions});

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final titleSize = Responsive.value<double>(context, mobile: 22, tablet: 26, desktop: 32);
    final subtitleSize = Responsive.value<double>(context, mobile: 13, tablet: 14, desktop: 16);

    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: titleSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
        )),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: subtitleSize,
          fontWeight: FontWeight.w400,
        )),
      ],
    );

    final actionsRow = actions != null
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: actions!,
          )
        : null;

    return Padding(
      padding: EdgeInsets.only(bottom: mobile ? 20 : 32),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textBlock,
                if (actionsRow != null) ...[const SizedBox(height: 16), actionsRow],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: textBlock),
                if (actionsRow != null) ...[const SizedBox(width: 16), actionsRow],
              ],
            ),
    );
  }
}
