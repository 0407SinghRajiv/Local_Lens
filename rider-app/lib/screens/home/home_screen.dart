import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../models/ride.dart';
import '../../widgets/mock_map_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Listen for pending ride requests to navigate
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForNavigation();
    });
  }

  void _listenForNavigation() {
    final state = context.read<AppState>();
    state.addListener(() {
      if (!mounted) return;

      // Navigate to ride request when pending
      if (state.hasPendingRequest &&
          state.pendingRequest!.status == RideStatus.searching) {
        Navigator.pushNamed(context, '/ride-request');
      }

      // Navigate to pickup when ride accepted
      if (state.hasActiveRide) {
        final ride = state.activeRide!;
        switch (ride.status) {
          case RideStatus.accepted:
            Navigator.pushNamed(context, '/pickup');
            break;
          case RideStatus.arrived:
            Navigator.pushNamed(context, '/arrived');
            break;
          case RideStatus.started:
            Navigator.pushNamed(context, '/active-ride');
            break;
          case RideStatus.completed:
            Navigator.pushNamed(context, '/completed');
            break;
          default:
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final driver = state.driver;
        if (driver == null) return const SizedBox();

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ─── Top Bar ───
                  _buildTopBar(state),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // ─── Map ───
                        MockMapWidget(
                          driverLat: state.currentLocation?.latitude ?? 19.076,
                          driverLng: state.currentLocation?.longitude ?? 72.877,
                          height: 220,
                        ),
                        const SizedBox(height: 16),

                        // ─── Status Card ───
                        _buildStatusCard(state),
                        const SizedBox(height: 16),

                        // ─── Stats Row ───
                        _buildStatsRow(state),
                        const SizedBox(height: 16),

                        // ─── Online/Offline Button ───
                        _buildToggleButton(state),
                        const SizedBox(height: 16),

                        // ─── TEST RIDE REQUEST (Dev) ───
                        if (state.isOnline) ...[
                          _buildTestRideButton(state),
                          const SizedBox(height: 16),
                        ],

                        // ─── Driver Info Card ───
                        _buildDriverInfoCard(state),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(AppState state) {
    final driver = state.driver!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
              child: Text(
                driver.name.substring(0, 1),
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${driver.name.split(' ').first}!',
                  style: AppTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.isOnline
                            ? AppTheme.success
                            : AppTheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isOnline ? 'Online' : 'Offline',
                      style: AppTheme.bodySmall.copyWith(
                        color: state.isOnline
                            ? AppTheme.success
                            : AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Rating badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: AppTheme.tertiary, size: 16),
                const SizedBox(width: 4),
                Text(
                  driver.rating.toStringAsFixed(1),
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.tertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Notification bell
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            color: AppTheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AppState state) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: state.isOnline
            ? const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
              )
            : const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (state.isOnline ? AppTheme.primary : AppTheme.secondary)
                .withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.isOnline
                    ? Icons.wifi_rounded
                    : Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                state.isOnline ? 'You\'re Online' : 'You\'re Offline',
                style: AppTheme.titleLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            state.isOnline
                ? 'Searching for ride requests near you...'
                : 'Go online to start receiving ride requests',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          if (state.isOnline) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPulsingDot(),
                const SizedBox(width: 8),
                Text(
                  'Listening for rides',
                  style: AppTheme.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5 + value * 0.5),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildStatsRow(AppState state) {
    final driver = state.driver!;
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.currency_rupee_rounded,
          label: 'Today\'s Earnings',
          value: '₹${driver.todayEarnings.toStringAsFixed(0)}',
          color: AppTheme.primary,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.route_rounded,
          label: 'Today\'s Rides',
          value: '${driver.todayRides}',
          color: AppTheme.secondary,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: AppTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(AppState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: state.isLoading
            ? null
            : () {
                if (state.isOnline) {
                  state.goOffline();
                } else {
                  state.goOnline();
                }
              },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              state.isOnline ? AppTheme.error : AppTheme.primary,
          shape: const StadiumBorder(),
        ),
        child: state.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state.isOnline
                        ? Icons.power_settings_new_rounded
                        : Icons.power_settings_new_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.isOnline ? 'GO OFFLINE' : 'GO ONLINE',
                    style: AppTheme.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTestRideButton(AppState state) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => state.triggerTestRide(),
        icon: const Icon(Icons.bug_report_rounded, size: 18),
        label: const Text('TEST RIDE REQUEST'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.tertiary,
          side: BorderSide(
            color: AppTheme.tertiary.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard(AppState state) {
    final driver = state.driver!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle Information', style: AppTheme.titleMedium),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.directions_car, 'Vehicle', driver.vehicleModel),
          _buildInfoRow(Icons.pin, 'Number', driver.vehicleNumber),
          _buildInfoRow(Icons.category, 'Type', driver.vehicleType),
          const Divider(height: 24),
          _buildInfoRow(
              Icons.location_on, 'Location', 'Andheri West, Mumbai'),
          _buildInfoRow(Icons.route, 'Total Rides', '${driver.totalRides}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
