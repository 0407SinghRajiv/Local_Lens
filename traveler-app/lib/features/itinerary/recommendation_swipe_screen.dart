import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/locallens_design_system.dart';
import '../../models/recommendation_model.dart';
import '../../providers/itinerary_provider.dart';
import '../../services/itinerary_api_service.dart';
import '../../widgets/common/locallens_components.dart';
import '../../widgets/recommendation_swipe_stack.dart';

/// Screen for Multi-Stack Swipeable Recommendation Selection
/// Creates N separate stacks (N = placesToVisit), where each stack corresponds to 1 final selection.
class RecommendationSwipeScreen extends ConsumerStatefulWidget {
  const RecommendationSwipeScreen({super.key});

  @override
  ConsumerState<RecommendationSwipeScreen> createState() => _RecommendationSwipeScreenState();
}

class _RecommendationSwipeScreenState extends ConsumerState<RecommendationSwipeScreen> {
  final List<RecommendationModel> _selectedPlaces = [];
  final Set<String> _selectedPlaceIds = {};
  final Set<String> _rejectedPlaceIds = {};
  final Set<String> _shownPlaceIds = {};

  int _currentStackIndex = 0;
  List<String> _stackThemes = [];
  List<bool> _stackIsMixed = [];
  List<List<RecommendationModel>> _stackCandidates = [];

  bool _isLoading = false;
  bool _isGeneratingItinerary = false;

  final List<String> _timePresets = ['09:00 AM', '10:00 AM', '10:30 AM', '11:00 AM', '02:00 PM', '04:00 PM'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStacks();
    });
  }

  /// Categorization & Interest matcher helper
  static bool _matchesInterest(RecommendationModel rec, String interest) {
    final cat = rec.category.trim().toLowerCase();
    final subCat = (rec.subCategory ?? '').trim().toLowerCase();
    final intr = interest.trim().toLowerCase();

    if (intr == cat) return true;
    if (intr == 'food') {
      return cat == 'food' ||
          cat.contains('food') ||
          cat.contains('cuisine') ||
          cat == 'street food' ||
          cat == 'local cuisine' ||
          cat == 'seafood';
    }
    if (intr == 'culture') {
      return cat == 'culture' ||
          cat == 'heritage' ||
          cat == 'museum' ||
          cat == 'temple' ||
          cat == 'religious' ||
          cat == 'spiritual' ||
          cat == 'architecture' ||
          cat == 'art' ||
          cat == 'handicraft' ||
          cat == 'workshop' ||
          cat == 'workshops';
    }
    if (intr == 'adventure') {
      return cat == 'adventure' ||
          cat.contains('adventure') ||
          cat == 'trekking' ||
          cat == 'water sports' ||
          cat == 'sports' ||
          cat == 'boat ride';
    }
    if (intr == 'nature') {
      return cat == 'nature' ||
          cat.contains('nature') ||
          cat == 'beach' ||
          cat == 'wildlife' ||
          cat == 'waterfall' ||
          cat == 'bird watching' ||
          cat == 'coastal';
    }
    if (intr == 'heritage') {
      return cat == 'heritage' ||
          cat.contains('heritage') ||
          cat == 'fort' ||
          cat == 'temple' ||
          cat == 'religious' ||
          cat == 'architecture' ||
          cat == 'museum';
    }
    if (intr == 'beach') {
      return cat == 'beach' || cat.contains('beach') || cat == 'coastal' || cat == 'water sports';
    }
    if (intr == 'shopping') {
      return cat == 'shopping' || cat.contains('shopping') || cat == 'market' || cat == 'markets' || cat == 'handicraft';
    }
    if (intr == 'nightlife') {
      return cat == 'nightlife' || cat.contains('nightlife') || cat == 'entertainment';
    }
    if (intr == 'local experiences' || intr == 'hidden gems') {
      return rec.localExperience || rec.hiddenGem || cat.contains('local') || cat.contains('homestay');
    }
    return cat.contains(intr) || subCat.contains(intr);
  }

  /// Validates if a recommendation belongs to any of the user's selected interests
  static bool _matchesAnySelectedInterest(RecommendationModel rec, List<String> selectedInterests) {
    if (selectedInterests.isEmpty) return true;
    for (final interest in selectedInterests) {
      if (_matchesInterest(rec, interest)) return true;
    }
    return false;
  }

  /// Initialize N separate stacks for placesToVisit
  Future<void> _initializeStacks() async {
    final state = ref.read(itineraryProvider);
    final int placesToVisit = state.desiredExperienceCount > 0 ? state.desiredExperienceCount : 4;
    final List<String> selectedInterests = state.interests.isNotEmpty
        ? state.interests
        : ['Food', 'Culture', 'Local Experiences'];
    final int interestCount = selectedInterests.length;

    _stackThemes = List.generate(placesToVisit, (index) {
      if (index < interestCount) {
        return selectedInterests[index];
      } else {
        return 'Mixed (${selectedInterests.take(3).join(' • ')})';
      }
    });

    _stackIsMixed = List.generate(placesToVisit, (index) => index >= interestCount);
    _stackCandidates = List.generate(placesToVisit, (_) => <RecommendationModel>[]);

    setState(() {
      _isLoading = true;
    });

    // 1. Distribute available pool from initial provider recommendations
    final initialRecs = state.recommendations;
    for (int stackIdx = 0; stackIdx < placesToVisit; stackIdx++) {
      final isMixed = _stackIsMixed[stackIdx];
      final theme = _stackThemes[stackIdx];

      for (final rec in initialRecs) {
        final id = rec.experienceId.trim();
        if (id.isEmpty ||
            _selectedPlaceIds.contains(id) ||
            _rejectedPlaceIds.contains(id) ||
            _shownPlaceIds.contains(id)) {
          continue;
        }

        final bool matches = isMixed
            ? _matchesAnySelectedInterest(rec, selectedInterests)
            : _matchesInterest(rec, theme);

        if (matches && _stackCandidates[stackIdx].length < 6) {
          _stackCandidates[stackIdx].add(rec);
          _shownPlaceIds.add(id);
        }
      }
    }

    // 2. Replenish any stack that has fewer than 5 candidates
    await _replenishAllStacksIfNeeded(selectedInterests);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetch additional candidates per stack to ensure 5-6 candidates per stack
  Future<void> _replenishAllStacksIfNeeded(List<String> selectedInterests) async {
    final state = ref.read(itineraryProvider);
    final dest = state.locationMode == LocationMode.exact
        ? state.displayAddress
        : (state.destination.isNotEmpty ? state.destination : 'Mumbai');

    for (int stackIdx = 0; stackIdx < _stackThemes.length; stackIdx++) {
      if (_stackCandidates[stackIdx].length >= 5) continue;

      final isMixed = _stackIsMixed[stackIdx];
      final theme = _stackThemes[stackIdx];

      try {
        final freshRecs = await ItineraryApiService.fetchRecommendations(
          destination: dest,
          startLocation: state.displayAddress,
          startLat: state.latitude,
          startLon: state.longitude,
          budget: state.totalBudgetInr > 0 ? state.totalBudgetInr : 5000.0,
          durationHours: state.durationHours > 0 ? state.durationHours : 6.0,
          travelerCount: state.travelerCount,
          travelerType: state.groupType,
          interests: isMixed ? selectedInterests : [theme],
          preferences: state.preferences,
          topN: 15,
        );

        for (final rec in freshRecs) {
          final id = rec.experienceId.trim();
          if (id.isEmpty ||
              _selectedPlaceIds.contains(id) ||
              _rejectedPlaceIds.contains(id) ||
              _shownPlaceIds.contains(id)) {
            continue;
          }

          final bool matches = isMixed
              ? _matchesAnySelectedInterest(rec, selectedInterests)
              : _matchesInterest(rec, theme);

          if (matches && _stackCandidates[stackIdx].length < 6) {
            _stackCandidates[stackIdx].add(rec);
            _shownPlaceIds.add(id);
          }
        }
      } catch (e) {
        debugPrint('[RecommendationSwipeScreen] Error replenishing stack $stackIdx: $e');
      }
    }
  }

  /// Fetch more candidates for the currently active stack
  Future<void> _fetchMoreForActiveStack() async {
    if (_isLoading || _currentStackIndex >= _stackThemes.length) return;

    setState(() {
      _isLoading = true;
    });

    final state = ref.read(itineraryProvider);
    final List<String> selectedInterests = state.interests.isNotEmpty
        ? state.interests
        : ['Food', 'Culture', 'Local Experiences'];
    final dest = state.locationMode == LocationMode.exact
        ? state.displayAddress
        : (state.destination.isNotEmpty ? state.destination : 'Mumbai');
    final isMixed = _stackIsMixed[_currentStackIndex];
    final theme = _stackThemes[_currentStackIndex];

    try {
      final freshRecs = await ItineraryApiService.fetchRecommendations(
        destination: dest,
        startLocation: state.displayAddress,
        startLat: state.latitude,
        startLon: state.longitude,
        budget: state.totalBudgetInr > 0 ? state.totalBudgetInr : 5000.0,
        durationHours: state.durationHours > 0 ? state.durationHours : 6.0,
        travelerCount: state.travelerCount,
        travelerType: state.groupType,
        interests: isMixed ? selectedInterests : [theme],
        preferences: state.preferences,
        topN: 20,
      );

      final newUnique = <RecommendationModel>[];
      for (final rec in freshRecs) {
        final id = rec.experienceId.trim();
        if (id.isEmpty ||
            _selectedPlaceIds.contains(id) ||
            _rejectedPlaceIds.contains(id) ||
            _shownPlaceIds.contains(id)) {
          continue;
        }

        final bool matches = isMixed
            ? _matchesAnySelectedInterest(rec, selectedInterests)
            : _matchesInterest(rec, theme);

        if (matches) {
          newUnique.add(rec);
          _shownPlaceIds.add(id);
        }
      }

      if (mounted) {
        setState(() {
          _stackCandidates[_currentStackIndex].addAll(newUnique);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSwipeRight(RecommendationModel candidate) {
    setState(() {
      final id = candidate.experienceId;
      _selectedPlaceIds.add(id);
      _shownPlaceIds.add(id);
      _selectedPlaces.add(candidate);

      // Remove from all remaining stacks to prevent cross-stack duplicates
      for (int i = _currentStackIndex; i < _stackCandidates.length; i++) {
        _stackCandidates[i].removeWhere((c) => c.experienceId == id);
      }

      // CURRENT STACK TERMINATES IMMEDIATELY
      _currentStackIndex++;
    });
  }

  void _onSwipeLeft(RecommendationModel candidate) {
    setState(() {
      final id = candidate.experienceId;
      _rejectedPlaceIds.add(id);
      _shownPlaceIds.add(id);

      // Candidate is rejected from current stack
      if (_currentStackIndex < _stackCandidates.length) {
        _stackCandidates[_currentStackIndex].removeWhere((c) => c.experienceId == id);
      }
    });

    // If current stack ran out of candidates without a selection, fetch more
    if (_currentStackIndex < _stackCandidates.length && _stackCandidates[_currentStackIndex].isEmpty) {
      _fetchMoreForActiveStack();
    }
  }

  void _removeSelectedPlace(String experienceId) {
    setState(() {
      _selectedPlaceIds.remove(experienceId);
      final removedIndex = _selectedPlaces.indexWhere((p) => p.experienceId == experienceId);
      if (removedIndex != -1) {
        _selectedPlaces.removeAt(removedIndex);
        if (_currentStackIndex > _selectedPlaces.length) {
          _currentStackIndex = _selectedPlaces.length;
        }
      }
    });

    if (_currentStackIndex < _stackCandidates.length && _stackCandidates[_currentStackIndex].isEmpty) {
      _fetchMoreForActiveStack();
    }
  }

  Future<void> _generateItineraryFromSelection() async {
    setState(() {
      _isGeneratingItinerary = true;
    });

    final notifier = ref.read(itineraryProvider.notifier);
    notifier.setSelectedPlaces(_selectedPlaces);
    notifier.setSelectedExperienceIds(_selectedPlaceIds);

    // Navigate to Generating Screen
    context.push(AppRoutes.aiItineraryGenerating);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryProvider);
    final placesToVisit = state.desiredExperienceCount > 0 ? state.desiredExperienceCount : 4;
    final isComplete = _selectedPlaces.length >= placesToVisit || _currentStackIndex >= placesToVisit;
    final remainingCount = max(0, placesToVisit - _selectedPlaces.length);

    return Scaffold(
      backgroundColor: LocalLensColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LocalLensColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'Select Experiences',
              style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${_selectedPlaces.length} of $placesToVisit places selected',
              style: LocalLensTypography.caption.copyWith(
                color: LocalLensColors.primaryTeal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (!isComplete)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: LocalLensColors.textSecondary),
                tooltip: 'Fetch more recommendations for this stack',
                onPressed: _fetchMoreForActiveStack,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TOP PROGRESS BAR
            LinearProgressIndicator(
              value: placesToVisit > 0 ? (_selectedPlaces.length / placesToVisit).clamp(0.0, 1.0) : 0.0,
              backgroundColor: LocalLensColors.surfaceSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(LocalLensColors.primaryTeal),
              minHeight: 4,
            ),

            Expanded(
              child: isComplete
                  ? _buildCompletionConfirmationView(state)
                  : _buildActiveStackView(placesToVisit, remainingCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveStackView(int placesToVisit, int remainingCount) {
    if (_isLoading && (_currentStackIndex >= _stackCandidates.length || _stackCandidates[_currentStackIndex].isEmpty)) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(LocalLensColors.primaryTeal),
            ),
            SizedBox(height: 16),
            Text(
              'Finding matching local experiences for your itinerary...',
              style: TextStyle(fontWeight: FontWeight.w600, color: LocalLensColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final activeCandidates = _currentStackIndex < _stackCandidates.length ? _stackCandidates[_currentStackIndex] : <RecommendationModel>[];
    final currentTheme = _currentStackIndex < _stackThemes.length ? _stackThemes[_currentStackIndex] : 'Experience';

    if (activeCandidates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.travel_explore_rounded, size: 64, color: LocalLensColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'No more candidates in $currentTheme stack',
                style: LocalLensTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tap Load More to find more local options matching your preferences.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _fetchMoreForActiveStack,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Load More'),
                  ),
                  if (_selectedPlaces.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LocalLensColors.primaryTeal,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        _generateItineraryFromSelection();
                      },
                      child: Text('Continue with ${_selectedPlaces.length}'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 12),

        // PROFESSIONAL STACK STEP & THEME INDICATOR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: LocalLensColors.primaryTeal,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                        ),
                        child: Text(
                          'STEP ${_currentStackIndex + 1} OF $placesToVisit',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: LocalLensColors.accentOrangeSoft,
                          borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                        ),
                        child: Text(
                          currentTheme.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: LocalLensColors.accentOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    remainingCount == 1 ? '1 place remaining' : '$remainingCount places remaining',
                    style: LocalLensTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: LocalLensColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select 1 place for this stack • Swipe right to choose',
                style: LocalLensTypography.caption.copyWith(
                  color: LocalLensColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // CARD STACK FOR CURRENT THEME
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RecommendationSwipeStack(
              key: ValueKey('stack_$_currentStackIndex'),
              candidates: activeCandidates,
              placesToVisit: placesToVisit,
              selectedCount: _selectedPlaces.length,
              onSwipeRight: _onSwipeRight,
              onSwipeLeft: _onSwipeLeft,
              onStackEmpty: _fetchMoreForActiveStack,
            ),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  /// Confirmation view when exact required number of places is selected
  Widget _buildCompletionConfirmationView(CreateItineraryState state) {
    final notifier = ref.read(itineraryProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SUCCESS HERO CARD
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LocalLensColors.heroCardGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: LocalLensDimensions.floatingShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 24),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_selectedPlaces.length} Places Selected',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Your Places Are Ready!',
                  style: LocalLensTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All ${_selectedPlaces.length} selected experiences will be synthesized into a chronological route with connected maps.',
                  style: LocalLensTypography.bodyMedium.copyWith(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // TRIP TIMING SETUP
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: LocalLensColors.border),
              boxShadow: LocalLensDimensions.softCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: LocalLensColors.primaryTeal, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Trip Date & Start Time',
                      style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Date Button
                    Expanded(
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
                            final str =
                                "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            notifier.setTripDate(str);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: LocalLensColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: LocalLensColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 16, color: LocalLensColors.primaryTeal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.tripDate,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Time Button
                    Expanded(
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: LocalLensColors.surfaceSecondary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: LocalLensColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 16, color: LocalLensColors.primaryTeal),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.tripStartTime,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Quick Time Chips
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

          const SizedBox(height: 20),

          // SELECTED PLACES LIST
          Text(
            'Your Selected Places (${_selectedPlaces.length})',
            style: LocalLensTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),

          ..._selectedPlaces.asMap().entries.map((entry) {
            final idx = entry.key;
            final place = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: LocalLensColors.borderLight),
                boxShadow: LocalLensDimensions.softCardShadow,
              ),
              child: Row(
                children: [
                  // Order Index Number
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: LocalLensColors.primaryTeal,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Image Thumbnail
                  LocalLensNetworkImage(
                    imageUrl: place.image,
                    width: 48,
                    height: 48,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              place.category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: LocalLensColors.accentOrange,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: LocalLensColors.textMuted, fontSize: 10)),
                            const SizedBox(width: 6),
                            Text(
                              '${place.durationMinutes}m',
                              style: const TextStyle(fontSize: 11, color: LocalLensColors.textSecondary),
                            ),
                            const SizedBox(width: 6),
                            const Text('•', style: TextStyle(color: LocalLensColors.textMuted, fontSize: 10)),
                            const SizedBox(width: 6),
                            Text(
                              place.price > 0 ? '₹${place.price.toInt()}' : 'Free',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: LocalLensColors.primaryTeal),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Remove / Swap Button
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: LocalLensColors.errorRed, size: 20),
                    tooltip: 'Remove place and pick another',
                    onPressed: () => _removeSelectedPlace(place.experienceId),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // FINAL ACTION BUTTON: GENERATE MY ITINERARY
          LocalLensPrimaryButton(
            text: 'Generate My Itinerary (${_selectedPlaces.length} Places)',
            isLoading: _isGeneratingItinerary,
            icon: Icons.route_rounded,
            onPressed: _generateItineraryFromSelection,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
