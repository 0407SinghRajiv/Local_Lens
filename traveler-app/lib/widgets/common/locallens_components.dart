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

/// Experience image component with network loading, placeholder skeleton, error fallback and aspect ratio preservation.
class LocalLensNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackAsset;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const LocalLensNetworkImage({
    super.key,
    required this.imageUrl,
    this.fallbackAsset = 'assets/images/destinations/food_trail.png',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    final url = imageUrl?.trim() ?? '';

    if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: LocalLensColors.surfaceSecondary,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(LocalLensColors.primaryTeal),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    } else if (url.startsWith('assets/')) {
      imageWidget = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      imageWidget = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    return Image.asset(
      fallbackAsset,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: LocalLensColors.primaryTealSoft,
        child: const Icon(
          Icons.image_outlined,
          color: LocalLensColors.primaryTeal,
          size: 24,
        ),
      ),
    );
  }
}

/// Section Header with Title and optional action button
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: LocalLensTypography.titleLarge,
          ),
          if (actionText != null && onActionTap != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: LocalLensTypography.titleSmall.copyWith(
                  color: LocalLensColors.primaryTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rating Badge Pill (e.g., "★ 4.8")
class RatingBadge extends StatelessWidget {
  final double rating;
  final int? reviewCount;

  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            size: 14,
            color: LocalLensColors.accentOrange,
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: LocalLensTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: LocalLensColors.textPrimary,
            ),
          ),
          if (reviewCount != null) ...[
            const SizedBox(width: 2),
            Text(
              '($reviewCount)',
              style: LocalLensTypography.caption.copyWith(
                fontSize: 10,
                color: LocalLensColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hero Destination Card (Airbnb-inspired large photography card)
class DestinationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final String ctaText;
  final VoidCallback onTap;

  const DestinationCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.ctaText = 'Continue trip →',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.floating,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              Positioned.fill(
                child: LocalLensNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: LocalLensColors.accentOrange,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'CURRENT TRIP',
                        style: LocalLensTypography.badge.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: LocalLensTypography.displayMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              subtitle,
                              style: LocalLensTypography.bodyMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            Text(
                              ctaText,
                              style: LocalLensTypography.titleSmall.copyWith(
                                color: LocalLensColors.primaryTealLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Experience Card (Airbnb style, vertical/horizontal layout for local experiences)
class ExperienceCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final double rating;
  final String category;
  final double priceInr;
  final String location;
  final double? distanceKm;
  final double? durationHours;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback? onSaveTap;
  final double width;

  const ExperienceCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.category,
    required this.priceInr,
    required this.location,
    this.distanceKm,
    this.durationHours,
    this.isSaved = false,
    required this.onTap,
    this.onSaveTap,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
          border: Border.all(color: LocalLensColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                  child: LocalLensNetworkImage(
                    imageUrl: imageUrl,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onSaveTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: isSaved ? LocalLensColors.accentOrange : LocalLensColors.textMuted,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: RatingBadge(rating: rating),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: LocalLensColors.primaryTealSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          category.toUpperCase(),
                          style: LocalLensTypography.badge.copyWith(
                            color: LocalLensColors.primaryTeal,
                            fontSize: 9,
                          ),
                        ),
                      ),
                      if (distanceKm != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${distanceKm!.toStringAsFixed(1)} km away',
                          style: LocalLensTypography.caption.copyWith(fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LocalLensTypography.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: LocalLensColors.textMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LocalLensTypography.caption,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${priceInr.toInt()}',
                        style: LocalLensTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          color: LocalLensColors.primaryTeal,
                        ),
                      ),
                      if (durationHours != null)
                        Text(
                          '${durationHours!.toStringAsFixed(1)}h',
                          style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wanderlog-inspired Trip Header Card
class TripHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final int placesCount;
  final String totalDuration;
  final double estimatedCost;
  final bool isMapView;
  final ValueChanged<bool> onToggleView;

  const TripHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.placesCount,
    required this.totalDuration,
    required this.estimatedCost,
    required this.isMapView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
        border: Border.all(color: LocalLensColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: LocalLensTypography.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: LocalLensTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              // Map / List Toggle Pills
              Container(
                decoration: BoxDecoration(
                  color: LocalLensColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => onToggleView(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: !isMapView ? LocalLensColors.primaryTeal : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.format_list_bulleted_rounded,
                              size: 15,
                              color: !isMapView ? Colors.white : LocalLensColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'List',
                              style: LocalLensTypography.caption.copyWith(
                                color: !isMapView ? Colors.white : LocalLensColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onToggleView(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isMapView ? LocalLensColors.primaryTeal : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.map_rounded,
                              size: 15,
                              color: isMapView ? Colors.white : LocalLensColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Map',
                              style: LocalLensTypography.caption.copyWith(
                                color: isMapView ? Colors.white : LocalLensColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatChip(Icons.place_rounded, '$placesCount places'),
              const SizedBox(width: 10),
              _buildStatChip(Icons.schedule_rounded, totalDuration),
              const SizedBox(width: 10),
              _buildStatChip(Icons.payments_rounded, '₹${estimatedCost.toInt()} est.'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: LocalLensColors.primaryTealSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: LocalLensColors.primaryTeal),
          const SizedBox(width: 4),
          Text(
            label,
            style: LocalLensTypography.caption.copyWith(
              color: LocalLensColors.primaryTealDark,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wanderlog-inspired Itinerary Card Component
class ItineraryCardWidget extends StatelessWidget {
  final String time;
  final String title;
  final double rating;
  final String category;
  final String durationText;
  final String? travelTimeFromPrevious;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onReorder;

  const ItineraryCardWidget({
    super.key,
    required this.time,
    required this.title,
    required this.rating,
    required this.category,
    required this.durationText,
    this.travelTimeFromPrevious,
    this.onTap,
    this.onDelete,
    this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (travelTimeFromPrevious != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 36, top: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.directions_car_rounded, size: 14, color: LocalLensColors.accentOrange),
                const SizedBox(width: 6),
                Text(
                  travelTimeFromPrevious!,
                  style: LocalLensTypography.caption.copyWith(
                    color: LocalLensColors.accentOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: LocalLensColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle Icon
                Icon(
                  Icons.drag_indicator_rounded,
                  color: LocalLensColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                // Time pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: LocalLensColors.primaryTealSoft,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    time,
                    style: LocalLensTypography.caption.copyWith(
                      color: LocalLensColors.primaryTealDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: LocalLensTypography.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingBadge(rating: rating),
                          const SizedBox(width: 8),
                          Text('•', style: LocalLensTypography.caption),
                          const SizedBox(width: 8),
                          Text(
                            durationText,
                            style: LocalLensTypography.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: LocalLensColors.textMuted),
                    onPressed: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Shimmer Skeleton Loading Card
class LoadingCard extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const LoadingCard({
    super.key,
    this.height = 140,
    this.width,
    this.borderRadius = AppRadius.md,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: LocalLensColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Friendly Empty State Widget per design.md Section 25
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonTap;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: LocalLensColors.primaryTealSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: LocalLensColors.primaryTeal,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: LocalLensTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: LocalLensTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (buttonText != null && onButtonTap != null) ...[
            const SizedBox(height: AppSpacing.xl),
            LocalLensPrimaryButton(
              text: buttonText!,
              onPressed: onButtonTap,
              width: 200,
            ),
          ],
        ],
      ),
    );
  }
}


