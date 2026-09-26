"use client";

import React, { useState } from "react";
import { ExperienceListing, BoostPackage } from "@/types/experience";
import { BOOST_PACKAGES } from "@/services/mockExperiences";
import { formatINR } from "@/utils/geoMath";
import {
  X,
  Zap,
  CheckCircle2,
  Radio,
  Flame,
  ShieldCheck,
} from "lucide-react";
import confetti from "canvas-confetti";

interface SponsorshipBoostModalProps {
  listing: ExperienceListing | null;
  isOpen: boolean;
  onClose: () => void;
  onApplyBoost: (listingId: string, boostTier: BoostPackage["name"]) => void;
}

export const SponsorshipBoostModal: React.FC<SponsorshipBoostModalProps> = ({
  listing,
  isOpen,
  onClose,
  onApplyBoost,
}) => {
  const [selectedPackage, setSelectedPackage] = useState<BoostPackage>(
    BOOST_PACKAGES[1] // Weekly Surge default
  );
  const [isProcessing, setIsProcessing] = useState(false);

  if (!isOpen || !listing) return null;

  const handleActivateBoost = () => {
    setIsProcessing(true);
    setTimeout(() => {
      onApplyBoost(listing.experience_id, selectedPackage.name);
      setIsProcessing(false);

      // Trigger celebratory confetti for real-time engagement
      confetti({
        particleCount: 80,
        spread: 70,
        origin: { y: 0.6 },
        colors: ["#8b5cf6", "#ec4899", "#3b82f6", "#10b981"],
      });

      onClose();
    }, 700);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/45 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white/95 backdrop-blur-xl border border-violet-100 rounded-3xl shadow-2xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header with Violet Gradient */}
        <div className="px-6 py-5 bg-gradient-to-r from-violet-900 via-indigo-900 to-slate-900 text-white flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-violet-600/60 border border-violet-400/40 text-yellow-300 flex items-center justify-center shadow-lg">
              <Zap className="w-5 h-5 fill-yellow-300 animate-pulse" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base font-bold tracking-tight">
                  Sponsorship &amp; Sponsored Boost Hub
                </h2>
                <span className="text-[10px] font-black uppercase px-2 py-0.5 rounded-full bg-violet-500/40 border border-violet-400 text-violet-200">
                  3D Radar Active
                </span>
              </div>
              <p className="text-xs text-violet-200/80 truncate max-w-md">
                Propel {listing.experience_name} across traveler itineraries
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-xl text-violet-300 hover:text-white hover:bg-violet-800/50 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body Packages */}
        <div className="p-6 overflow-y-auto space-y-6">
          <div className="flex items-center gap-3 p-3.5 rounded-2xl bg-violet-50 border border-violet-200/80 text-violet-950 text-xs">
            <Radio className="w-4 h-4 text-violet-700 animate-spin shrink-0" />
            <span>
              Activating any package immediately renders an omnidirectional{" "}
              <strong>pulsing 3D radar ring</strong> at your experience&apos;s coordinates on the map.
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-3.5">
            {BOOST_PACKAGES.map((pkg) => {
              const isSelected = selectedPackage.id === pkg.id;
              const isPopular = pkg.id === "boost-surge";

              return (
                <div
                  key={pkg.id}
                  onClick={() => setSelectedPackage(pkg)}
                  className={`relative p-4 rounded-2xl border-2 cursor-pointer transition-all duration-200 flex flex-col justify-between ${
                    isSelected
                      ? "border-violet-600 bg-violet-50/50 shadow-md ring-2 ring-violet-500/20"
                      : "border-slate-200 hover:border-violet-300 bg-white"
                  }`}
                >
                  {isPopular && (
                    <span className="absolute -top-2.5 left-1/2 -translate-x-1/2 px-2 py-0.5 rounded-full bg-gradient-to-r from-violet-600 to-indigo-600 text-[10px] font-extrabold text-white shadow-sm flex items-center gap-1">
                      <Flame className="w-3 h-3 fill-white" /> Popular Choice
                    </span>
                  )}

                  <div>
                    <div className="text-xs font-bold text-slate-500 uppercase tracking-wider">
                      {pkg.durationDays} Days Duration
                    </div>
                    <div className="text-base font-extrabold text-slate-900 mt-1">
                      {pkg.name}
                    </div>
                    <div className="text-xl font-black text-violet-700 mt-2">
                      {formatINR(pkg.price)}
                    </div>
                    <div className="text-xs font-bold text-emerald-600 mt-0.5">
                      {pkg.multiplierText}
                    </div>

                    <p className="text-[11px] text-slate-600 mt-3 leading-relaxed">
                      {pkg.description}
                    </p>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-500">
                    <span>Target: {pkg.recommendedFor.split("&")[0]}</span>
                    {isSelected && (
                      <CheckCircle2 className="w-4 h-4 text-violet-600" />
                    )}
                  </div>
                </div>
              );
            })}
          </div>

          <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200/80 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <ShieldCheck className="w-5 h-5 text-emerald-600" />
              <div>
                <div className="text-xs font-bold text-slate-800">
                  Instant Algorithmic Elevation
                </div>
                <div className="text-[11px] text-slate-500">
                  Instant activation upon confirmation &bull; No hidden lock-in fees
                </div>
              </div>
            </div>

            <div className="text-right">
              <span className="text-xs text-slate-400">Total Payable:</span>
              <div className="text-base font-black text-slate-900">
                {formatINR(selectedPackage.price)}
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-between bg-slate-50/50">
          <button
            onClick={onClose}
            className="px-4 py-2 rounded-xl border border-slate-200 hover:bg-slate-100 text-slate-700 text-xs font-bold transition-all"
          >
            Cancel
          </button>

          <button
            onClick={handleActivateBoost}
            disabled={isProcessing}
            className="px-6 py-2.5 rounded-xl bg-gradient-to-r from-violet-600 via-indigo-600 to-purple-600 hover:opacity-95 text-white text-xs font-bold shadow-lg shadow-violet-600/30 transition-all flex items-center gap-2 disabled:opacity-50"
          >
            <Zap className="w-4 h-4 fill-white" />
            <span>
              {isProcessing
                ? "Authorizing Boost..."
                : `Confirm & Activate ${selectedPackage.name}`}
            </span>
          </button>
        </div>
      </div>
    </div>
  );
};