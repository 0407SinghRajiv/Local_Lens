import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/auth_provider.dart';

/// Screen: Traveler Profile & Personality (Stitch UI)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final displayName = userProfile?.displayName.isNotEmpty == true
        ? userProfile!.displayName
        : 'Elena Rostova';

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      appBar: AppBar(
        backgroundColor: LocalLensColors.background,
        elevation: 0,
        title: Text(
          'Traveler Profile',
          style: LocalLensTypography.headlineMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: LocalLensColors.deepInk,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: LocalLensColors.deepInk),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LocalLensColors.borderSubtle),
                  boxShadow: LocalLensDimensions.softCardShadow,
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
                                border: Border.all(color: LocalLensColors.terracottaPrimary.withOpacity(0.3), width: 2),
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
                                decoration: const BoxDecoration(
                                  color: LocalLensColors.terracottaPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
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
                                  color: LocalLensColors.deepInk,
                                ),
                              ),
                              Text(
                                '@elena_wanderer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: LocalLensColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: LocalLensColors.coastalSage.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, color: LocalLensColors.coastalSage, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Curator Level 4 • 18 Cities',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: LocalLensColors.coastalSage,
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
                        color: LocalLensColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('3', 'Trips Planned', isAccent: true),
                          Container(width: 1, height: 28, color: LocalLensColors.borderSubtle),
                          _buildStatItem('24', 'Saved Spots', isAccent: false),
                          Container(width: 1, height: 28, color: LocalLensColors.borderSubtle),
                          _buildStatItem('12', 'Story Reviews', isAccent: false),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LocalLensColors.borderSubtle),
                  boxShadow: LocalLensDimensions.softCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.psychology_alt_rounded, color: LocalLensColors.terracottaPrimary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'TRAVEL DNA',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: LocalLensColors.terracottaPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => context.push(AppRoutes.travelPersonality),
                          style: TextButton.styleFrom(
                            backgroundColor: LocalLensColors.surfaceContainerLow,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: Text('Fine-tune', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: LocalLensColors.deepInk)),
                          label: Icon(Icons.tune_rounded, size: 14, color: LocalLensColors.deepInk),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The Cultured Flâneur & Foodie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: LocalLensColors.deepInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You savor slow-paced explorations, lingering over terrace espresso, ancient craft, and candid sunset panoramas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: LocalLensColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Trait Progress Bars
                    _buildTraitBar('Culture & Heritage', 0.92, LocalLensColors.terracottaPrimary, Icons.museum_rounded),
                    const SizedBox(height: 8),
                    _buildTraitBar('Street Food & Artisan Cafes', 0.85, LocalLensColors.coastalSage, Icons.bakery_dining_rounded),
                    const SizedBox(height: 8),
                    _buildTraitBar('Photography & Golden Hour', 0.80, LocalLensColors.sandTertiary, Icons.photo_camera_rounded),
                    const SizedBox(height: 8),
                    _buildTraitBar('Adventure & Nightlife', 0.35, LocalLensColors.textSecondary, Icons.hiking_rounded),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: LocalLensColors.sandTertiary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: LocalLensColors.sandTertiary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 11, color: LocalLensColors.deepInk),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LocalLensColors.borderSubtle),
                  boxShadow: LocalLensDimensions.softCardShadow,
                ),
                child: Column(
                  children: [
                    _buildMenuTile(Icons.card_travel_rounded, 'My Trips', () {
                      context.push(AppRoutes.myItinerary);
                    }),
                    const Divider(height: 1, indent: 52, endIndent: 16),
                    _buildMenuTile(Icons.history_rounded, 'Travel History', () {
                      context.push(AppRoutes.travelHistory);
                    }),
                    const Divider(height: 1, indent: 52, endIndent: 16),
                    _buildMenuTile(Icons.psychology_rounded, 'Travel Personality', () {
                      context.push(AppRoutes.travelPersonality);
                    }),
                    const Divider(height: 1, indent: 52, endIndent: 16),
                    _buildMenuTile(Icons.bookmark_outline_rounded, 'Saved Places', () {
                      context.push(AppRoutes.saved);
                    }),
                    const Divider(height: 1, indent: 52, endIndent: 16),
                    _buildMenuTile(Icons.tune_rounded, 'Preferences', () {
                      context.push(AppRoutes.interestSelection);
                    }),
                    const Divider(height: 1, indent: 52, endIndent: 16),
                    _buildMenuTile(Icons.settings_outlined, 'Settings', () {
                      context.push(AppRoutes.settings);
                    }),
                    const Divider(height: 1, indent: 52, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, color: LocalLensColors.errorRed, size: 20),
                      title: const Text(
                        'Log Out',
                        style: TextStyle(color: LocalLensColors.errorRed, fontWeight: FontWeight.w700, fontSize: 14),
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
    );
  }

  Widget _buildStatItem(String val, String label, {required bool isAccent}) {
    return Column(
      children: [
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isAccent ? LocalLensColors.terracottaPrimary : LocalLensColors.deepInk,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: LocalLensColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTraitBar(String name, double percent, Color color, IconData icon) {
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
                    color: LocalLensColors.deepInk,
                  ),
                ),
              ],
            ),
            Text(
              '${(percent * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: LocalLensColors.deepInk,
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
            backgroundColor: LocalLensColors.surfaceContainerLow,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: LocalLensColors.terracottaPrimary, size: 20),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: LocalLensColors.deepInk,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: LocalLensColors.textSecondary),
      onTap: onTap,
    );
  }
}
