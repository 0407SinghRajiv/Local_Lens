"use client";

import React, { useState, useEffect, useMemo } from "react";
import Link from "next/link";
import Image from "next/image";
import { ProviderNavbar } from "@/components/layout/ProviderNavbar";
import {
  getStoredExperiences,
  saveStoredExperiences,
} from "@/services/mockExperiences";
import { ExperienceListing, BoostPackage } from "@/types/experience";
import { formatINR } from "@/utils/geoMath";
import { AiQualityAuditModal } from "@/components/modals/AiQualityAuditModal";
import { SponsorshipBoostModal } from "@/components/modals/SponsorshipBoostModal";
import { SponsorCampaignsTable } from "@/components/sponsors/SponsorCampaignsTable";
import {
  Plus,
  Search,
  Zap,
  Sparkles,
  MapPin,
  AlertTriangle,
  CheckCircle2,
  PauseCircle,
  PlayCircle,
  LayoutGrid,
  Table,
} from "lucide-react";

export default function ListingsPage() {
  const [experiences, setExperiences] = useState<ExperienceListing[]>([]);
  const [searchQuery, setSearchQuery] = useState("");
  const [filterCategory, setFilterCategory] = useState("All");
  const [activeTab, setActiveTab] = useState<"listings" | "sponsor_campaigns">("listings");

  // Modals
  const [selectedForAudit, setSelectedForAudit] = useState<ExperienceListing | null>(null);
  const [isAuditOpen, setIsAuditOpen] = useState(false);

  const [selectedForBoost, setSelectedForBoost] = useState<ExperienceListing | null>(null);
  const [isBoostOpen, setIsBoostOpen] = useState(false);

  const loadExperiences = async () => {
    try {
      const resp = await fetch("/api/experiences?all=true");
      const res = await resp.json();
      if (res.success && Array.isArray(res.data) && res.data.length > 0) {
        setExperiences(res.data);
        return;
      }
    } catch (e) {
      console.warn("API experience load notice:", e);
    }
    // Fallback to local storage only if offline/unreachable
    const stored = getStoredExperiences();
    if (stored && stored.length > 0) {
      setExperiences(stored);
    }
  };

  useEffect(() => {
    loadExperiences();
    const handleUpdate = () => {
      loadExperiences();
    };
    window.addEventListener("experiences_updated", handleUpdate);
    return () => window.removeEventListener("experiences_updated", handleUpdate);
  }, []);

  const handleTogglePause = (experienceId: string) => {
    const updated = experiences.map((exp) => {
      if (exp.experience_id === experienceId) {
        return {
          ...exp,
          status: exp.status === "paused" ? ("active" as const) : ("paused" as const),
        };
      }
      return exp;
    });
    setExperiences(updated);
    saveStoredExperiences(updated);
  };

  const handleApplyAuditImprovement = (
    listingId: string,
    updates: Partial<ExperienceListing>
  ) => {
    const updated = experiences.map((exp) =>
      exp.experience_id === listingId ? { ...exp, ...updates } : exp
    );
    setExperiences(updated);
    saveStoredExperiences(updated);
  };

  const handleApplyBoost = (listingId: string, boostTier: BoostPackage['name']) => {
    const updated = experiences.map((exp) => {
      if (exp.experience_id === listingId) {
        return {
          ...exp,
          status: "boosted" as const,
          boost_tier: boostTier,
          boost_expires_at: new Date(Date.now() + 7 * 86400000).toISOString(),
        };
      }
      return exp;
    });
    setExperiences(updated);
    saveStoredExperiences(updated);
  };

  const boostedCount = useMemo(() => {
    return experiences.filter((e) => e.status === "boosted").length;
  }, [experiences]);

  const filtered = useMemo(() => {
    return experiences.filter((exp) => {
      const matchesSearch =
        exp.experience_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        exp.city.toLowerCase().includes(searchQuery.toLowerCase()) ||
        exp.tags.some((t) => t.toLowerCase().includes(searchQuery.toLowerCase()));

      const matchesCat = filterCategory === "All" || exp.category === filterCategory;
      return matchesSearch && matchesCat;
    });
  }, [experiences, searchQuery, filterCategory]);

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans selection:bg-emerald-500 selection:text-white pb-20">
      <ProviderNavbar />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 space-y-6">
        {/* Header Strip */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-6 rounded-3xl border border-slate-200/80 shadow-sm">
          <div>
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
              <h1 className="text-2xl font-black text-slate-900 tracking-tight">
                Provider Experience Hub &amp; Sponsorships
              </h1>
            </div>
            <p className="text-xs text-slate-500 mt-1">
              Manage status, review AI quality compliance, track database sponsor campaigns, and activate 3D radar boosts
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => {
                if (experiences.length > 0) {
                  setSelectedForBoost(experiences[0]);
                  setIsBoostOpen(true);
                }
              }}
              className="px-4 py-2.5 rounded-2xl bg-gradient-to-r from-violet-600 to-indigo-600 hover:opacity-95 text-white font-extrabold text-xs shadow-lg shadow-violet-600/25 transition-all flex items-center gap-1.5"
            >
              <Zap className="w-4 h-4 fill-white" />
              <span>Boost / Sponsor</span>
            </button>

            <Link
              href="/experiences/new"
              className="px-5 py-2.5 rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs shadow-lg shadow-emerald-600/25 transition-all flex items-center gap-1.5"
            >
              <Plus className="w-4 h-4" />
              <span>Create New Listing</span>
            </Link>
          </div>
        </div>

        {/* Tab Switcher: "Experiences & Listings" vs "Sponsor Campaigns Table" */}
        <div className="flex items-center gap-2 p-1.5 bg-slate-200/70 rounded-2xl w-fit">
          <button
            onClick={() => setActiveTab("listings")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === "listings"
                ? "bg-white text-slate-900 shadow-sm"
                : "text-slate-600 hover:text-slate-900"
            }`}
          >
            <LayoutGrid className="w-3.5 h-3.5" />
            <span>My Listings</span>
            <span className="px-1.5 py-0.5 rounded-full bg-slate-100 text-[10px] font-extrabold">
              {experiences.length}
            </span>
          </button>

          <button
            onClick={() => setActiveTab("sponsor_campaigns")}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 ${
              activeTab === "sponsor_campaigns"
                ? "bg-gradient-to-r from-violet-600 to-indigo-600 text-white shadow-sm"
                : "text-slate-600 hover:text-slate-900"
            }`}
          >
            <Table className="w-3.5 h-3.5" />
            <Zap className="w-3.5 h-3.5 fill-current text-yellow-300" />
            <span>Sponsor Campaigns Table</span>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-black uppercase ${
              activeTab === "sponsor_campaigns" ? "bg-white/20 text-white" : "bg-violet-100 text-violet-700"
            }`}>
              {boostedCount > 0 ? `${boostedCount} Active` : "Database"}
            </span>
          </button>
        </div>

        {/* Render Tab Contents */}
        {activeTab === "sponsor_campaigns" ? (
          <SponsorCampaignsTable
            onOpenBoostModal={() => {
              if (experiences.length > 0) {
                setSelectedForBoost(experiences[0]);
                setIsBoostOpen(true);
              }
            }}
          />
        ) : (
          <>
            {/* Search & Categories Bar */}
            <div className="flex flex-col md:flex-row gap-4 items-center justify-between">
              <div className="relative w-full md:w-96">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Search listings by title, city, or tags..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 rounded-2xl bg-white border border-slate-200 text-xs focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-600"
                />
              </div>

              <div className="flex gap-2 overflow-x-auto w-full md:w-auto pb-1 scrollbar-none text-xs font-semibold">
                {["All", "Heritage", "Culinary & Food", "Nature & Adventure", "Culture & Arts"].map((cat) => (
                  <button
                    key={cat}
                    onClick={() => setFilterCategory(cat)}
                    className={`px-3.5 py-1.5 rounded-xl shrink-0 transition-all ${
                      filterCategory === cat
                        ? "bg-emerald-600 text-white font-bold shadow-sm"
                        : "bg-white text-slate-600 border border-slate-200 hover:bg-slate-100"
                    }`}
                  >
                    {cat}
                  </button>
                ))}
              </div>
            </div>

            {/* Listings Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {filtered.map((exp) => {
                const isBoosted = exp.status === "boosted";
                const isNeedsAudit = exp.status === "needs_improvement";

            const isPaused = exp.status === "paused";

            return (
              <div
                key={exp.experience_id}
                className="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden flex flex-col justify-between hover:shadow-md transition-shadow"
              >
                {/* Media Image */}
                <div className="relative aspect-video w-full">
                  <Image
                    src={exp.images[0]}
                    alt={exp.experience_name}
                    fill
                    className="object-cover"
                    unoptimized
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />

                  {/* Badges Overlay */}
                  <div className="absolute top-3 left-3 flex gap-1.5">
                    <span className="px-2.5 py-1 rounded-full bg-slate-900/80 backdrop-blur-md text-[10px] font-bold text-white">
                      {exp.category}
                    </span>

                    {exp.hidden_gem_bool && (
                      <span className="px-2 py-0.5 rounded-full bg-emerald-600/90 text-[10px] font-bold text-white shadow-sm">
                        💎 Hidden Gem
                      </span>
                    )}
                  </div>

                  {/* Status Pill on Media */}
                  <div className="absolute top-3 right-3">
                    {isBoosted && (
                      <span className="px-2.5 py-1 rounded-full bg-violet-600 text-[10px] font-extrabold text-white flex items-center gap-1 shadow-lg">
                        <Zap className="w-3 h-3 fill-white" /> Sponsored
                      </span>
                    )}

                    {isNeedsAudit && (
                      <span className="px-2.5 py-1 rounded-full bg-amber-500 text-[10px] font-bold text-white flex items-center gap-1 shadow-md">
                        <AlertTriangle className="w-3 h-3" /> Needs Review
                      </span>
                    )}

                    {isPaused && (
                      <span className="px-2.5 py-1 rounded-full bg-slate-700 text-[10px] font-bold text-white flex items-center gap-1 shadow-sm">
                        <PauseCircle className="w-3 h-3" /> Paused
                      </span>
                    )}

                    {!isBoosted && !isNeedsAudit && !isPaused && (
                      <span className="px-2.5 py-1 rounded-full bg-emerald-600 text-[10px] font-bold text-white flex items-center gap-1 shadow-sm">
                        <CheckCircle2 className="w-3 h-3" /> Active
                      </span>
                    )}
                  </div>

                  <div className="absolute bottom-3 left-3 right-3 text-white">
                    <div className="text-[11px] text-slate-200 flex items-center gap-1">
                      <MapPin className="w-3 h-3 text-emerald-400" />
                      <span>{exp.district}, {exp.city}</span>
                    </div>
                  </div>
                </div>

                {/* Card Content Body */}
                <div className="p-5 space-y-4 flex-1 flex flex-col justify-between">
                  <div>
                    <h3 className="text-sm font-extrabold text-slate-900 line-clamp-1">
                      {exp.experience_name}
                    </h3>
                    <p className="text-xs text-slate-500 mt-1 line-clamp-2 leading-relaxed">
                      {exp.description}
                    </p>
                  </div>

                  {/* Spec Strip */}
                  <div className="grid grid-cols-3 gap-2 p-2.5 rounded-2xl bg-slate-50 border border-slate-100 text-center">
                    <div>
                      <div className="text-[10px] text-slate-400 font-semibold uppercase">Price</div>
                      <div className="text-xs font-black text-slate-900 mt-0.5">
                        {formatINR(exp.price_inr_clean)}
                      </div>
                    </div>
                    <div>
                      <div className="text-[10px] text-slate-400 font-semibold uppercase">Duration</div>
                      <div className="text-xs font-bold text-slate-900 mt-0.5">
                        {exp.duration_hours_clean} hrs
                      </div>
                    </div>
                    <div>
                      <div className="text-[10px] text-slate-400 font-semibold uppercase">Quality</div>
                      <div className="text-xs font-black text-emerald-600 mt-0.5">
                        {exp.health_score}%
                      </div>
                    </div>
                  </div>

                  {/* Action Buttons */}
                  <div className="pt-2 border-t border-slate-100 flex items-center gap-2">
                    {/* AI Audit */}
                    <button
                      onClick={() => {
                        setSelectedForAudit(exp);
                        setIsAuditOpen(true);
                      }}
                      className="flex-1 py-2 rounded-xl border border-slate-200 hover:border-emerald-300 hover:bg-emerald-50/50 text-[11px] font-bold text-slate-700 transition-all flex items-center justify-center gap-1"
                    >
                      <Sparkles className="w-3.5 h-3.5 text-emerald-600" />
                      <span>Audit</span>
                    </button>

                    {/* Pause / Resume */}
                    <button
                      onClick={() => handleTogglePause(exp.experience_id)}
                      className={`p-2 rounded-xl border text-xs transition-colors ${
                        isPaused
                          ? "border-emerald-200 text-emerald-700 hover:bg-emerald-50"
                          : "border-slate-200 text-slate-600 hover:bg-slate-100"
                      }`}
                      title={isPaused ? "Resume Experience" : "Pause Experience"}
                    >
                      {isPaused ? <PlayCircle className="w-4 h-4" /> : <PauseCircle className="w-4 h-4" />}
                    </button>

                    {/* Sponsored Boost */}
                    <button
                      onClick={() => {
                        setSelectedForBoost(exp);
                        setIsBoostOpen(true);
                      }}
                      className="py-2 px-3.5 rounded-xl bg-violet-600 hover:bg-violet-700 text-white text-[11px] font-bold shadow-md shadow-violet-600/20 transition-all flex items-center gap-1"
                    >
                      <Zap className="w-3.5 h-3.5 fill-white" />
                      <span>Boost</span>
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </>
    )}
  </main>

      {/* MODALS */}
      <AiQualityAuditModal
        listing={selectedForAudit}
        isOpen={isAuditOpen}
        onClose={() => setIsAuditOpen(false)}
        onApplyImprovement={handleApplyAuditImprovement}
      />

      <SponsorshipBoostModal
        listing={selectedForBoost}
        isOpen={isBoostOpen}
        onClose={() => setIsBoostOpen(false)}
        onApplyBoost={handleApplyBoost}
      />
    </div>
  );
}