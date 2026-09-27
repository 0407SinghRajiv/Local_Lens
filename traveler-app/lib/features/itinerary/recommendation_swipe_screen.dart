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

/// Screen for Swipeable Recommendation Selection & Automatic Itinerary Generation.
/// Presents the FULL recommendation candidate pool from the ML model.
/// User swipes:
///   RIGHT -> Select / Keep
///   LEFT  -> Skip / Reject
/// When selectedPlaces.length === placesToVisit -> AUTOMATICALLY triggers itinerary generation!
class RecommendationSwipeScreen extends ConsumerStatefulWidget {
  const RecommendationSwipeScreen({super.key});

  @override
  ConsumerState<RecommendationSwipeScreen> createState() => _RecommendationSwipeScreenState();
}

class _RecommendationSwipeScreenState extends ConsumerState<RecommendationSwipeScreen> {
  final List<RecommendationModel> _selectedPlaces = [];
  final Set<String> _selectedPlaceIds = {};
  final Set<String> _rejectedPlaceIds = {};
  final List<RecommendationModel> _candidatePool = [];

  bool _isLoading = false;
  bool _isGeneratingItinerary = false;
  bool _hasTriggeredAutoGeneration = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCandidates();
    });
  }

  /// Initializes the full candidate pool from provider recommendations or backend
  Future<void> _initializeCandidates() async {
    final state = ref.read(itineraryProvider);
    final int placesToVisit = state.desiredExperienceCount > 0 ? state.desiredExperienceCount : 4;

    setState(() {
      _isLoading = true;
    });

    List<RecommendationModel> initialRecs = List.from(state.recommendations);

    // If initial recommendations are empty or fewer than target, fetch a rich pool of 50 candidates
    if (initialRecs.isEmpty || initialRecs.length < placesToVisit) {
      try {
        final dest = state.locationMode == LocationMode.exact
            ? state.displayAddress
            : (state.destination.isNotEmpty ? state.destination : 'Mumbai');

        initialRecs = await ItineraryApiService.fetchRecommendations(
          destination: dest,
          startLocation: state.displayAddress,
          startLat: state.latitude,
          startLon: state.longitude,
          budget: state.totalBudgetInr > 0 ? state.totalBudgetInr : 5000.0,
          durationHours: state.durationHours > 0 ? state.durationHours : 6.0,
          travelerCount: state.travelerCount,
          travelerType: state.groupType,
          interests: state.interests,
          preferences: state.preferences,
          excludedCategories: state.excludedCategories,
          topN: 50,
        );
      } catch (e) {
        debugPrint('[RecommendationSwipeScreen] Error fetching recommendations: $e');
      }
    }

    if (mounted) {
      setState(() {
        _candidatePool.clear();
        for (final rec in initialRecs) {
          final id = rec.experienceId.trim();
          final isExcluded = state.excludedCategories.any((ex) => rec.matchesExcludedCategory(ex));
          final matchesInterest = state.interests.isEmpty || rec.matchesAnyInterest(state.interests);
          if (id.isNotEmpty && !isExcluded && matchesInterest && !_selectedPlaceIds.contains(id) && !_rejectedPlaceIds.contains(id)) {
            _candidatePool.add(rec);
          }
        }
        // If strict interest filter yielded 0 candidates, fallback to non-excluded candidates
        if (_candidatePool.isEmpty && initialRecs.isNotEmpty) {
          for (final rec in initialRecs) {
            final id = rec.experienceId.trim();
            final isExcluded = state.excludedCategories.any((ex) => rec.matchesExcludedCategory(ex));
            if (id.isNotEmpty && !isExcluded && !_selectedPlaceIds.contains(id) && !_rejectedPlaceIds.contains(id)) {
              _candidatePool.add(rec);
            }
          }
        }
        _isLoading = false;
      });

      debugPrint(
        '[RecommendationSwipeScreen] Initialized pool with ${_candidatePool.length} candidates. Selection target: $placesToVisit places.',
      );
    }
  }

  /// Asynchronously replenishes candidate pool when running low (< 3 remaining)
  Future<void> _fetchMoreCandidates() async {
    if (_isLoading || _isGeneratingItinerary || _hasTriggeredAutoGeneration) return;

    final state = ref.read(itineraryProvider);
    final dest = state.locationMode == LocationMode.exact
        ? state.displayAddress
        : (state.destination.isNotEmpty ? state.destination : 'Mumbai');

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
        interests: state.interests,
        preferences: state.preferences,
        excludedCategories: state.excludedCategories,
        topN: 50,
      );

      final newUnique = <RecommendationModel>[];
      final existingPoolIds = _candidatePool.map((c) => c.experienceId.trim()).toSet();

      for (final rec in freshRecs) {
        final id = rec.experienceId.trim();
        final isExcluded = state.excludedCategories.any((ex) => rec.matchesExcludedCategory(ex));
        final matchesInterest = state.interests.isEmpty || rec.matchesAnyInterest(state.interests);
        if (id.isNotEmpty &&
            !isExcluded &&
            matchesInterest &&
            !_selectedPlaceIds.contains(id) &&
            !_rejectedPlaceIds.contains(id) &&
            !existingPoolIds.contains(id)) {
          newUnique.add(rec);
          existingPoolIds.add(id);
        }
      }

      if (mounted && newUnique.isNotEmpty) {
        setState(() {
          _candidatePool.addAll(newUnique);
        });
        debugPrint('[RecommendationSwipeScreen] Replenished candidate pool with +${newUnique.length} places.');
      }
    } catch (e) {
      debugPrint('[RecommendationSwipeScreen] Error fetching more candidates: $e');
    }
  }

  /// RIGHT SWIPE: User selects / keeps the candidate
  void _onSwipeRight(RecommendationModel candidate) {
    if (_isGeneratingItinerary || _hasTriggeredAutoGeneration) return;

    final id = candidate.experienceId.trim();
    if (_selectedPlaceIds.contains(id)) return;

    setState(() {
      _selectedPlaceIds.add(id);
      _selectedPlaces.add(candidate);
      _candidatePool.removeWhere((c) => c.experienceId.trim() == id);
    });

    final state = ref.read(itineraryProvider);
    final int placesToVisit = state.desiredExperienceCount > 0 ? state.desiredExperienceCount : 4;

    debugPrint(
      '[RecommendationSwipeScreen] SELECT -> "${candidate.name}" (${_selectedPlaces.length}/$placesToVisit selected)',
    );

    // CRITICAL REQUIREMENT: When selectedPlaces.length === placesToVisit -> AUTOMATICALLY GENERATE ITINERARY
    if (_selectedPlaces.length >= placesToVisit) {
      _triggerAutoItineraryGeneration();
    } else if (_candidatePool.length < 3) {
      _fetchMoreCandidates();
    }
  }

  /// LEFT SWIPE: User skips / rejects the candidate
  void _onSwipeLeft(RecommendationModel candidate) {
    if (_isGeneratingItinerary || _hasTriggeredAutoGeneration) return;

    final id = candidate.experienceId.trim();
    setState(() {
      _rejectedPlaceIds.add(id);
      _candidatePool.removeWhere((c) => c.experienceId.trim() == id);
    });

    final state = ref.read(itineraryProvider);
    final int placesToVisit = state.desiredExperienceCount > 0 ? state.desiredExperienceCount : 4;

    debugPrint(
      '[RecommendationSwipeScreen] SKIP -> "${candidate.name}" (Selected: ${_selectedPlaces.length}/$placesToVisit, Pool remaining: ${_candidatePool.length})',
    );

    if (_candidatePool.length < 3 && _selectedPlaces.length < placesToVisit) {
      _fetchMoreCandidates();
    }
  }

  /// Removes an already-selected place from the tray if user wants to swap
  void _removeSelectedPlace(String experienceId) {
    if (_isGeneratingItinerary || _hasTriggeredAutoGeneration) return;

    setState(() {
      _selectedPlaceIds.remove(experienceId);
      final removedIndex = _selectedPlaces.indexWhere((p) => p.experienceId == experienceId);
      if (removedIndex != -1) {
        final removed = _selectedPlaces.removeAt(removedIndex);
        // Put back at the beginning of candidate pool
        _candidatePool.insert(0, removed);
      }
    });
  }

  /// AUTOMATIC ITINERARY GENERATION TRIGGER
  /// Protected against duplicate execution / race conditions
  void _triggerAutoItineraryGeneration() {
    if (_isGeneratingItinerary || _hasTriggeredAutoGeneration) return;

    final state = ref.read(itineraryProvider);
    final int placesToVisit = state.desiredExperienceCount > 0 ? state.desiredExperienceCount : 4;

    if (_selectedPlaces.length < placesToVisit) return;

    setState(() {
      _isGeneratingItinerary = true;
      _hasTriggeredAutoGeneration = true;
    });

    final notifier = ref.read(itineraryProvider.notifier);
    notifier.setSelectedPlaces(List.from(_selectedPlaces));
    notifier.setSelectedExperienceIds(Set.from(_selectedPlaceIds));

    debugPrint(
      '[RecommendationSwipeScreen] >>> AUTOMATIC ITINERARY GENERATION TRIGGERED with ${_selectedPlaces.length} places! Target: $placesToVisit',
    );

    // Smooth immediate transition to Generating screen
    if (mounted) {
      context.push(AppRoutes.aiItineraryGenerating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itineraryProvider);
    final placesToVisit = state.desiredExperienceCount > 0 ? state.desiredExperienceCount : 4;
    final progress = placesToVisit > 0 ? (_selectedPlaces.length / placesToVisit).clamp(0.0, 1.0) : 0.0;
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: LocalLensColors.textSecondary),
              tooltip: 'Fetch more recommendations',
              onPressed: _fetchMoreCandidates,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TOP PROGRESS BAR
            LinearProgressIndicator(
              value: progress,
              backgroundColor: LocalLensColors.surfaceSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(LocalLensColors.primaryTeal),
              minHeight: 4,
            ),

            // SELECTION STATUS BADGES
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: LocalLensColors.primaryTeal,
                      borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                    ),
                    child: Text(
                      '${_selectedPlaces.length}/$placesToVisit SELECTED',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Text(
                    remainingCount == 0
                        ? 'Target reached! Generating...'
                        : (remainingCount == 1 ? '1 place needed' : '$remainingCount places needed'),
                    style: LocalLensTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: remainingCount == 0 ? LocalLensColors.primaryTeal : LocalLensColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // MAIN SWIPE CARD STACK
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _buildMainStackContent(placesToVisit),
              ),
            ),

            // BOTTOM SELECTED PLACES TRAY
            if (_selectedPlaces.isNotEmpty) _buildSelectedPlacesTray(placesToVisit),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStackContent(int placesToVisit) {
    if (_isLoading && _candidatePool.isEmpty) {
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

    if (_candidatePool.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.travel_explore_rounded, size: 64, color: LocalLensColors.textMuted),
              const SizedBox(height: 16),
              Text(
                'All recommendations reviewed',
                style: LocalLensTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You have selected ${_selectedPlaces.length} of $placesToVisit places. Load more to discover additional local experiences.',
                textAlign: TextAlign.center,
                style: LocalLensTypography.bodyMedium.copyWith(color: LocalLensColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _fetchMoreCandidates,
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
                        // Allow proceeding with current selection if user chooses
                        setState(() {
                          _isGeneratingItinerary = true;
                          _hasTriggeredAutoGeneration = true;
                        });
                        final notifier = ref.read(itineraryProvider.notifier);
                        notifier.setSelectedPlaces(List.from(_selectedPlaces));
                        notifier.setSelectedExperienceIds(Set.from(_selectedPlaceIds));
                        context.push(AppRoutes.aiItineraryGenerating);
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

    return RecommendationSwipeStack(
      key: const ValueKey('active_recommendation_pool'),
      candidates: _candidatePool,
      placesToVisit: placesToVisit,
      selectedCount: _selectedPlaces.length,
      onSwipeRight: _onSwipeRight,
      onSwipeLeft: _onSwipeLeft,
      onStackEmpty: _fetchMoreCandidates,
    );
  }

  Widget _buildSelectedPlacesTray(int placesToVisit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: LocalLensColors.borderLight)),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Places (${_selectedPlaces.length}/$placesToVisit)',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: LocalLensColors.textPrimary),
              ),
              if (_selectedPlaces.length >= placesToVisit)
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: LocalLensColors.successGreen, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Ready!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: LocalLensColors.successGreen),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _selectedPlaces.asMap().entries.map((entry) {
                final idx = entry.key;
                final place = entry.value;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  decoration: BoxDecoration(
                    color: LocalLensColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: LocalLensColors.primaryTeal.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Number badge
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: LocalLensColors.primaryTeal,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Thumbnail
                      LocalLensNetworkImage(
                        imageUrl: place.image,
                        width: 24,
                        height: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(width: 6),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Text(
                          place.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => _removeSelectedPlace(place.experienceId),
                        child: const Icon(Icons.close_rounded, size: 14, color: LocalLensColors.textMuted),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
