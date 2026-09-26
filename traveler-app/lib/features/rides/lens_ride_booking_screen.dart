import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';

/// Screen: Lens Ride Booking (Stitch UI)
class LensRideBookingScreen extends ConsumerStatefulWidget {
  const LensRideBookingScreen({super.key});

  @override
  ConsumerState<LensRideBookingScreen> createState() => _LensRideBookingScreenState();
}

class _LensRideBookingScreenState extends ConsumerState<LensRideBookingScreen> {
  int _selectedVehicleIndex = 0;

  final List<Map<String, dynamic>> _vehicleOptions = [
    {
      'title': 'Lens Auto',
      'subtitle': 'Fastest for narrow heritage lanes',
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
      'subtitle': 'Quick solo heritage commute',
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
      backgroundColor: LocalLensColors.background,
      body: Stack(
        children: [
          // Top Map Header Section
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/54511.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                color: Colors.black.withOpacity(0.12),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, color: LocalLensColors.deepInk),
                            onPressed: () => context.pop(),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: LocalLensDimensions.softCardShadow,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.near_me_rounded, color: LocalLensColors.terracottaPrimary, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Amer Fort → Hawa Mahal',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: LocalLensColors.deepInk,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.my_location_rounded, color: LocalLensColors.deepInk),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Tactile Ride-Booking Sheet
          Positioned.fill(
            top: 260,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: LocalLensDimensions.floatingShadow,
              ),
              child: Column(
                children: [
                  // Sheet Handle
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: LocalLensColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Sheet Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.travel_explore_rounded, color: LocalLensColors.terracottaPrimary, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Lens Ride',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: LocalLensColors.deepInk,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: LocalLensColors.coastalSage.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Connected',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: LocalLensColors.coastalSage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Heritage corridor transit synced with your schedule',
                              style: TextStyle(
                                fontSize: 11,
                                color: LocalLensColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Walking Guidance Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LocalLensColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: LocalLensColors.terracottaPrimary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.directions_walk_rounded, color: LocalLensColors.terracottaPrimary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Amer Fort Parking Lot A',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: LocalLensColors.deepInk,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '• 2 min walk',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: LocalLensColors.coastalSage,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Walk past Elephant Stand Gate towards Pillar 4',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: LocalLensColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'Change',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: LocalLensColors.terracottaPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Transits List Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Available Transits',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: LocalLensColors.deepInk,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Vehicle Selector Cards
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: LocalLensDimensions.paddingScreen),
                      itemCount: _vehicleOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final option = _vehicleOptions[index];
                        final isSelected = _selectedVehicleIndex == index;

                        return GestureDetector(
                          onTap: () => setState(() => _selectedVehicleIndex = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LocalLensColors.terracottaPrimary.withOpacity(0.04)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? LocalLensColors.terracottaPrimary
                                    : LocalLensColors.borderSubtle,
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? LocalLensColors.terracottaPrimary
                                        : LocalLensColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    option['icon'] as IconData,
                                    color: isSelected ? Colors.white : LocalLensColors.deepInk,
                                    size: 24,
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
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: LocalLensColors.deepInk,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '• ${option['eta']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: LocalLensColors.terracottaPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option['subtitle'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: LocalLensColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '₹${option['price']}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isSelected
                                        ? LocalLensColors.terracottaPrimary
                                        : LocalLensColors.deepInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action Section
                  Padding(
                    padding: const EdgeInsets.all(LocalLensDimensions.paddingScreen),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: LocalLensColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Fare',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: LocalLensColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '₹${selectedOption['price']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: LocalLensColors.terracottaPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 14, color: LocalLensColors.coastalSage),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${selectedOption['eta']} arrival',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: LocalLensColors.deepInk,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final vehicleType = selectedOption['type'] as VehicleType;
                              final option = VehicleOption(
                                type: vehicleType,
                                name: selectedOption['title'] as String,
                                estimatedFare: (selectedOption['price'] as num).toDouble(),
                                etaMinutes: 4,
                                capacity: '4 seats',
                                icon: selectedOption['icon'] as IconData,
                              );
                              ref.read(rideProvider.notifier).selectVehicle(option);
                              ref.read(rideProvider.notifier).requestRide(
                                pickup: 'Amer Fort Parking Lot A',
                                drop: 'Hawa Mahal, Pink City',
                              );
                              context.push(AppRoutes.rideSearching);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: LocalLensColors.terracottaPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Book ${selectedOption['title']}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
