"use client";

import React, { useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import dynamic from "next/dynamic";
import {
  MapPin,
  UploadCloud,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Sparkles,
  Plus,
  Compass,
} from "lucide-react";
import {
  getStoredExperiences,
  saveStoredExperiences,
} from "@/services/mockExperiences";
import { ExperienceListing } from "@/types/experience";

// Leaflet map component dynamically loaded
const LeafletPinDropper = dynamic(
  () =>
    import("@/components/map/LeafletPinDropper").then(
      (mod) => mod.LeafletPinDropper
    ),
  {
    ssr: false,
    loading: () => (
      <div className="w-full h-64 bg-slate-100 rounded-2xl flex items-center justify-center text-xs text-slate-400 font-bold">
        Loading Map...
      </div>
    ),
  }
);

export default function ExperienceListingWizardPage() {
  const router = useRouter();
  const [step, setStep] = useState<1 | 2 | 3>(2); // Step 2 active exactly matching Screen 3

  // Form State
  const [category, setCategory] = useState("Adventure");
  const [experienceName, setExperienceName] = useState("Sunset Kayaking at Versova");
  const [setting, setSetting] = useState<"Indoor" | "Outdoor" | "Mixed">("Outdoor");
  const [isAuthenticLocal, setIsAuthenticLocal] = useState(true);
  const [isHiddenGem, setIsHiddenGem] = useState(true);

  // Map state
  const [coords, setCoords] = useState({
    lat: 19.131102,
    lng: 72.815410,
    district: "Mumbai Suburban",
    city: "Mumbai",
  });

  const handleUseMyLocation = () => {
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition((pos) => {
        setCoords((prev) => ({
          ...prev,
          lat: Number(pos.coords.latitude.toFixed(6)),
          lng: Number(pos.coords.longitude.toFixed(6)),
        }));
      });
    }
  };

  const handleContinuePricing = () => {
    // Save listing
    const current = getStoredExperiences();
    const newListing: ExperienceListing = {
      experience_id: `EXP-MUM-00${current.length + 1}`,
      experience_name: experienceName,
      category: "Nature & Adventure",
      sub_category: "Kayaking & Watersports",
      tags: ["kayaking", "sunset", "versova", "adventure"],
      local_experience_bool: isAuthenticLocal,
      hidden_gem_bool: isHiddenGem,
      latitude: coords.lat,
      longitude: coords.lng,
      city: coords.city,
      district: coords.district,
      state: "Maharashtra",
      region: "Konkan",
      price_inr_clean: 1200,
      duration_hours_clean: 2.0,
      min_group_size: 1,
      max_group_size: 8,
      booking_required_bool: true,
      advance_booking_days_clean: 1,
      availability: "Daily, 05:00 PM - 07:00 PM",
      indoor_outdoor_clean: setting,
      best_time: "Sunset 05:30 PM",
      season: "October to May",
      accessibility: "Basic swimming required",
      images: [
        "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80",
        "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80",
      ],
      description: "Sunset kayaking off Versova beach with safety marshals and gear.",
      meeting_point: "Versova Beach Lifeguard Post 2",
      inclusions: ["Kayaks", "Lifejackets", "Trained Instructor"],
      rules: ["Wear swimwear or synthetic shorts"],
      cancellation_policy: "100% refund 24 hours prior",
      status: "active",
      health_score: 88,
      earnings_generated_inr: 0,
      bookings_count: 0,
      rating: 4.8,
      review_count: 142,
    };

    saveStoredExperiences([newListing, ...current]);
    router.push("/boost");
  };

  return (
    <div className="min-h-screen bg-[#f8fafc] text-slate-900 font-sans pb-16">
      {/* Top Wizard Tracker Header */}
      <header className="bg-white border-b border-slate-200/80 sticky top-0 z-30">
        <div className="max-w-6xl mx-auto px-6 h-20 flex items-center justify-between">
          <Link href="/dashboard" className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-[#0e8a5b] text-white flex items-center justify-center">
              <Compass className="w-5 h-5" />
            </div>
            <span className="font-extrabold text-sm text-slate-900">
              Local Lens
            </span>
          </Link>

          {/* 3 Steps Tracker exactly matching Screen 3 Header */}
          <div className="flex items-center gap-6 sm:gap-12">
            {/* Step 1: Completed */}
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-full bg-[#0e8a5b] text-white flex items-center justify-center text-xs font-bold">
                ✓
              </div>
              <div className="hidden sm:block">
                <div className="text-xs font-bold text-slate-800">
                  1. Story &amp; Category
                </div>
                <div className="text-[10px] text-slate-400">
                  Basic details and description
                </div>
              </div>
            </div>

            <div className="h-[1px] w-6 bg-slate-300 hidden md:block" />

            {/* Step 2: Active */}
            <div className="flex items-center gap-2.5">
              <div className="w-7 h-7 rounded-full bg-[#0e8a5b] text-white flex items-center justify-center text-xs font-bold ring-4 ring-emerald-100">
                2
              </div>
              <div className="hidden sm:block">
                <div className="text-xs font-bold text-[#0e8a5b]">
                  2. Coordinates &amp; Media
                </div>
                <div className="text-[10px] text-slate-400">
                  Add photos and location
                </div>
              </div>
            </div>

            <div className="h-[1px] w-6 bg-slate-300 hidden md:block" />

            {/* Step 3: Upcoming */}
            <div className="flex items-center gap-2.5 opacity-40">
              <div className="w-7 h-7 rounded-full bg-slate-200 text-slate-600 flex items-center justify-center text-xs font-bold">
                3
              </div>
              <div className="hidden sm:block">
                <div className="text-xs font-bold text-slate-600">
                  3. Pricing &amp; Logistics
                </div>
                <div className="text-[10px] text-slate-400">
                  Set price, timing and more
                </div>
              </div>
            </div>
          </div>

          <div />
        </div>
      </header>

      {/* Main 2-Panel Wizard Layout matching Screen 3 */}
      <main className="max-w-6xl mx-auto px-6 pt-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
          {/* Left Panel (5 cols): Experience Details & Photos */}
          <div className="lg:col-span-5 bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-5">
            <div>
              <h2 className="text-sm font-bold text-slate-900">
                Experience Details
              </h2>
            </div>

            {/* Experience Category & Name */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-[11px] font-semibold text-slate-600 mb-1">
                  Experience Category
                </label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-white border border-slate-200 text-xs font-medium text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/20"
                >
                  <option value="Adventure">Adventure</option>
                  <option value="Heritage">Heritage</option>
                  <option value="Food">Food</option>
                  <option value="Art">Art</option>
                </select>
              </div>

              <div>
                <label className="block text-[11px] font-semibold text-slate-600 mb-1">
                  Experience Name
                </label>
                <input
                  type="text"
                  value={experienceName}
                  onChange={(e) => setExperienceName(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl bg-white border border-slate-200 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/20"
                />
              </div>
            </div>

            {/* Setting: Indoor / Outdoor / Mixed */}
            <div>
              <label className="block text-[11px] font-semibold text-slate-600 mb-1.5">
                Setting
              </label>
              <div className="grid grid-cols-3 gap-2">
                {(["Indoor", "Outdoor", "Mixed"] as const).map((opt) => (
                  <button
                    key={opt}
                    type="button"
                    onClick={() => setSetting(opt)}
                    className={`py-1.5 rounded-xl text-xs font-bold transition-all border ${
                      setting === opt
                        ? "bg-[#0e8a5b] text-white border-[#0e8a5b] shadow-sm"
                        : "bg-white text-slate-600 border-slate-200 hover:bg-slate-50"
                    }`}
                  >
                    {opt}
                  </button>
                ))}
              </div>
            </div>

            {/* Tags Toggles: Authentic Local Experience & Hidden Gem */}
            <div className="space-y-2 pt-1">
              <label className="block text-[11px] font-semibold text-slate-600">
                Tags
              </label>
              <div className="flex items-center justify-between gap-4">
                {/* Toggle 1 */}
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setIsAuthenticLocal(!isAuthenticLocal)}
                    className={`w-9 h-5 flex items-center rounded-full p-0.5 transition-colors ${
                      isAuthenticLocal ? "bg-[#0e8a5b] justify-end" : "bg-slate-200 justify-start"
                    }`}
                  >
                    <span className="w-4 h-4 rounded-full bg-white shadow-sm" />
                  </button>
                  <span className="text-xs font-semibold text-slate-700">
                    Authentic Local Experience
                  </span>
                </div>

                {/* Toggle 2 */}
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setIsHiddenGem(!isHiddenGem)}
                    className={`w-9 h-5 flex items-center rounded-full p-0.5 transition-colors ${
                      isHiddenGem ? "bg-[#0e8a5b] justify-end" : "bg-slate-200 justify-start"
                    }`}
                  >
                    <span className="w-4 h-4 rounded-full bg-white shadow-sm" />
                  </button>
                  <span className="text-xs font-semibold text-slate-700">
                    Hidden Gem
                  </span>
                </div>
              </div>
            </div>

            {/* Photos (JPG/PNG) Uploader & Thumbnails matching Screen 3 */}
            <div className="space-y-2 pt-2">
              <label className="block text-[11px] font-semibold text-slate-600">
                Photos (JPG/PNG)
              </label>

              <div className="grid grid-cols-3 gap-2.5">
                {/* Upload Box */}
                <div className="border-2 border-dashed border-slate-200 rounded-2xl flex flex-col items-center justify-center p-3 text-center cursor-pointer hover:border-[#0e8a5b] bg-slate-50/50 aspect-square">
                  <UploadCloud className="w-5 h-5 text-slate-400 mb-1" />
                  <span className="text-[10px] font-bold text-slate-600 leading-tight">
                    Drag &amp; drop photos here or click to upload
                  </span>
                  <span className="text-[8px] text-slate-400 mt-1">
                    JPG, PNG (Max 10MB each)
                  </span>
                </div>

                {/* Image 1 */}
                <div className="relative rounded-2xl overflow-hidden aspect-square border border-slate-200">
                  <Image
                    src="https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=400&q=80"
                    alt="Kayaking preview 1"
                    fill
                    className="object-cover"
                    unoptimized
                  />
                  <button className="absolute top-1 right-1 w-4 h-4 rounded-full bg-black/60 text-white text-[9px] flex items-center justify-center">
                    &times;
                  </button>
                </div>

                {/* Image 2 */}
                <div className="relative rounded-2xl overflow-hidden aspect-square border border-slate-200">
                  <Image
                    src="https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=400&q=80"
                    alt="Kayaking preview 2"
                    fill
                    className="object-cover"
                    unoptimized
                  />
                  <button className="absolute top-1 right-1 w-4 h-4 rounded-full bg-black/60 text-white text-[9px] flex items-center justify-center">
                    &times;
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Right Panel (7 cols): Map Pin Dropper & Coordinates Inputs */}
          <div className="lg:col-span-7 bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="text-sm font-bold text-slate-900">
                Select Location on Map
              </h2>
            </div>

            {/* Search Input on Map */}
            <div className="relative">
              <MapPin className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search for a place or drag the pin..."
                className="w-full pl-9 pr-4 py-2 rounded-xl bg-slate-50 border border-slate-200 text-xs text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/20"
              />
            </div>

            {/* Leaflet Map with Versova Coordinates and Use My Location Button */}
            <div className="relative rounded-2xl overflow-hidden border border-slate-200">
              <LeafletPinDropper
                position={{ lat: coords.lat, lng: coords.lng }}
                onPinSelected={(pt) =>
                  setCoords((prev) => ({
                    ...prev,
                    lat: pt.lat,
                    lng: pt.lng,
                  }))
                }
              />
              <button
                type="button"
                onClick={handleUseMyLocation}
                className="absolute bottom-3 right-3 z-[400] px-3 py-1.5 rounded-xl bg-white text-slate-700 text-xs font-bold shadow-md border border-slate-200 hover:bg-slate-50 flex items-center gap-1.5"
              >
                <MapPin className="w-3.5 h-3.5 text-[#0e8a5b]" />
                <span>Use My Location</span>
              </button>
            </div>

            {/* 4 Coords Fields matching Screen 3 bottom */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2">
              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase">
                  Latitude
                </label>
                <input
                  type="text"
                  readOnly
                  value={coords.lat}
                  className="w-full px-2.5 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-mono font-bold text-slate-800"
                />
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase">
                  Longitude
                </label>
                <input
                  type="text"
                  readOnly
                  value={coords.lng}
                  className="w-full px-2.5 py-1.5 rounded-xl bg-slate-50 border border-slate-200 text-xs font-mono font-bold text-slate-800"
                />
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase">
                  District
                </label>
                <input
                  type="text"
                  value={coords.district}
                  onChange={(e) => setCoords({ ...coords, district: e.target.value })}
                  className="w-full px-2.5 py-1.5 rounded-xl bg-white border border-slate-200 text-xs text-slate-800"
                />
              </div>

              <div>
                <label className="block text-[10px] font-bold text-slate-500 uppercase">
                  City
                </label>
                <input
                  type="text"
                  value={coords.city}
                  onChange={(e) => setCoords({ ...coords, city: e.target.value })}
                  className="w-full px-2.5 py-1.5 rounded-xl bg-white border border-slate-200 text-xs text-slate-800"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Bar matching Screen 3: Back Button, AI Quality Score: 88/100, and Continue to Pricing */}
        <div className="mt-8 bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <Link
            href="/dashboard"
            className="px-5 py-2 rounded-xl border border-slate-200 hover:bg-slate-50 text-xs font-bold text-slate-700 flex items-center gap-1.5"
          >
            <span>&larr; Back</span>
          </Link>

          {/* AI Quality Score: 88/100 pill */}
          <div className="flex items-center gap-2.5 bg-amber-50/60 border border-amber-200/80 px-3.5 py-1.5 rounded-full">
            <Sparkles className="w-4 h-4 text-amber-500" />
            <span className="text-xs font-bold text-slate-800">
              AI Quality Score: <strong className="text-emerald-700 font-extrabold">88/100</strong>
            </span>
            <span className="w-2 h-2 rounded-full bg-emerald-500" />
            <span className="text-[11px] font-semibold text-emerald-800">
              Ready to publish
            </span>
          </div>

          <button
            type="button"
            onClick={handleContinuePricing}
            className="px-6 py-2.5 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white text-xs font-extrabold shadow-md shadow-emerald-700/20 flex items-center gap-1.5"
          >
            <span>Continue to Pricing</span>
            <span>&rarr;</span>
          </button>
        </div>
      </main>
    </div>
  );
}