import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 25: Ride Arrived & Feedback Screen
class TripCompleteScreen extends StatefulWidget {
  const TripCompleteScreen({super.key});

  @override
  State<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends State<TripCompleteScreen> {
  int _selectedRating = 5;
  int _selectedTip = 20;

  final List<int> _tipOptions = [0, 20, 50, 100];
  final List<String> _compliments = ['Great music', 'Clean car', 'Smooth driving', 'Friendly guide'];
  final Set<String> _selectedCompliments = {'Smooth driving', 'Clean car'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('You\'ve arrived!', style: LocalLensTypography.displayLarge),
              const SizedBox(height: 6),
              Text(
                'Welcome to Local Food Experience. Enjoy your authentic tasting!',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Arrival Celebration Illustration
              Container(
                width: 220,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  boxShadow: LocalLensDimensions.softCardShadow,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/illustrations/ride_arrived.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Rate Driver Stars
              Text('Rate your ride with Rahul', style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  return IconButton(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      starNumber <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() => _selectedRating = starNumber);
                    },
                  );
                }),
              ),

              const SizedBox(height: 10),

              // Compliment tags
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: _compliments.map((tag) {
                  final isSelected = _selectedCompliments.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCompliments.add(tag);
                        } else {
                          _selectedCompliments.remove(tag);
                        }
                      });
                    },
                    selectedColor: LocalLensColors.primaryTealSoft,
                    checkmarkColor: LocalLensColors.primaryTeal,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 10),

              // Tip Driver Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Add tip: ', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ..._tipOptions.map((tip) {
                    final isSelected = _selectedTip == tip;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(tip == 0 ? 'No tip' : '₹$tip'),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedTip = tip),
                        selectedColor: LocalLensColors.accentOrange,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    );
                  }),
                ],
              ),

              const Spacer(),

              // Continue Trip Button (Orange)
              LocalLensPrimaryButton(
                text: 'Continue Trip',
                isOrange: true,
                onPressed: () {
                  context.push(AppRoutes.adventureComplete);
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
