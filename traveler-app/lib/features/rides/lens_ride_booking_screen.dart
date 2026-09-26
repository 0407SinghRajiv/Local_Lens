import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 22: Lens Ride Booking Screen
class LensRideBookingScreen extends ConsumerStatefulWidget {
  const LensRideBookingScreen({super.key});

  @override
  ConsumerState<LensRideBookingScreen> createState() => _LensRideBookingScreenState();
}

class _LensRideBookingScreenState extends ConsumerState<LensRideBookingScreen> {
  int _selectedVehicleIndex = 1;

  final List<Map<String, dynamic>> _vehicleOptions = [
    {
      'title': 'Lens Auto',
      'subtitle': 'Fastest for narrow streets',
      'price': 60,
      'eta': '4 min',
      'icon': Icons.electric_rickshaw_rounded,
      'type': VehicleType.auto,
    },
    {
      'title': 'Lens Sedan',
      'subtitle': 'AC sedan with top rated driver',
      'price': 120,
      'eta': '8 min',
      'icon': Icons.directions_car_rounded,
      'type': VehicleType.sedan,
    },
    {
      'title': 'Lens SUV XL',
      'subtitle': 'Spacious for groups & luggage',
      'price': 220,
      'eta': '10 min',
      'icon': Icons.airport_shuttle_rounded,
      'type': VehicleType.suv,
    },
    {
      'title': 'Lens Moto',
      'subtitle': 'Quick solo commute',
      'price': 35,
      'eta': '3 min',
      'icon': Icons.two_wheeler_rounded,
      'type': VehicleType.bike,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final selectedOption = _vehicleOptions[_selectedVehicleIndex];

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
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LocalLensColors.primaryTealSoft,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: LocalLensColors.primaryTeal,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lens Ride', style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                          Text('Local verified drivers synced with your itinerary', style: LocalLensTypography.caption),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Location Inputs Card (Pickup & Drop)
              Container(
                padding: const EdgeInsets.all(14),
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
                        const Icon(Icons.my_location_rounded, color: LocalLensColors.primaryTeal, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pickup', style: LocalLensTypography.caption.copyWith(fontSize: 10)),
                              Text('Current Location • Panvel Station', style: LocalLensTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Divider(height: 1),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.place_rounded, color: LocalLensColors.accentOrange, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Drop-off', style: LocalLensTypography.caption.copyWith(fontSize: 10)),
                              Text('Local Food Experience (Stop 2)', style: LocalLensTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              Text('Choose Vehicle', style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // Selectable Vehicle Options
              Expanded(
                child: ListView.separated(
                  itemCount: _vehicleOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final option = _vehicleOptions[index];
                    final isSelected = _selectedVehicleIndex == index;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedVehicleIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? LocalLensColors.primaryTealSoft : Colors.white,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                          border: Border.all(
                            color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
                            width: isSelected ? 1.8 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.surfaceSecondary,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                option['icon'] as IconData,
                                color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        option['title'] as String,
                                        style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• ${option['eta']}',
                                        style: LocalLensTypography.caption.copyWith(color: LocalLensColors.primaryTeal, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    option['subtitle'] as String,
                                    style: LocalLensTypography.caption.copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${option['price']}',
                              style: LocalLensTypography.titleMedium.copyWith(
                                color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Price & ETA summary bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        Text('Total to pay', style: LocalLensTypography.caption),
                        Text(
                          '₹${selectedOption['price']}',
                          style: LocalLensTypography.titleLarge.copyWith(
                            color: LocalLensColors.primaryTeal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: LocalLensColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${selectedOption['eta']} arrival', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Book Button (Orange)
              LocalLensPrimaryButton(
                text: 'Book ${selectedOption['title']}',
                isOrange: true,
                onPressed: () {
                  final vehicleType = selectedOption['type'] as VehicleType;
                  final option = VehicleOption(
                    type: vehicleType,
                    name: selectedOption['title'] as String,
                    estimatedFare: (selectedOption['price'] as num).toDouble(),
                    etaMinutes: 5,
                    capacity: '4 seats',
                    icon: selectedOption['icon'] as IconData,
                  );
                  ref.read(rideProvider.notifier).selectVehicle(option);
                  ref.read(rideProvider.notifier).requestRide(
                    pickup: 'Panvel Station, Mumbai',
                    drop: 'Local Food Experience, Bandra',
                  );
                  context.push(AppRoutes.rideSearching);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
