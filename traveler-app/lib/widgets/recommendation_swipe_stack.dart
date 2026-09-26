import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/locallens_design_system.dart';
import '../models/recommendation_model.dart';
import 'common/locallens_components.dart';

/// Direction of card swipe
enum SwipeDirection { left, right }

/// High-performance, Google Photos / Tinder style Swipeable Card Stack for recommendations
class RecommendationSwipeStack extends StatefulWidget {
  final List<RecommendationModel> candidates;
  final ValueChanged<RecommendationModel> onSwipeRight; // Select / Keep
  final ValueChanged<RecommendationModel> onSwipeLeft; // Skip / Reject
  final VoidCallback? onStackEmpty;
  final int placesToVisit;
  final int selectedCount;

  const RecommendationSwipeStack({
    super.key,
    required this.candidates,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    this.onStackEmpty,
    required this.placesToVisit,
    required this.selectedCount,
  });

  @override
  State<RecommendationSwipeStack> createState() => RecommendationSwipeStackState();
}

class RecommendationSwipeStackState extends State<RecommendationSwipeStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  bool _isAnimating = false;

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _slideAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Trigger programmed swipe right (Select) via button or keyboard
  void swipeRight() {
    if (_isAnimating || widget.candidates.isEmpty) return;
    _executeSwipe(SwipeDirection.right);
  }

  /// Trigger programmed swipe left (Skip) via button or keyboard
  void swipeLeft() {
    if (_isAnimating || widget.candidates.isEmpty) return;
    _executeSwipe(SwipeDirection.left);
  }

  void _executeSwipe(SwipeDirection direction) {
    if (_isAnimating || widget.candidates.isEmpty) return;
    _isAnimating = true;

    final screenWidth = MediaQuery.of(context).size.width;
    final targetX = direction == SwipeDirection.right ? screenWidth * 1.5 : -screenWidth * 1.5;
    final targetRotation = direction == SwipeDirection.right ? 0.35 : -0.35;

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy * 0.3),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad));

    _rotationAnimation = Tween<double>(
      begin: (_dragOffset.dx / (screenWidth > 0 ? screenWidth : 360.0)) * 0.35,
      end: targetRotation,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad));

    _animationController.forward(from: 0.0).then((_) {
      if (!mounted) return;
      if (widget.candidates.isNotEmpty) {
        final swipedCard = widget.candidates.first;
        _dragOffset = Offset.zero;
        _animationController.reset();
        _isDragging = false;
        _isAnimating = false;

        if (direction == SwipeDirection.right) {
          widget.onSwipeRight(swipedCard);
        } else {
          widget.onSwipeLeft(swipedCard);
        }
      } else {
        _isAnimating = false;
        _isDragging = false;
      }
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating || widget.candidates.isEmpty) return;
    _isDragging = true;
    _dragOffset = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isAnimating || widget.candidates.isEmpty) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating || widget.candidates.isEmpty) return;
    _isDragging = false;

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.26;

    // Check velocity and offset for intuitive swipe
    final velocityX = details.velocity.pixelsPerSecond.dx;
    if (_dragOffset.dx > threshold || velocityX > 700) {
      _executeSwipe(SwipeDirection.right);
    } else if (_dragOffset.dx < -threshold || velocityX < -700) {
      _executeSwipe(SwipeDirection.left);
    } else {
      // Smoothly spring back to center
      _isAnimating = true;
      _slideAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

      _rotationAnimation = Tween<double>(
        begin: (_dragOffset.dx / screenWidth) * 0.35,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

      _animationController.forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() {
            _dragOffset = Offset.zero;
            _animationController.reset();
            _isAnimating = false;
          });
        }
      });
    }
  }

  void _onPanCancel() {
    if (_isAnimating) return;
    if (mounted) {
      setState(() {
        _isDragging = false;
        _dragOffset = Offset.zero;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.candidates.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 64, color: LocalLensColors.primaryTeal),
            const SizedBox(height: 16),
            Text('All cards reviewed!', style: LocalLensTypography.titleLarge),
            const SizedBox(height: 8),
            Text('Generating recommendations...', style: LocalLensTypography.bodyMedium),
          ],
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.28;
    final dragDx = _isDragging ? _dragOffset.dx : _slideAnimation.value.dx;
    final rightSelectOpacity = (dragDx / threshold).clamp(0.0, 1.0);
    final leftSkipOpacity = (-dragDx / threshold).clamp(0.0, 1.0);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            swipeRight();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            swipeLeft();
          }
        }
      },
      child: Column(
        children: [
          // STACK CONTAINER
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = min(constraints.maxWidth * 0.92, 420.0);
                final cardHeight = constraints.maxHeight - 20;

                // Max 4 visible layered cards in deck
                final visibleCount = min(widget.candidates.length, 4);

                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(visibleCount, (index) {
                    final reverseIndex = visibleCount - 1 - index;
                    final candidate = widget.candidates[reverseIndex];

                    if (reverseIndex == 0) {
                      // TOP ACTIVE CARD WITH GESTURE & TRANSFORMS
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final currentOffset = _isDragging ? _dragOffset : _slideAnimation.value;
                          final currentRotation = _isDragging
                              ? (_dragOffset.dx / screenWidth) * 0.35
                              : _rotationAnimation.value;

                              return Transform.translate(
                            offset: currentOffset,
                            child: Transform.rotate(
                              angle: currentRotation,
                              child: MouseRegion(
                                cursor: _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
                                child: GestureDetector(
                                  onPanStart: _onPanStart,
                                  onPanUpdate: _onPanUpdate,
                                  onPanEnd: _onPanEnd,
                                  onPanCancel: _onPanCancel,
                                  child: Stack(
                                    children: [
                                      _buildCard(
                                        candidate: candidate,
                                        width: cardWidth,
                                        height: cardHeight,
                                        isTopCard: true,
                                      ),
                                    // SELECT BADGE OVERLAY
                                    if (rightSelectOpacity > 0.05)
                                      Positioned(
                                        top: 24,
                                        left: 24,
                                        child: Opacity(
                                          opacity: rightSelectOpacity,
                                          child: Transform.rotate(
                                            angle: -0.2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: LocalLensColors.successGreen,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: LocalLensDimensions.floatingShadow,
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.check_rounded, color: Colors.white, size: 22),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'SELECT',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 16,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    // SKIP BADGE OVERLAY
                                    if (leftSkipOpacity > 0.05)
                                      Positioned(
                                        top: 24,
                                        right: 24,
                                        child: Opacity(
                                          opacity: leftSkipOpacity,
                                          child: Transform.rotate(
                                            angle: 0.2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: LocalLensColors.errorRed,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: LocalLensDimensions.floatingShadow,
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.close_rounded, color: Colors.white, size: 22),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    'SKIP',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 16,
                                                      letterSpacing: 1.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                    // LAYERED BACKGROUND CARDS IN DECK
                    final scale = 1.0 - (reverseIndex * 0.05);
                    final yOffset = reverseIndex * 14.0;

                    return Transform.translate(
                      offset: Offset(0, yOffset),
                      child: Transform.scale(
                        scale: scale,
                        child: _buildCard(
                          candidate: candidate,
                          width: cardWidth,
                          height: cardHeight,
                          isTopCard: false,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // BOTTOM BUTTON CONTROLS (ACCESSIBILITY & DESKTOP)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // SKIP BUTTON
                _buildActionButton(
                  icon: Icons.close_rounded,
                  label: 'Skip',
                  color: LocalLensColors.errorRed,
                  backgroundColor: LocalLensColors.errorRed.withValues(alpha: 0.12),
                  onTap: swipeLeft,
                ),

                const SizedBox(width: 24),

                // SELECT / KEEP BUTTON
                _buildActionButton(
                  icon: Icons.favorite_rounded,
                  label: 'Select',
                  color: LocalLensColors.primaryTeal,
                  backgroundColor: LocalLensColors.primaryTealSoft,
                  isPrimary: true,
                  onTap: swipeRight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color backgroundColor,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(36),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isPrimary ? 28 : 22, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: isPrimary ? LocalLensDimensions.softCardShadow : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: isPrimary ? 24 : 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: LocalLensTypography.button.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: isPrimary ? 15 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required RecommendationModel candidate,
    required double width,
    required double height,
    required bool isTopCard,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTopCard ? LocalLensColors.border : LocalLensColors.borderLight,
          width: 1.2,
        ),
        boxShadow: isTopCard ? LocalLensDimensions.floatingShadow : LocalLensDimensions.softCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Section
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalLensNetworkImage(
                    imageUrl: candidate.image,
                    borderRadius: BorderRadius.zero,
                  ),
                  // Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.75),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Top Category & Rating Badges
                  Positioned(
                    top: 14,
                    left: 14,
                    right: 14,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: LocalLensColors.accentOrange,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: LocalLensDimensions.softCardShadow,
                          ),
                          child: Text(
                            candidate.category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (candidate.rating != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                const SizedBox(width: 4),
                                Text(
                                  '${candidate.rating}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Bottom Title & Location Overlay on Image
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          candidate.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.place_rounded, color: Colors.white70, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                candidate.location,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Info Details Section
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Price & Duration Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: LocalLensColors.primaryTealSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            candidate.price > 0 ? '₹${candidate.price.toInt()}' : 'Free Entry',
                            style: const TextStyle(
                              color: LocalLensColors.primaryTealDark,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: LocalLensColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: LocalLensColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 13, color: LocalLensColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${candidate.durationMinutes} mins',
                                style: const TextStyle(
                                  color: LocalLensColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (candidate.hiddenGem) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: const Text(
                              '💎 Hidden Gem',
                              style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Recommendation Rationale
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: LocalLensColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LocalLensColors.borderLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: LocalLensColors.accentOrange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              candidate.reason,
                              style: LocalLensTypography.caption.copyWith(
                                color: LocalLensColors.textPrimary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Swipe Hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swipe_rounded, size: 14, color: LocalLensColors.textMuted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Swipe Right to Keep • Swipe Left to Skip',
                            style: LocalLensTypography.caption.copyWith(
                              color: LocalLensColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
