"use client";

import React, { useState } from "react";
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
} from "lucide-react";
import confetti from "canvas-confetti";

export default function BoostYourListingPage() {
  const router = useRouter();

  // Step 1 Selection
  const [selectedListing] = useState({
    name: "Sunset Kayaking at Versova",
    category: "Adventure",
    price: "₹1,200 / person",
    rating: 4.8,
    reviews: 142,
    location: "Versova Beach, Mumbai",
    duration: "2-3 hours",
    type: "Guided Tour",
    image: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=600&q=80",
  });

  // Step 2 Package Selection ('spark' | 'push' | 'surge')
  const [packageType, setPackageType] = useState<"spark" | "push" | "surge">("push");

  // Step 3 Payment Selection
  const [paymentMethod, setPaymentMethod] = useState<"upi" | "card" | "netbanking">("upi");
  const [isProcessing, setIsProcessing] = useState(false);

  const handleLaunchBoost = () => {
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);
      confetti({
        particleCount: 120,
        spread: 80,
        origin: { y: 0.6 },
        colors: ["#0e8a5b", "#8b5cf6", "#f59e0b", "#3b82f6"],
      });
      setTimeout(() => {
        router.push("/dashboard");
      }, 1000);
    }, 700);
  };

  const getPackagePrice = () => {
    if (packageType === "spark") return { name: "Weekend Spark (3 Days)", amount: 499 };
    if (packageType === "push") return { name: "Weekly Push (7 Days)", amount: 999 };
    return { name: "Festival Surge (14 Days)", amount: 1999 };
  };

  const currentPkg = getPackagePrice();

  return (
    <div className="min-h-screen bg-[#f8fafc] text-slate-900 font-sans pb-16">
      {/* Top Header with Close Button matching Screen 4 */}
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
              <h1 className="text-xl sm:text-2xl font-black text-slate-900 tracking-tight">
                Promote Your Experience to Top Traveler Feeds
              </h1>
              <p className="text-xs text-slate-500 mt-0.5">
                Reach more travelers and get more bookings with a sponsored boost campaign.
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Main 2-Column Split: Steps (Left 8 cols) vs Preview & Summary (Right 4 cols) */}
      <main className="max-w-6xl mx-auto px-6 pt-4">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          {/* Left Column (8 cols): 3-Step Selection */}
          <div className="lg:col-span-8 space-y-6">
            {/* 1. Select Your Listing */}
            <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-3">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                1. Select Your Listing
              </h2>

              <div className="flex items-center justify-between p-3 rounded-2xl border border-slate-200 bg-slate-50/50">
                <div className="flex items-center gap-3">
                  <div className="relative w-14 h-10 rounded-xl overflow-hidden shrink-0 border border-slate-200">
                    <Image
                      src={selectedListing.image}
                      alt={selectedListing.name}
                      fill
                      className="object-cover"
                      unoptimized
                    />
                  </div>
                  <div>
                    <div className="text-xs font-extrabold text-slate-900">
                      {selectedListing.name}
                    </div>
                    <div className="text-[11px] text-slate-500">
                      {selectedListing.category} &bull; {selectedListing.price}
                    </div>
                  </div>
                </div>

                <span className="text-slate-400 text-xs">&#9662;</span>
              </div>
            </div>

            {/* 2. Choose a Boost Package */}
            <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                2. Choose a Boost Package
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
                    <div className="text-xs font-bold text-slate-800">
                      Weekend Spark
                    </div>
                    <span
                      className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                        packageType === "spark"
                          ? "border-[#0e8a5b] bg-[#0e8a5b] text-white"
                          : "border-slate-300"
                      }`}
                    >
                      {packageType === "spark" && <span className="w-1.5 h-1.5 rounded-full bg-white" />}
                    </span>
                  </div>

                  <div className="mt-2">
                    <div className="text-2xl font-black text-slate-900">₹499</div>
                    <div className="text-xs font-semibold text-slate-500">3 Days</div>
                  </div>

                  <div className="text-xs font-bold text-[#0e8a5b] mt-3">
                    ~800
                  </div>
                  <div className="text-[10px] text-slate-400">nearby travelers reached</div>

                  <ul className="mt-4 space-y-1.5 text-[11px] text-slate-600">
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Show in top traveler feeds</span>
                    </li>
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Target local &amp; nearby travelers</span>
                    </li>
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Perfect for weekends</span>
                    </li>
                  </ul>
                </div>

                {/* Package 2: Weekly Push (Recommended) */}
                <div
                  onClick={() => setPackageType("push")}
                  className={`relative p-5 rounded-2xl border-2 cursor-pointer transition-all ${
                    packageType === "push"
                      ? "border-[#0e8a5b] bg-emerald-50/20 shadow-md ring-2 ring-emerald-500/10"
                      : "border-slate-200 hover:border-slate-300 bg-white"
                  }`}
                >
                  <span className="absolute -top-3 left-1/2 -translate-x-1/2 px-2.5 py-0.5 rounded-full bg-amber-500 text-[10px] font-black text-white shadow-sm">
                    Recommended
                  </span>

                  <div className="flex items-center justify-between">
                    <div className="text-xs font-bold text-slate-800">
                      Weekly Push
                    </div>
                    <span
                      className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                        packageType === "push"
                          ? "border-[#0e8a5b] bg-[#0e8a5b] text-white"
                          : "border-slate-300"
                      }`}
                    >
                      {packageType === "push" && <span className="w-1.5 h-1.5 rounded-full bg-white" />}
                    </span>
                  </div>

                  <div className="mt-2">
                    <div className="text-2xl font-black text-slate-900">₹999</div>
                    <div className="text-xs font-semibold text-slate-500">7 Days</div>
                  </div>

                  <div className="text-xs font-bold text-[#0e8a5b] mt-3">
                    ~2,400
                  </div>
                  <div className="text-[10px] text-slate-400">nearby travelers reached</div>

                  <ul className="mt-4 space-y-1.5 text-[11px] text-slate-600">
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Higher visibility in search</span>
                    </li>
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Show in category highlights</span>
                    </li>
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Better chance of bookings</span>
                    </li>
                  </ul>
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
                    <div className="text-xs font-bold text-slate-800">
                      Festival Surge
                    </div>
                    <span
                      className={`w-4 h-4 rounded-full border flex items-center justify-center ${
                        packageType === "surge"
                          ? "border-[#0e8a5b] bg-[#0e8a5b] text-white"
                          : "border-slate-300"
                      }`}
                    >
                      {packageType === "surge" && <span className="w-1.5 h-1.5 rounded-full bg-white" />}
                    </span>
                  </div>

                  <div className="mt-2">
                    <div className="text-2xl font-black text-slate-900">₹1,999</div>
                    <div className="text-xs font-semibold text-slate-500">14 Days</div>
                  </div>

                  <div className="text-xs font-bold text-[#0e8a5b] mt-3">
                    ~6,000
                  </div>
                  <div className="text-[10px] text-slate-400">nearby travelers reached</div>

                  <ul className="mt-4 space-y-1.5 text-[11px] text-slate-600">
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Maximum visibility</span>
                    </li>
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Featured in festival campaigns</span>
                    </li>
                    <li className="flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 text-[#0e8a5b]" />
                      <span>Best for holiday season</span>
                    </li>
                  </ul>
                </div>
              </div>
            </div>

            {/* 3. Payment Method matching Screen 4 bottom */}
            <div className="bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
              <h2 className="text-xs font-bold text-slate-800 uppercase tracking-wider">
                3. Payment Method
              </h2>

              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                {/* UPI (Recommended) */}
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
                    <div className="text-xs font-bold text-slate-900">
                      UPI <span className="text-[10px] text-slate-400 font-normal">(Recommended)</span>
                    </div>
                    <div className="text-[10px] text-slate-400 font-medium">
                      GPay &bull; PhonePe &bull; Paytm
                    </div>
                  </div>
                </label>

                {/* Credit / Debit Card */}
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
                    <div className="text-xs font-bold text-slate-900">
                      Credit / Debit Card
                    </div>
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
                    <div className="text-xs font-bold text-slate-900">
                      Net Banking
                    </div>
                  </div>
                </label>
              </div>
            </div>
          </div>

          {/* Right Column (4 cols): Preview in Traveler App & Campaign Summary */}
          <div className="lg:col-span-4 space-y-5">
            {/* Preview in Traveler App Card matching Screen 4 right */}
            <div className="bg-white p-5 rounded-3xl border border-slate-200/80 shadow-sm space-y-3">
              <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                Preview in Traveler App
              </h3>

              <div className="rounded-2xl border border-slate-200/80 overflow-hidden shadow-sm">
                <div className="relative aspect-[16/10] w-full">
                  <Image
                    src={selectedListing.image}
                    alt={selectedListing.name}
                    fill
                    className="object-cover"
                    unoptimized
                  />
                  {/* Sponsored Tag */}
                  <span className="absolute top-2.5 left-2.5 px-2 py-0.5 rounded-md bg-white/90 backdrop-blur-md text-[10px] font-extrabold text-slate-900 shadow-sm">
                    Sponsored
                  </span>

                  {/* Heart */}
                  <button className="absolute top-2.5 right-2.5 w-6 h-6 rounded-full bg-white/90 flex items-center justify-center text-slate-700">
                    &hearts;
                  </button>
                </div>

                <div className="p-3.5 space-y-1.5">
                  <h4 className="text-xs font-extrabold text-slate-900">
                    {selectedListing.name}
                  </h4>

                  <div className="flex items-center gap-1 text-[11px] text-slate-500">
                    <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                    <span className="font-bold text-slate-900">{selectedListing.rating}</span>
                    <span>({selectedListing.reviews})</span>
                  </div>

                  <div className="text-[11px] text-slate-500 flex items-center gap-1">
                    <MapPin className="w-3 h-3 text-slate-400" />
                    <span>{selectedListing.location}</span>
                  </div>

                  <div className="text-xs font-black text-slate-900 pt-1">
                    {selectedListing.price}
                  </div>

                  <div className="pt-2 flex items-center gap-3 text-[10px] text-slate-500 border-t border-slate-100">
                    <span>⏱ {selectedListing.duration}</span>
                    <span>🎯 {selectedListing.type}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Campaign Summary Box matching Screen 4 bottom right */}
            <div className="bg-white p-5 rounded-3xl border border-slate-200/80 shadow-sm space-y-4">
              <h3 className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                Campaign Summary
              </h3>

              <div className="space-y-2 text-xs">
                <div className="flex items-center justify-between text-slate-600">
                  <span>{currentPkg.name}</span>
                  <span className="font-bold text-slate-900">₹{currentPkg.amount}</span>
                </div>
                <div className="flex items-center justify-between text-slate-600">
                  <span>Platform Fee (0%)</span>
                  <span className="font-bold text-slate-900">₹0</span>
                </div>
                <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-sm font-black text-slate-900">
                  <span>Total Amount</span>
                  <span className="text-base text-[#0e8a5b]">₹{currentPkg.amount}</span>
                </div>
              </div>

              <button
                type="button"
                onClick={handleLaunchBoost}
                disabled={isProcessing}
                className="w-full py-3.5 px-4 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white font-extrabold text-xs shadow-lg shadow-emerald-700/25 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
              >
                <Zap className="w-4 h-4 fill-white" />
                <span>
                  {isProcessing ? "Launching Campaign..." : "Confirm & Launch Boost 🚀"}
                </span>
              </button>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}