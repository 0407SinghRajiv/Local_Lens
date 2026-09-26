import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/auth_provider.dart';

/// Screen 30: Settings Screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider);
    final emailDisplay = userProfile?.email.isNotEmpty == true
        ? userProfile!.email
        : 'rajiv@example.com';

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Settings', style: LocalLensTypography.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 16,
          ),
          children: [
            _buildSectionHeader('Preferences'),
            _buildSettingTile(Icons.person_outline_rounded, 'Account Profile', emailDisplay),
            _buildSettingTile(Icons.notifications_none_rounded, 'Push Notifications', 'Enabled'),
            _buildSettingTile(Icons.location_on_outlined, 'Location Services', 'Always On'),
            _buildSettingTile(Icons.history_rounded, 'Travel History', 'Syncing active'),

            const SizedBox(height: 16),
            _buildSectionHeader('System & App'),
            _buildSettingTile(Icons.lock_outline_rounded, 'Privacy & Permissions', null),
            _buildSettingTile(Icons.accessibility_new_rounded, 'Accessibility', null),
            _buildSettingTile(Icons.language_rounded, 'Language', 'English (US)'),
            _buildSettingTile(Icons.currency_rupee_rounded, 'Currency', 'INR (₹)'),
            _buildSettingTile(Icons.help_outline_rounded, 'Help & Support', null),
            _buildSettingTile(Icons.palette_outlined, 'Design System & Component Library', null, onTap: () {
              context.push(AppRoutes.designSystem);
            }),

            const SizedBox(height: 24),
            // Logout
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                boxShadow: LocalLensDimensions.softCardShadow,
              ),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded, color: LocalLensColors.errorRed),
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: LocalLensColors.errorRed, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await ref.read(authNotifierProvider).signOut();
                  // Router automatically reacts to AuthStatus.unauthenticated and redirects to /login / /welcome
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: LocalLensTypography.caption.copyWith(
          letterSpacing: 0.8,
          fontWeight: FontWeight.bold,
          color: LocalLensColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String? subtitle, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: ListTile(
        leading: Icon(icon, color: LocalLensColors.primaryTeal),
        title: Text(title, style: LocalLensTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: LocalLensTypography.caption) : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: LocalLensColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
