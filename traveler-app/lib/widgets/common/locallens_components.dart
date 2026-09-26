import 'package:flutter/material.dart';
import '../../core/theme/locallens_design_system.dart';

/// LocalLens Brand Logo with Pin & Lens Icon
class LocalLensLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final Color? textColor;

  const LocalLensLogo({
    super.key,
    this.size = 36,
    this.showTagline = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Teal Pin with Orange Lens Center
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LocalLensColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x330E8388),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: size * 0.45,
                  height: size * 0.45,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: LocalLensColors.accentOrange,
                  ),
                  child: Center(
                    child: Container(
                      width: size * 0.18,
                      height: size * 0.18,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                text: 'Local',
                style: LocalLensTypography.displayMedium.copyWith(
                  color: textColor ?? LocalLensColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: size * 0.75,
                ),
                children: [
                  TextSpan(
                    text: 'Lens',
                    style: TextStyle(
                      color: LocalLensColors.primaryTeal,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          Text(
            'See More. Experience Local.',
            style: LocalLensTypography.caption.copyWith(
              color: textColor?.withValues(alpha: 0.8) ?? LocalLensColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// Primary Action Button (Orange gradient or Teal)
class LocalLensPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isOrange;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const LocalLensPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOrange = true,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = LocalLensDimensions.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isOrange
        ? LocalLensColors.orangeGradient
        : LocalLensColors.primaryGradient;

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed != null ? gradient : null,
        color: onPressed == null ? LocalLensColors.textMuted : null,
        borderRadius: BorderRadius.circular(LocalLensDimensions.buttonRadius),
        boxShadow: onPressed != null
            ? [
                BoxShadow(
                  color: isOrange
                      ? const Color(0x40FF6B4A)
                      : const Color(0x400E8388),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(LocalLensDimensions.buttonRadius),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: LocalLensTypography.button,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Secondary Outlined / Light Surface Button
class LocalLensSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isOutlined;
  final double? width;
  final double height;

  const LocalLensSecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isOutlined = true,
    this.width,
    this.height = LocalLensDimensions.buttonHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: isOutlined ? Colors.white : LocalLensColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(LocalLensDimensions.buttonRadius),
        border: isOutlined
            ? Border.all(color: LocalLensColors.border, width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(LocalLensDimensions.buttonRadius),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: LocalLensColors.textPrimary, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: LocalLensTypography.button.copyWith(
                    color: LocalLensColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Category Pill Chip
class LocalLensCategoryChip extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const LocalLensCategoryChip({
    super.key,
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? LocalLensColors.primaryTeal : Colors.white,
          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: LocalLensColors.primaryTeal.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : LocalLensDimensions.softCardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : LocalLensColors.primaryTeal,
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: LocalLensTypography.bodyLarge.copyWith(
                color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Match Percentage Badge (e.g., "100% Match")
class MatchBadge extends StatelessWidget {
  final String text;

  const MatchBadge({
    super.key,
    this.text = '100% Match',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: LocalLensColors.successGreenSoft,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
        border: Border.all(
          color: LocalLensColors.successGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: LocalLensColors.successGreen,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: LocalLensTypography.badge.copyWith(
              color: LocalLensColors.successGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified 5-Tab Bottom Navigation Bar matching the reference design
class LocalLensBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const LocalLensBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: LocalLensColors.border.withValues(alpha: 0.7)),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0B2545),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_rounded, 'Home'),
              _buildNavItem(1, Icons.explore_rounded, 'Explore'),
              _buildNavItem(2, Icons.route_rounded, 'Trips'),
              _buildNavItem(3, Icons.bookmark_rounded, 'Saved'),
              _buildNavItem(4, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? LocalLensColors.primaryTeal
                  : LocalLensColors.textMuted,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? LocalLensColors.primaryTeal
                    : LocalLensColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
