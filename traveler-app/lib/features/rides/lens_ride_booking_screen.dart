import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 22: Lens Ride Booking Screen
class LensRideBookingScreen extends StatelessWidget {
  const LensRideBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How are you\ngetting there?', style: LocalLensTypography.displayMedium),
              const SizedBox(height: 8),

              // Lens Ride Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: LocalLensColors.primaryTealSoft,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_taxi_rounded, color: LocalLensColors.primaryTeal, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lens Ride', style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text('Local verified drivers for your itinerary', style: LocalLensTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Location Inputs Card (Pickup & Drop)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                  border: Border.all(color: LocalLensColors.border),
                  boxShadow: LocalLensDimensions.softCardShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: LocalLensColors.primaryTeal, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pickup', style: LocalLensTypography.caption),
                            Text('Your Current Location', style: LocalLensTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, color: LocalLensColors.accentOrange, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Drop-off', style: LocalLensTypography.caption),
                            Text('Local Food Experience', style: LocalLensTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Price & ETA summary
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: LocalLensColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated Fare', style: LocalLensTypography.caption),
                        Text('₹120', style: LocalLensTypography.titleLarge.copyWith(color: LocalLensColors.primaryTeal, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: LocalLensColors.textMuted),
                        const SizedBox(width: 4),
                        Text('8 min arrival', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Book Button (Orange)
              LocalLensPrimaryButton(
                text: 'Book Lens Ride',
                isOrange: true,
                onPressed: () {
                  context.push(AppRoutes.rideSearching);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
