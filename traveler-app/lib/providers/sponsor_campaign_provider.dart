import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/sponsor_campaign_model.dart';
import '../services/sponsor_campaign_service.dart';

/// Provider for SponsorCampaignService
final sponsorCampaignServiceProvider = Provider<SponsorCampaignService>((ref) {
  return SponsorCampaignService();
});

/// State for sponsored campaigns
class SponsorCampaignsState {
  final List<SponsorCampaign> campaigns;
  final bool isLoading;
  final String? errorMessage;
  final String selectedCategory;

  const SponsorCampaignsState({
    this.campaigns = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory = 'All',
  });

  SponsorCampaignsState copyWith({
    List<SponsorCampaign>? campaigns,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
  }) {
    return SponsorCampaignsState(
      campaigns: campaigns ?? this.campaigns,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

/// Notifier to manage sponsored campaigns with live Supabase fetching
class SponsorCampaignsNotifier extends StateNotifier<SponsorCampaignsState> {
  final SponsorCampaignService _service;

  SponsorCampaignsNotifier(this._service) : super(const SponsorCampaignsState()) {
    fetchCampaigns();
  }

  Future<void> fetchCampaigns({String? category}) async {
    final cat = category ?? state.selectedCategory;
    state = state.copyWith(isLoading: true, errorMessage: null, selectedCategory: cat);

    try {
      final results = await _service.getSponsoredCampaigns(category: cat);
      state = state.copyWith(
        campaigns: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        campaigns: SponsorCampaignService.getCuratedSponsoredCampaigns(),
      );
    }
  }

  void filterCategory(String category) {
    fetchCampaigns(category: category);
  }
}

/// Main Riverpod provider for sponsored campaigns
final sponsorCampaignsProvider =
    StateNotifierProvider<SponsorCampaignsNotifier, SponsorCampaignsState>((ref) {
  final service = ref.watch(sponsorCampaignServiceProvider);
  return SponsorCampaignsNotifier(service);
});
