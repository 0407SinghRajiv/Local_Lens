export type ExperienceCategory =
  | 'Heritage'
  | 'Culture & Arts'
  | 'Culinary & Food'
  | 'Nature & Adventure'
  | 'Wellness & Spiritual'
  | 'Nightlife & Social'
  | 'Workshops & Crafts';

export type IndoorOutdoorType = 'Indoor' | 'Outdoor' | 'Mixed';

export interface ExperienceListing {
  // ML Dataset Schema Identity
  experience_id: string;
  experience_name: string;
  category: ExperienceCategory;
  sub_category: string;
  tags: string[];
  local_experience_bool: boolean;
  hidden_gem_bool: boolean;

  // Geolocation
  latitude: number;
  longitude: number;
  city: string;
  district: string;
  state: string;
  region: string;

  // Logistics
  price_inr_clean: number;
  duration_hours_clean: number;
  min_group_size: number;
  max_group_size: number;
  booking_required_bool: boolean;
  advance_booking_days_clean: number;
  availability: string;

  // Adaptability & Accessibility
  indoor_outdoor_clean: IndoorOutdoorType;
  best_time: string;
  season: string;
  accessibility: string;

  // Media & Narrative
  images: string[];
  description: string;
  meeting_point: string;
  inclusions: string[];
  rules: string[];
  cancellation_policy: string;

  // Provider Platform Status
  status: 'active' | 'needs_improvement' | 'boosted' | 'paused';
  health_score: number; // 0 - 100
  boost_tier?: 'Weekend Spark' | 'Weekly Surge' | 'Season Push' | null;
  boost_expires_at?: string | null;
  earnings_generated_inr?: number;
  bookings_count?: number;
  rating?: number;
  review_count?: number;
}

export interface BoostPackage {
  id: string;
  name: 'Weekend Spark' | 'Weekly Surge' | 'Season Push';
  price: number;
  durationDays: number;
  multiplierText: string;
  description: string;
  recommendedFor: string;
}
