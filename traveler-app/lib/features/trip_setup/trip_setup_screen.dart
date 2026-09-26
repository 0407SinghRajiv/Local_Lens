import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 4: Trip Setup Screen
class TripSetupScreen extends StatefulWidget {
  const TripSetupScreen({super.key});

  @override
  State<TripSetupScreen> createState() => _TripSetupScreenState();
}

class _TripSetupScreenState extends State<TripSetupScreen> {
  String _selectedCity = 'Panvel';
  String _selectedDuration = '3 hrs';

  final List<String> _popularCities = [
    'Panvel',
    'Goa',
    'Mumbai',
    'Bengaluru',
    'Jaipur',
  ];

  final List<String> _durations = [
    '1 hr',
    '3 hrs',
    'Half day',
    'Full day',
    'Multiple days',
  ];

  DateTime _selectedDate = DateTime(2025, 10, 12);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: LocalLensColors.primaryTeal,
              onPrimary: Colors.white,
              onSurface: LocalLensColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where are you heading?',
                style: LocalLensTypography.displayMedium,
              ),
              const SizedBox(height: 16),

              // Destination Search Field
              Container(
                decoration: BoxDecoration(
                  color: LocalLensColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search destination (e.g. Panvel, Goa)',
                    hintStyle: LocalLensTypography.bodyMedium,
                    prefixIcon: const Icon(Icons.search_rounded, color: LocalLensColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Popular Cities Chips
              Text('Popular', style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _popularCities.map((city) {
                  final isSelected = _selectedCity == city;
                  return ChoiceChip(
                    label: Text(city),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCity = city),
                    selectedColor: LocalLensColors.primaryTeal,
                    backgroundColor: LocalLensColors.surfaceSecondary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // When are you traveling? Date Picker
              Text('When are you traveling?', style: LocalLensTypography.titleMedium),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                    border: Border.all(color: LocalLensColors.border),
                    boxShadow: LocalLensDimensions.softCardShadow,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: LocalLensColors.primaryTeal),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_selectedDate),
                        style: LocalLensTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: LocalLensColors.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // How much time do you have?
              Text('How much time do you have?', style: LocalLensTypography.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _durations.map((duration) {
                  final isSelected = _selectedDuration == duration;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDuration = duration),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? LocalLensColors.primaryTeal : Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                        border: Border.all(
                          color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
                        ),
                      ),
                      child: Text(
                        duration,
                        style: TextStyle(
                          color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // Next Button (Teal)
              LocalLensPrimaryButton(
                text: 'Next',
                isOrange: false,
                onPressed: () {
                  context.push(AppRoutes.travelGroup);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
