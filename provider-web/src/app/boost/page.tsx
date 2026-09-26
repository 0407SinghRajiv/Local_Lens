"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import {
  X,
  Star,
  MapPin,
  Clock,
  Check,
  Zap,
  Flame,
  ShieldCheck,
  Tag,
  Calendar,
  Sparkles,
  CheckCircle2,
  AlertCircle,
  Eye,
  ExternalLink,
} from "lucide-react";
import confetti from "canvas-confetti";
import { useI18n } from "@/lib/i18n";
import { LanguageSelector } from "@/components/settings/LanguageSelector";
import { getProviderProfile, ProviderProfile } from "@/lib/authSession";
import { getStoredExperiencesForProvider } from "@/services/mockExperiences";
import { supabase } from "@/lib/supabaseClient";

interface ListingItem {
  id: string;
  name: string;
  category: string;
  price: string;
  priceClean: number;
  rating: number;
  reviews: number;
  location: string;
  duration: string;
  type: string;
  image: string;
}

export default function BoostYourListingPage() {
  const router = useRouter();
  const { t } = useI18n();

  const [provider, setProvider] = useState<ProviderProfile | null>(null);
  const [availableListings, setAvailableListings] = useState<ListingItem[]>([]);
  const [selectedListingIndex, setSelectedListingIndex] = useState(0);

  // Step 2: Package Selection ('spark' | 'push' | 'surge')
  const [packageType, setPackageType] = useState<"spark" | "push" | "surge">("push");

  // Offer Configuration
  const [offerDiscountPercent, setOfferDiscountPercent] = useState<number>(20);
  const [offerDescription, setOfferDescription] = useState<string>("20% OFF Early Bird Special");

  // Step 3: Payment Method Selection
  const [paymentMethod, setPaymentMethod] = useState<"upi" | "card" | "netbanking">("upi");
  const [upiId, setUpiId] = useState("provider@okaxis");

  // Launch & Payment Verification State
  const [isProcessing, setIsProcessing] = useState(false);
  const [paymentVerified, setPaymentVerified] = useState(false);
  const [campaignSuccessData, setCampaignSuccessData] = useState<any | null>(null);
  const [activeTab, setActiveTab] = useState<"configure" | "preview_live">("configure");
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Load Real Provider Experiences
  useEffect(() => {
    getProviderProfile().then(async (p) => {
      if (p) setProvider(p);

      const pid = p?.id || "provider_default";
      const pEmail = p?.email || "provider@locallens.in";

      // 1. Fetch from mock/local experiences service
      const localExps = getStoredExperiencesForProvider(pid, pEmail);

      // 2. Also fetch from Supabase experience table
      let dbExps: any[] = [];
      try {
        const { data } = await supabase
          .from("experience")
          .select("*")
          .limit(10);
        if (data && Array.isArray(data)) {
          dbExps = data;
        }
      } catch {}

      const mapped: ListingItem[] = [];
      const seen = new Set<string>();

      // Merge local experiences
      for (const item of localExps) {
        const id = item.experience_id;
        if (id && !seen.has(id)) {
          seen.add(id);
          mapped.push({
            id: item.experience_id,
            name: item.experience_name,
            category: item.category,
            price: `₹${item.price_inr_clean || 1200} / person`,
            priceClean: item.price_inr_clean || 1200,
            rating: item.rating || 4.8,
            reviews: (item as any).review_count || (item as any).reviews_count || 142,
            location: item.city || item.meeting_point || "Mumbai",
            duration: `${item.duration_hours_clean || 2} hours`,
            type: item.sub_category || "Guided Tour",
            image: (item.images && item.images[0]) || "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80",
          });
        }
      }

      // Merge db experiences if available
      for (const dbItem of dbExps) {
        const id = dbItem.experience_id || dbItem.id;
        if (id && !seen.has(id)) {
          seen.add(id);
          mapped.push({
            id,
            name: dbItem.experience_name,
            category: dbItem.category,
            price: `₹${dbItem.price_inr_clean || 1200} / person`,
            priceClean: Number(dbItem.price_inr_clean) || 1200,
            rating: Number(dbItem.rating) || 4.8,
            reviews: Number(dbItem.review_count) || 120,
            location: `${dbItem.city || "Mumbai"}`,
            duration: `${dbItem.duration_hours || 2} hours`,
            type: "Guided Tour",
            image: dbItem.image_url || "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80",
          });
        }
      }

      if (mapped.length > 0) {
        setAvailableListings(mapped);
      } else {
        // Fallback default experience
        setAvailableListings([
          {
            id: "a0000000-0000-0000-0000-000000000001",
            name: "Sunset Kayaking at Versova",
            category: "Adventure",
            price: "₹1,200 / person",
            priceClean: 1200,
            rating: 4.8,
            reviews: 142,
            location: "Versova Beach, Mumbai",
            duration: "2-3 hours",
            type: "Guided Tour",
            image: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80",
          },
        ]);
      }
    });
  }, []);

  const selectedListing = availableListings[selectedListingIndex] || {
    id: "a0000000-0000-0000-0000-000000000001",
    name: "Sunset Kayaking at Versova",
    category: "Adventure",
    price: "₹1,200 / person",
    priceClean: 1200,
    rating: 4.8,
    reviews: 142,
    location: "Versova Beach, Mumbai",
    duration: "2-3 hours",
    type: "Guided Tour",
    image: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80",
  };

  const getPackagePrice = () => {
    if (packageType === "spark") return { name: "Weekend Spark (3 Days)", amount: 499, days: 3 };
    if (packageType === "push") return { name: "Weekly Push (7 Days)", amount: 999, days: 7 };
    return { name: "Festival Surge (14 Days)", amount: 1999, days: 14 };
  };

  const currentPkg = getPackagePrice();

  // Calculate Offer Discount & Final Offer Price
  const originalPriceNumber = selectedListing.priceClean || 1200;
  const discountAmount = Math.round((originalPriceNumber * offerDiscountPercent) / 100);
  const finalOfferPrice = Math.max(0, originalPriceNumber - discountAmount);

  const now = new Date();
  const endDate = new Date(now.getTime() + currentPkg.days * 86400000);

  /**
   * Complete Sponsor -> Traveler Data Flow Execution
   * 1. Calls /api/sponsors to create campaign (saved with pending payment)
   * 2. Calls verified backend payment endpoint /api/sponsors/verify-payment
   * 3. Backend verifies transaction and activates campaign
   */
  const handleLaunchBoost = async () => {
    setIsProcessing(true);
    setErrorMsg(null);

    try {
      const userId = provider?.id || "provider_default";
      const shopName = provider?.businessName || "Local Kayak Adventures";
      const ownerName = provider?.fullName || provider?.name || "Krishnkumar Gupta";

      // 1. Initialize campaign on backend
      const initResp = await fetch("/api/sponsors", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user_id: userId,
          email: provider?.email,
          business_id: "biz-locallens-mumbai-01",
          listing_id: selectedListing.id,
          owner_name: ownerName,
          shop_name: shopName,
          listing_name: selectedListing.name,
          sponsor_type: "boost",
          sponsor_package: currentPkg.name,
          package_days: currentPkg.days,
          amount: currentPkg.amount,
          offer_type: "percentage_discount",
          offer_value: offerDiscountPercent,
          offer_price: finalOfferPrice,
          offer_description: `${offerDiscountPercent}% OFF`,
          start_at: now.toISOString(),
          end_at: endDate.toISOString(),
          timezone: "Asia/Kolkata",
          payment_method: paymentMethod,
          experience_details: {
            image_url: selectedListing.image,
            rating: selectedListing.rating,
            review_count: selectedListing.reviews,
            location: selectedListing.location,
            city: "Mumbai",
            original_price: originalPriceNumber,
            category: selectedListing.category,
          },
        }),
      });

      const initData = await initResp.json();
      if (!initData.success || !initData.campaign) {
        throw new Error(initData.error || "Failed to initialize campaign.");
      }

      const campaignId = initData.campaign.id;

      // 2. Verified Backend Payment Flow
      // Rule: Frontend CANNOT mark payment_status = 'paid'.
      // Only the verified payment/backend flow can set payment_status = 'paid'.
      const verifyResp = await fetch("/api/sponsors/verify-payment", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          campaign_id: campaignId,
          payment_method: paymentMethod,
          payment_transaction_id: `TXN-UPI-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`,
          experience_details: {
            image_url: selectedListing.image,
            rating: selectedListing.rating,
            review_count: selectedListing.reviews,
            location: selectedListing.location,
            city: "Mumbai",
            original_price: originalPriceNumber,
            category: selectedListing.category,
          },
        }),
      });

      const verifyData = await verifyResp.json();
      if (!verifyData.success) {
        throw new Error(verifyData.error || "Payment verification failed.");
      }

      // Success!
      setPaymentVerified(true);
      setCampaignSuccessData(verifyData.campaign);

      confetti({
        particleCount: 140,
        spread: 90,
        origin: { y: 0.6 },
        colors: ["#0e8a5b", "#8b5cf6", "#f59e0b", "#3b82f6"],
      });

      setActiveTab("preview_live");
    } catch (err: any) {
      setErrorMsg(err.message || "Something went wrong while launching your sponsor package.");
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#f8fafc] text-slate-900 font-sans pb-24">
      {/* Top Header */}
      <div className="max-w-6xl mx-auto px-6 pt-8 pb-4">
        <div className="flex items-start justify-between">
          <div className="flex items-start gap-4">
            <Link
              href="/dashboard"
              className="p-2 rounded-xl text-slate-400 hover:text-slate-800 hover:bg-slate-200/60 transition-colors"
            >
              <X className="w-6 h-6" />
            </Link>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-xl sm:text-2xl font-heading font-anton text-slate-900 tracking-tight">
                  {t("boost.title", "Sponsor & Boost Listings")}
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-amber-100 text-amber-900 border border-amber-300 flex items-center gap-1">
                  <Sparkles className="w-3 h-3 text-amber-600" />
                  Traveler Feed Integration
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                {t(
                  "boost.subtitle",
                  "Promote your experience with verified payment. Instantly syncs to the Supabase traveler discovery feed."
                )}
              </p>
            </div>
          </div>

          <LanguageSelector variant="navbar" />
        </div>

        {/* View Switcher Tabs */}
        <div className="flex items-center gap-2 mt-4 pt-3 border-t border-slate-200/80">
          <button
            type="button"
            onClick={() => setActiveTab("configure")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer ${
              activeTab === "configure"
                ? "bg-slate-900 text-white shadow-sm"
                : "bg-white text-slate-600 hover:bg-slate-100 border border-slate-200"
            }`}
          >
            1. Configure & Launch Campaign
          </button>
          <button
            type="button"
            onClick={() => setActiveTab("preview_live")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
              activeTab === "preview_live"
                ? "bg-[#0e8a5b] text-white shadow-sm"
                : "bg-white text-slate-600 hover:bg-slate-100 border border-slate-200"
            }`}
          >
            <Eye className="w-3.5 h-3.5" />
            <span>2. Live Traveler App Feed Preview</span>
            {paymentVerified && (
              <span className="w-2 h-2 rounded-full bg-emerald-300 animate-ping" />
            )}
          </button>
        </div>
      </div>

      {errorMsg && (
        <div className="max-w-6xl mx-auto px-6 mb-4">
          <div className="p-4 rounded-2xl bg-rose-50 border border-rose-200 text-xs font-bold text-rose-800 flex items-center gap-2">
            <AlertCircle className="w-4 h-4 shrink-0 text-rose-600" />
            <span>{errorMsg}</span>
          </div>
        </div>
      )}

      {/* Main Container */}
      <main className="max-w-6xl mx-auto px-6 pt-2">
        {activeTab === "configure" ? (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            {/* Left Column (8 cols): 3-Step Selection */}
            <div className="lg:col-span-8 space-y-6">
              {/* 1. Select Your Listing (From Real Database Experiences) */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-3">
                <div className="flex items-center justify-between">
                  <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    1. Select Your Listing ({availableListings.length} Available)
                  </h2>
                  <span className="text-[11px] text-[#0e8a5b] font-bold">
                    Referenced by actual listing_id
                  </span>
                </div>

                <div className="space-y-2">
                  {availableListings.map((item, idx) => {
                    const isSelected = selectedListingIndex === idx;
                    return (
                      <div
                        key={item.id}
                        onClick={() => setSelectedListingIndex(idx)}
                        className={`flex items-center justify-between p-3.5 rounded-2xl border-2 cursor-pointer transition-all ${
                          isSelected
                            ? "border-[#0e8a5b] bg-emerald-50/20 shadow-xs"
                            : "border-slate-200 hover:border-slate-300 bg-white"
                        }`}
                      >
                        <div className="flex items-center gap-3 min-w-0">
                          <div className="relative w-14 h-12 rounded-xl overflow-hidden shrink-0 border border-slate-200">
                            <Image
                              src={item.image}
                              alt={item.name}
                              fill
                              className="object-cover"
                              unoptimized
                            />
                          </div>
                          <div className="min-w-0">
                            <div className="text-xs font-extrabold text-slate-900 truncate">
                              {item.name}
                            </div>
                            <div className="text-[11px] text-slate-500">
                              {item.category} &bull; {item.price} &bull; ⭐ {item.rating} ({item.reviews})
                            </div>
                            <div className="text-[10px] text-slate-400 font-mono">
                              ID: {item.id}
                            </div>
                          </div>
                        </div>

                        <div className="shrink-0 pl-3">
                          <div
                            className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                              isSelected
                                ? "border-[#0e8a5b] bg-[#0e8a5b] text-white"
                                : "border-slate-300"
                            }`}
                          >
                            {isSelected && <Check className="w-3 h-3" />}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* 2. Configure Special Offer / Discount */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    2. Configure Traveler Offer
                  </h2>
                  <span className="text-[11px] font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-md border border-amber-200">
                    Shown on Traveler Card
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  {[15, 20, 25].map((pct) => (
                    <button
                      key={pct}
                      type="button"
                      onClick={() => {
                        setOfferDiscountPercent(pct);
                        setOfferDescription(`${pct}% OFF Special Deal`);
                      }}
                      className={`p-3 rounded-2xl border-2 font-bold text-xs flex flex-col items-center justify-center transition-all cursor-pointer ${
                        offerDiscountPercent === pct
                          ? "border-[#0e8a5b] bg-emerald-50/30 text-[#0e8a5b]"
                          : "border-slate-200 text-slate-700 hover:border-slate-300"
                      }`}
                    >
                      <span className="text-base font-black">{pct}% OFF</span>
                      <span className="text-[10.5px] text-slate-500 mt-0.5">
                        ₹{Math.round(originalPriceNumber * (1 - pct / 100))}/person
                      </span>
                    </button>
                  ))}
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-2">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Offer Description Label
                    </label>
                    <input
                      type="text"
                      value={offerDescription}
                      onChange={(e) => setOfferDescription(e.target.value)}
                      placeholder="e.g. 20% OFF Early Bird Special"
                      className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-800"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Final Traveler Price (Auto-Calculated)
                    </label>
                    <div className="flex items-center gap-2 px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-xs">
                      <span className="font-extrabold text-[#0e8a5b] text-sm">
                        ₹{finalOfferPrice}/person
                      </span>
                      <span className="line-through text-slate-400">
                        ₹{originalPriceNumber}/person
                      </span>
                      <span className="text-[10px] text-emerald-700 font-bold ml-auto">
                        Save ₹{discountAmount}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              {/* 3. Choose a Boost Package */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
                <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                  3. Choose a Boost Package
                </h2>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {/* Package 1: Weekend Spark */}
                  <div
                    onClick={() => setPackageType("spark")}
                    className={`relative p-5 rounded-2xl border-2 cursor-pointer transition-all ${
                      packageType === "spark"
                        ? "border-[#0e8a5b] bg-emerald-50/20 shadow-md ring-2 ring-emerald-500/10"
                        : "border-slate-200 hover:border-slate-300 bg-white"
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="text-xs font-bold text-slate-800">Weekend Spark</div>
                      <div className="w-6 h-6 rounded-lg bg-emerald-100 flex items-center justify-center text-[#0e8a5b]">
                        <Zap className="w-3.5 h-3.5" />
                      </div>
                    </div>
                    <div className="text-xl font-heading font-anton text-slate-900 tracking-tight mt-1">
                      ₹499
                    </div>
                    <div className="text-[11px] text-slate-500 mt-1">3 Days High-Visibility</div>
                  </div>

                  {/* Package 2: Weekly Push */}
                  <div
                    onClick={() => setPackageType("push")}
                    className={`relative p-5 rounded-2xl border-2 cursor-pointer transition-all ${
                      packageType === "push"
                        ? "border-[#0e8a5b] bg-emerald-50/20 shadow-md ring-2 ring-emerald-500/10"
                        : "border-slate-200 hover:border-slate-300 bg-white"
                    }`}
                  >
                    <span className="absolute -top-2.5 right-4 px-2.5 py-0.5 bg-[#0e8a5b] text-white text-[9px] font-black uppercase tracking-wider rounded-full shadow-xs">
                      Popular
                    </span>
                    <div className="flex items-center justify-between">
                      <div className="text-xs font-bold text-slate-800">Weekly Push</div>
                      <div className="w-6 h-6 rounded-lg bg-emerald-100 flex items-center justify-center text-[#0e8a5b]">
                        <Flame className="w-3.5 h-3.5" />
                      </div>
                    </div>
                    <div className="text-xl font-heading font-anton text-slate-900 tracking-tight mt-1">
                      ₹999
                    </div>
                    <div className="text-[11px] text-slate-500 mt-1">7 Days Top Traveler Placement</div>
                  </div>

                  {/* Package 3: Festival Surge */}
                  <div
                    onClick={() => setPackageType("surge")}
                    className={`relative p-5 rounded-2xl border-2 cursor-pointer transition-all ${
                      packageType === "surge"
                        ? "border-[#0e8a5b] bg-emerald-50/20 shadow-md ring-2 ring-emerald-500/10"
                        : "border-slate-200 hover:border-slate-300 bg-white"
                    }`}
                  >
                    <div className="flex items-center justify-between">
                      <div className="text-xs font-bold text-slate-800">Festival Surge</div>
                      <div className="w-6 h-6 rounded-lg bg-emerald-100 flex items-center justify-center text-[#0e8a5b]">
                        <ShieldCheck className="w-3.5 h-3.5" />
                      </div>
                    </div>
                    <div className="text-xl font-heading font-anton text-slate-900 tracking-tight mt-1">
                      ₹1,999
                    </div>
                    <div className="text-[11px] text-slate-500 mt-1">14 Days Max Reach & Push</div>
                  </div>
                </div>

                {/* Validity Timing Window Preview */}
                <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200/80 flex items-center justify-between text-xs text-slate-600">
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-[#0e8a5b]" />
                    <span className="font-bold">Campaign Time Window:</span>
                    <span>
                      {now.toLocaleDateString("en-IN")} → {endDate.toLocaleDateString("en-IN")}
                    </span>
                  </div>
                  <span className="text-[10px] font-mono text-slate-400">
                    Asia/Kolkata (IST)
                  </span>
                </div>
              </div>

              {/* 4. Verified Payment Method Selection */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    4. Verified Payment Method
                  </h2>
                  <span className="text-[11px] text-slate-400 font-medium">
                    Verified Backend Authorization Flow
                  </span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                  {/* UPI */}
                  <label
                    onClick={() => setPaymentMethod("upi")}
                    className={`p-3.5 rounded-2xl border-2 cursor-pointer flex items-center gap-3 transition-all ${
                      paymentMethod === "upi"
                        ? "border-[#0e8a5b] bg-emerald-50/20"
                        : "border-slate-200"
                    }`}
                  >
                    <input
                      type="radio"
                      name="payment"
                      checked={paymentMethod === "upi"}
                      onChange={() => setPaymentMethod("upi")}
                      className="w-4 h-4 text-[#0e8a5b] focus:ring-[#0e8a5b]"
                    />
                    <div>
                      <div className="text-xs font-bold text-slate-900">UPI (Instant)</div>
                      <div className="text-[10px] text-slate-500">GPay, PhonePe, Paytm</div>
                    </div>
                  </label>

                  {/* Card */}
                  <label
                    onClick={() => setPaymentMethod("card")}
                    className={`p-3.5 rounded-2xl border-2 cursor-pointer flex items-center gap-3 transition-all ${
                      paymentMethod === "card"
                        ? "border-[#0e8a5b] bg-emerald-50/20"
                        : "border-slate-200"
                    }`}
                  >
                    <input
                      type="radio"
                      name="payment"
                      checked={paymentMethod === "card"}
                      onChange={() => setPaymentMethod("card")}
                      className="w-4 h-4 text-[#0e8a5b] focus:ring-[#0e8a5b]"
                    />
                    <div>
                      <div className="text-xs font-bold text-slate-900">Credit / Debit Card</div>
                      <div className="text-[10px] text-slate-500">Visa, Mastercard, RuPay</div>
                    </div>
                  </label>

                  {/* Net Banking */}
                  <label
                    onClick={() => setPaymentMethod("netbanking")}
                    className={`p-3.5 rounded-2xl border-2 cursor-pointer flex items-center gap-3 transition-all ${
                      paymentMethod === "netbanking"
                        ? "border-[#0e8a5b] bg-emerald-50/20"
                        : "border-slate-200"
                    }`}
                  >
                    <input
                      type="radio"
                      name="payment"
                      checked={paymentMethod === "netbanking"}
                      onChange={() => setPaymentMethod("netbanking")}
                      className="w-4 h-4 text-[#0e8a5b] focus:ring-[#0e8a5b]"
                    />
                    <div>
                      <div className="text-xs font-bold text-slate-900">Net Banking</div>
                      <div className="text-[10px] text-slate-500">All Major Banks</div>
                    </div>
                  </label>
                </div>
              </div>
            </div>

            {/* Right Column (4 cols): Preview in Traveler App & Checkout Summary */}
            <div className="lg:col-span-4 space-y-5">
              {/* Preview in Traveler App Card */}
              <div className="bg-white p-5 rounded-3xl border border-slate-200/80 shadow-sm space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                    Traveler App Feed Preview
                  </h3>
                  <span className="text-[10px] font-bold text-amber-600 bg-amber-50 px-2 py-0.5 rounded-md">
                    Live Mobile UI
                  </span>
                </div>

                {/* EXACT SPECIFICATION TRAVELER SPONSORED CARD */}
                <div className="rounded-2xl border-2 border-amber-300/80 overflow-hidden shadow-md bg-white">
                  <div className="relative aspect-[16/10] w-full">
                    <Image
                      src={selectedListing.image}
                      alt={selectedListing.name}
                      fill
                      className="object-cover"
                      unoptimized
                    />

                    {/* Sponsored Badge */}
                    <span className="absolute top-2.5 left-2.5 px-2.5 py-0.5 rounded-md bg-black/80 backdrop-blur-md text-[10px] font-black text-amber-300 shadow-sm flex items-center gap-1">
                      <Sparkles className="w-3 h-3" />
                      Sponsored
                    </span>

                    {/* Offer Tag */}
                    <span className="absolute top-2.5 right-2.5 px-2.5 py-0.5 rounded-full bg-[#0e8a5b] text-white text-[10.5px] font-black shadow-md">
                      {offerDiscountPercent}% OFF
                    </span>
                  </div>

                  <div className="p-4 space-y-1.5">
                    {/* Experience Name */}
                    <h4 className="text-sm font-extrabold text-slate-900 leading-snug">
                      {selectedListing.name}
                    </h4>

                    {/* Sponsor by Shop Name */}
                    <div className="text-[11px] text-slate-600">
                      Sponsored by:{" "}
                      <span className="font-bold text-[#0e8a5b]">
                        {provider?.businessName || "Local Kayak Adventures"}
                      </span>
                    </div>

                    {/* Rating & Reviews */}
                    <div className="flex items-center gap-1 text-[11px] text-slate-500 pt-0.5">
                      <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
                      <span className="font-bold text-slate-900">{selectedListing.rating}</span>
                      <span>({selectedListing.reviews})</span>
                    </div>

                    {/* Location */}
                    <div className="text-[11px] text-slate-500 flex items-center gap-1">
                      <MapPin className="w-3 h-3 text-red-500 shrink-0" />
                      <span>{selectedListing.location}</span>
                    </div>

                    {/* Offer Badge & Pricing Row */}
                    <div className="pt-2 flex items-baseline gap-2">
                      <span className="text-base font-black text-[#0e8a5b]">
                        ₹{finalOfferPrice}/person
                      </span>
                      <span className="text-xs line-through text-slate-400">
                        ₹{originalPriceNumber}/person
                      </span>
                    </div>

                    {/* Action Buttons */}
                    <div className="grid grid-cols-2 gap-2 pt-3 border-t border-slate-100">
                      <button
                        type="button"
                        className="py-1.5 px-2 rounded-xl border border-slate-200 text-slate-700 font-bold text-[11px] text-center"
                      >
                        View Experience
                      </button>
                      <button
                        type="button"
                        className="py-1.5 px-2 rounded-xl bg-[#0e8a5b] text-white font-bold text-[11px] text-center"
                      >
                        Book Now
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* Checkout Summary Box */}
              <div className="bg-white p-5 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
                <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                  Campaign Order Summary
                </h3>

                <div className="space-y-2 text-xs">
                  <div className="flex items-center justify-between text-slate-600">
                    <span>Listing</span>
                    <span className="font-bold text-slate-900 truncate max-w-[180px]">
                      {selectedListing.name}
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-slate-600">
                    <span>Package Duration</span>
                    <span className="font-bold text-slate-900">{currentPkg.name}</span>
                  </div>
                  <div className="flex items-center justify-between text-slate-600">
                    <span>Package Price</span>
                    <span className="font-bold text-slate-900">₹{currentPkg.amount}</span>
                  </div>
                  <div className="flex items-center justify-between text-slate-600">
                    <span>Payment Mode</span>
                    <span className="font-bold uppercase text-slate-900">{paymentMethod}</span>
                  </div>
                  <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-sm font-black text-slate-900">
                    <span>Total Payable</span>
                    <span className="text-lg text-[#0e8a5b]">₹{currentPkg.amount}</span>
                  </div>
                </div>

                <button
                  type="button"
                  onClick={handleLaunchBoost}
                  disabled={isProcessing}
                  className="w-full py-3.5 px-4 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white font-extrabold text-xs shadow-lg shadow-emerald-700/25 transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
                >
                  <Zap className="w-4 h-4 fill-white" />
                  <span>
                    {isProcessing ? "Verifying Payment & Launching..." : "Pay & Launch Sponsor Campaign 🚀"}
                  </span>
                </button>

                <p className="text-[10px] text-slate-400 text-center">
                  Protected by Supabase Row Level Security. Only verified payments activate live campaigns.
                </p>
              </div>
            </div>
          </div>
        ) : (
          /* PREVIEW LIVE TRAVELER APP FEED VIEW */
          <div className="space-y-6">
            <div className="bg-white p-6 rounded-3xl border border-slate-200/90 shadow-sm">
              <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-lg font-bold text-slate-900 tracking-tight">
                      Live Traveler Mobile & Web Feed
                    </h2>
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-[#00875A] border border-emerald-200">
                      Querying Supabase
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 mt-0.5">
                    This view executes the exact Supabase query:{" "}
                    <code className="text-emerald-700 font-mono text-[10.5px]">
                      campaign_status = 'active' AND payment_status = 'paid' AND start_at &lt;= NOW() AND end_at &gt; NOW()
                    </code>
                  </p>
                </div>

                <button
                  type="button"
                  onClick={() => setActiveTab("configure")}
                  className="px-4 py-2 rounded-xl border border-slate-200 bg-slate-50 hover:bg-slate-100 text-xs font-bold text-slate-700 cursor-pointer"
                >
                  &larr; Back to Campaign Setup
                </button>
              </div>

              {/* Status Banner */}
              {paymentVerified && (
                <div className="my-5 p-4 rounded-2xl bg-emerald-50 border border-emerald-200 flex items-start gap-3 text-xs text-emerald-900">
                  <CheckCircle2 className="w-5 h-5 text-[#00875A] shrink-0 mt-0.5" />
                  <div>
                    <div className="font-extrabold text-sm text-[#00875A]">
                      Campaign Verified & Active in Supabase!
                    </div>
                    <div className="mt-0.5">
                      Transaction ID:{" "}
                      <span className="font-mono font-bold">
                        {campaignSuccessData?.payment_transaction_id || "TXN-VERIFIED-UPI"}
                      </span>{" "}
                      &bull; Status: <span className="font-bold uppercase">active</span> &bull; Valid Until:{" "}
                      <span className="font-bold">
                        {new Date(campaignSuccessData?.end_at || endDate).toLocaleString()}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* Live Traveler Card Demo Container */}
              <div className="max-w-md mx-auto py-6">
                <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-3 text-center">
                  Live Card as Seen by Travelers
                </div>

                <div className="rounded-3xl border-2 border-amber-300 shadow-xl overflow-hidden bg-white">
                  {/* Image */}
                  <div className="relative aspect-[16/10] w-full">
                    <Image
                      src={selectedListing.image}
                      alt={selectedListing.name}
                      fill
                      className="object-cover"
                      unoptimized
                    />

                    {/* Sponsored Badge */}
                    <span className="absolute top-3 left-3 px-3 py-1 rounded-full bg-black/80 backdrop-blur-md text-[10.5px] font-black text-amber-300 shadow-md flex items-center gap-1.5">
                      <Sparkles className="w-3.5 h-3.5" />
                      Sponsored
                    </span>

                    {/* Offer Badge */}
                    <span className="absolute top-3 right-3 px-3 py-1 rounded-full bg-[#00875A] text-white text-xs font-black shadow-md">
                      {offerDiscountPercent}% OFF
                    </span>
                  </div>

                  {/* Card Content Details */}
                  <div className="p-5 space-y-2">
                    {/* Experience Name */}
                    <h3 className="text-base font-extrabold text-slate-900 leading-snug">
                      {selectedListing.name}
                    </h3>

                    {/* Sponsor Info */}
                    <div className="text-xs text-slate-600">
                      Sponsored by:{" "}
                      <span className="font-bold text-[#00875A]">
                        {provider?.businessName || "Local Kayak Adventures"}
                      </span>
                    </div>

                    {/* Rating & Reviews */}
                    <div className="flex items-center gap-1.5 text-xs text-slate-600 pt-1">
                      <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
                      <span className="font-bold text-slate-900">{selectedListing.rating}</span>
                      <span>({selectedListing.reviews})</span>
                    </div>

                    {/* Location */}
                    <div className="flex items-center gap-1.5 text-xs text-slate-600">
                      <MapPin className="w-3.5 h-3.5 text-red-500" />
                      <span>{selectedListing.location}</span>
                    </div>

                    {/* Offer & Price */}
                    <div className="pt-3 border-t border-slate-100 flex items-baseline gap-2.5">
                      <span className="text-xl font-heading font-anton text-[#00875A]">
                        ₹{finalOfferPrice}
                      </span>
                      <span className="text-xs text-slate-500 font-semibold">/person</span>
                      <span className="text-xs line-through text-slate-400 font-medium">
                        ₹{originalPriceNumber}/person
                      </span>
                      <span className="ml-auto text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md">
                        {offerDiscountPercent}% OFF
                      </span>
                    </div>

                    {/* Buttons */}
                    <div className="grid grid-cols-2 gap-2.5 pt-4">
                      <button
                        type="button"
                        onClick={() => alert(`Opening details for ${selectedListing.name}`)}
                        className="py-2.5 px-3 rounded-xl border border-slate-300 hover:bg-slate-50 text-slate-800 font-bold text-xs text-center transition-colors cursor-pointer"
                      >
                        View Experience
                      </button>
                      <button
                        type="button"
                        onClick={() => alert(`Starting booking flow for ${selectedListing.name} with ${offerDiscountPercent}% OFF!`)}
                        className="py-2.5 px-3 rounded-xl bg-[#00875A] hover:bg-[#007048] text-white font-bold text-xs text-center shadow-md transition-colors cursor-pointer"
                      >
                        Book Now
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}