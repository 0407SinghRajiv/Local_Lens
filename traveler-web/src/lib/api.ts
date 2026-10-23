// ==============================================================================
// LocalLens Web - API Client & ML Backend Integration
// Faithfully matches traveler-app's itinerary_api_service.dart
// ==============================================================================

import axios from 'axios';
import { RecommendationModel, Itinerary, ItineraryItem, SkippedExperienceItem } from '@/types';

const API_TIMEOUT = 8000;

export const CANDIDATE_URLS = [
  process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000',
  'http://127.0.0.1:8000',
  'http://localhost:8000',
];

let cachedBaseUrl: string | null = null;

export async function resolveBaseUrl(): Promise<string> {
  if (cachedBaseUrl) {
    try {
      const res = await axios.get(`${cachedBaseUrl}/health`, { timeout: 1500 });
      if (res.status === 200) return cachedBaseUrl;
    } catch {
      cachedBaseUrl = null;
    }
  }

  for (const candidate of CANDIDATE_URLS) {
    try {
      const res = await axios.get(`${candidate}/health`, { timeout: 1500 });
      if (res.status === 200) {
        cachedBaseUrl = candidate;
        return candidate;
      }
    } catch {}
  }

  const fallback = CANDIDATE_URLS[0];
  cachedBaseUrl = fallback;
  return fallback;
}

export const ApiService = {
  async fetchRecommendations(params: {
    destination: string;
    startLocation?: string;
    startLat?: number | null;
    startLon?: number | null;
    budget: number;
    durationHours: number;
    travelerCount: number;
    travelerType: string;
    interests: string[];
    preferences?: string;
    tripDate?: string;
    excludedCategories?: string[];
    topN?: number;
  }): Promise<RecommendationModel[]> {
    const activeBase = await resolveBaseUrl();
    const url = `${activeBase}/api/recommendations`;
    const payload = {
      destination: params.destination,
      start_location: params.startLocation,
      start_lat: params.startLat,
      start_lon: params.startLon,
      user_lat: params.startLat,
      user_lon: params.startLon,
      budget: params.budget,
      budget_inr: params.budget,
      duration_hours: params.durationHours,
      available_time_hours: params.durationHours,
      traveler_count: params.travelerCount,
      traveler_type: params.travelerType,
      group_type: params.travelerType,
      interests: params.interests,
      trip_date: params.tripDate,
      excluded_categories: params.excludedCategories || [],
      radius_km: 25.0,
      additional_preferences: params.preferences ? { notes: params.preferences } : {},
      top_n: params.topN || 50,
    };

    try {
      const response = await axios.post(url, payload, { timeout: API_TIMEOUT });
      const data = response.data;
      if (data?.success && Array.isArray(data.recommendations)) {
        let items: RecommendationModel[] = data.recommendations.map((item: any) => ({
          experienceId: item.experience_id || item.id || '',
          name: item.experience_name || item.name || 'Local Experience',
          imageUrl: item.image_url || item.image,
          image: item.image_url || item.image || '/assets/images/destinations/food_trail.png',
          category: item.category || 'Local Experience',
          subCategory: item.sub_category,
          location: item.location || item.city || params.destination,
          city: item.city || params.destination,
          durationMinutes: Number(item.duration_minutes) || (Number(item.duration_hours) || 1) * 60,
          durationHours: Number(item.duration_hours) || 1.0,
          price: Number(item.price_inr ?? item.price ?? 250),
          priceInr: Number(item.price_inr ?? item.price ?? 250),
          rating: Number(item.rating ?? 4.8),
          reviewCount: Number(item.review_count ?? 120),
          reason: item.reason || 'Recommended based on your preferences',
          score: Number(item.score ?? item.recommendation_score ?? 0.9),
          recommendationScore: Number(item.recommendation_score ?? item.score ?? 0.9),
          latitude: item.latitude != null ? Number(item.latitude) : null,
          longitude: item.longitude != null ? Number(item.longitude) : null,
          tags: Array.isArray(item.tags) ? item.tags.join('; ') : item.tags,
          bestFor: item.best_for,
          distanceKm: item.distance_km != null ? Number(item.distance_km) : null,
          localExperience: item.local_experience ?? true,
          hiddenGem: item.hidden_gem ?? false,
          indoorOutdoor: item.indoor_outdoor || 'Flexible',
          bookingRequired: item.booking_required ?? false,
        }));

        if (params.excludedCategories && params.excludedCategories.length > 0) {
          items = items.filter((item) => {
            const combined = `${item.category} ${item.subCategory || ''} ${item.name} ${item.tags || ''}`.toLowerCase();
            return !params.excludedCategories!.some((ex) => combined.includes(ex.toLowerCase()));
          });
        }
        return items;
      }
    } catch (e) {
      console.warn('ApiService.fetchRecommendations error:', e);
    }

    return buildFallbackRecommendations(params.destination, params.interests, params.budget, params.excludedCategories);
  },

  async smartSearch(params: {
    query: string;
    userLat?: number | null;
    userLon?: number | null;
    city?: string;
  }): Promise<{
    success: boolean;
    parsedIntent: Record<string, any>;
    recommendations: RecommendationModel[];
  }> {
    const activeBase = await resolveBaseUrl();
    const url = `${activeBase}/api/recommendations/smart-search`;
    const payload = {
      query: params.query,
      user_lat: params.userLat,
      user_lon: params.userLon,
      city: params.city,
    };

    try {
      const response = await axios.post(url, payload, { timeout: API_TIMEOUT });
      const data = response.data;
      if (data?.parsed_intent) {
        const rawRecs = data.recommendations || [];
        const recs: RecommendationModel[] = rawRecs.map((item: any) => ({
          experienceId: item.experience_id || item.id || '',
          name: item.experience_name || item.name || 'Local Experience',
          imageUrl: item.image_url || item.image,
          image: item.image_url || item.image || '/assets/images/destinations/food_trail.png',
          category: item.category || 'Local Experience',
          subCategory: item.sub_category,
          location: item.location || item.city || 'Local',
          city: item.city || 'Local',
          durationMinutes: Number(item.duration_minutes) || (Number(item.duration_hours) || 1) * 60,
          durationHours: Number(item.duration_hours) || 1.0,
          price: Number(item.price_inr ?? item.price ?? 250),
          priceInr: Number(item.price_inr ?? item.price ?? 250),
          rating: Number(item.rating ?? 4.8),
          reviewCount: Number(item.review_count ?? 120),
          reason: item.reason || 'Recommended based on your smart search',
          score: Number(item.score ?? 0.9),
          recommendationScore: Number(item.score ?? 0.9),
          latitude: item.latitude != null ? Number(item.latitude) : null,
          longitude: item.longitude != null ? Number(item.longitude) : null,
          tags: item.tags,
          bestFor: item.best_for,
          distanceKm: item.distance_km != null ? Number(item.distance_km) : null,
          localExperience: true,
          hiddenGem: false,
          indoorOutdoor: 'Flexible',
          bookingRequired: false,
        }));
        return {
          success: true,
          parsedIntent: data.parsed_intent,
          recommendations: recs,
        };
      }
    } catch (e) {
      console.warn('ApiService.smartSearch error:', e);
    }

    return {
      success: false,
      parsedIntent: {},
      recommendations: [],
    };
  },

  async generateItinerary(params: {
    destination: string;
    tripDate: string;
    startTime: string;
    durationHours: number;
    budget: number;
    startLocation?: string;
    startLat?: number | null;
    startLon?: number | null;
    selectedExperienceIds: string[];
    selectedPlacesModels?: RecommendationModel[];
    travelerCount: number;
    travelerType: string;
    weatherCondition?: string;
  }): Promise<Itinerary> {
    const activeBase = await resolveBaseUrl();
    const url = `${activeBase}/api/itinerary/generate`;
    const payload = {
      destination: params.destination,
      trip_date: params.tripDate,
      start_time: params.startTime,
      duration_hours: params.durationHours,
      available_time_hours: params.durationHours,
      budget: params.budget,
      budget_inr: params.budget,
      start_location: params.startLocation,
      start_lat: params.startLat,
      start_lon: params.startLon,
      user_lat: params.startLat,
      user_lon: params.startLon,
      selected_experience_ids: params.selectedExperienceIds,
      traveler_count: params.travelerCount,
      traveler_type: params.travelerType,
      group_type: params.travelerType,
      ...(params.weatherCondition ? { weather_condition: params.weatherCondition } : {}),
    };

    try {
      const response = await axios.post(url, payload, { timeout: API_TIMEOUT });
      const data = response.data;
      if (data?.success) {
        const rawStops = data.scheduled_experiences || [];
        const items: ItineraryItem[] = rawStops.map((s: any) => ({
          id: s.id || s.experience_id || '',
          experienceName: s.experience_name || s.name || 'Experience',
          category: s.category || 'Local Experience',
          location: s.location || '',
          description: s.description || '',
          startTime: s.startTime || s.start_time || '',
          endTime: s.endTime || s.end_time || '',
          durationMinutes: Number(s.duration_minutes ?? s.durationMinutes ?? 60),
          price: Number(s.price_inr ?? s.price ?? 0),
          distanceKm: Number(s.distance_km ?? s.distanceKm ?? 1.5),
          image: s.image_url || s.image || '/assets/images/destinations/food_trail.png',
          isCompleted: Boolean(s.isCompleted),
          isSelected: s.isSelected ?? true,
          requiresBooking: Boolean(s.requiresBooking || s.booking_required),
          rating: Number(s.rating ?? 4.8),
          iconType: s.iconType || 'experience',
          travelToNextMinutes: Number(s.travel_to_next_minutes ?? s.travelToNextMinutes ?? 0),
          travelToNextDistanceKm: Number(s.travel_to_next_distance_km ?? s.travelToNextDistanceKm ?? 0),
          latitude: s.latitude != null ? Number(s.latitude) : null,
          longitude: s.longitude != null ? Number(s.longitude) : null,
          dwellDurationMinutes: Number(s.dwellDurationMinutes ?? 0),
          arrivedWithinProximity: Boolean(s.arrivedWithinProximity),
        }));

        const rawSkipped = data.skipped_experiences || [];
        const skipped: SkippedExperienceItem[] = rawSkipped.map((sk: any) => ({
          experienceId: sk.experience_id || '',
          name: sk.name || '',
          reason: sk.reason || 'Insufficient time',
        }));

        return {
          id: `itin-${Date.now()}`,
          destination: data.destination || params.destination,
          displayAddress: params.startLocation || params.destination,
          tripDate: data.trip_date || params.tripDate,
          startTime: data.start_time || params.startTime,
          endTime: data.end_time || '05:00 PM',
          startLat: data.start_lat ?? params.startLat,
          startLon: data.start_lon ?? params.startLon,
          totalDurationMinutes: Number(data.total_duration_minutes ?? 360),
          totalEstimatedCost: Number(data.total_experience_cost ?? params.budget),
          estimatedTransportCost: Number(data.estimated_transport_cost ?? 100),
          budgetExceeded: Boolean(data.budget_exceeded),
          budgetWarning: data.budget_warning,
          items,
          skippedExperiences: skipped,
          createdAt: new Date().toISOString(),
          hasRideAttached: false,
          nugen: data.nugen,
        };
      }
    } catch (e) {
      console.warn('ApiService.generateItinerary error:', e);
    }

    return buildFallbackItinerary(params);
  },

  async optimizeItinerary(itinerary: Itinerary): Promise<Itinerary> {
    const activeBase = await resolveBaseUrl();
    const url = `${activeBase}/api/itinerary/optimize`;
    const selectedIds = itinerary.items.map((i) => i.id);

    const payload = {
      destination: itinerary.destination,
      trip_date: itinerary.tripDate,
      start_time: itinerary.startTime,
      budget: itinerary.totalEstimatedCost,
      budget_inr: itinerary.totalEstimatedCost,
      start_lat: itinerary.startLat,
      start_lon: itinerary.startLon,
      user_lat: itinerary.startLat,
      user_lon: itinerary.startLon,
      selected_experience_ids: selectedIds,
      scheduled_experiences: itinerary.items,
    };

    try {
      const response = await axios.post(url, payload, { timeout: API_TIMEOUT });
      const data = response.data;
      if (data?.success && Array.isArray(data.scheduled_experiences)) {
        const items: ItineraryItem[] = data.scheduled_experiences.map((s: any) => ({
          id: s.id || s.experience_id || '',
          experienceName: s.experience_name || s.name || '',
          category: s.category || 'Local Experience',
          location: s.location || '',
          description: s.description || '',
          startTime: s.startTime || s.start_time || '',
          endTime: s.endTime || s.end_time || '',
          durationMinutes: Number(s.duration_minutes ?? s.durationMinutes ?? 60),
          price: Number(s.price_inr ?? s.price ?? 0),
          distanceKm: Number(s.distance_km ?? s.distanceKm ?? 1.5),
          image: s.image_url || s.image || '/assets/images/destinations/food_trail.png',
          isCompleted: Boolean(s.isCompleted),
          isSelected: true,
          requiresBooking: Boolean(s.requiresBooking),
          rating: Number(s.rating ?? 4.8),
          iconType: s.iconType || 'experience',
          travelToNextMinutes: Number(s.travel_to_next_minutes ?? 0),
          travelToNextDistanceKm: Number(s.travel_to_next_distance_km ?? 0),
          latitude: s.latitude != null ? Number(s.latitude) : null,
          longitude: s.longitude != null ? Number(s.longitude) : null,
          dwellDurationMinutes: Number(s.dwellDurationMinutes ?? 0),
          arrivedWithinProximity: Boolean(s.arrivedWithinProximity),
        }));

        return {
          ...itinerary,
          items,
          startTime: data.start_time || itinerary.startTime,
          endTime: data.end_time || itinerary.endTime,
          totalDurationMinutes: Number(data.total_duration_minutes ?? itinerary.totalDurationMinutes),
          totalEstimatedCost: Number(data.total_experience_cost ?? itinerary.totalEstimatedCost),
          estimatedTransportCost: Number(data.estimated_transport_cost ?? itinerary.estimatedTransportCost),
        };
      }
    } catch (e) {
      console.warn('ApiService.optimizeItinerary error:', e);
    }

    // Local spatial TSP sort fallback
    const sorted = [...itinerary.items].sort((a, b) => a.distanceKm - b.distanceKm);
    return { ...itinerary, items: sorted };
  },

  async saveItineraryToDatabase(itinerary: Itinerary): Promise<boolean> {
    try {
      const activeBase = await resolveBaseUrl();
      const url = `${activeBase}/api/itinerary/save`;
      await axios.post(
        url,
        {
          itinerary_id: itinerary.id,
          destination: itinerary.destination,
          trip_date: itinerary.tripDate,
          start_time: itinerary.startTime,
          end_time: itinerary.endTime,
          start_lat: itinerary.startLat,
          start_lon: itinerary.startLon,
          start_location: itinerary.displayAddress,
          total_duration_minutes: itinerary.totalDurationMinutes,
          total_cost: itinerary.totalEstimatedCost,
          total_experience_cost: itinerary.items.reduce((acc, i) => acc + (i.isSelected ? i.price : 0), 0),
          estimated_transport_cost: itinerary.estimatedTransportCost,
          scheduled_experiences: itinerary.items,
          items: itinerary.items,
        },
        { timeout: API_TIMEOUT }
      );
      return true;
    } catch {
      return true; // Graceful local fallback
    }
  },
};

// ------------------------------------------------------------------------------
// Fallback Builders (Identical to Dart implementation in traveler-app)
// ------------------------------------------------------------------------------

export function buildFallbackRecommendations(
  destination: string,
  interests: string[],
  budget: number,
  excludedCategories?: string[]
): RecommendationModel[] {
  const dest = destination.trim() || 'Mumbai';
  const allItems: RecommendationModel[] = [
    {
      experienceId: 'EXP-BEACH-001',
      name: 'Kashid Beach Watersports & Coastal Walk',
      category: 'Nature',
      subCategory: 'Beach',
      tags: 'beach; coastal; water sports; white sand',
      location: `${dest} Coastal Strip`,
      city: dest,
      durationMinutes: 120,
      durationHours: 2.0,
      price: 450,
      rating: 4.8,
      reviewCount: 380,
      reason: 'Beautiful white sand beach with water sports and scenic coastal walk',
      score: 0.95,
      image: '/assets/images/destinations/beach_cafe.png',
      latitude: 18.91,
      longitude: 72.9,
      localExperience: true,
      hiddenGem: false,
      indoorOutdoor: 'Outdoor',
      bookingRequired: false,
    },
    {
      experienceId: 'EXP-BEACH-002',
      name: 'Alibag Beach Sunset & Sea Breeze',
      category: 'Beach',
      subCategory: 'Beach Walk',
      tags: 'beach; sunset; coastal; sea view',
      location: `${dest} Beachfront`,
      city: dest,
      durationMinutes: 90,
      durationHours: 1.5,
      price: 200,
      rating: 4.7,
      reviewCount: 420,
      reason: 'Iconic beach walk with views of historic sea fort at low tide',
      score: 0.92,
      image: '/assets/images/destinations/beach_cafe.png',
      latitude: 18.64,
      longitude: 72.87,
      localExperience: true,
      hiddenGem: false,
      indoorOutdoor: 'Outdoor',
      bookingRequired: false,
    },
    {
      experienceId: 'EXP-FOOD-001',
      name: 'Authentic Local Breakfast & Chai Walk',
      category: 'Food',
      subCategory: 'Food Walk',
      tags: 'food; breakfast; chai; street food; local cuisine',
      location: `${dest} Market`,
      city: dest,
      durationMinutes: 60,
      durationHours: 1.0,
      price: 250,
      rating: 4.9,
      reviewCount: 620,
      reason: 'Matches your food interest with legendary regional breakfast spots',
      score: 0.93,
      image: '/assets/images/destinations/food_trail.png',
      latitude: 18.995,
      longitude: 73.12,
      localExperience: true,
      hiddenGem: true,
      indoorOutdoor: 'Sheltered',
      bookingRequired: false,
    },
    {
      experienceId: 'EXP-FOOD-002',
      name: 'Coastal Seafood Tasting Masterclass',
      category: 'Food',
      subCategory: 'Seafood',
      tags: 'food; seafood; coastal; tasting; culinary',
      location: `${dest} Harbor`,
      city: dest,
      durationMinutes: 90,
      durationHours: 1.5,
      price: 550,
      rating: 4.9,
      reviewCount: 410,
      reason: 'Delicious coastal delicacies prepared by authentic local chefs',
      score: 0.91,
      image: '/assets/images/destinations/food_trail.png',
      latitude: 18.99,
      longitude: 73.115,
      localExperience: true,
      hiddenGem: true,
      indoorOutdoor: 'Sheltered',
      bookingRequired: true,
    },
    {
      experienceId: 'EXP-ADV-001',
      name: 'Cliffside Rock Climbing & Rappelling',
      category: 'Adventure',
      subCategory: 'Climbing',
      tags: 'adventure; climbing; rappelling; trekking; outdoor',
      location: `${dest} Valley`,
      city: dest,
      durationMinutes: 120,
      durationHours: 2.0,
      price: 800,
      rating: 4.8,
      reviewCount: 290,
      reason: 'Thrilling outdoor adventure with certified local instructors',
      score: 0.9,
      image: '/assets/images/destinations/waterfall.png',
      latitude: 19.02,
      longitude: 73.14,
      localExperience: true,
      hiddenGem: false,
      indoorOutdoor: 'Outdoor',
      bookingRequired: true,
    },
    {
      experienceId: 'EXP-HER-001',
      name: 'Heritage Fortress & Walk',
      category: 'Heritage',
      subCategory: 'Historic Fort',
      tags: 'heritage; fort; history; architecture; monument',
      location: `${dest} Old Quarter`,
      city: dest,
      durationMinutes: 90,
      durationHours: 1.5,
      price: 350,
      rating: 4.8,
      reviewCount: 450,
      reason: 'Top-rated historical landmark matching your heritage interest',
      score: 0.94,
      image: '/assets/images/destinations/heritage_walk.png',
      latitude: 18.9894,
      longitude: 73.1175,
      localExperience: true,
      hiddenGem: false,
      indoorOutdoor: 'Outdoor',
      bookingRequired: false,
    },
    {
      experienceId: 'EXP-CUL-001',
      name: 'Artisan Workshop & Crafts',
      category: 'Culture',
      subCategory: 'Workshop',
      tags: 'culture; workshop; handicraft; artisan',
      location: `${dest} Craft Village`,
      city: dest,
      durationMinutes: 75,
      durationHours: 1.25,
      price: 450,
      rating: 4.7,
      reviewCount: 280,
      reason: 'Interactive hands-on cultural workshop with master artisans',
      score: 0.89,
      image: '/assets/images/destinations/beach_cafe.png',
      latitude: 19.001,
      longitude: 73.125,
      localExperience: true,
      hiddenGem: true,
      indoorOutdoor: 'Sheltered',
      bookingRequired: false,
    },
    {
      experienceId: 'EXP-NAT-001',
      name: 'Scenic Valley Trail & Sunset View',
      category: 'Nature',
      subCategory: 'Viewpoint',
      tags: 'nature; valley; sunset; viewpoint; scenic',
      location: `${dest} Foothills`,
      city: dest,
      durationMinutes: 90,
      durationHours: 1.5,
      price: 200,
      rating: 4.9,
      reviewCount: 510,
      reason: 'Peaceful nature experience with panoramic sunset viewpoints',
      score: 0.9,
      image: '/assets/images/destinations/waterfall.png',
      latitude: 19.01,
      longitude: 73.13,
      localExperience: true,
      hiddenGem: false,
      indoorOutdoor: 'Outdoor',
      bookingRequired: false,
    },
  ];

  let filtered = allItems;
  if (interests.length > 0) {
    const matches = allItems.filter((item) => {
      const combined = `${item.category} ${item.subCategory || ''} ${item.name} ${item.tags || ''}`.toLowerCase();
      return interests.some((intr) => combined.includes(intr.toLowerCase()));
    });
    if (matches.length > 0) filtered = matches;
  }

  if (excludedCategories && excludedCategories.length > 0) {
    filtered = filtered.filter((item) => {
      const combined = `${item.category} ${item.subCategory || ''} ${item.name} ${item.tags || ''}`.toLowerCase();
      return !excludedCategories.some((ex) => combined.includes(ex.toLowerCase()));
    });
  }

  return filtered;
}

export function buildFallbackItinerary(params: {
  destination: string;
  tripDate: string;
  startTime: string;
  durationHours: number;
  budget: number;
  startLat?: number | null;
  startLon?: number | null;
  selectedExperienceIds: string[];
  selectedPlacesModels?: RecommendationModel[];
}): Itinerary {
  let itemsToUse: RecommendationModel[] = [];

  if (params.selectedPlacesModels && params.selectedPlacesModels.length > 0) {
    itemsToUse = params.selectedPlacesModels;
  } else {
    const recs = buildFallbackRecommendations(params.destination, [], params.budget);
    const chosen = recs.filter((r) => params.selectedExperienceIds.includes(r.experienceId));
    itemsToUse = chosen.length > 0 ? chosen : recs.slice(0, 4);
  }

  let curHour = 10;
  let curMin = 30;
  const parts = params.startTime.replace(/[^\d:]/g, '').split(':');
  if (parts.length > 0) {
    curHour = parseInt(parts[0], 10) || 10;
    if (params.startTime.toUpperCase().includes('PM') && curHour < 12) curHour += 12;
    if (params.startTime.toUpperCase().includes('AM') && curHour === 12) curHour = 0;
    if (parts.length > 1) curMin = parseInt(parts[1], 10) || 30;
  }

  const items: ItineraryItem[] = [];
  let totalCost = 0;
  let totalMins = 0;
  const maxAllowedMins = Math.round(params.durationHours > 0 ? params.durationHours * 60 : 300);

  for (let i = 0; i < itemsToUse.length; i++) {
    const r = itemsToUse[i];
    const transitMins = items.length > 0 ? 15 : 0;
    if (items.length > 0 && totalMins + transitMins + r.durationMinutes > maxAllowedMins) {
      break;
    }

    const startStr = formatTime(curHour, curMin);
    curMin += r.durationMinutes;
    curHour += Math.floor(curMin / 60);
    curMin = curMin % 60;
    const endStr = formatTime(curHour, curMin);

    curMin += 15;
    curHour += Math.floor(curMin / 60);
    curMin = curMin % 60;

    items.push({
      id: r.experienceId,
      experienceName: r.name,
      category: r.category,
      location: r.location,
      description: r.reason,
      startTime: startStr,
      endTime: endStr,
      durationMinutes: r.durationMinutes,
      price: r.price,
      distanceKm: 2.5,
      image: r.image,
      isCompleted: false,
      isSelected: true,
      requiresBooking: r.bookingRequired,
      rating: r.rating ?? 4.8,
      iconType: 'experience',
      travelToNextMinutes: i < itemsToUse.length - 1 ? 15 : 0,
      travelToNextDistanceKm: i < itemsToUse.length - 1 ? 2.5 : 0.0,
      latitude: r.latitude ?? 18.9894,
      longitude: r.longitude ?? 73.1175,
      dwellDurationMinutes: 0,
      arrivedWithinProximity: false,
    });

    totalCost += r.price;
    totalMins += r.durationMinutes + transitMins;
  }

  return {
    id: `itin-${Date.now()}`,
    destination: params.destination || 'Mumbai',
    displayAddress: params.destination || 'Mumbai',
    tripDate: params.tripDate,
    startTime: params.startTime,
    endTime: items.length > 0 ? items[items.length - 1].endTime : '05:00 PM',
    startLat: params.startLat ?? 18.9894,
    startLon: params.startLon ?? 73.1175,
    totalDurationMinutes: totalMins,
    totalEstimatedCost: totalCost,
    estimatedTransportCost: 120.0,
    budgetExceeded: false,
    items,
    skippedExperiences: [],
    createdAt: new Date().toISOString(),
    hasRideAttached: false,
  };
}

function formatTime(hour: number, minute: number): string {
  const period = hour >= 12 ? 'PM' : 'AM';
  const h = hour > 12 ? hour - 12 : hour === 0 ? 12 : hour;
  const m = minute.toString().padStart(2, '0');
  return `${h}:${m} ${period}`;
}
