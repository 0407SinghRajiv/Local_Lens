"use client";

import React, { useState, useEffect, useMemo, useCallback } from "react";
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
  RefreshCw,
  CreditCard,
  QrCode,
  Building2,
  XCircle,
  ExternalLink,
  ChevronRight,
  Info,
} from "lucide-react";
import confetti from "canvas-confetti";
import { useI18n } from "@/lib/i18n";
import { LanguageSelector } from "@/components/settings/LanguageSelector";
import { getProviderProfile, ProviderProfile } from "@/lib/authSession";
import { getStoredExperiencesForProvider } from "@/services/mockExperiences";
import { supabase } from "@/lib/supabaseClient";
import { SponsorCampaign } from "@/types/sponsor";

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
  const [isLoadingListings, setIsLoadingListings] = useState(true);
  const [selectedListingIndex, setSelectedListingIndex] = useState(0);

  // Step 2: Package Selection ('spark' | 'push' | 'surge')
  const [packageType, setPackageType] = useState<"spark" | "push" | "surge">("push");

  // Step 3: Offer Configuration
  const [offerType, setOfferType] = useState<"percentage" | "flat">("percentage");
  const [offerDiscountPercent, setOfferDiscountPercent] = useState<number>(20);
  const [flatDiscountAmount, setFlatDiscountAmount] = useState<number>(250);
  const [offerDescription, setOfferDescription] = useState<string>("20% OFF Early Bird Special");

  // Step 4: Schedule / Start Timing
  const [scheduleOption, setScheduleOption] = useState<"now" | "later">("now");
  const [customStartDate, setCustomStartDate] = useState<string>(() => {
    // Tomorrow at 10:00 AM
    const tmrw = new Date(Date.now() + 86400000);
    tmrw.setHours(10, 0, 0, 0);
    return tmrw.toISOString().slice(0, 16);
  });

  // Step 5: Payment Method Selection
  const [paymentMethod, setPaymentMethod] = useState<"upi" | "card" | "netbanking">("upi");
  const [upiId, setUpiId] = useState("provider@okaxis");

  // Payment Gateway Modal State
  const [showPaymentModal, setShowPaymentModal] = useState(false);
  const [pendingCampaignId, setPendingCampaignId] = useState<string | null>(null);
  const [isProcessingPayment, setIsProcessingPayment] = useState(false);

  // Verification & Status State
  const [paymentVerified, setPaymentVerified] = useState(false);
  const [campaignSuccessData, setCampaignSuccessData] = useState<SponsorCampaign | null>(null);
  const [activeTab, setActiveTab] = useState<"configure" | "preview_live" | "history">("configure");
  const [bannerNotice, setBannerNotice] = useState<{ type: "success" | "warning" | "error"; text: string } | null>(null);

  // Live Traveler Feed Querying State
  const [travelerFeed, setTravelerFeed] = useState<any[]>([]);
  const [isLoadingFeed, setIsLoadingFeed] = useState(false);

  // Provider Campaign History State
  const [providerCampaigns, setProviderCampaigns] = useState<SponsorCampaign[]>([]);
  const [isLoadingHistory, setIsLoadingHistory] = useState(false);

  // Load Real Provider Experiences
  useEffect(() => {
    let isMounted = true;
    setIsLoadingListings(true);

    getProviderProfile().then(async (p) => {
      if (!isMounted) return;
      if (p) setProvider(p);

      const pid = p?.id || "provider_default";
      const pEmail = p?.email || "provider@locallens.in";

      // 1. Fetch from mock/local experiences service
      const localExps = getStoredExperiencesForProvider(pid, pEmail);

      // 2. Fetch from Supabase experience table
      let dbExps: any[] = [];
      try {
        const { data } = await supabase.from("experience").select("*").limit(15);
        if (data && Array.isArray(data)) {
          dbExps = data;
        }
      } catch (err) {
        console.warn("Notice loading DB experiences:", err);
      }

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
            price: `₹${dbItem.price_inr_clean || dbItem.price_inr || 1200} / person`,
            priceClean: Number(dbItem.price_inr_clean) || Number(dbItem.price_inr) || 1200,
            rating: Number(dbItem.rating) || 4.8,
            reviews: Number(dbItem.review_count) || 120,
            location: `${dbItem.city || dbItem.meeting_point || "Mumbai"}`,
            duration: `${dbItem.duration_hours || 2} hours`,
            type: "Guided Tour",
            image: dbItem.image_url || (Array.isArray(dbItem.images) && dbItem.images[0]) || "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80",
          });
        }
      }

      if (isMounted) {
        if (mapped.length > 0) {
          setAvailableListings(mapped);
        } else {
          // Default listing fallback
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
        setIsLoadingListings(false);
      }
    });

    return () => {
      isMounted = false;
    };
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

  const currentPkg = useMemo(() => {
    if (packageType === "spark") return { name: "Weekend Spark (3 Days)", amount: 499, days: 3 };
    if (packageType === "push") return { name: "Weekly Push (7 Days)", amount: 999, days: 7 };
    return { name: "Festival Surge (14 Days)", amount: 1999, days: 14 };
  }, [packageType]);

  // Pricing & Offer Calculations
  const originalPriceNumber = selectedListing.priceClean || 1200;

  const { discountAmount, finalOfferPrice, calculatedOfferLabel } = useMemo(() => {
    if (offerType === "percentage") {
      const discount = Math.round((originalPriceNumber * offerDiscountPercent) / 100);
      const finalPrice = Math.max(0, originalPriceNumber - discount);
      return {
        discountAmount: discount,
        finalOfferPrice: finalPrice,
        calculatedOfferLabel: `${offerDiscountPercent}% OFF`,
      };
    } else {
      const discount = Math.min(flatDiscountAmount, originalPriceNumber);
      const finalPrice = Math.max(0, originalPriceNumber - discount);
      return {
        discountAmount: discount,
        finalOfferPrice: finalPrice,
        calculatedOfferLabel: `₹${flatDiscountAmount} OFF`,
      };
    }
  }, [offerType, offerDiscountPercent, flatDiscountAmount, originalPriceNumber]);

  // Timing Calculations
  const { startDateTime, endDateTime, isScheduledFuture } = useMemo(() => {
    const now = new Date();
    let start: Date;
    if (scheduleOption === "now") {
      start = now;
    } else {
      const parsed = new Date(customStartDate);
      start = isNaN(parsed.getTime()) ? now : parsed;
    }
    const end = new Date(start.getTime() + currentPkg.days * 86400000);
    const isFuture = start.getTime() > now.getTime();
    return {
      startDateTime: start,
      endDateTime: end,
      isScheduledFuture: isFuture,
    };
  }, [scheduleOption, customStartDate, currentPkg.days]);

  // Fetch Live Traveler Feed directly
  const fetchLiveTravelerFeed = useCallback(async () => {
    setIsLoadingFeed(true);
    try {
      const res = await fetch("/api/sponsors/active", { cache: "no-store" });
      const data = await res.json();
      if (data.success && Array.isArray(data.data)) {
        setTravelerFeed(data.data);
      }
    } catch (e) {
      console.warn("Error fetching traveler feed:", e);
    } finally {
      setIsLoadingFeed(false);
    }
  }, []);

  // Fetch Provider's Campaigns
  const fetchProviderHistory = useCallback(async () => {
    setIsLoadingHistory(true);
    try {
      const pid = provider?.id || "provider_default";
      const email = provider?.email || "";
      const res = await fetch(`/api/sponsors?user_id=${encodeURIComponent(pid)}&email=${encodeURIComponent(email)}`, {
        cache: "no-store",
      });
      const data = await res.json();
      if (data.success && Array.isArray(data.data)) {
        setProviderCampaigns(data.data);
      }
    } catch (e) {
      console.warn("Error fetching provider campaigns:", e);
    } finally {
      setIsLoadingHistory(false);
    }
  }, [provider]);

  useEffect(() => {
    if (activeTab === "preview_live") {
      fetchLiveTravelerFeed();
    } else if (activeTab === "history") {
      fetchProviderHistory();
    }
  }, [activeTab, fetchLiveTravelerFeed, fetchProviderHistory]);

  /**
   * STEP 1: Initialize Campaign with pending payment status
   * Frontend initiates draft -> opens Payment Gateway modal
   */
  const handleInitiateBoost = async () => {
    setBannerNotice(null);
    setIsProcessingPayment(true);

    try {
      const userId = provider?.id || "provider_default";
      const shopName = provider?.businessName || "Local Kayak Adventures";
      const ownerName = provider?.fullName || provider?.name || "Krishnkumar Gupta";
      const businessId = `biz_${userId}`;

      // Save initial campaign with payment_status: 'pending'
      const initResp = await fetch("/api/sponsors", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user_id: userId,
          email: provider?.email,
          business_id: businessId,
          listing_id: selectedListing.id,
          owner_name: ownerName,
          shop_name: shopName,
          listing_name: selectedListing.name,
          sponsor_type: "boost",
          sponsor_package: currentPkg.name,
          package_days: currentPkg.days,
          amount: currentPkg.amount,
          offer_type: offerType === "percentage" ? "percentage_discount" : "flat_discount",
          offer_value: offerType === "percentage" ? offerDiscountPercent : flatDiscountAmount,
          offer_price: finalOfferPrice,
          offer_description: offerDescription || calculatedOfferLabel,
          start_at: startDateTime.toISOString(),
          end_at: endDateTime.toISOString(),
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

      setPendingCampaignId(initData.campaign.id);
      setShowPaymentModal(true);
    } catch (err: any) {
      setBannerNotice({
        type: "error",
        text: err.message || "Failed to initiate sponsor campaign.",
      });
    } finally {
      setIsProcessingPayment(false);
    }
  };

  /**
   * STEP 2A: Cancelled Payment Flow
   * User cancels or abandons payment -> Campaign remains 'pending'
   * Does NOT show in Traveler App (enforces strict security rule)
   */
  const handleCancelPayment = () => {
    setShowPaymentModal(false);
    setBannerNotice({
      type: "warning",
      text: "Payment was cancelled. Your campaign was saved as 'pending' draft and will NOT appear to travelers until verified.",
    });
  };

  /**
   * STEP 2B: Verified Payment Flow (Backend Security Boundary)
   * Only the verified payment endpoint can set payment_status = 'paid'
   */
  const handleAuthorizePayment = async () => {
    if (!pendingCampaignId) return;
    setIsProcessingPayment(true);

    try {
      const generatedTxnId = `TXN-${paymentMethod.toUpperCase()}-${Date.now().toString(36).toUpperCase()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;

      const verifyResp = await fetch("/api/sponsors/verify-payment", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          campaign_id: pendingCampaignId,
          payment_method: paymentMethod,
          payment_transaction_id: generatedTxnId,
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

      // Success
      setShowPaymentModal(false);
      setPaymentVerified(true);
      setCampaignSuccessData(verifyData.campaign);

      const isScheduled = verifyData.campaign?.campaign_status === "scheduled";

      setBannerNotice({
        type: "success",
        text: isScheduled
          ? `Payment verified! Campaign is SCHEDULED and will go live on ${new Date(verifyData.campaign.start_at).toLocaleString("en-IN")}.`
          : "Payment verified successfully! Your campaign is now ACTIVE in the traveler feed.",
      });

      confetti({
        particleCount: 130,
        spread: 85,
        origin: { y: 0.6 },
        colors: ["#0e8a5b", "#8b5cf6", "#f59e0b", "#3b82f6"],
      });

      // Switch to preview tab
      setActiveTab("preview_live");
      fetchLiveTravelerFeed();
    } catch (err: any) {
      setBannerNotice({
        type: "error",
        text: err.message || "Payment verification failed.",
      });
    } finally {
      setIsProcessingPayment(false);
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
                  {t("boost.title", "Sponsor & Boost Campaigns")}
                </h1>
                <span className="px-2.5 py-0.5 rounded-full text-[10px] font-extrabold bg-amber-100 text-amber-900 border border-amber-300 flex items-center gap-1">
                  <Sparkles className="w-3 h-3 text-amber-600" />
                  Supabase Live Feed
                </span>
              </div>
              <p className="text-xs text-slate-500 mt-0.5">
                {t(
                  "boost.subtitle",
                  "Promote real experiences with verified payment. Syncs to the Supabase traveler discovery feed."
                )}
              </p>
            </div>
          </div>

          <LanguageSelector variant="navbar" />
        </div>

        {/* View Switcher Tabs */}
        <div className="flex flex-wrap items-center gap-2 mt-4 pt-3 border-t border-slate-200/80">
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
          <button
            type="button"
            onClick={() => setActiveTab("history")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center gap-1.5 ${
              activeTab === "history"
                ? "bg-indigo-600 text-white shadow-sm"
                : "bg-white text-slate-600 hover:bg-slate-100 border border-slate-200"
            }`}
          >
            <Clock className="w-3.5 h-3.5" />
            <span>Campaign History & Status</span>
          </button>
        </div>
      </div>

      {/* Global Notice Banner */}
      {bannerNotice && (
        <div className="max-w-6xl mx-auto px-6 mb-4">
          <div
            className={`p-4 rounded-2xl border text-xs font-bold flex items-center justify-between gap-3 ${
              bannerNotice.type === "success"
                ? "bg-emerald-50 border-emerald-200 text-emerald-900"
                : bannerNotice.type === "warning"
                ? "bg-amber-50 border-amber-200 text-amber-900"
                : "bg-rose-50 border-rose-200 text-rose-900"
            }`}
          >
            <div className="flex items-center gap-2">
              {bannerNotice.type === "success" && <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />}
              {bannerNotice.type === "warning" && <AlertCircle className="w-4 h-4 text-amber-600 shrink-0" />}
              {bannerNotice.type === "error" && <XCircle className="w-4 h-4 text-rose-600 shrink-0" />}
              <span>{bannerNotice.text}</span>
            </div>
            <button
              type="button"
              onClick={() => setBannerNotice(null)}
              className="text-slate-400 hover:text-slate-600 cursor-pointer text-xs"
            >
              Dismiss
            </button>
          </div>
        </div>
      )}

      {/* Main Container */}
      <main className="max-w-6xl mx-auto px-6 pt-2">
        {activeTab === "configure" ? (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            {/* Left Column (8 cols): 5-Step Selection */}
            <div className="lg:col-span-8 space-y-6">
              {/* 1. Select Your Listing (From Real Database Experiences) */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-3">
                <div className="flex items-center justify-between">
                  <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    1. Select Real Listing / Experience
                  </h2>
                  <span className="text-[11px] text-[#0e8a5b] font-bold">
                    Referenced by actual listing_id &bull; No Duplicates
                  </span>
                </div>

                {isLoadingListings ? (
                  /* Shimmer Skeleton Loaders */
                  <div className="space-y-2">
                    {[1, 2].map((i) => (
                      <div key={i} className="animate-pulse flex items-center gap-3 p-3.5 rounded-2xl border border-slate-100 bg-slate-50">
                        <div className="w-14 h-12 bg-slate-200 rounded-xl" />
                        <div className="space-y-1.5 flex-1">
                          <div className="h-3 bg-slate-200 rounded w-1/2" />
                          <div className="h-2.5 bg-slate-200 rounded w-1/3" />
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
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
                              <div className="text-[10px] text-slate-400 font-mono truncate">
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
                )}
              </div>

              {/* 2. Choose Sponsor / Boost Package */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
                <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                  2. Choose Boost Package
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
                    <div className="text-[11px] text-slate-500 mt-1">7 Days Top Placement</div>
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
                    <div className="text-[11px] text-slate-500 mt-1">14 Days Max Reach</div>
                  </div>
                </div>
              </div>

              {/* 3. Configure Special Offer / Discount */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    3. Configure Traveler Offer
                  </h2>
                  <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl">
                    <button
                      type="button"
                      onClick={() => setOfferType("percentage")}
                      className={`px-3 py-1 rounded-lg text-[11px] font-bold transition-all ${
                        offerType === "percentage" ? "bg-white text-slate-900 shadow-xs" : "text-slate-500"
                      }`}
                    >
                      Percentage %
                    </button>
                    <button
                      type="button"
                      onClick={() => setOfferType("flat")}
                      className={`px-3 py-1 rounded-lg text-[11px] font-bold transition-all ${
                        offerType === "flat" ? "bg-white text-slate-900 shadow-xs" : "text-slate-500"
                      }`}
                    >
                      Flat INR (₹)
                    </button>
                  </div>
                </div>

                {offerType === "percentage" ? (
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    {[10, 15, 20, 25].map((pct) => (
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
                        <span className="text-[10px] text-slate-500 mt-0.5">
                          ₹{Math.round(originalPriceNumber * (1 - pct / 100))}/person
                        </span>
                      </button>
                    ))}
                  </div>
                ) : (
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    {[150, 250, 350, 500].map((amt) => (
                      <button
                        key={amt}
                        type="button"
                        onClick={() => {
                          setFlatDiscountAmount(amt);
                          setOfferDescription(`₹${amt} OFF Flat Deal`);
                        }}
                        className={`p-3 rounded-2xl border-2 font-bold text-xs flex flex-col items-center justify-center transition-all cursor-pointer ${
                          flatDiscountAmount === amt
                            ? "border-[#0e8a5b] bg-emerald-50/30 text-[#0e8a5b]"
                            : "border-slate-200 text-slate-700 hover:border-slate-300"
                        }`}
                      >
                        <span className="text-base font-black">₹{amt} OFF</span>
                        <span className="text-[10px] text-slate-500 mt-0.5">
                          ₹{Math.max(0, originalPriceNumber - amt)}/person
                        </span>
                      </button>
                    ))}
                  </div>
                )}

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

              {/* 4. Schedule & Campaign Timing */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    4. Start Timing & Schedule
                  </h2>
                  <span
                    className={`text-[10px] font-extrabold px-2.5 py-0.5 rounded-full border ${
                      isScheduledFuture
                        ? "bg-purple-50 text-purple-700 border-purple-200"
                        : "bg-emerald-50 text-emerald-700 border-emerald-200"
                    }`}
                  >
                    {isScheduledFuture ? "STATUS: SCHEDULED" : "STATUS: ACTIVE IMMEDIATELY"}
                  </span>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <label
                    onClick={() => setScheduleOption("now")}
                    className={`p-3.5 rounded-2xl border-2 cursor-pointer flex items-start gap-3 transition-all ${
                      scheduleOption === "now"
                        ? "border-[#0e8a5b] bg-emerald-50/20"
                        : "border-slate-200 hover:border-slate-300"
                    }`}
                  >
                    <input
                      type="radio"
                      name="scheduleOpt"
                      checked={scheduleOption === "now"}
                      onChange={() => setScheduleOption("now")}
                      className="mt-0.5 text-[#0e8a5b] focus:ring-[#0e8a5b]"
                    />
                    <div>
                      <div className="text-xs font-extrabold text-slate-900">Start Immediately</div>
                      <div className="text-[11px] text-slate-500 mt-0.5">
                        Go live right after verified payment
                      </div>
                    </div>
                  </label>

                  <label
                    onClick={() => setScheduleOption("later")}
                    className={`p-3.5 rounded-2xl border-2 cursor-pointer flex items-start gap-3 transition-all ${
                      scheduleOption === "later"
                        ? "border-[#0e8a5b] bg-emerald-50/20"
                        : "border-slate-200 hover:border-slate-300"
                    }`}
                  >
                    <input
                      type="radio"
                      name="scheduleOpt"
                      checked={scheduleOption === "later"}
                      onChange={() => setScheduleOption("later")}
                      className="mt-0.5 text-[#0e8a5b] focus:ring-[#0e8a5b]"
                    />
                    <div>
                      <div className="text-xs font-extrabold text-slate-900">Schedule for Later</div>
                      <div className="text-[11px] text-slate-500 mt-0.5">
                        Set a future start date & time
                      </div>
                    </div>
                  </label>
                </div>

                {scheduleOption === "later" && (
                  <div className="pt-2">
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Choose Future Start Date & Time
                    </label>
                    <input
                      type="datetime-local"
                      value={customStartDate}
                      onChange={(e) => setCustomStartDate(e.target.value)}
                      className="px-3.5 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-800 bg-white"
                    />
                  </div>
                )}

                {/* Validity Timing Window Preview */}
                <div className="p-3.5 rounded-2xl bg-slate-50 border border-slate-200/80 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 text-xs text-slate-600">
                  <div className="flex items-center gap-2">
                    <Calendar className="w-4 h-4 text-[#0e8a5b] shrink-0" />
                    <span className="font-bold">Active Time Window:</span>
                    <span>
                      {startDateTime.toLocaleDateString("en-IN", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                      {" → "}
                      {endDateTime.toLocaleDateString("en-IN", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                    </span>
                  </div>
                  <span className="text-[10px] font-mono text-slate-400">
                    Asia/Kolkata (IST) &bull; {currentPkg.days} Days
                  </span>
                </div>
              </div>

              {/* 5. Verified Payment Method Selection */}
              <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
                <div className="flex items-center justify-between">
                  <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                    5. Verified Payment Method
                  </h2>
                  <span className="text-[11px] text-slate-400 font-medium">
                    Strict Backend Verification Flow
                  </span>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
                  {/* UPI */}
                  <label
                    onClick={() => setPaymentMethod("upi")}
                    className={`p-3.5 rounded-2xl border-2 cursor-pointer flex items-center gap-3 transition-all ${
                      paymentMethod === "upi"
                        ? "border-[#0e8a5b] bg-emerald-50/20"
                        : "border-slate-200 hover:border-slate-300"
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
                        : "border-slate-200 hover:border-slate-300"
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
                      <div className="text-xs font-bold text-slate-900">Debit / Credit Card</div>
                      <div className="text-[10px] text-slate-500">Visa, Mastercard, RuPay</div>
                    </div>
                  </label>

                  {/* Net Banking */}
                  <label
                    onClick={() => setPaymentMethod("netbanking")}
                    className={`p-3.5 rounded-2xl border-2 cursor-pointer flex items-center gap-3 transition-all ${
                      paymentMethod === "netbanking"
                        ? "border-[#0e8a5b] bg-emerald-50/20"
                        : "border-slate-200 hover:border-slate-300"
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
                      {calculatedOfferLabel}
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
                    <span>Start Timing</span>
                    <span className="font-bold text-slate-900">
                      {isScheduledFuture ? "Scheduled (Future)" : "Immediate (Now)"}
                    </span>
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
                  onClick={handleInitiateBoost}
                  disabled={isProcessingPayment}
                  className="w-full py-3.5 px-4 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white font-extrabold text-xs shadow-lg shadow-emerald-700/25 transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
                >
                  <Zap className="w-4 h-4 fill-white" />
                  <span>
                    {isProcessingPayment ? "Initializing Campaign..." : `Proceed to Pay ₹${currentPkg.amount} 🚀`}
                  </span>
                </button>

                <p className="text-[10px] text-slate-400 text-center">
                  Protected by Supabase Row Level Security. Only verified payments activate live campaigns.
                </p>
              </div>
            </div>
          </div>
        ) : activeTab === "preview_live" ? (
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
                      Direct Supabase Query
                    </span>
                  </div>
                  <p className="text-xs text-slate-500 mt-0.5">
                    Filtered strictly by:{" "}
                    <code className="text-emerald-700 font-mono text-[10.5px]">
                      campaign_status = 'active' AND payment_status = 'paid' AND start_at &lt;= NOW() AND end_at &gt; NOW()
                    </code>
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={fetchLiveTravelerFeed}
                    disabled={isLoadingFeed}
                    className="px-3.5 py-2 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-xs font-bold text-slate-700 flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
                  >
                    <RefreshCw className={`w-3.5 h-3.5 ${isLoadingFeed ? "animate-spin text-emerald-600" : ""}`} />
                    <span>Refresh Feed</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setActiveTab("configure")}
                    className="px-4 py-2 rounded-xl bg-slate-900 text-white text-xs font-bold cursor-pointer"
                  >
                    &larr; Campaign Setup
                  </button>
                </div>
              </div>

              {/* Status Banner if verified */}
              {paymentVerified && campaignSuccessData && (
                <div className="my-5 p-4 rounded-2xl bg-emerald-50 border border-emerald-200 flex items-start gap-3 text-xs text-emerald-900">
                  <CheckCircle2 className="w-5 h-5 text-[#00875A] shrink-0 mt-0.5" />
                  <div>
                    <div className="font-extrabold text-sm text-[#00875A]">
                      Campaign Verified & Saved in Supabase!
                    </div>
                    <div className="mt-0.5">
                      Transaction ID:{" "}
                      <span className="font-mono font-bold">
                        {campaignSuccessData.payment_transaction_id}
                      </span>{" "}
                      &bull; Status: <span className="font-bold uppercase">{campaignSuccessData.campaign_status}</span> &bull; Valid Until:{" "}
                      <span className="font-bold">
                        {new Date(campaignSuccessData.end_at).toLocaleString("en-IN")}
                      </span>
                    </div>
                  </div>
                </div>
              )}

              {/* Traveler Cards Grid */}
              <div className="py-4">
                {isLoadingFeed ? (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {[1, 2, 3].map((i) => (
                      <div key={i} className="animate-pulse rounded-2xl border border-slate-100 bg-slate-50 p-4 space-y-3">
                        <div className="h-44 bg-slate-200 rounded-xl" />
                        <div className="h-4 bg-slate-200 rounded w-3/4" />
                        <div className="h-3 bg-slate-200 rounded w-1/2" />
                      </div>
                    ))}
                  </div>
                ) : travelerFeed.length === 0 ? (
                  <div className="text-center py-12 text-slate-500 space-y-2">
                    <Sparkles className="w-8 h-8 text-amber-500 mx-auto" />
                    <div className="font-bold text-sm text-slate-700">No active sponsored campaigns at this moment</div>
                    <p className="text-xs text-slate-400 max-w-md mx-auto">
                      Only campaigns with verified payment, active status, and current time validity window appear here.
                    </p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {travelerFeed.map((item, idx) => (
                      <div
                        key={item.campaign_id || idx}
                        className="rounded-3xl border-2 border-amber-300/80 shadow-md overflow-hidden bg-white flex flex-col justify-between"
                      >
                        <div>
                          {/* Image & Badges */}
                          <div className="relative aspect-[16/10] w-full">
                            <Image
                              src={item.image_url}
                              alt={item.listing_name}
                              fill
                              className="object-cover"
                              unoptimized
                            />
                            <span className="absolute top-2.5 left-2.5 px-2.5 py-0.5 rounded-full bg-black/80 backdrop-blur-md text-[10px] font-black text-amber-300 shadow-sm flex items-center gap-1">
                              <Sparkles className="w-3 h-3 text-amber-400" />
                              {item.badge || "Sponsored"}
                            </span>
                            <span className="absolute top-2.5 right-2.5 px-2.5 py-0.5 rounded-full bg-[#00875A] text-white text-[11px] font-black shadow-md">
                              {item.offer_label || `${item.offer_value}% OFF`}
                            </span>
                          </div>

                          {/* Content */}
                          <div className="p-4 space-y-1.5">
                            <h3 className="text-sm font-extrabold text-slate-900 leading-snug">
                              {item.listing_name}
                            </h3>
                            <div className="text-[11px] text-slate-600">
                              Sponsored by:{" "}
                              <span className="font-bold text-[#00875A]">
                                {item.shop_name}
                              </span>
                            </div>

                            <div className="flex items-center gap-1.5 text-[11px] text-slate-600 pt-1">
                              <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400" />
                              <span className="font-bold text-slate-900">{item.rating}</span>
                              <span>({item.reviews_count})</span>
                              <span className="mx-1 text-slate-300">&bull;</span>
                              <MapPin className="w-3 h-3 text-red-500" />
                              <span className="truncate">{item.location}</span>
                            </div>

                            {/* Offer & Price */}
                            <div className="pt-2 flex items-baseline gap-2">
                              <span className="text-lg font-black text-[#00875A]">
                                ₹{item.offer_price}
                              </span>
                              <span className="text-xs text-slate-500 font-semibold">/person</span>
                              <span className="text-xs line-through text-slate-400">
                                ₹{item.original_price}/person
                              </span>
                            </div>
                          </div>
                        </div>

                        {/* Card Buttons */}
                        <div className="p-4 pt-0 grid grid-cols-2 gap-2">
                          <button
                            type="button"
                            onClick={() => alert(`View Experience: ${item.listing_name}`)}
                            className="py-2 px-3 rounded-xl border border-slate-200 hover:bg-slate-50 text-slate-800 font-bold text-xs text-center cursor-pointer"
                          >
                            View Experience
                          </button>
                          <button
                            type="button"
                            onClick={() => alert(`Book Now: ${item.listing_name} with offer!`)}
                            className="py-2 px-3 rounded-xl bg-[#00875A] hover:bg-[#007048] text-white font-bold text-xs text-center shadow-sm cursor-pointer"
                          >
                            Book Now
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        ) : (
          /* CAMPAIGN HISTORY & STATUS VIEW */
          <div className="bg-white p-6 rounded-3xl border border-slate-200/90 shadow-sm space-y-4">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 pb-4 border-b border-slate-100">
              <div>
                <h2 className="text-lg font-bold text-slate-900 tracking-tight">
                  Your Sponsor Campaigns ({providerCampaigns.length})
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Full status history for provider ID:{" "}
                  <code className="text-slate-700 font-mono text-[11px]">
                    {provider?.id || "provider_default"}
                  </code>
                </p>
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={fetchProviderHistory}
                  disabled={isLoadingHistory}
                  className="px-3.5 py-2 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-xs font-bold text-slate-700 flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${isLoadingHistory ? "animate-spin text-indigo-600" : ""}`} />
                  <span>Refresh History</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab("configure")}
                  className="px-4 py-2 rounded-xl bg-slate-900 text-white text-xs font-bold cursor-pointer"
                >
                  + New Campaign
                </button>
              </div>
            </div>

            {isLoadingHistory ? (
              <div className="py-8 text-center text-xs text-slate-400">Loading campaign records...</div>
            ) : providerCampaigns.length === 0 ? (
              <div className="py-12 text-center text-slate-500 space-y-1">
                <Clock className="w-8 h-8 text-slate-300 mx-auto" />
                <div className="font-bold text-sm text-slate-700">No campaigns launched yet</div>
                <p className="text-xs text-slate-400">
                  Select a listing and launch a boost campaign to reach thousands of travelers.
                </p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50 text-slate-600 uppercase text-[10px] tracking-wider border-b border-slate-100">
                    <tr>
                      <th className="py-3 px-4">Listing</th>
                      <th className="py-3 px-4">Package</th>
                      <th className="py-3 px-4">Amount</th>
                      <th className="py-3 px-4">Payment</th>
                      <th className="py-3 px-4">Status</th>
                      <th className="py-3 px-4">Start At</th>
                      <th className="py-3 px-4">End At</th>
                      <th className="py-3 px-4">Txn ID</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-medium">
                    {providerCampaigns.map((camp) => {
                      const isExpired = new Date(camp.end_at).getTime() < Date.now();
                      const statusDisplay = isExpired ? "expired" : camp.campaign_status;

                      return (
                        <tr key={camp.id} className="hover:bg-slate-50/60">
                          <td className="py-3 px-4 font-bold text-slate-900 truncate max-w-[180px]">
                            {camp.listing_name}
                          </td>
                          <td className="py-3 px-4 text-slate-600">{camp.sponsor_package}</td>
                          <td className="py-3 px-4 font-bold text-slate-900">₹{camp.amount}</td>
                          <td className="py-3 px-4">
                            <span
                              className={`px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase ${
                                camp.payment_status === "paid"
                                  ? "bg-emerald-100 text-emerald-800"
                                  : "bg-amber-100 text-amber-800"
                              }`}
                            >
                              {camp.payment_status}
                            </span>
                          </td>
                          <td className="py-3 px-4">
                            <span
                              className={`px-2 py-0.5 rounded-full text-[10px] font-extrabold uppercase ${
                                statusDisplay === "active"
                                  ? "bg-emerald-100 text-[#00875A]"
                                  : statusDisplay === "scheduled"
                                  ? "bg-purple-100 text-purple-800"
                                  : statusDisplay === "expired"
                                  ? "bg-slate-100 text-slate-600"
                                  : "bg-amber-100 text-amber-800"
                              }`}
                            >
                              {statusDisplay}
                            </span>
                          </td>
                          <td className="py-3 px-4 text-slate-500 whitespace-nowrap">
                            {new Date(camp.start_at).toLocaleDateString("en-IN", { month: "short", day: "numeric" })}
                          </td>
                          <td className="py-3 px-4 text-slate-500 whitespace-nowrap">
                            {new Date(camp.end_at).toLocaleDateString("en-IN", { month: "short", day: "numeric" })}
                          </td>
                          <td className="py-3 px-4 font-mono text-[10px] text-slate-400 truncate max-w-[120px]">
                            {camp.payment_transaction_id || "-"}
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}
      </main>

      {/* SECURE PAYMENT GATEWAY MODAL (Enforces Cancelled Payment and Verified Backend Flow) */}
      {showPaymentModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-5 animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between pb-3 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-emerald-100 flex items-center justify-center text-[#0e8a5b]">
                  <ShieldCheck className="w-5 h-5" />
                </div>
                <div>
                  <div className="text-xs font-black uppercase text-slate-900 tracking-wider">
                    LocalLens Secure Checkout
                  </div>
                  <div className="text-[10px] text-slate-400">
                    256-Bit Encrypted &bull; Verified Gateway
                  </div>
                </div>
              </div>
              <button
                type="button"
                onClick={handleCancelPayment}
                className="p-1 rounded-lg text-slate-400 hover:text-slate-700"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Order Details */}
            <div className="p-4 rounded-2xl bg-slate-50 border border-slate-100 space-y-2 text-xs">
              <div className="flex items-center justify-between text-slate-600">
                <span>Experience</span>
                <span className="font-bold text-slate-900 truncate max-w-[190px]">
                  {selectedListing.name}
                </span>
              </div>
              <div className="flex items-center justify-between text-slate-600">
                <span>Boost Package</span>
                <span className="font-bold text-slate-900">{currentPkg.name}</span>
              </div>
              <div className="flex items-center justify-between text-slate-600">
                <span>Timing Status</span>
                <span className="font-bold text-slate-900">
                  {isScheduledFuture ? "Scheduled for Later" : "Active Immediately"}
                </span>
              </div>
              <div className="flex items-center justify-between text-slate-600">
                <span>Payment Mode</span>
                <span className="font-bold uppercase text-slate-900">{paymentMethod}</span>
              </div>
              <div className="pt-2 border-t border-slate-200 flex items-center justify-between text-sm font-black text-slate-900">
                <span>Total Amount Due</span>
                <span className="text-xl text-[#0e8a5b]">₹{currentPkg.amount}</span>
              </div>
            </div>

            {/* Payment Mode Instructions */}
            {paymentMethod === "upi" ? (
              <div className="p-3.5 rounded-2xl border border-emerald-200 bg-emerald-50/40 text-xs space-y-2">
                <div className="flex items-center gap-2 font-bold text-emerald-900">
                  <QrCode className="w-4 h-4 text-[#0e8a5b]" />
                  <span>Instant UPI Authorization</span>
                </div>
                <p className="text-[11px] text-slate-600">
                  Simulating approved authorization for UPI ID:{" "}
                  <span className="font-mono font-bold text-slate-800">{upiId}</span>
                </p>
              </div>
            ) : paymentMethod === "card" ? (
              <div className="p-3.5 rounded-2xl border border-slate-200 bg-slate-50 text-xs space-y-2">
                <div className="flex items-center gap-2 font-bold text-slate-800">
                  <CreditCard className="w-4 h-4 text-indigo-600" />
                  <span>Card Authorization</span>
                </div>
                <p className="text-[11px] text-slate-600">
                  Ending in <span className="font-mono font-bold">•••• 4242</span> &bull; Verified via OTP
                </p>
              </div>
            ) : (
              <div className="p-3.5 rounded-2xl border border-slate-200 bg-slate-50 text-xs space-y-2">
                <div className="flex items-center gap-2 font-bold text-slate-800">
                  <Building2 className="w-4 h-4 text-blue-600" />
                  <span>Net Banking Gateway</span>
                </div>
                <p className="text-[11px] text-slate-600">
                  Direct Bank Settlement &bull; Immediate Receipt
                </p>
              </div>
            )}

            {/* Action Buttons */}
            <div className="space-y-2 pt-2">
              <button
                type="button"
                onClick={handleAuthorizePayment}
                disabled={isProcessingPayment}
                className="w-full py-3 px-4 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white font-extrabold text-xs shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
              >
                <Check className="w-4 h-4" />
                <span>
                  {isProcessingPayment ? "Verifying Transaction..." : `Authorize & Pay ₹${currentPkg.amount}`}
                </span>
              </button>

              <button
                type="button"
                onClick={handleCancelPayment}
                disabled={isProcessingPayment}
                className="w-full py-2.5 px-4 rounded-xl border border-slate-200 bg-white hover:bg-slate-100 text-slate-700 font-bold text-xs text-center transition-colors cursor-pointer"
              >
                Cancel Payment (Abandon)
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}