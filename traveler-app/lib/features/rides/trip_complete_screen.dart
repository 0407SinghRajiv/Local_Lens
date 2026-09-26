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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LocalLensDimensions.paddingScreen,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Text('You\'ve arrived!', style: LocalLensTypography.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Welcome to Local Food Experience. Enjoy your authentic tasting!',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium,
              ),

              const Spacer(),

              // Arrival Celebration Illustration
              Container(
                width: 240,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  boxShadow: LocalLensDimensions.softCardShadow,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/54511.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const Spacer(),

              // Rate Driver Stars
              Text('Rate your ride with Rahul', style: LocalLensTypography.titleMedium),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  return IconButton(
                    icon: Icon(
                      starNumber <= _selectedRating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 34,
                    ),
                    onPressed: () {
                      setState(() => _selectedRating = starNumber);
                    },
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Continue Trip Button (Orange)
              LocalLensPrimaryButton(
                text: 'Continue Trip',
                isOrange: true,
                onPressed: () {
                  context.push(AppRoutes.adventureComplete);
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
