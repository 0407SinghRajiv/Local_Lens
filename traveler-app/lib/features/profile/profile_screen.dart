import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/auth_provider.dart';

/// Screen: Traveler Profile & Personality (Stitch UI)
class ProfileScreen extends ConsumerWidget {
  final bool isStormy;
  const ProfileScreen({super.key, this.isStormy = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final displayName = userProfile?.displayName.isNotEmpty == true
        ? userProfile!.displayName
        : 'Elena Rostova';

    final bgColor = isStormy ? const Color(0xFF0F172A) : LocalLensColors.background;
    final cardBg = isStormy ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isStormy ? const Color(0xFF334155) : LocalLensColors.borderSubtle;
    final primaryTextColor = isStormy ? Colors.white : LocalLensColors.deepInk;
    final secondaryTextColor = isStormy ? const Color(0xFF94A3B8) : LocalLensColors.textSecondary;
    final cyanAccent = isStormy ? const Color(0xFF38BDF8) : LocalLensColors.terracottaPrimary;
    final subContainerBg = isStormy ? const Color(0xFF0F172A) : LocalLensColors.surfaceContainerLow;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: isStormy ? const Color(0xFF1E293B) : LocalLensColors.background,
          elevation: 0,
          title: Text(
            'Traveler Profile',
            style: LocalLensTypography.headlineMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(Icons.settings_outlined, color: primaryTextColor),
              onPressed: () => context.push(AppRoutes.settings),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: LocalLensDimensions.paddingScreen,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: isStormy ? null : LocalLensDimensions.softCardShadow,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cyanAccent.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  image: DecorationImage(
                                    image: userProfile?.photoUrl != null && userProfile!.photoUrl!.startsWith('http')
                                        ? NetworkImage(userProfile.photoUrl!) as ImageProvider
                                        : const AssetImage('assets/images/characters/solo.png'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: cyanAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.verified_rounded, color: isStormy ? const Color(0xFF0F172A) : Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: primaryTextColor,
                                  ),
                                ),
                                Text(
                                  '@elena_wanderer',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isStormy ? const Color(0xFF38BDF8) : LocalLensColors.coastalSage).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.workspace_premium_rounded,
                                        color: isStormy ? const Color(0xFF38BDF8) : LocalLensColors.coastalSage,
                                        size: 13,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Curator Level 4 • 18 Cities',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isStormy ? const Color(0xFF38BDF8) : LocalLensColors.coastalSage,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Quick Stats Bar
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: subContainerBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('3', 'Trips Planned', isAccent: true, primaryTextColor: primaryTextColor, secondaryTextColor: secondaryTextColor, accentColor: cyanAccent),
                            Container(width: 1, height: 28, color: borderColor),
                            _buildStatItem('24', 'Saved Spots', isAccent: false, primaryTextColor: primaryTextColor, secondaryTextColor: secondaryTextColor, accentColor: cyanAccent),
                            Container(width: 1, height: 28, color: borderColor),
                            _buildStatItem('12', 'Story Reviews', isAccent: false, primaryTextColor: primaryTextColor, secondaryTextColor: secondaryTextColor, accentColor: cyanAccent),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Travel Personality DNA Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: isStormy ? null : LocalLensDimensions.softCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.psychology_alt_rounded, color: cyanAccent, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'TRAVEL DNA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: cyanAccent,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => context.push(AppRoutes.travelPersonality),
                            style: TextButton.styleFrom(
                              backgroundColor: subContainerBg,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Text('Fine-tune', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryTextColor)),
                            label: Icon(Icons.tune_rounded, size: 14, color: primaryTextColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The Cultured Flâneur & Foodie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You savor slow-paced explorations, lingering over terrace espresso, ancient craft, and candid sunset panoramas.',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Trait Progress Bars
                      _buildTraitBar('Culture & Heritage', 0.92, cyanAccent, Icons.museum_rounded, primaryTextColor, subContainerBg),
                      const SizedBox(height: 8),
                      _buildTraitBar('Street Food & Artisan Cafes', 0.85, isStormy ? const Color(0xFF2DD4BF) : LocalLensColors.coastalSage, Icons.bakery_dining_rounded, primaryTextColor, subContainerBg),
                      const SizedBox(height: 8),
                      _buildTraitBar('Photography & Golden Hour', 0.80, isStormy ? const Color(0xFFF59E0B) : LocalLensColors.sandTertiary, Icons.photo_camera_rounded, primaryTextColor, subContainerBg),
                      const SizedBox(height: 8),
                      _buildTraitBar('Adventure & Nightlife', 0.35, secondaryTextColor, Icons.hiking_rounded, primaryTextColor, subContainerBg),

                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isStormy ? const Color(0xFF0F172A) : LocalLensColors.sandTertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, color: isStormy ? const Color(0xFF38BDF8) : LocalLensColors.sandTertiary, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 11, color: primaryTextColor),
                                  children: const [
                                    TextSpan(text: 'Matches curated itineraries in '),
                                    TextSpan(text: 'Florence, Oaxaca,', style: TextStyle(fontWeight: FontWeight.w700)),
                                    TextSpan(text: ' and '),
                                    TextSpan(text: 'Kyoto.', style: TextStyle(fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Menu List Options
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: isStormy ? null : LocalLensDimensions.softCardShadow,
                  ),
                  child: Column(
                    children: [
                      _buildMenuTile(Icons.card_travel_rounded, 'My Trips', () {
                        context.push(AppRoutes.myItinerary);
                      }, primaryTextColor, cyanAccent, secondaryTextColor),
                      Divider(height: 1, indent: 52, endIndent: 16, color: borderColor),
                      _buildMenuTile(Icons.history_rounded, 'Travel History', () {
                        context.push(AppRoutes.travelHistory);
                      }, primaryTextColor, cyanAccent, secondaryTextColor),
                      Divider(height: 1, indent: 52, endIndent: 16, color: borderColor),
                      _buildMenuTile(Icons.psychology_rounded, 'Travel Personality', () {
                        context.push(AppRoutes.travelPersonality);
                      }, primaryTextColor, cyanAccent, secondaryTextColor),
                      Divider(height: 1, indent: 52, endIndent: 16, color: borderColor),
                      _buildMenuTile(Icons.bookmark_outline_rounded, 'Saved Places', () {
                        context.push(AppRoutes.saved);
                      }, primaryTextColor, cyanAccent, secondaryTextColor),
                      Divider(height: 1, indent: 52, endIndent: 16, color: borderColor),
                      _buildMenuTile(Icons.tune_rounded, 'Preferences', () {
                        context.push(AppRoutes.interestSelection);
                      }, primaryTextColor, cyanAccent, secondaryTextColor),
                      Divider(height: 1, indent: 52, endIndent: 16, color: borderColor),
                      _buildMenuTile(Icons.settings_outlined, 'Settings', () {
                        context.push(AppRoutes.settings);
                      }, primaryTextColor, cyanAccent, secondaryTextColor),
                      Divider(height: 1, indent: 52, endIndent: 16, color: borderColor),
                      ListTile(
                        leading: Icon(
                          Icons.logout_rounded,
                          color: isStormy ? const Color(0xFFF87171) : LocalLensColors.errorRed,
                          size: 20,
                        ),
                        title: Text(
                          'Log Out',
                          style: TextStyle(
                            color: isStormy ? const Color(0xFFF87171) : LocalLensColors.errorRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () async {
                          await ref.read(authNotifierProvider).signOut();
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String val,
    String label, {
    required bool isAccent,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color accentColor,
  }) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isAccent ? accentColor : primaryTextColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTraitBar(
    String name,
    double percent,
    Color color,
    IconData icon,
    Color primaryTextColor,
    Color progressBgColor,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
            Text(
              '${(percent * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: primaryTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: progressBgColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(
    IconData icon,
    String title,
    VoidCallback onTap,
    Color primaryTextColor,
    Color iconColor,
    Color trailingColor,
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: primaryTextColor,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: trailingColor),
      onTap: onTap,
    );
  }
}
