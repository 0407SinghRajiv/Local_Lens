"use client";

import React, { useState, useEffect, useMemo, useRef } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import dynamic from "next/dynamic";
import {
  Compass,
  ArrowLeft,
  ArrowRight,
  Save,
  CheckCircle2,
  AlertCircle,
  UploadCloud,
  Trash2,
  Plus,
  X,
  MapPin,
  Clock,
  Calendar,
  Sparkles,
  ChevronDown,
  ChevronUp,
  Eye,
  Rocket,
  ShieldCheck,
  Star,
  Users,
  Layers,
  Search,
  Loader2,
} from "lucide-react";
import confetti from "canvas-confetti";
import { searchPlaceLocation } from "@/services/geocodingService";
import { supabase } from "@/lib/supabaseClient";
import {
  getStoredExperiences,
  saveStoredExperiences,
  getStoredExperiencesForProvider,
  saveStoredExperiencesForProvider,
} from "@/services/mockExperiences";
import { getProviderProfile } from "@/lib/authSession";
import { ExperienceListing, ExperienceCategory } from "@/types/experience";
import { AIContentValidatorWidget } from "@/components/ai/AIContentValidatorWidget";
import { checkProfanity, checkClarity, validateExperienceLocations } from "@/lib/aiValidator";
import { useI18n } from "@/lib/i18n";
import { LanguageSelector } from "@/components/settings/LanguageSelector";

// Google Maps & OpenStreetMap Pin Dropper dynamically loaded client-side
const GoogleMapPinDropper = dynamic(
  () =>
    import("@/components/map/GoogleMapPinDropper").then(
      (mod) => mod.GoogleMapPinDropper
    ),
  {
    ssr: false,
    loading: () => (
      <div className="w-full h-[320px] bg-slate-100 rounded-2xl flex items-center justify-center text-xs text-slate-400 font-bold">
        Loading Interactive Map...
      </div>
    ),
  }
);

const CATEGORIES: ExperienceCategory[] = [
  "Nature & Adventure",
  "Heritage",
  "Culinary & Food",
  "Culture & Arts",
  "Wellness & Spiritual",
  "Nightlife & Social",
  "Workshops & Crafts",
];

const SAMPLE_PHOTOS = [
  "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
  "https://images.unsplash.com/photo-1512343879784-a960bf40e7f2?auto=format&fit=crop&w=800&q=80",
];

export default function SimplifiedExperienceCreationPage() {
  const router = useRouter();
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const { t } = useI18n();

  // Active Provider Identity (Multi-tenant isolation)
  const [currentProviderId, setCurrentProviderId] = useState<string>("provider_default");
  const [currentProviderEmail, setCurrentProviderEmail] = useState<string>("provider@locallens.in");

  useEffect(() => {
    async function initProviderIdentity() {
      try {
        const prof = await getProviderProfile();
        let sessionData: any = null;
        try {
          const { data } = await supabase.auth.getSession();
          sessionData = data?.session?.user;
        } catch {}

        let localSession: any = null;
        if (typeof window !== "undefined") {
          try {
            const raw = localStorage.getItem("locallens_provider_session");
            if (raw) localSession = JSON.parse(raw);
          } catch {}
        }

        const uid =
          sessionData?.id ||
          localSession?.id ||
          prof?.id ||
          sessionData?.email ||
          localSession?.email ||
          prof?.email ||
          "provider_default";

        const uemail =
          sessionData?.email ||
          localSession?.email ||
          prof?.email ||
          "provider@locallens.in";

        setCurrentProviderId(uid);
        setCurrentProviderEmail(uemail);
      } catch (e) {
        console.warn("Provider identity notice:", e);
      }
    }
    initProviderIdentity();
  }, []);

  // -------------------------------------------------------------
  // 1. Wizard Step State: 1 (Details), 2 (Location), 3 (Pricing)
  // -------------------------------------------------------------
  const [step, setStep] = useState<1 | 2 | 3>(1);

  // -------------------------------------------------------------
  // 2. Step 1: Details State
  // -------------------------------------------------------------
  const [experienceName, setExperienceName] = useState("Sunset Kayaking at Versova");
  const [category, setCategory] = useState<ExperienceCategory>("Nature & Adventure");
  const [setting, setSetting] = useState<"Indoor" | "Outdoor" | "Mixed">("Outdoor");
  const [description, setDescription] = useState(
    "Sunset kayaking off Versova beach with certified safety marshals, top-grade equipment, and scenic mangrove waterways. Suitable for beginners and nature enthusiasts."
  );
  const [photos, setPhotos] = useState<string[]>([
    "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80",
    "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
  ]);
  const [photoUrlInput, setPhotoUrlInput] = useState("");
  const [highlights, setHighlights] = useState<string[]>([
    "Certified Kayaks & Lifejackets",
    "Sunset Mangrove Trail",
    "Professional Safety Marshals",
    "Beginner Friendly",
  ]);
  const [newHighlight, setNewHighlight] = useState("");
  const [isAuthenticLocal, setIsAuthenticLocal] = useState(true);
  const [isHiddenGem, setIsHiddenGem] = useState(true);

  // -------------------------------------------------------------
  // 3. Step 2: Location & Schedule State
  // -------------------------------------------------------------
  const [meetingPoint1, setMeetingPoint1] = useState("Versova Beach Pier 2, Off Jetty Road");
  const [startTime1, setStartTime1] = useState("05:00 PM");
  const [endTime1, setEndTime1] = useState("07:00 PM");
  const [coords1, setCoords1] = useState({
    lat: 19.131102,
    lng: 72.81541,
    city: "Mumbai",
    district: "Mumbai Suburban",
  });

  // Multi-Show: Show 2 is only revealed when provider needs it
  const [hasShow2, setHasShow2] = useState(false);
  const [activeShowTab, setActiveShowTab] = useState<1 | 2>(1);
  const [meetingPoint2, setMeetingPoint2] = useState("Juhu Coastal Base Station");
  const [startTime2, setStartTime2] = useState("07:30 AM");
  const [endTime2, setEndTime2] = useState("09:30 AM");
  const [coords2, setCoords2] = useState({
    lat: 19.0988,
    lng: 72.8264,
    city: "Mumbai",
    district: "Mumbai Suburban",
  });

  const [showAdvancedLocation, setShowAdvancedLocation] = useState(false);

  // -------------------------------------------------------------
  // 4. Step 3: Pricing & Publish State
  // -------------------------------------------------------------
  const [priceInr, setPriceInr] = useState<number>(1200);
  const [minGuests, setMinGuests] = useState<number>(1);
  const [maxGuests, setMaxGuests] = useState<number>(8);
  const [durationHours, setDurationHours] = useState<number>(2.0);
  const [availability, setAvailability] = useState("Daily, 05:00 PM - 07:00 PM");

  // -------------------------------------------------------------
  // 5. System, Validation & Notification State
  // -------------------------------------------------------------
  const [formError, setFormError] = useState<string | null>(null);
  const [saveToast, setSaveToast] = useState<{ message: string; type: "success" | "info" } | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [publishedListing, setPublishedListing] = useState<ExperienceListing | null>(null);

  // Multi-show objects for validation & saving
  const show1Data = useMemo(
    () => ({
      id: "show-1",
      name: "Primary Show",
      venue: meetingPoint1,
      city: coords1.city,
      district: coords1.district,
      lat: coords1.lat,
      lng: coords1.lng,
      timeSlot: `${startTime1} - ${endTime1}`,
    }),
    [meetingPoint1, coords1, startTime1, endTime1]
  );

  const show2Data = useMemo(
    () =>
      hasShow2
        ? {
            id: "show-2",
            name: "Morning Show",
            venue: meetingPoint2,
            city: coords2.city,
            district: coords2.district,
            lat: coords2.lat,
            lng: coords2.lng,
            timeSlot: `${startTime2} - ${endTime2}`,
          }
        : null,
    [hasShow2, meetingPoint2, coords2, startTime2, endTime2]
  );

  // Active show convenience accessors for map
  const activeShowCoords = activeShowTab === 1 ? coords1 : coords2;
  const updateActiveCoords = (coords: { lat: number; lng: number }) => {
    if (activeShowTab === 1) {
      setCoords1((prev) => ({ ...prev, lat: coords.lat, lng: coords.lng }));
    } else {
      setCoords2((prev) => ({ ...prev, lat: coords.lat, lng: coords.lng }));
    }
  };

  // -------------------------------------------------------------
  // Place Search & Map Geolocation Logic
  // Automatically searches place in map when user enters place name
  // -------------------------------------------------------------
  const [isSearchingPlace, setIsSearchingPlace] = useState(false);
  const [placeSearchResult, setPlaceSearchResult] = useState<{
    showTab: 1 | 2;
    displayName: string;
    lat: number;
    lng: number;
  } | null>(null);

  const handlePerformPlaceSearch = async (tab: 1 | 2, textOverride?: string) => {
    const query = (textOverride !== undefined ? textOverride : (tab === 1 ? meetingPoint1 : meetingPoint2)).trim();
    if (!query || query.length < 2) return;

    setIsSearchingPlace(true);
    try {
      const result = await searchPlaceLocation(query);
      if (result) {
        if (tab === 1) {
          setCoords1((prev) => ({ ...prev, lat: result.lat, lng: result.lng }));
        } else {
          setCoords2((prev) => ({ ...prev, lat: result.lat, lng: result.lng }));
        }
        setPlaceSearchResult({
          showTab: tab,
          displayName: result.displayName,
          lat: result.lat,
          lng: result.lng,
        });
      }
    } catch (err) {
      console.warn("Place search notice:", err);
    } finally {
      setIsSearchingPlace(false);
    }
  };

  // Debounced auto-search when user enters place name
  useEffect(() => {
    const target = activeShowTab === 1 ? meetingPoint1 : meetingPoint2;
    if (!target || target.trim().length < 3) return;

    const timer = setTimeout(() => {
      handlePerformPlaceSearch(activeShowTab, target);
    }, 700);

    return () => clearTimeout(timer);
  }, [meetingPoint1, meetingPoint2, activeShowTab]);

  // -------------------------------------------------------------
  // Photo Handling Handlers
  // -------------------------------------------------------------
  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length === 0) return;

    Array.from(files).forEach((file) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        if (event.target?.result) {
          setPhotos((prev) => [...prev, event.target!.result as string]);
        }
      };
      reader.readAsDataURL(file);
    });

    if (fileInputRef.current) fileInputRef.current.value = "";
  };

  const handleAddPhotoUrl = () => {
    if (!photoUrlInput.trim()) return;
    setPhotos((prev) => [...prev, photoUrlInput.trim()]);
    setPhotoUrlInput("");
  };

  const handleDeletePhoto = (index: number) => {
    setPhotos((prev) => prev.filter((_, i) => i !== index));
  };

  // -------------------------------------------------------------
  // Highlight Tags Handlers
  // -------------------------------------------------------------
  const handleAddHighlight = () => {
    if (!newHighlight.trim()) return;
    if (!highlights.includes(newHighlight.trim())) {
      setHighlights((prev) => [...prev, newHighlight.trim()]);
    }
    setNewHighlight("");
  };

  const handleRemoveHighlight = (item: string) => {
    setHighlights((prev) => prev.filter((h) => h !== item));
  };

  // -------------------------------------------------------------
  // Step Validation & Navigation Handlers
  // -------------------------------------------------------------
  const validateStep1 = (): boolean => {
    setFormError(null);
    if (!experienceName.trim() || experienceName.trim().length < 4) {
      setFormError("Please enter a descriptive experience name (at least 4 characters).");
      return false;
    }
    if (!description.trim() || description.trim().length < 15) {
      setFormError("Please write a short description explaining what travelers will do (at least 15 characters).");
      return false;
    }
    if (photos.length === 0) {
      setFormError("Please add at least one photo for your experience.");
      return false;
    }
    return true;
  };

  const validateStep2 = (): boolean => {
    setFormError(null);
    if (!meetingPoint1.trim()) {
      setFormError("Please provide a meeting point or venue address for travelers.");
      return false;
    }
    if (hasShow2 && !meetingPoint2.trim()) {
      setFormError("Please provide a venue address for Show 2 or remove it.");
      return false;
    }
    return true;
  };

  const handleNextFromStep1 = () => {
    if (validateStep1()) {
      setStep(2);
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };

  const handleNextFromStep2 = () => {
    if (validateStep2()) {
      setStep(3);
      window.scrollTo({ top: 0, behavior: "smooth" });
    }
  };

  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // Save Draft Handler (Stores in Supabase and localStorage scoped to provider)
  // -------------------------------------------------------------
  const handleSaveDraft = async () => {
    setSaveToast(null);
    setFormError(null);

    const currentList = getStoredExperiencesForProvider(currentProviderId);
    const draftId = `EXP-DFT-${Date.now().toString().slice(-4)}`;

    const draftListing: ExperienceListing = {
      experience_id: draftId,
      provider_id: currentProviderId,
      provider_email: currentProviderEmail,
      experience_name: experienceName || "Draft Experience",
      category: category,
      sub_category: "Local Exploration",
      tags: [...highlights, `provider:${currentProviderId}`, `provider_email:${currentProviderEmail}`],
      local_experience_bool: isAuthenticLocal,
      hidden_gem_bool: isHiddenGem,
      latitude: coords1.lat,
      longitude: coords1.lng,
      city: coords1.city,
      district: coords1.district,
      state: "Maharashtra",
      region: "Konkan",
      price_inr_clean: priceInr || 1200,
      duration_hours_clean: durationHours || 2.0,
      min_group_size: minGuests || 1,
      max_group_size: maxGuests || 8,
      booking_required_bool: true,
      advance_booking_days_clean: 1,
      availability: availability || `${startTime1} - ${endTime1}`,
      indoor_outdoor_clean: setting,
      best_time: startTime1,
      season: "All Year",
      accessibility: "Standard",
      images: photos.length > 0 ? photos : SAMPLE_PHOTOS,
      description: description.trim(),
      meeting_point: meetingPoint1,
      inclusions: highlights,
      rules: ["Valid government ID required"],
      cancellation_policy: "100% refund up to 24h prior",
      status: "needs_improvement",
      health_score: 85,
      earnings_generated_inr: 0,
      bookings_count: 0,
      rating: 4.8,
      review_count: 0,
    };

    // Save strictly to this provider's storage
    saveStoredExperiencesForProvider(currentProviderId, [draftListing, ...currentList]);

    // Save to Supabase experience table with provider ownership tags
    try {
      const payload = {
        experience_id: draftListing.experience_id,
        experience_name: draftListing.experience_name,
        city: draftListing.city,
        district: draftListing.district,
        state: draftListing.state,
        region: draftListing.region,
        latitude: draftListing.latitude,
        longitude: draftListing.longitude,
        category: draftListing.category,
        sub_category: draftListing.sub_category,
        description: draftListing.description,
        tags: highlights.concat([`provider:${currentProviderId}`, `provider_email:${currentProviderEmail}`]).join(", "),
        price_inr: `₹${draftListing.price_inr_clean}`,
        duration_hours: `${draftListing.duration_hours_clean} hours`,
        best_for: "Travelers & Explorers",
        min_group_size: draftListing.min_group_size,
        max_group_size: draftListing.max_group_size,
        rating: draftListing.rating,
        review_count: draftListing.review_count,
        best_time: draftListing.best_time,
        season: draftListing.season,
        indoor_outdoor: draftListing.indoor_outdoor_clean,
        booking_required: "Yes",
        advance_booking_days: "1 day",
        availability: draftListing.availability,
        accessibility: draftListing.accessibility,
        local_experience: "Yes",
        hidden_gem: isHiddenGem ? "Yes" : "No",
        image_url: photos[0] || "",
        source_name: `provider:${currentProviderId}`,
        source_url: `https://locallens.in/provider/${currentProviderId}`,
        last_verified: new Date().toISOString(),
      };

      await supabase.from("experience").insert(payload);

      fetch("/api/experiences", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...payload, provider_id: currentProviderId, provider_email: currentProviderEmail }),
      }).catch((e) => console.warn("API sync note:", e));
    } catch (err) {
      console.warn("Supabase draft sync notice:", err);
    }

    setSaveToast({ message: "Draft saved successfully! You can resume editing anytime.", type: "success" });
    setTimeout(() => setSaveToast(null), 4000);
  };

  // -------------------------------------------------------------
  // Publish Experience Handler
  // -------------------------------------------------------------
  const handlePublish = async () => {
    if (!validateStep1() || !validateStep2()) {
      return;
    }

    if (priceInr <= 0) {
      setFormError("Please enter a valid price per guest (greater than 0).");
      return;
    }

    setIsSubmitting(true);
    setFormError(null);

    const currentList = getStoredExperiencesForProvider(currentProviderId, currentProviderEmail);
    const publishedId = `EXP-${Date.now().toString(36).toUpperCase()}-${Math.floor(Math.random() * 899 + 100)}`;

    const newListing: ExperienceListing = {
      experience_id: publishedId,
      provider_id: currentProviderId,
      provider_email: currentProviderEmail,
      experience_name: experienceName.trim(),
      category: category,
      sub_category: "Local Exploration",
      tags: [...highlights, `provider:${currentProviderId}`, `provider_email:${currentProviderEmail}`],
      local_experience_bool: isAuthenticLocal,
      hidden_gem_bool: isHiddenGem,
      latitude: coords1.lat,
      longitude: coords1.lng,
      city: coords1.city,
      district: coords1.district,
      state: "Maharashtra",
      region: "Konkan",
      price_inr_clean: priceInr,
      duration_hours_clean: durationHours,
      min_group_size: minGuests,
      max_group_size: maxGuests,
      booking_required_bool: true,
      advance_booking_days_clean: 1,
      availability: hasShow2
        ? `2 Shows Daily (${startTime1} & ${startTime2})`
        : `${availability || "Daily"} (${startTime1} - ${endTime1})`,
      indoor_outdoor_clean: setting,
      best_time: startTime1,
      season: "All Year",
      accessibility: "Standard",
      images: photos.length > 0 ? photos : SAMPLE_PHOTOS,
      description: description.trim(),
      meeting_point: meetingPoint1,
      inclusions: highlights,
      rules: ["Valid government ID required", "Arrive 10 minutes before start time"],
      cancellation_policy: "100% refund up to 24 hours prior",
      status: "active",
      health_score: 95,
      earnings_generated_inr: 0,
      bookings_count: 0,
      rating: 5.0,
      review_count: 1,
    };

    // 1. Persist strictly to this provider's storage for immediate dashboard display
    saveStoredExperiencesForProvider(currentProviderId, [newListing, ...currentList], currentProviderEmail);

    // 2. Persist to Supabase experience table & server API
    const payload = {
      experience_id: newListing.experience_id,
      experience_name: newListing.experience_name,
      city: newListing.city,
      district: newListing.district,
      state: newListing.state,
      region: newListing.region,
      latitude: newListing.latitude,
      longitude: newListing.longitude,
      category: newListing.category,
      sub_category: newListing.sub_category,
      description: newListing.description,
      tags: highlights.concat([`provider:${currentProviderId}`, `provider_email:${currentProviderEmail}`]).join(", "),
      price_inr: `₹${newListing.price_inr_clean}`,
      price_inr_clean: newListing.price_inr_clean,
      duration_hours: `${newListing.duration_hours_clean} hours`,
      best_for: "Travelers & Explorers",
      min_group_size: newListing.min_group_size,
      max_group_size: newListing.max_group_size,
      rating: 5.0,
      review_count: 1,
      best_time: newListing.best_time,
      season: newListing.season,
      indoor_outdoor: newListing.indoor_outdoor_clean,
      booking_required: "Yes",
      advance_booking_days: "1 day",
      availability: newListing.availability,
      accessibility: newListing.accessibility,
      local_experience: isAuthenticLocal ? "Yes" : "No",
      hidden_gem: isHiddenGem ? "Yes" : "No",
      image_url: photos[0] || "",
      images: photos.length > 0 ? photos : SAMPLE_PHOTOS,
      source_name: `provider:${currentProviderId}`,
      source_url: `https://locallens.in/provider/${currentProviderId}`,
      last_verified: new Date().toISOString(),
    };

    try {
      await supabase.from("experience").insert(payload);
    } catch (dbErr) {
      console.warn("Supabase insert note:", dbErr);
    }

    try {
      await fetch("/api/experiences", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ ...payload, provider_id: currentProviderId, provider_email: currentProviderEmail, images: photos.length > 0 ? photos : SAMPLE_PHOTOS }),
      });
    } catch (apiErr) {
      console.warn("API sync note:", apiErr);
    }

    setIsSubmitting(false);
    setPublishedListing(newListing);

    // Launch celebratory confetti
    try {
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 },
      });
    } catch {
      // Confetti fallback
    }
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900 font-sans pb-24">
      {/* ------------------------------------------------------------- */}
      {/* Top Header & 3-Step Wizard Flow Tracker */}
      {/* ------------------------------------------------------------- */}
      <header className="bg-white border-b border-slate-200/80 sticky top-0 z-30 shadow-2xs">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 h-18 flex items-center justify-between gap-4">
          <Link href="/dashboard" className="flex items-center gap-2.5 shrink-0">
            <div className="w-8 h-8 rounded-xl bg-[#0e8a5b] text-white flex items-center justify-center shadow-xs">
              <Compass className="w-4 h-4" />
            </div>
            <div>
              <span className="font-heading font-anton text-base text-slate-900 tracking-tight">
                {t("nav.brand", "Local Lens")}
              </span>
              <span className="text-[10px] text-slate-400 block -mt-0.5 font-medium">
                {t("experienceForm.pageTitle", "List a New Local Experience")}
              </span>
            </div>
          </Link>

          {/* 3 Step Interactive Indicator */}
          <div className="flex items-center gap-2 sm:gap-6">
            {/* Step 1 Pill */}
            <button
              type="button"
              onClick={() => setStep(1)}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                step === 1
                  ? "bg-emerald-50 text-[#0e8a5b] ring-1 ring-[#0e8a5b]/30 font-bold"
                  : step > 1
                  ? "text-slate-700 hover:bg-slate-50 font-semibold"
                  : "text-slate-400"
              }`}
            >
              <div
                className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-black ${
                  step > 1
                    ? "bg-[#0e8a5b] text-white"
                    : step === 1
                    ? "bg-[#0e8a5b] text-white"
                    : "bg-slate-200 text-slate-500"
                }`}
              >
                {step > 1 ? "✓" : "1"}
              </div>
              <div className="text-left hidden sm:block">
                <div className="text-xs leading-none">{t("experienceForm.step1", "Step 1: Details")}</div>
              </div>
            </button>

            <div className="h-[1px] w-4 sm:w-6 bg-slate-300" />

            {/* Step 2 Pill */}
            <button
              type="button"
              onClick={() => validateStep1() && setStep(2)}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                step === 2
                  ? "bg-emerald-50 text-[#0e8a5b] ring-1 ring-[#0e8a5b]/30 font-bold"
                  : step > 2
                  ? "text-slate-700 hover:bg-slate-50 font-semibold"
                  : "text-slate-400"
              }`}
            >
              <div
                className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-black ${
                  step > 2
                    ? "bg-[#0e8a5b] text-white"
                    : step === 2
                    ? "bg-[#0e8a5b] text-white"
                    : "bg-slate-200 text-slate-500"
                }`}
              >
                {step > 2 ? "✓" : "2"}
              </div>
              <div className="text-left hidden sm:block">
                <div className="text-xs leading-none">{t("experienceForm.step2", "Step 2: Location & Schedule")}</div>
              </div>
            </button>

            <div className="h-[1px] w-4 sm:w-6 bg-slate-300" />

            {/* Step 3 Pill */}
            <button
              type="button"
              onClick={() => validateStep1() && validateStep2() && setStep(3)}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                step === 3
                  ? "bg-emerald-50 text-[#0e8a5b] ring-1 ring-[#0e8a5b]/30 font-bold"
                  : "text-slate-400 hover:text-slate-600"
              }`}
            >
              <div
                className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-black ${
                  step === 3
                    ? "bg-[#0e8a5b] text-white"
                    : "bg-slate-200 text-slate-500"
                }`}
              >
                3
              </div>
              <div className="text-left hidden sm:block">
                <div className="text-xs leading-none">{t("experienceForm.step3", "Step 3: Pricing & Publish")}</div>
              </div>
            </button>
          </div>

          {/* Language Selector & Quick Save Draft */}
          <div className="flex items-center gap-2.5">
            <LanguageSelector variant="navbar" />

            <button
              type="button"
              onClick={handleSaveDraft}
              className="hidden md:inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-700 shadow-2xs transition-colors cursor-pointer"
            >
              <Save className="w-3.5 h-3.5 text-slate-500" />
              <span>{t("experienceForm.saveDraft", "Save Draft")}</span>
            </button>
          </div>
        </div>
      </header>

      {/* ------------------------------------------------------------- */}
      {/* Main Wizard Content Area */}
      {/* ------------------------------------------------------------- */}
      <main className="max-w-5xl mx-auto px-4 sm:px-6 pt-5 space-y-5">
        {/* Save Draft Toast */}
        {saveToast && (
          <div className="p-3 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-900 text-xs font-semibold flex items-center gap-2.5 shadow-xs animate-in fade-in">
            <CheckCircle2 className="w-4 h-4 text-[#0e8a5b] shrink-0" />
            <span className="flex-1">{saveToast.message}</span>
            <button
              type="button"
              onClick={() => setSaveToast(null)}
              className="text-emerald-700 hover:text-emerald-900 font-bold"
            >
              &times;
            </button>
          </div>
        )}

        {/* Real Validation Error Alert (Only shown when there is an actual error) */}
        {formError && (
          <div className="p-3.5 rounded-2xl bg-rose-50 border border-rose-200 text-rose-900 text-xs font-semibold flex items-center gap-3 shadow-xs animate-in fade-in">
            <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
            <span className="flex-1">{formError}</span>
            <button
              type="button"
              onClick={() => setFormError(null)}
              className="text-rose-500 hover:text-rose-800 text-base font-bold cursor-pointer"
            >
              &times;
            </button>
          </div>
        )}

        {/* Small Collapsible AI Quality Check Card (Requirement 5) */}
        <AIContentValidatorWidget
          title={experienceName}
          description={description}
          onApplyPolish={(polished) => setDescription(polished)}
          show1={show1Data}
          show2={show2Data}
        />

        {/* ========================================================= */}
        {/* STEP 1: DETAILS                                           */}
        {/* ========================================================= */}
        {step === 1 && (
          <div className="bg-white p-6 sm:p-8 rounded-3xl border border-slate-200/90 shadow-2xs space-y-6">
            <div>
              <h1 className="text-lg font-black text-slate-900 tracking-tight">
                Step 1: Experience Details
              </h1>
              <p className="text-xs text-slate-500 mt-0.5">
                Tell travelers what makes your experience special and upload welcoming photos.
              </p>
            </div>

            {/* Experience Name */}
            <div className="space-y-1.5">
              <label className="block text-xs font-bold text-slate-700">
                Experience Name <span className="text-rose-500">*</span>
              </label>
              <input
                type="text"
                value={experienceName}
                onChange={(e) => setExperienceName(e.target.value)}
                placeholder="e.g. Sunset Kayaking at Versova"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/20 focus:border-[#0e8a5b]"
              />
              <p className="text-[10.5px] text-slate-400">
                A descriptive title that travelers will search for.
              </p>
            </div>

            {/* Category & Setting Grid */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {/* Category */}
              <div className="space-y-1.5">
                <label className="block text-xs font-bold text-slate-700">
                  Category
                </label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value as ExperienceCategory)}
                  className="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-800 bg-white focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/20 focus:border-[#0e8a5b]"
                >
                  {CATEGORIES.map((cat) => (
                    <option key={cat} value={cat}>
                      {cat}
                    </option>
                  ))}
                </select>
              </div>

              {/* Setting: Indoor / Outdoor / Mixed */}
              <div className="space-y-1.5">
                <label className="block text-xs font-bold text-slate-700">
                  Setting
                </label>
                <div className="grid grid-cols-3 gap-1.5 p-1 bg-slate-100 rounded-xl">
                  {(["Indoor", "Outdoor", "Mixed"] as const).map((opt) => (
                    <button
                      key={opt}
                      type="button"
                      onClick={() => setSetting(opt)}
                      className={`py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                        setting === opt
                          ? "bg-white text-[#0e8a5b] shadow-xs"
                          : "text-slate-600 hover:text-slate-900"
                      }`}
                    >
                      {opt === "Indoor" ? "🏠 Indoor" : opt === "Outdoor" ? "🌿 Outdoor" : "⛅ Mixed"}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Short Description */}
            <div className="space-y-1.5">
              <div className="flex items-center justify-between">
                <label className="block text-xs font-bold text-slate-700">
                  Short Description <span className="text-rose-500">*</span>
                </label>
                <span className="text-[10.5px] text-slate-400 font-medium">
                  {description.split(/\s+/).filter(Boolean).length} words
                </span>
              </div>
              <textarea
                rows={3}
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Describe what guests will see, do, explore, and remember..."
                className="w-full p-3.5 rounded-xl border border-slate-200 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/20 focus:border-[#0e8a5b] leading-relaxed"
              />
            </div>

            {/* Photos (Functional Upload & Delete) */}
            <div className="space-y-2 pt-2 border-t border-slate-100">
              <div className="flex items-center justify-between">
                <label className="block text-xs font-bold text-slate-700">
                  Photos ({photos.length}) <span className="text-rose-500">*</span>
                </label>
                <span className="text-[10.5px] text-slate-400">
                  JPG / PNG • Upload from computer or paste image link
                </span>
              </div>

              {/* Photo Thumbnails Grid */}
              <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-5 gap-3">
                {/* Upload Button Card */}
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="border-2 border-dashed border-slate-200 hover:border-[#0e8a5b] bg-slate-50/50 hover:bg-emerald-50/30 rounded-2xl flex flex-col items-center justify-center p-3 text-center cursor-pointer aspect-square transition-all group"
                >
                  <UploadCloud className="w-5 h-5 text-slate-400 group-hover:text-[#0e8a5b] mb-1 group-hover:scale-110 transition-transform" />
                  <span className="text-[11px] font-bold text-slate-700 group-hover:text-[#0e8a5b]">
                    Upload Photo
                  </span>
                  <span className="text-[9.5px] text-slate-400 mt-0.5">Select file</span>
                </button>

                <input
                  type="file"
                  ref={fileInputRef}
                  onChange={handleFileUpload}
                  multiple
                  accept="image/*"
                  className="hidden"
                />

                {/* Photo Previews with Delete Button */}
                {photos.map((url, idx) => (
                  <div
                    key={idx}
                    className="relative rounded-2xl overflow-hidden aspect-square border border-slate-200 group bg-slate-100 shadow-2xs"
                  >
                    <Image
                      src={url}
                      alt={`Photo ${idx + 1}`}
                      fill
                      className="object-cover"
                      unoptimized
                    />
                    {idx === 0 && (
                      <span className="absolute top-1.5 left-1.5 bg-slate-900/80 backdrop-blur-xs text-white text-[9px] font-extrabold px-1.5 py-0.5 rounded-md pointer-events-none">
                        Cover
                      </span>
                    )}
                    {/* Delete Photo Button */}
                    <button
                      type="button"
                      onClick={() => handleDeletePhoto(idx)}
                      className="absolute top-1.5 right-1.5 w-6 h-6 rounded-lg bg-rose-600/90 text-white flex items-center justify-center opacity-90 group-hover:opacity-100 hover:bg-rose-700 transition-all cursor-pointer shadow-xs"
                      title="Delete photo"
                    >
                      <Trash2 className="w-3 h-3" />
                    </button>
                  </div>
                ))}
              </div>

              {/* Paste Image URL Input */}
              <div className="flex items-center gap-2 pt-1">
                <input
                  type="url"
                  value={photoUrlInput}
                  onChange={(e) => setPhotoUrlInput(e.target.value)}
                  placeholder="Or paste an image URL here..."
                  className="flex-1 px-3 py-1.5 rounded-xl border border-slate-200 text-xs text-slate-800 focus:outline-none focus:ring-1 focus:ring-[#0e8a5b]"
                />
                <button
                  type="button"
                  onClick={handleAddPhotoUrl}
                  disabled={!photoUrlInput.trim()}
                  className="px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-slate-200 disabled:opacity-50 text-slate-700 text-xs font-bold transition-colors cursor-pointer"
                >
                  + Add URL
                </button>
              </div>
            </div>

            {/* Experience Highlights */}
            <div className="space-y-2 pt-2 border-t border-slate-100">
              <label className="block text-xs font-bold text-slate-700">
                Experience Highlights &amp; Inclusions
              </label>

              {/* Highlights Chip Cloud */}
              <div className="flex flex-wrap items-center gap-1.5">
                {highlights.map((item) => (
                  <span
                    key={item}
                    className="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl bg-emerald-50 text-[#0e8a5b] text-xs font-bold border border-emerald-200/80"
                  >
                    <span>{item}</span>
                    <button
                      type="button"
                      onClick={() => handleRemoveHighlight(item)}
                      className="hover:text-rose-600 cursor-pointer text-xs"
                    >
                      &times;
                    </button>
                  </span>
                ))}
              </div>

              {/* Add New Highlight Tag */}
              <div className="flex items-center gap-2 pt-1 max-w-md">
                <input
                  type="text"
                  value={newHighlight}
                  onChange={(e) => setNewHighlight(e.target.value)}
                  onKeyDown={(e) => e.key === "Enter" && (e.preventDefault(), handleAddHighlight())}
                  placeholder="Add a highlight (e.g. Safety Marshals, Gear Included)..."
                  className="flex-1 px-3 py-1.5 rounded-xl border border-slate-200 text-xs text-slate-800 focus:outline-none focus:ring-1 focus:ring-[#0e8a5b]"
                />
                <button
                  type="button"
                  onClick={handleAddHighlight}
                  disabled={!newHighlight.trim()}
                  className="px-3 py-1.5 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] disabled:opacity-50 text-white text-xs font-bold transition-colors cursor-pointer"
                >
                  + Add
                </button>
              </div>

              {/* Badges Toggles */}
              <div className="flex flex-wrap items-center gap-4 pt-3">
                <label className="flex items-center gap-2 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={isAuthenticLocal}
                    onChange={(e) => setIsAuthenticLocal(e.target.checked)}
                    className="w-4 h-4 rounded text-[#0e8a5b] focus:ring-[#0e8a5b]"
                  />
                  <span className="text-xs font-bold text-slate-700">
                    Authentic Local Experience
                  </span>
                </label>

                <label className="flex items-center gap-2 cursor-pointer select-none">
                  <input
                    type="checkbox"
                    checked={isHiddenGem}
                    onChange={(e) => setIsHiddenGem(e.target.checked)}
                    className="w-4 h-4 rounded text-[#0e8a5b] focus:ring-[#0e8a5b]"
                  />
                  <span className="text-xs font-bold text-slate-700">
                    Hidden Gem (Off the beaten path)
                  </span>
                </label>
              </div>
            </div>

            {/* Bottom Bar: Back to Dashboard & Continue to Step 2 */}
            <div className="pt-4 border-t border-slate-100 flex items-center justify-between gap-4">
              <Link
                href="/dashboard"
                className="px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-600 transition-colors"
              >
                &larr; Back to Dashboard
              </Link>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleSaveDraft}
                  className="px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-700 shadow-2xs transition-colors cursor-pointer"
                >
                  Save Draft
                </button>

                <button
                  type="button"
                  onClick={handleNextFromStep1}
                  className="px-5 py-2.5 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white text-xs font-extrabold shadow-sm shadow-emerald-700/20 flex items-center gap-1.5 cursor-pointer transition-all"
                >
                  <span>Continue to Location</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* STEP 2: LOCATION & SCHEDULE                               */}
        {/* ========================================================= */}
        {step === 2 && (
          <div className="bg-white p-6 sm:p-8 rounded-3xl border border-slate-200/90 shadow-2xs space-y-6">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h1 className="text-lg font-black text-slate-900 tracking-tight">
                  Step 2: Location &amp; Schedule
                </h1>
                <p className="text-xs text-slate-500 mt-0.5">
                  Set meeting point, schedule timings, and place the pin on the map.
                </p>
              </div>

              {/* Multi-Show Add/Remove Button (Shown only when needed) */}
              {!hasShow2 ? (
                <button
                  type="button"
                  onClick={() => {
                    setHasShow2(true);
                    setActiveShowTab(2);
                  }}
                  className="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl bg-slate-100 hover:bg-emerald-50 text-slate-700 hover:text-[#0e8a5b] text-xs font-bold border border-slate-200 transition-colors cursor-pointer"
                >
                  <Plus className="w-3.5 h-3.5 text-[#0e8a5b]" />
                  <span>+ Add Another Show / Slot</span>
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => {
                    setHasShow2(false);
                    setActiveShowTab(1);
                  }}
                  className="inline-flex items-center gap-1 px-3 py-1.5 rounded-xl bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold border border-rose-200 transition-colors cursor-pointer"
                >
                  <X className="w-3.5 h-3.5 text-rose-600" />
                  <span>Remove Show 2</span>
                </button>
              )}
            </div>

            {/* Show Switcher Tabs if 2 Shows exist */}
            {hasShow2 && (
              <div className="flex items-center gap-2 p-1 bg-slate-100 rounded-2xl">
                <button
                  type="button"
                  onClick={() => setActiveShowTab(1)}
                  className={`flex-1 py-2 px-3 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
                    activeShowTab === 1
                      ? "bg-white text-[#0e8a5b] shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  <span className="w-2 h-2 rounded-full bg-[#0e8a5b]" />
                  <span>Show 1: {meetingPoint1 || "Primary Slot"}</span>
                </button>

                <button
                  type="button"
                  onClick={() => setActiveShowTab(2)}
                  className={`flex-1 py-2 px-3 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
                    activeShowTab === 2
                      ? "bg-white text-indigo-700 shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  <span className="w-2 h-2 rounded-full bg-indigo-500" />
                  <span>Show 2: {meetingPoint2 || "Second Slot"}</span>
                </button>
              </div>
            )}

            {/* Meeting Point & Schedule Timing Input */}
            <div className="grid grid-cols-1 md:grid-cols-12 gap-4">
              {/* Meeting Point Venue & Automated Place Search (7 cols) */}
              <div className="md:col-span-7 space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="block text-xs font-bold text-slate-700">
                    Meeting Point / Place Name {hasShow2 ? `(Show ${activeShowTab})` : ""} <span className="text-rose-500">*</span>
                  </label>
                  {isSearchingPlace && (
                    <span className="text-[10.5px] font-semibold text-[#0e8a5b] flex items-center gap-1 animate-pulse">
                      <Loader2 className="w-3 h-3 animate-spin" />
                      Searching place on map...
                    </span>
                  )}
                </div>
                <div className="relative flex items-center">
                  <MapPin className="w-4 h-4 text-[#0e8a5b] absolute left-3 top-3 pointer-events-none" />
                  <input
                    type="text"
                    value={activeShowTab === 1 ? meetingPoint1 : meetingPoint2}
                    onChange={(e) =>
                      activeShowTab === 1
                        ? setMeetingPoint1(e.target.value)
                        : setMeetingPoint2(e.target.value)
                    }
                    onKeyDown={(e) => {
                      if (e.key === "Enter") {
                        e.preventDefault();
                        handlePerformPlaceSearch(activeShowTab);
                      }
                    }}
                    placeholder="e.g. Versova Beach, Gateway of India, Marine Drive"
                    className="w-full pl-9 pr-24 py-2.5 rounded-xl border border-slate-200 text-xs font-semibold text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/20 focus:border-[#0e8a5b]"
                  />
                  <button
                    type="button"
                    onClick={() => handlePerformPlaceSearch(activeShowTab)}
                    disabled={isSearchingPlace}
                    className="absolute right-1.5 top-1.5 bottom-1.5 px-3 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-[#0e8a5b] border border-emerald-200 text-[11px] font-bold flex items-center gap-1.5 transition-colors cursor-pointer disabled:opacity-50"
                    title="Search place on map"
                  >
                    {isSearchingPlace ? (
                      <Loader2 className="w-3 h-3 animate-spin" />
                    ) : (
                      <Search className="w-3 h-3" />
                    )}
                    <span>Search</span>
                  </button>
                </div>

                {/* Real Place Location Confirmation Banner */}
                {placeSearchResult && placeSearchResult.showTab === activeShowTab ? (
                  <div className="p-2.5 rounded-xl bg-emerald-50/90 border border-emerald-200 flex items-start gap-2 text-[11px] text-emerald-950 animate-fadeIn">
                    <CheckCircle2 className="w-3.5 h-3.5 text-[#0e8a5b] shrink-0 mt-0.5" />
                    <div className="min-w-0 flex-1">
                      <div className="font-bold text-[#0e8a5b]">Original Location Located on Map</div>
                      <div className="truncate text-slate-700 font-medium">{placeSearchResult.displayName}</div>
                      <div className="font-mono text-[10px] text-slate-500 mt-0.5">
                        Coordinates: {placeSearchResult.lat.toFixed(6)}, {placeSearchResult.lng.toFixed(6)} • Pin placed!
                      </div>
                    </div>
                  </div>
                ) : (
                  <p className="text-[10.5px] text-slate-400">
                    Enter the name of any place or landmark — the map automatically searches and shows the original location.
                  </p>
                )}
              </div>

              {/* Start & End Time (5 cols) */}
              <div className="md:col-span-5 space-y-1.5">
                <label className="block text-xs font-bold text-slate-700">
                  Schedule Timing {hasShow2 ? `(Show ${activeShowTab})` : ""}
                </label>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <input
                      type="text"
                      value={activeShowTab === 1 ? startTime1 : startTime2}
                      onChange={(e) =>
                        activeShowTab === 1
                          ? setStartTime1(e.target.value)
                          : setStartTime2(e.target.value)
                      }
                      placeholder="Start: 05:00 PM"
                      className="w-full px-3 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-800 text-center"
                    />
                  </div>
                  <div>
                    <input
                      type="text"
                      value={activeShowTab === 1 ? endTime1 : endTime2}
                      onChange={(e) =>
                        activeShowTab === 1
                          ? setEndTime1(e.target.value)
                          : setEndTime2(e.target.value)
                      }
                      placeholder="End: 07:00 PM"
                      className="w-full px-3 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-800 text-center"
                    />
                  </div>
                </div>
              </div>
            </div>

            {/* Interactive Map (Google Maps with Automatic OpenStreetMap Fallback) */}
            <div className="space-y-2">
              <label className="block text-xs font-bold text-slate-700">
                Interactive Map Pin {hasShow2 ? `(Show ${activeShowTab})` : ""}
              </label>

              <GoogleMapPinDropper
                position={{ lat: activeShowCoords.lat, lng: activeShowCoords.lng }}
                venueName={activeShowTab === 1 ? meetingPoint1 : meetingPoint2}
                onPinSelected={updateActiveCoords}
              />
            </div>

            {/* Hide Latitude / Longitude under Collapsible "Advanced Location" (Requirement 3) */}
            <div className="rounded-2xl border border-slate-200/80 bg-slate-50/60 overflow-hidden">
              <button
                type="button"
                onClick={() => setShowAdvancedLocation(!showAdvancedLocation)}
                className="w-full px-4 py-2.5 flex items-center justify-between text-xs font-bold text-slate-700 hover:bg-slate-100/70 transition-colors cursor-pointer"
              >
                <span className="flex items-center gap-2">
                  <Compass className="w-3.5 h-3.5 text-slate-500" />
                  <span>Advanced Location Coordinates (Optional)</span>
                </span>
                <span className="text-[11px] font-semibold text-slate-400 flex items-center gap-1">
                  {showAdvancedLocation ? "Hide" : "Show"}
                  {showAdvancedLocation ? (
                    <ChevronUp className="w-3.5 h-3.5" />
                  ) : (
                    <ChevronDown className="w-3.5 h-3.5" />
                  )}
                </span>
              </button>

              {showAdvancedLocation && (
                <div className="p-4 pt-2 border-t border-slate-200/60 grid grid-cols-2 sm:grid-cols-4 gap-3 bg-white">
                  <div>
                    <label className="block text-[10px] font-bold text-slate-500 uppercase">
                      Latitude
                    </label>
                    <input
                      type="number"
                      step="0.000001"
                      value={activeShowCoords.lat}
                      onChange={(e) =>
                        updateActiveCoords({
                          lat: parseFloat(e.target.value) || 0,
                          lng: activeShowCoords.lng,
                        })
                      }
                      className="w-full px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-mono font-bold text-slate-800"
                    />
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-slate-500 uppercase">
                      Longitude
                    </label>
                    <input
                      type="number"
                      step="0.000001"
                      value={activeShowCoords.lng}
                      onChange={(e) =>
                        updateActiveCoords({
                          lat: activeShowCoords.lat,
                          lng: parseFloat(e.target.value) || 0,
                        })
                      }
                      className="w-full px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-mono font-bold text-slate-800"
                    />
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-slate-500 uppercase">
                      City
                    </label>
                    <input
                      type="text"
                      value={activeShowTab === 1 ? coords1.city : coords2.city}
                      onChange={(e) => {
                        const val = e.target.value;
                        if (activeShowTab === 1) setCoords1((prev) => ({ ...prev, city: val }));
                        else setCoords2((prev) => ({ ...prev, city: val }));
                      }}
                      className="w-full px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs text-slate-800 font-medium"
                    />
                  </div>

                  <div>
                    <label className="block text-[10px] font-bold text-slate-500 uppercase">
                      District
                    </label>
                    <input
                      type="text"
                      value={activeShowTab === 1 ? coords1.district : coords2.district}
                      onChange={(e) => {
                        const val = e.target.value;
                        if (activeShowTab === 1) setCoords1((prev) => ({ ...prev, district: val }));
                        else setCoords2((prev) => ({ ...prev, district: val }));
                      }}
                      className="w-full px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs text-slate-800 font-medium"
                    />
                  </div>
                </div>
              )}
            </div>

            {/* Bottom Bar: Back to Step 1 & Continue to Step 3 */}
            <div className="pt-4 border-t border-slate-100 flex items-center justify-between gap-4">
              <button
                type="button"
                onClick={() => setStep(1)}
                className="px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-600 transition-colors cursor-pointer"
              >
                &larr; Back to Details
              </button>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleSaveDraft}
                  className="px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-700 shadow-2xs transition-colors cursor-pointer"
                >
                  Save Draft
                </button>

                <button
                  type="button"
                  onClick={handleNextFromStep2}
                  className="px-5 py-2.5 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white text-xs font-extrabold shadow-sm shadow-emerald-700/20 flex items-center gap-1.5 cursor-pointer transition-all"
                >
                  <span>Continue to Pricing</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* STEP 3: PRICING & PUBLISH (with Live Preview)             */}
        {/* ========================================================= */}
        {step === 3 && (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
            {/* Left Panel: Pricing & Capacity Form (7 cols) */}
            <div className="lg:col-span-7 bg-white p-6 sm:p-8 rounded-3xl border border-slate-200/90 shadow-2xs space-y-6">
              <div>
                <h1 className="text-lg font-black text-slate-900 tracking-tight">
                  Step 3: Pricing &amp; Capacity
                </h1>
                <p className="text-xs text-slate-500 mt-0.5">
                  Set your price per guest, group size limits, and schedule availability.
                </p>
              </div>

              {/* Price Per Person */}
              <div className="space-y-2">
                <label className="block text-xs font-bold text-slate-700">
                  Price per Guest (INR) <span className="text-rose-500">*</span>
                </label>
                <div className="relative max-w-sm">
                  <span className="absolute left-4 top-2.5 text-base font-black text-slate-400">
                    ₹
                  </span>
                  <input
                    type="number"
                    min="100"
                    step="50"
                    value={priceInr}
                    onChange={(e) => setPriceInr(parseInt(e.target.value) || 0)}
                    placeholder="1200"
                    className="w-full pl-8 pr-4 py-2.5 rounded-xl border border-slate-200 text-sm font-black text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/20 focus:border-[#0e8a5b]"
                  />
                </div>

                {/* Quick Price Presets */}
                <div className="flex flex-wrap items-center gap-1.5 pt-1">
                  <span className="text-[10px] font-bold text-slate-400 uppercase mr-1">
                    Presets:
                  </span>
                  {[499, 799, 1200, 1800, 2500].map((preset) => (
                    <button
                      key={preset}
                      type="button"
                      onClick={() => setPriceInr(preset)}
                      className={`px-2.5 py-1 rounded-lg text-xs font-bold border transition-colors cursor-pointer ${
                        priceInr === preset
                          ? "bg-emerald-50 text-[#0e8a5b] border-emerald-300"
                          : "bg-white text-slate-600 border-slate-200 hover:bg-slate-50"
                      }`}
                    >
                      ₹{preset.toLocaleString()}
                    </button>
                  ))}
                </div>
              </div>

              {/* Guests Capacity & Duration */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {/* Max Guests */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-bold text-slate-700">
                    Maximum Group Size
                  </label>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => setMaxGuests(Math.max(1, maxGuests - 1))}
                      className="w-9 h-9 rounded-xl border border-slate-200 hover:bg-slate-50 flex items-center justify-center font-bold text-sm text-slate-700 cursor-pointer"
                    >
                      -
                    </button>
                    <input
                      type="number"
                      min="1"
                      max="100"
                      value={maxGuests}
                      onChange={(e) => setMaxGuests(parseInt(e.target.value) || 1)}
                      className="w-16 py-2 rounded-xl border border-slate-200 text-xs font-bold text-center text-slate-900"
                    />
                    <button
                      type="button"
                      onClick={() => setMaxGuests(maxGuests + 1)}
                      className="w-9 h-9 rounded-xl border border-slate-200 hover:bg-slate-50 flex items-center justify-center font-bold text-sm text-slate-700 cursor-pointer"
                    >
                      +
                    </button>
                    <span className="text-xs text-slate-500 font-medium">guests</span>
                  </div>
                </div>

                {/* Duration */}
                <div className="space-y-1.5">
                  <label className="block text-xs font-bold text-slate-700">
                    Duration (Hours)
                  </label>
                  <div className="flex items-center gap-2">
                    <input
                      type="number"
                      min="0.5"
                      step="0.5"
                      value={durationHours}
                      onChange={(e) => setDurationHours(parseFloat(e.target.value) || 1)}
                      className="w-20 py-2 rounded-xl border border-slate-200 text-xs font-bold text-center text-slate-900"
                    />
                    <span className="text-xs text-slate-500 font-medium">hours</span>
                  </div>
                </div>
              </div>

              {/* Availability */}
              <div className="space-y-1.5">
                <label className="block text-xs font-bold text-slate-700">
                  Availability Schedule
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {["Daily", "Weekends Only", "Weekdays Only", "Fridays & Sundays"].map((opt) => (
                    <button
                      key={opt}
                      type="button"
                      onClick={() => setAvailability(opt)}
                      className={`p-2 rounded-xl text-[11px] font-bold border transition-colors cursor-pointer ${
                        availability === opt
                          ? "bg-emerald-50 text-[#0e8a5b] border-emerald-300 ring-1 ring-[#0e8a5b]/20"
                          : "bg-white text-slate-600 border-slate-200 hover:bg-slate-50"
                      }`}
                    >
                      {opt}
                    </button>
                  ))}
                </div>
              </div>

              {/* Bottom Actions for Step 3 */}
              <div className="pt-4 border-t border-slate-100 flex items-center justify-between gap-3">
                <button
                  type="button"
                  onClick={() => setStep(2)}
                  className="px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-600 transition-colors cursor-pointer"
                >
                  &larr; Back to Location
                </button>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={handleSaveDraft}
                    className="px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-700 shadow-2xs transition-colors cursor-pointer"
                  >
                    Save Draft
                  </button>

                  <button
                    type="button"
                    onClick={handlePublish}
                    disabled={isSubmitting}
                    className="px-6 py-2.5 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] disabled:opacity-50 text-white text-xs font-black shadow-md shadow-emerald-700/25 flex items-center gap-1.5 cursor-pointer transition-all"
                  >
                    <Rocket className="w-3.5 h-3.5" />
                    <span>{isSubmitting ? "Publishing..." : "Publish Experience"}</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Right Panel: Live Traveler Preview Card (5 cols) (Requirement 4) */}
            <div className="lg:col-span-5 space-y-3">
              <div className="flex items-center justify-between px-1">
                <span className="text-xs font-black text-slate-700 uppercase tracking-wider flex items-center gap-1.5">
                  <Eye className="w-3.5 h-3.5 text-[#0e8a5b]" />
                  <span>Traveler Live Preview</span>
                </span>
                <span className="text-[10.5px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md">
                  Real-time preview
                </span>
              </div>

              {/* LocalLens Experience Card */}
              <div className="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden flex flex-col">
                {/* Card Image */}
                <div className="relative aspect-[16/10] w-full bg-slate-100">
                  <Image
                    src={photos[0] || SAMPLE_PHOTOS[0]}
                    alt={experienceName}
                    fill
                    className="object-cover"
                    unoptimized
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-slate-900/60 via-transparent to-transparent pointer-events-none" />

                  {/* Category Badge */}
                  <span className="absolute top-3 left-3 px-2.5 py-1 rounded-lg bg-white/95 backdrop-blur-md text-[10px] font-extrabold text-slate-900 shadow-xs">
                    {category}
                  </span>

                  {/* Rating Badge */}
                  <span className="absolute top-3 right-3 px-2 py-0.5 rounded-lg bg-slate-900/85 backdrop-blur-md text-white text-[10.5px] font-bold flex items-center gap-1">
                    <Star className="w-3 h-3 text-amber-400 fill-amber-400" />
                    <span>5.0</span>
                  </span>

                  {/* Setting Pill */}
                  <span className="absolute bottom-3 left-3 text-[10.5px] font-bold text-white flex items-center gap-1 drop-shadow-sm">
                    <MapPin className="w-3.5 h-3.5 text-emerald-400" />
                    <span>{coords1.city || "Mumbai"}</span>
                    <span>•</span>
                    <span>{setting}</span>
                  </span>
                </div>

                {/* Card Content Details */}
                <div className="p-4 space-y-2.5">
                  <h3 className="text-sm font-extrabold text-slate-900 leading-snug line-clamp-2">
                    {experienceName || "Sunset Kayaking at Versova"}
                  </h3>

                  <p className="text-[11px] text-slate-500 line-clamp-2 leading-relaxed">
                    {description || "Explore picturesque waters with certified guides."}
                  </p>

                  {/* Highlights Pill Cloud */}
                  <div className="flex flex-wrap items-center gap-1 pt-0.5">
                    {highlights.slice(0, 3).map((hl) => (
                      <span
                        key={hl}
                        className="px-2 py-0.5 rounded-md bg-slate-100 text-[10px] font-bold text-slate-600"
                      >
                        ✓ {hl}
                      </span>
                    ))}
                    {highlights.length > 3 && (
                      <span className="text-[9.5px] text-slate-400 font-semibold">
                        +{highlights.length - 3} more
                      </span>
                    )}
                  </div>

                  {/* Meeting Point & Schedule Info */}
                  <div className="pt-2 border-t border-slate-100 space-y-1 text-[11px] text-slate-600">
                    <div className="flex items-center gap-1.5">
                      <MapPin className="w-3.5 h-3.5 text-[#0e8a5b] shrink-0" />
                      <span className="truncate">{meetingPoint1 || "Meeting point"}</span>
                    </div>

                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5">
                        <Clock className="w-3.5 h-3.5 text-slate-400" />
                        <span>{durationHours} hrs • {startTime1}</span>
                      </div>
                      <div className="flex items-center gap-1 text-slate-500">
                        <Users className="w-3.5 h-3.5 text-slate-400" />
                        <span>Up to {maxGuests}</span>
                      </div>
                    </div>
                  </div>

                  {/* Price & Booking Button */}
                  <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                    <div>
                      <span className="text-[10px] text-slate-400 block font-medium">Price</span>
                      <div className="text-base font-black text-[#0e8a5b]">
                        ₹{priceInr.toLocaleString()}
                        <span className="text-[10.5px] text-slate-400 font-normal ml-0.5">
                          / guest
                        </span>
                      </div>
                    </div>

                    <span className="px-3.5 py-1.5 rounded-xl bg-[#0e8a5b] text-white text-[11px] font-extrabold shadow-2xs">
                      Instant Book
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>

      {/* ------------------------------------------------------------- */}
      {/* 6. Success Modal upon Publication (Celebratory Confetti)       */}
      {/* ------------------------------------------------------------- */}
      {publishedListing && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 sm:p-8 max-w-md w-full shadow-2xl border border-slate-100 text-center space-y-4 animate-in zoom-in-95 duration-200">
            <div className="w-14 h-14 rounded-2xl bg-emerald-50 text-[#0e8a5b] mx-auto flex items-center justify-center shadow-xs">
              <CheckCircle2 className="w-8 h-8 text-[#0e8a5b]" />
            </div>

            <div>
              <span className="text-[11px] font-extrabold uppercase text-[#0e8a5b] tracking-wider">
                Listing Published Successfully!
              </span>
              <h2 className="text-lg font-black text-slate-900 mt-1">
                {publishedListing.experience_name}
              </h2>
              <p className="text-xs text-slate-500 mt-1">
                Your experience is live on LocalLens and discoverable by travelers across Mumbai.
              </p>
            </div>

            <div className="p-3 bg-slate-50 rounded-2xl border border-slate-200 text-left text-xs space-y-1">
              <div className="flex justify-between">
                <span className="text-slate-500">Listing ID:</span>
                <span className="font-mono font-bold text-slate-800">{publishedListing.experience_id}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Price:</span>
                <span className="font-bold text-[#0e8a5b]">₹{publishedListing.price_inr_clean} / person</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Venue:</span>
                <span className="font-bold text-slate-800 truncate max-w-[200px]">{publishedListing.meeting_point}</span>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-2.5 pt-2">
              <Link
                href="/dashboard"
                className="py-2.5 px-3 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-700 text-center transition-colors"
              >
                Go to Dashboard
              </Link>
              <Link
                href="/boost"
                className="py-2.5 px-3 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white text-xs font-bold text-center shadow-xs transition-colors"
              >
                Boost This Listing 🚀
              </Link>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
