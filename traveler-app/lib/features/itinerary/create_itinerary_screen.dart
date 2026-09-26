import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../providers/itinerary_provider.dart';
import '../../services/location_service.dart';
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

  bool _isResolvingLocation = false;
  bool _isLoadingRecommendations = false;
  String? _locationError;

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
    setState(() {
      _isLoadingRecommendations = true;
    });

    final notifier = ref.read(itineraryProvider.notifier);
    final recs = await notifier.fetchRecommendations();

    if (!mounted) return;

    setState(() {
      _isLoadingRecommendations = false;
    });

    if (recs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No experiences found for this location. Please try other filters.'),
          backgroundColor: LocalLensColors.errorRed,
        ),
      );
      return;
    }

    _showRecommendationModal(context);
  }

  void _showRecommendationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return const _RecommendationSelectionSheet();
      },
    );
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

                    // SECTION 2: AVAILABLE TIME
                    _buildSectionHeader(
                      icon: Icons.schedule_rounded,
                      title: 'How much time do you have?',
                    ),
                    const SizedBox(height: 12),
                    _buildTimeSelector(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 3: TOTAL BUDGET
                    _buildSectionHeader(
                      icon: Icons.currency_rupee_rounded,
                      title: 'What\'s your total budget?',
                    ),
                    const SizedBox(height: 12),
                    _buildBudgetField(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 4: TRAVEL GROUP
                    _buildSectionHeader(
                      icon: Icons.groups_rounded,
                      title: 'Who\'s traveling?',
                    ),
                    const SizedBox(height: 12),
                    _buildGroupSelector(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 5: INTERESTS
                    _buildSectionHeader(
                      icon: Icons.interests_rounded,
                      title: 'What interests you?',
                    ),
                    const SizedBox(height: 12),
                    _buildInterestsGrid(state, notifier),

                    const SizedBox(height: 24),

                    // SECTION 6: OPTIONAL PREFERENCES
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
                    },
                    decoration: InputDecoration(
                      hintText: 'Search destination (e.g. Mumbai, Delhi, Panvel)',
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
    return Row(
      children: _groupTypes.map((group) {
        final isSelected = state.groupType.toLowerCase() == (group['title'] as String).toLowerCase();
        return Expanded(
          child: GestureDetector(
            onTap: () {
              notifier.setGroup(group['title'] as String, group['count'] as int);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? LocalLensColors.primaryTealSoft : Colors.white,
                borderRadius: BorderRadius.circular(LocalLensDimensions.radiusMedium),
                border: Border.all(
                  color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.border,
                  width: isSelected ? 1.8 : 1.0,
                ),
                boxShadow: LocalLensDimensions.softCardShadow,
              ),
              child: Column(
                children: [
                  Icon(
                    group['icon'] as IconData,
                    color: isSelected ? LocalLensColors.primaryTeal : LocalLensColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    group['title'] as String,
                    style: LocalLensTypography.caption.copyWith(
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
