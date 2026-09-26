import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 7: Budget Preference Screen
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  RangeValues _currentRangeValues = const RangeValues(2500, 3500);

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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'What feels right\nfor your trip?',
                  style: LocalLensTypography.displayMedium,
                ),
              ),
              const SizedBox(height: 20),

              // Budget Badge pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: LocalLensColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                  border: Border.all(color: LocalLensColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${_currentRangeValues.start.toInt()} - ₹${_currentRangeValues.end.toInt()}',
                      style: LocalLensTypography.titleMedium.copyWith(
                        color: LocalLensColors.primaryTeal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• per person • moderate',
                      style: LocalLensTypography.caption.copyWith(
                        color: LocalLensColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Slider
              RangeSlider(
                values: _currentRangeValues,
                min: 500,
                max: 10000,
                divisions: 95,
                activeColor: LocalLensColors.primaryTeal,
                inactiveColor: LocalLensColors.border,
                labels: RangeLabels(
                  '₹${_currentRangeValues.start.toInt()}',
                  '₹${_currentRangeValues.end.toInt()}',
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    _currentRangeValues = values;
                  });
                },
              ),

              const Spacer(),

              // Scenic Illustration Card
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
                  boxShadow: LocalLensDimensions.softCardShadow,
                  image: const DecorationImage(
                    image: AssetImage('assets/images/54506.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const Spacer(),

              // Action Buttons
              LocalLensPrimaryButton(
                text: 'Import Google Travel History',
                isOrange: false,
                icon: Icons.history_rounded,
                onPressed: () {
                  context.push(AppRoutes.travelHistory);
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  context.push(AppRoutes.aiPersonalization);
                },
                child: Text(
                  'Skip for now',
                  style: LocalLensTypography.button.copyWith(
                    color: LocalLensColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
