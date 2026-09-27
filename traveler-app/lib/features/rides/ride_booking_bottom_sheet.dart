import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/ride_model.dart';
import '../../providers/ride_provider.dart';

/// Modal Bottom Sheet helper to show ride booking popup with vehicle options & fare rates
void showRideBookingBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String destinationTitle,
  required String destinationLocation,
  double? distanceKm,
  double? dropLat,
  double? dropLng,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RideBookingSheetContent(
      ref: ref,
      destinationTitle: destinationTitle,
      destinationLocation: destinationLocation,
      distanceKm: distanceKm ?? 4.2,
      dropLat: dropLat,
      dropLng: dropLng,
    ),
  );
}

class _RideBookingSheetContent extends StatefulWidget {
  final WidgetRef ref;
  final String destinationTitle;
  final String destinationLocation;
  final double distanceKm;
  final double? dropLat;
  final double? dropLng;

  const _RideBookingSheetContent({
    required this.ref,
    required this.destinationTitle,
    required this.destinationLocation,
    required this.distanceKm,
    this.dropLat,
    this.dropLng,
  });

  @override
  State<_RideBookingSheetContent> createState() => _RideBookingSheetContentState();
}

class _RideBookingSheetContentState extends State<_RideBookingSheetContent> {
  late VehicleOption _selectedOption;
  late List<VehicleOption> _vehicleOptions;

  @override
  void initState() {
    super.initState();
    // Calculate distance-adjusted fares based on experience distance
    final factor = (widget.distanceKm / 4.0).clamp(0.8, 3.5);
    _vehicleOptions = VehicleType.values.map((vt) {
      final fare = (vt.baseFare * factor).roundToDouble();
      return VehicleOption(
        type: vt,
        name: vt.title,
        estimatedFare: fare,
        etaMinutes: (int.tryParse(vt.etaText.split(' ').first) ?? 4),
        capacity: vt.capacity,
        icon: vt.icon,
      );
    }).toList();

    _selectedOption = _vehicleOptions.firstWhere(
      (v) => v.type == VehicleType.sedan,
      orElse: () => _vehicleOptions.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: LocalLensDimensions.floatingShadow,
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle bar
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title & Destination Banner
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LocalLensColors.terracottaPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_taxi_rounded,
                  color: LocalLensColors.terracottaPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Ride to Destination',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LocalLensColors.sandTertiary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      widget.destinationTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: LocalLensColors.deepInk,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: LocalLensColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Location summary pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: LocalLensColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.near_me_rounded, color: LocalLensColors.coastalSage, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pickup: Current Location • Destination: ${widget.destinationLocation}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: LocalLensColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${widget.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: LocalLensColors.deepInk,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'SELECT RIDE TYPE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: LocalLensColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Vehicle options list
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: _vehicleOptions.map((v) {
                  final isSelected = _selectedOption.type == v.type;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedOption = v;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? LocalLensColors.terracottaPrimary.withValues(alpha: 0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? LocalLensColors.terracottaPrimary
                              : LocalLensColors.borderSubtle,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(v.icon, color: isSelected ? LocalLensColors.terracottaPrimary : LocalLensColors.deepInk, size: 28),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      v.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: LocalLensColors.deepInk,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: LocalLensColors.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        v.capacity,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: LocalLensColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pickup in ${v.etaMinutes} mins • Fast arrival',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: LocalLensColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${v.estimatedFare.toInt()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? LocalLensColors.terracottaPrimary : LocalLensColors.deepInk,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Radio<VehicleType>(
                            value: v.type,
                            groupValue: _selectedOption.type,
                            activeColor: LocalLensColors.terracottaPrimary,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedOption = v;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Confirm Book Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                final notifier = widget.ref.read(rideProvider.notifier);
                notifier.selectVehicle(_selectedOption);
                notifier.setLocations(
                  pickup: 'Current Location (Panvel)',
                  drop: '${widget.destinationTitle} (${widget.destinationLocation})',
                  dropLat: widget.dropLat ?? 19.0596,
                  dropLng: widget.dropLng ?? 72.8295,
                );
                notifier.requestRide(
                  pickup: 'Current Location (Panvel)',
                  drop: widget.destinationTitle,
                );

                Navigator.pop(context);

                // Auto navigate to Searching / Fetching Rider screen
                context.push(AppRoutes.travelerRideSearching);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking ${_selectedOption.name} to ${widget.destinationTitle}...'),
                    backgroundColor: LocalLensColors.terracottaPrimary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LocalLensColors.terracottaPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'BOOK RIDE NOW — ₹${_selectedOption.estimatedFare.toInt()}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
