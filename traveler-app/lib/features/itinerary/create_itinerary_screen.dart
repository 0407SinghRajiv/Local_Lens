import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/itinerary_provider.dart';
import '../../services/location_service.dart';
import '../../services/geocoding_service.dart';
import '../../widgets/common/locallens_components.dart';

/// Screen 1 — Create Itinerary & Recommendation Discovery
class CreateItineraryScreen extends ConsumerStatefulWidget {
  const CreateItineraryScreen({super.key});

  @override
  ConsumerState<CreateItineraryScreen> createState() => _CreateItineraryScreenState();
}

class _CreateItineraryScreenState extends ConsumerState<CreateItineraryScreen> {
  late TextEditingController _destinationController;
  late TextEditingController _timeController;
  late TextEditingController _budgetController;
  late TextEditingController _preferencesController;

  late DateTime _selectedTripDate;
  late TimeOfDay _selectedStartTime;

  bool _isResolvingLocation = false;
  bool _isLoadingRecommendations = false;
  bool _isLoadingWeather = false;
  String? _locationError;

  // Live/Forecast Weather Info for Selected Date & Destination
  String _weatherTemp = '28°C';
  String _weatherCondition = 'Clear & Sunny';
  String _weatherRainChance = '10%';
  String _weatherAdvice = 'Ideal outdoor sightseeing conditions. Great for walking tours & open viewpoints.';
  IconData _weatherIcon = Icons.wb_sunny_rounded;
  Color _weatherColor = const Color(0xFFE65100);
  Color _weatherBgColor = const Color(0xFFFFF3E0);

  final List<String> _interestOptions = [
    'Food',
    'Culture',
    'Adventure',
    'Nature',
    'Heritage',
    'Beach',
    'Shopping',
    'Nightlife',
    'Photography',
    'Wellness',
    'Hidden Gems',
    'Local Experiences',
  ];

  final List<Map<String, dynamic>> _groupTypes = [
    {'title': 'Solo', 'subtitle': '1 traveler', 'count': 1, 'icon': Icons.person_rounded},
    {'title': 'Couple', 'subtitle': '2 travelers', 'count': 2, 'icon': Icons.favorite_rounded},
    {'title': 'Friends', 'subtitle': '3-5 travelers', 'count': 4, 'icon': Icons.group_rounded},
    {'title': 'Family', 'subtitle': 'With family', 'count': 4, 'icon': Icons.family_restroom_rounded},
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(itineraryProvider);
    _destinationController = TextEditingController(text: state.destination);
    _timeController = TextEditingController(text: state.availableTime);
    _budgetController = TextEditingController(
        text: state.totalBudgetInr > 0 ? state.totalBudgetInr.toInt().toString() : '3000');
    _preferencesController = TextEditingController(text: state.preferences);

    // Keep provider in sync as user types
    _destinationController.addListener(() {
      final text = _destinationController.text;
      if (text.isNotEmpty) {
        ref.read(itineraryProvider.notifier).setDestination(text);
      }
    });
    _budgetController.addListener(() {
      final budget = double.tryParse(_budgetController.text);
      if (budget != null && budget > 0) {
        ref.read(itineraryProvider.notifier).setBudget(budget);
      }
    });
    _preferencesController.addListener(() {
      ref.read(itineraryProvider.notifier).setPreferences(_preferencesController.text);
    });

    final now = DateTime.now();
    if (state.tripDate.isNotEmpty) {
      try {
        _selectedTripDate = DateTime.parse(state.tripDate);
      } catch (_) {
        _selectedTripDate = now;
      }
    } else {
      _selectedTripDate = now;
    }

    _selectedStartTime = const TimeOfDay(hour: 10, minute: 30);

    // Initial weather forecast fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncDateAndFetchWeather();
    });
  }

  void _syncDateAndFetchWeather() {
    final formattedDate =
        '${_selectedTripDate.year}-${_selectedTripDate.month.toString().padLeft(2, '0')}-${_selectedTripDate.day.toString().padLeft(2, '0')}';
    ref.read(itineraryProvider.notifier).setTripDate(formattedDate);
    _fetchWeatherForecastForTrip();
  }

  Future<void> _fetchWeatherForecastForTrip() async {
    setState(() {
      _isLoadingWeather = true;
    });

    final state = ref.read(itineraryProvider);
    final targetDest = state.locationMode == LocationMode.exact
        ? state.displayAddress
        : (state.destination.isNotEmpty ? state.destination : 'Mumbai');

    final coords = GeocodingService.resolveCoordinatesForCity(targetDest);
    double lat = state.locationMode == LocationMode.exact ? (state.latitude ?? coords.latitude) : coords.latitude;
    double lon = state.locationMode == LocationMode.exact ? (state.longitude ?? coords.longitude) : coords.longitude;
    final formattedDate =
        '${_selectedTripDate.year}-${_selectedTripDate.month.toString().padLeft(2, '0')}-${_selectedTripDate.day.toString().padLeft(2, '0')}';

    debugPrint('[WEATHER REQUEST] City: $targetDest, Lat: $lat, Lng: $lon, Date: $formattedDate');

    const apiKey = '9fb8d155eeb443116f6d35e81215a121';

    try {
      final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final main = data['main'];
        final weatherList = data['weather'] as List?;

        if (main != null && weatherList != null && weatherList.isNotEmpty) {
          final temp = (main['temp'] as num).round();
          final item = weatherList.first;
          final desc = (item['description'] as String?) ?? 'Clear Sky';
          final descLower = desc.toLowerCase();

          IconData icon = Icons.wb_sunny_rounded;
          Color col = const Color(0xFFE65100);
          Color bg = const Color(0xFFFFF3E0);
          String advice = 'Sunny conditions. Perfect for outdoor sightseeing & beaches.';
          String rainChance = '5%';

          if (descLower.contains('rain') || descLower.contains('drizzle')) {
            icon = Icons.water_drop_rounded;
            col = const Color(0xFF0288D1);
            bg = const Color(0xFFE1F5FE);
            advice = 'Rain expected. Indoor museums, food walks & covered stops prioritized.';
            rainChance = '75%';
          } else if (descLower.contains('thunder') || descLower.contains('storm')) {
            icon = Icons.thunderstorm_rounded;
            col = const Color(0xFF4A148C);
            bg = const Color(0xFFEDE7F6);
            advice = 'Stormy weather. Safe sheltered cultural stops & cozy dining recommended.';
            rainChance = '90%';
          } else if (descLower.contains('cloud')) {
            icon = Icons.cloud_rounded;
            col = const Color(0xFF37474F);
            bg = const Color(0xFFECEFF1);
            advice = 'Pleasant cloud cover. Comfortable for both indoor & outdoor exploration.';
            rainChance = '25%';
          }

          if (mounted) {
            setState(() {
              _weatherTemp = '$temp°C';
              _weatherCondition = desc.split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' ');
              _weatherRainChance = rainChance;
              _weatherAdvice = advice;
              _weatherIcon = icon;
              _weatherColor = col;
              _weatherBgColor = bg;
              _isLoadingWeather = false;
            });
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _pickTripDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTripDate.isBefore(now) ? now : _selectedTripDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
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
        _selectedTripDate = picked;
      });
      _syncDateAndFetchWeather();
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
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
        _selectedStartTime = picked;
      });
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final formattedTime = '$hour:$minute $period';
      ref.read(itineraryProvider.notifier).setTripStartTime(formattedTime);
    }
  }

  String _formatDisplayDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];
    return '$dayName, ${date.day} $monthName ${date.year}';
>>>>>>> 25fcca8 (fix(location): enforce destination as single source of truth for weather, recommendations, itinerary and map)
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _timeController.dispose();
    _budgetController.dispose();
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _handleExactLocationSelection() async {
    setState(() {
      _isResolvingLocation = true;
      _locationError = null;
    });

    final granted = await LocationService.requestLocationPermission(context);
    if (!mounted) return;

    if (granted) {
      final loc = await LocationService.getCurrentResolvedLocation();
      ref.read(itineraryProvider.notifier).setExactLocation(
            loc.latitude,
            loc.longitude,
            loc.displayAddress,
          );
      setState(() {
        _isResolvingLocation = false;
        _locationError = null;
      });
    } else {
      setState(() {
        _isResolvingLocation = false;
        _locationError = 'Location access not enabled. You can enter destination manually below.';
      });
    }
  }

  Future<void> _startRecommendationFlow() async {
    // Clear any previous errors before starting
    ref.read(itineraryProvider.notifier).clearError();

    setState(() {
      _isLoadingRecommendations = true;
    });

    final notifier = ref.read(itineraryProvider.notifier);
    final recs = await notifier.fetchRecommendations();

    if (!mounted) return;

    setState(() {
      _isLoadingRecommendations = false;
    });

    // Check for provider-level error message
    final providerState = ref.read(itineraryProvider);
    if (providerState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(providerState.error!),
          backgroundColor: LocalLensColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (recs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No experiences found for this location. Please try other filters.'),
          backgroundColor: LocalLensColors.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.push(AppRoutes.recommendationSwipe);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryProvider);
    final notifier = ref.read(itineraryProvider.notifier);

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.travelerHome);
            }
          },
        ),
        title: Text(
          'Plan Itinerary',
          style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: LocalLensDimensions.paddingScreen,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Subtitle Header
                    Text(
                      'Plan your perfect day',
                      style: LocalLensTypography.displayMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tell us a little about your trip and our ML recommender will find top local experiences.',
                      style: LocalLensTypography.bodyMedium.copyWith(
                        color: LocalLensColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: LOCATION
                    _buildSectionHeader(
                      icon: Icons.place_rounded,
                      title: 'Where are you exploring?',
                    ),
                    const SizedBox(height: 12),
                    _buildLocationSelector(state, notifier),
                    if (_locationError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: LocalLensColors.errorRedSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: LocalLensColors.errorRed, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _locationError!,
                                style: LocalLensTypography.caption.copyWith(color: LocalLensColors.errorRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // SECTION 2: TRIP DATE, TIME & WEATHER FORECAST
                    _buildSectionHeader(
                      icon: Icons.calendar_month_rounded,
                      title: 'When are you traveling & Weather',
                    ),
                    const SizedBox(height: 12),
                    _buildDateAndWeatherSelector(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 3: AVAILABLE TIME
                    _buildSectionHeader(
                      icon: Icons.schedule_rounded,
                      title: 'How much time do you have?',
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSelector(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 4: TOTAL BUDGET
                    _buildSectionHeader(
                      icon: Icons.currency_rupee_rounded,
                      title: 'What\'s your total budget?',
                    ),
                    const SizedBox(height: 12),
                    _buildBudgetField(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 5: TRAVELERS & NUMBER OF PERSONS
                    _buildSectionHeader(
                      icon: Icons.groups_rounded,
                      title: 'Who\'s traveling & How many persons?',
                    ),
                    const SizedBox(height: 12),
                    _buildGroupSelector(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 5: HOW MANY EXPERIENCES
                    _buildSectionHeader(
                      icon: Icons.auto_awesome_rounded,
                      title: 'How many experiences do you want?',
                    ),
                    const SizedBox(height: 12),
                    _buildExperienceCountSelector(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 6: INTERESTS
                    _buildSectionHeader(
                      icon: Icons.interests_rounded,
                      title: 'What interests you?',
                    ),
                    const SizedBox(height: 12),
                    _buildInterestsGrid(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 7: OPTIONAL PREFERENCES
                    _buildSectionHeader(
                      icon: Icons.tune_rounded,
                      title: 'Anything else?',
                      isOptional: true,
                    ),
                    const SizedBox(height: 12),
                    _buildPreferencesField(state, notifier),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Bar with Find Recommendations Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: LocalLensDimensions.floatingShadow,
                border: const Border(top: BorderSide(color: LocalLensColors.borderLight)),
              ),
              child: LocalLensPrimaryButton(
                text: _isLoadingRecommendations ? 'Finding experiences for you...' : 'Find Experiences & Build Plan',
                isOrange: true,
                icon: Icons.auto_awesome_rounded,
                onPressed: (state.isValid && !_isLoadingRecommendations)
                    ? () {
                        _startRecommendationFlow();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    bool isOptional = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: LocalLensColors.primaryTealSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: LocalLensColors.primaryTeal, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        if (isOptional) ...[
          const SizedBox(width: 6),
          Text(
            '(Optional)',
            style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSelector(CreateItineraryState state, ItineraryNotifier notifier) {
    final isExact = state.locationMode == LocationMode.exact;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        children: [
          // Option A: Use my exact location
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              notifier.setLocationMode(LocationMode.exact);
              notifier.setWeatherCondition('Live');
              _handleExactLocationSelection();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isExact ? LocalLensColors.primaryTealSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExact ? LocalLensColors.primaryTeal : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isExact ? LocalLensColors.primaryTeal : LocalLensColors.surfaceSecondary,
                      shape: BoxShape.circle,
                    ),
                    child: _isResolvingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.my_location_rounded,
                            color: isExact ? Colors.white : LocalLensColors.primaryTeal,
                            size: 18,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Use my exact location',
                          style: LocalLensTypography.titleSmall.copyWith(
                            color: isExact ? LocalLensColors.primaryTealDark : LocalLensColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isExact && state.displayAddress.isNotEmpty)
                          Text(
                            state.displayAddress,
                            style: LocalLensTypography.caption.copyWith(
                              color: LocalLensColors.primaryTeal,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          Text(
                            'Discover experiences right around where you are',
                            style: LocalLensTypography.caption,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isExact ? LocalLensColors.primaryTeal : LocalLensColors.border,
                        width: 2,
                      ),
                    ),
                    child: isExact
                        ? Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: LocalLensColors.primaryTeal,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('OR', style: TextStyle(fontSize: 11, color: LocalLensColors.textMuted, fontWeight: FontWeight.bold)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),

          // Option B: Choose Destination
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              notifier.setLocationMode(LocationMode.destination);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: !isExact ? LocalLensColors.primaryTealSoft.withValues(alpha: 0.5) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isExact ? LocalLensColors.primaryTeal : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: !isExact ? LocalLensColors.accentOrange : LocalLensColors.surfaceSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          color: !isExact ? Colors.white : LocalLensColors.textSecondary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Choose destination',
                          style: LocalLensTypography.titleSmall.copyWith(
                            color: !isExact ? LocalLensColors.textPrimary : LocalLensColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: !isExact ? LocalLensColors.primaryTeal : LocalLensColors.border,
                            width: 2,
                          ),
                        ),
                        child: !isExact
                            ? Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: LocalLensColors.primaryTeal,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _destinationController,
                    onChanged: (val) {
                      notifier.setDestination(val);
                      _syncDateAndFetchWeather();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search destination (e.g. Mumbai, Delhi, Jaipur)',
                      hintStyle: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textMuted),
                      prefixIcon: const Icon(Icons.location_city_rounded, color: LocalLensColors.primaryTeal, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: LocalLensColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: LocalLensColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: LocalLensColors.primaryTeal, width: 1.5),
                      ),
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

  Widget _buildDateAndWeatherSelector(CreateItineraryState state, ItineraryNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date & Time Selectors Row
          Row(
            children: [
              // Trip Date Picker Button
              Expanded(
                child: GestureDetector(
                  onTap: _pickTripDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: LocalLensColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LocalLensColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: LocalLensColors.primaryTeal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trip Date',
                                style: LocalLensTypography.caption.copyWith(
                                  color: LocalLensColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDisplayDate(_selectedTripDate),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: LocalLensColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: LocalLensColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Start Time Picker Button
              Expanded(
                child: GestureDetector(
                  onTap: _pickStartTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: LocalLensColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: LocalLensColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: LocalLensColors.accentOrange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Time',
                                style: LocalLensTypography.caption.copyWith(
                                  color: LocalLensColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedStartTime.hourOfPeriod == 0 ? 12 : _selectedStartTime.hourOfPeriod}:${_selectedStartTime.minute.toString().padLeft(2, '0')} ${_selectedStartTime.period == DayPeriod.am ? 'AM' : 'PM'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: LocalLensColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, color: LocalLensColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Live / Forecast Weather Card for Selected Date & Destination
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _weatherBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _weatherColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _weatherColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_weatherIcon, color: _weatherColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            _weatherTemp,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: _weatherColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• $_weatherCondition',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: _weatherColor,
                            ),
                          ),
                          if (_isLoadingWeather) ...[
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(_weatherColor),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _weatherColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.water_drop_rounded, size: 10, color: _weatherColor),
                                const SizedBox(width: 2),
                                Text(
                                  _weatherRainChance,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _weatherColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _weatherAdvice,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _weatherColor.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(CreateItineraryState state, ItineraryNotifier notifier) {
    final isHours = state.availableTimeUnit == 'Hours';
    final hourPresets = ['2', '3', '4', '6', '8', '10', '12'];
    final dayPresets = ['1', '2', '3', '4', '5'];
    final activePresets = isHours ? hourPresets : dayPresets;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _timeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) {
                    notifier.setTime(val, state.availableTimeUnit);
                  },
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    labelStyle: const TextStyle(color: LocalLensColors.textSecondary),
                    filled: true,
                    fillColor: LocalLensColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: LocalLensColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: state.availableTimeUnit,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: LocalLensColors.primaryTeal),
                      items: const [
                        DropdownMenuItem(value: 'Hours', child: Text('Hours', style: TextStyle(fontWeight: FontWeight.bold))),
                        DropdownMenuItem(value: 'Days', child: Text('Days', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      onChanged: (newUnit) {
                        if (newUnit != null) {
                          notifier.setTime(_timeController.text, newUnit);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activePresets.map((preset) {
                final isSelected = state.availableTime == preset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$preset ${state.availableTimeUnit}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _timeController.text = preset;
                        notifier.setTime(preset, state.availableTimeUnit);
                      }
                    },
                    selectedColor: LocalLensColors.primaryTeal,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : LocalLensColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetField(CreateItineraryState state, ItineraryNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0.0;
              notifier.setBudget(parsed);
            },
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Text('₹', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              labelText: 'Total Budget (INR)',
              helperText: 'Total budget for the trip',
              helperStyle: LocalLensTypography.caption.copyWith(color: LocalLensColors.textMuted),
              filled: true,
              fillColor: LocalLensColors.surfaceSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1000, 2500, 3000, 5000, 10000].map((preset) {
                final isSelected = state.totalBudgetInr == preset.toDouble();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text('₹$preset'),
                    backgroundColor: isSelected ? LocalLensColors.warmAmberSoft : LocalLensColors.surfaceSecondary,
                    side: BorderSide(
                      color: isSelected ? LocalLensColors.warmAmber : Colors.transparent,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? LocalLensColors.textPrimary : LocalLensColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                    onPressed: () {
                      _budgetController.text = preset.toString();
                      notifier.setBudget(preset.toDouble());
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSelector(CreateItineraryState state, ItineraryNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row of Group Category Cards
          Row(
            children: _groupTypes.map((group) {
              final isSelected = state.groupType.toLowerCase() == (group['title'] as String).toLowerCase();
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    notifier.setGroup(group['title'] as String, group['count'] as int);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? LocalLensColors.primaryTealSoft : LocalLensColors.surfaceSecondary,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? LocalLensColors.primaryTeal : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          group['icon'] as IconData,
                          color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          group['title'] as String,
                          style: LocalLensTypography.caption.copyWith(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? LocalLensColors.primaryTealDark : LocalLensColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Stepper: How many persons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Persons',
                    style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.travelerCount} ${state.travelerCount == 1 ? 'person' : 'people'} traveling',
                    style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  // Minus Button
                  IconButton(
                    onPressed: state.travelerCount > 1
                        ? () => notifier.setTravelerCount(state.travelerCount - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: LocalLensColors.primaryTeal,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: LocalLensColors.primaryTealSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LocalLensColors.primaryTeal.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${state.travelerCount}',
                      style: LocalLensTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LocalLensColors.primaryTealDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Plus Button
                  IconButton(
                    onPressed: state.travelerCount < 20
                        ? () => notifier.setTravelerCount(state.travelerCount + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: LocalLensColors.primaryTeal,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick Persons Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [1, 2, 3, 4, 5, 6, 8, 10].map((count) {
                final isSelected = state.travelerCount == count;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text('$count ${count == 1 ? 'person' : 'persons'}'),
                    backgroundColor: isSelected ? LocalLensColors.primaryTealSoft : LocalLensColors.surfaceSecondary,
                    side: BorderSide(
                      color: isSelected ? LocalLensColors.primaryTeal : Colors.transparent,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? LocalLensColors.primaryTealDark : LocalLensColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                    onPressed: () {
                      notifier.setTravelerCount(count);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCountSelector(CreateItineraryState state, ItineraryNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Experiences in Itinerary',
                    style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.desiredExperienceCount} stops to visit',
                    style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  // Minus Button
                  IconButton(
                    onPressed: state.desiredExperienceCount > 1
                        ? () => notifier.setDesiredExperienceCount(state.desiredExperienceCount - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    color: LocalLensColors.accentOrange,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: LocalLensColors.accentOrangeSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: LocalLensColors.accentOrange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${state.desiredExperienceCount}',
                      style: LocalLensTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LocalLensColors.accentOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Plus Button
                  IconButton(
                    onPressed: state.desiredExperienceCount < 10
                        ? () => notifier.setDesiredExperienceCount(state.desiredExperienceCount + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    color: LocalLensColors.accentOrange,
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Preset Experience Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                {'count': 2, 'label': '2 (Relaxed)'},
                {'count': 3, 'label': '3 (Balanced)'},
                {'count': 4, 'label': '4 (Full Day)'},
                {'count': 5, 'label': '5 (Packed)'},
                {'count': 6, 'label': '6+ (Active)'},
              ].map((item) {
                final count = item['count'] as int;
                final label = item['label'] as String;
                final isSelected = state.desiredExperienceCount == count;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    label: Text(label),
                    backgroundColor: isSelected ? LocalLensColors.accentOrangeSoft : LocalLensColors.surfaceSecondary,
                    side: BorderSide(
                      color: isSelected ? LocalLensColors.accentOrange : Colors.transparent,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? LocalLensColors.accentOrange : LocalLensColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                    onPressed: () {
                      notifier.setDesiredExperienceCount(count);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ML model ranks and auto-selects top ${state.desiredExperienceCount} matching experiences for your day.',
            style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsGrid(CreateItineraryState state, ItineraryNotifier notifier) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _interestOptions.map((interest) {
        final isSelected = state.interests.contains(interest);
        return FilterChip(
          label: Text(interest),
          selected: isSelected,
          onSelected: (_) => notifier.toggleInterest(interest),
          selectedColor: LocalLensColors.accentOrangeSoft,
          checkmarkColor: LocalLensColors.accentOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
            side: BorderSide(
              color: isSelected ? LocalLensColors.accentOrange : LocalLensColors.border,
            ),
          ),
          labelStyle: TextStyle(
            fontSize: 13,
            color: isSelected ? LocalLensColors.accentOrange : LocalLensColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPreferencesField(CreateItineraryState state, ItineraryNotifier notifier) {
    final samplePrompts = [
      'Prefer less crowded places',
      'Want local street food',
      'Need wheelchair accessible places',
      'Prefer indoor activities',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _preferencesController,
            maxLines: 2,
            onChanged: (val) => notifier.setPreferences(val),
            decoration: InputDecoration(
              hintText: 'e.g. Vegetarian food only, love scenic photography, traveling with family',
              hintStyle: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textMuted, fontSize: 13),
              filled: true,
              fillColor: LocalLensColors.surfaceSecondary,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: samplePrompts.map((prompt) {
              return GestureDetector(
                onTap: () {
                  final newText = _preferencesController.text.isEmpty
                      ? prompt
                      : '${_preferencesController.text}, $prompt';
                  _preferencesController.text = newText;
                  notifier.setPreferences(newText);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: LocalLensColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: LocalLensColors.borderLight),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: LocalLensColors.primaryTeal),
                      const SizedBox(width: 4),
                      Text(
                        prompt,
                        style: LocalLensTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet: Displays ML Recommendations & Collects Trip Start Timing
class _RecommendationSelectionSheet extends ConsumerStatefulWidget {
  const _RecommendationSelectionSheet();

  @override
  ConsumerState<_RecommendationSelectionSheet> createState() => _RecommendationSelectionSheetState();
}

class _RecommendationSelectionSheetState extends ConsumerState<_RecommendationSelectionSheet> {
  final List<String> _timePresets = ['09:00 AM', '10:00 AM', '10:30 AM', '11:00 AM', '02:00 PM', '04:00 PM'];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryProvider);
    final notifier = ref.read(itineraryProvider.notifier);
    final recs = state.recommendations;
    final selectedCount = state.selectedExperienceIds.length;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: LocalLensColors.accentOrange, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Recommended Experiences',
                              style: LocalLensTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ranked by ML model • Select to include',
                        style: LocalLensTypography.caption.copyWith(
                          color: LocalLensColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: () {
                    notifier.selectAllRecommendations();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Select All',
                    style: TextStyle(fontWeight: FontWeight.bold, color: LocalLensColors.primaryTeal, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable List of Recommendations
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              children: [
                // STEP A: TRIP START TIME INPUT SECTION
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LocalLensColors.primaryTealSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                    border: Border.all(color: LocalLensColors.primaryTeal.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: LocalLensColors.primaryTeal, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'When do you want to start your trip?',
                            style: LocalLensTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: LocalLensColors.primaryTealDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // Date Input
                          Expanded(
                            flex: 4,
                            child: InkWell(
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: now,
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  final str = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                                  notifier.setTripDate(str);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: LocalLensColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 14, color: LocalLensColors.primaryTeal),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        state.tripDate,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Custom Time Input / Picker
                          Expanded(
                            flex: 4,
                            child: InkWell(
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: const TimeOfDay(hour: 10, minute: 30),
                                );
                                if (time != null) {
                                  final period = time.period == DayPeriod.pm ? 'PM' : 'AM';
                                  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
                                  final min = time.minute.toString().padLeft(2, '0');
                                  notifier.setTripStartTime('$hour:$min $period');
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: LocalLensColors.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.schedule_rounded, size: 14, color: LocalLensColors.primaryTeal),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        state.tripStartTime,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Quick presets
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _timePresets.map((preset) {
                            final isSel = state.tripStartTime == preset;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(preset),
                                selected: isSel,
                                onSelected: (sel) {
                                  if (sel) notifier.setTripStartTime(preset);
                                },
                                selectedColor: LocalLensColors.primaryTeal,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSel ? Colors.white : LocalLensColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Select Experiences (${recs.length} found)',
                  style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),

                // Recommendation List Items
                if (recs.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: LocalLensColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          "We couldn't find suitable experiences nearby.",
                          textAlign: TextAlign.center,
                          style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Try increasing your search radius or changing your preferences.',
                          textAlign: TextAlign.center,
                          style: LocalLensTypography.caption.copyWith(color: LocalLensColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ...List.generate(recs.length, (index) {
                    final rec = recs[index];
                    final isSelected = state.selectedExperienceIds.contains(rec.experienceId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                        border: Border.all(
                          color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: LocalLensDimensions.softCardShadow,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                        onTap: () {
                          notifier.toggleExperienceSelection(rec.experienceId);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Selection Checkbox
                              Transform.scale(
                                scale: 0.95,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: LocalLensColors.primaryTeal,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (_) {
                                    notifier.toggleExperienceSelection(rec.experienceId);
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Remote/Asset Experience Image
                              LocalLensNetworkImage(
                                imageUrl: rec.imageUrl ?? rec.image,
                                width: 72,
                                height: 72,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              const SizedBox(width: 12),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: LocalLensColors.accentOrangeSoft,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            rec.category.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: LocalLensColors.accentOrange,
                                            ),
                                          ),
                                        ),
                                        if (rec.rating != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                              const SizedBox(width: 2),
                                              Text(
                                                rec.rating!.toStringAsFixed(1),
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      rec.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.place_outlined, size: 12, color: LocalLensColors.textMuted),
                                        const SizedBox(width: 2),
                                        Expanded(
                                          child: Text(
                                            rec.distanceKm != null
                                                ? '${rec.location} • ${rec.distanceKm!.toStringAsFixed(1)} km away'
                                                : rec.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: LocalLensTypography.caption.copyWith(
                                              color: LocalLensColors.textSecondary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          rec.price > 0 ? '₹${rec.price.toInt()}' : 'Free',
                                          style: LocalLensTypography.titleSmall.copyWith(
                                            color: LocalLensColors.primaryTeal,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          rec.durationHours >= 1.0
                                              ? '${rec.durationHours.toStringAsFixed(1).replaceAll('.0', '')} hr'
                                              : '${rec.durationMinutes} min',
                                          style: LocalLensTypography.caption.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: LocalLensColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Bottom Action: Generate Itinerary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: LocalLensDimensions.floatingShadow,
              border: Border(top: BorderSide(color: LocalLensColors.borderLight)),
            ),
            child: LocalLensPrimaryButton(
              text: 'Build Itinerary with $selectedCount Selected',
              isOrange: true,
              icon: Icons.auto_awesome_rounded,
              onPressed: selectedCount > 0
                  ? () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.aiItineraryGenerating);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
