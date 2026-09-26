/**
 * Sponsor & Boost Campaign Types for LocalLens
 * Matches Supabase `sponsor_campaigns` schema and Traveler App contract
 */

export type SponsorType = "boost" | "banner" | "curated_story";
export type SponsorPackage = "spark" | "push" | "surge";
export type PaymentStatus = "pending" | "paid" | "failed" | "refunded";
export type CampaignStatus = "draft" | "scheduled" | "active" | "completed" | "expired";
export type OfferType = "percentage_discount" | "flat_discount" | "complimentary_drink" | "group_deal";

export interface SponsorCampaign {
  id: string;
  user_id: string;
  business_id?: string;
  listing_id: string;
  owner_name: string;
  shop_name: string;
  listing_name: string;
  sponsor_type: SponsorType;
  sponsor_package: string;
  amount: number;
  offer_type: OfferType;
  offer_value: number; // e.g. 20 for 20%
  offer_price: number; // e.g. 960
  offer_description: string; // e.g. "20% OFF Early Bird Special"
  start_at: string;
  end_at: string;
  timezone: string;
  payment_method: "upi" | "card" | "netbanking";
  payment_status: PaymentStatus;
  payment_transaction_id?: string;
  campaign_status: CampaignStatus;
  created_at: string;
  updated_at?: string;

  // Joined/Enriched Experience metadata for Traveler view
  experience_details?: {
    image_url: string;
    rating: number;
    review_count: number;
    location: string;
    city: string;
    original_price: number;
    category: string;
  };
}
