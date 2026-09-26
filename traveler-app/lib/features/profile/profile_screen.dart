import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';

/// Screen 28: Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LocalLensColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar & Name
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: LocalLensColors.primaryTeal, width: 2),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/54511.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Rajiv Singh',
                style: LocalLensTypography.titleLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              GestureDetector(
                onTap: () => context.push(AppRoutes.travelPersonality),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: LocalLensColors.primaryTealSoft,
                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome, color: LocalLensColors.primaryTeal, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Curious Explorer',
                        style: LocalLensTypography.caption.copyWith(
                          color: LocalLensColors.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Stats Row (Trips, Places, Saved)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  boxShadow: LocalLensDimensions.softCardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('12', 'Trips'),
                    Container(height: 30, width: 1, color: LocalLensColors.border),
                    _buildStat('48', 'Places'),
                    Container(height: 30, width: 1, color: LocalLensColors.border),
                    _buildStat('32', 'Saved'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Menu Options
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  boxShadow: LocalLensDimensions.softCardShadow,
                ),
                child: Column(
                  children: [
                    _buildMenuItem(Icons.card_travel_rounded, 'My Trips', () {
                      context.push(AppRoutes.myItinerary);
                    }),
                    _buildDivider(),
                    _buildMenuItem(Icons.history_rounded, 'Travel History', () {
                      context.push(AppRoutes.travelHistory);
                    }),
                    _buildDivider(),
                    _buildMenuItem(Icons.psychology_rounded, 'Travel Personality', () {
                      context.push(AppRoutes.travelPersonality);
                    }),
                    _buildDivider(),
                    _buildMenuItem(Icons.bookmark_outline_rounded, 'Saved Places', () {
                      context.push(AppRoutes.saved);
                    }),
                    _buildDivider(),
                    _buildMenuItem(Icons.tune_rounded, 'Preferences', () {
                      context.push(AppRoutes.interestSelection);
                    }),
                    _buildDivider(),
                    _buildMenuItem(Icons.settings_outlined, 'Settings', () {
                      context.push(AppRoutes.settings);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: LocalLensTypography.titleLarge.copyWith(
            color: LocalLensColors.primaryTeal,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: LocalLensTypography.caption),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: LocalLensColors.primaryTeal),
      title: Text(title, style: LocalLensTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: LocalLensColors.textMuted),
      onTap: onTap,
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 54, endIndent: 16, color: LocalLensColors.border);
}
