'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import Link from 'next/link';
import { useAuth } from '@/context/AuthContext';
import { useTheme } from '@/context/ThemeContext';
import { useItinerary } from '@/context/ItineraryContext';
import { SmartSearchBar } from '@/components/home/SmartSearchBar';
import { SponsoredCarousel } from '@/components/home/SponsoredCarousel';
import { CategoryChips } from '@/components/home/CategoryChips';
import { ExperienceCard } from '@/components/home/ExperienceCard';
import { RecommendationModel } from '@/types';
import {
  VerifiedExperienceService,
  FetchVerifiedExperiencesResult,
} from '@/lib/verifiedExperienceService';
import {
  Sparkles,
  CloudRain,
  Compass,
  ArrowRight,
  ShieldCheck,
  MapPin,
  Search,
  RotateCw,
  AlertCircle,
  Camera,
  Filter,
} from 'lucide-react';

const PAGE_SIZE = 12;

export default function HomePage() {
  const { user } = useAuth();
  const { isStormy, weather } = useTheme();
  const { destination: contextDestination } = useItinerary();

  // State for verified Supabase experiences
  const [displayedItems, setDisplayedItems] = useState<RecommendationModel[]>([]);
  const [totalCount, setTotalCount] = useState<number>(0);
  const [page, setPage] = useState<number>(1);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isLoadingMore, setIsLoadingMore] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Filters
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [selectedDestination, setSelectedDestination] = useState<string>('All');
  const [searchFilter, setSearchFilter] = useState<string>('');
  const [availableDestinations, setAvailableDestinations] = useState<string[]>([]);

  // Prevent race conditions with request tracking
  const requestIdRef = useRef<number>(0);

  // Fetch available destinations dynamically from verified Supabase records
  useEffect(() => {
    async function loadDestinations() {
      const dests = await VerifiedExperienceService.getVerifiedDestinations();
      setAvailableDestinations(dests);
    }
    loadDestinations();
  }, []);

  // Primary loader function for verified experiences
  const loadVerifiedExperiences = useCallback(
    async (
      targetPage: number = 1,
      append: boolean = false
    ) => {
      const currentReqId = ++requestIdRef.current;

      if (targetPage === 1) {
        setIsLoading(true);
      } else {
        setIsLoadingMore(true);
      }
      setError(null);

      try {
        const result: FetchVerifiedExperiencesResult =
          await VerifiedExperienceService.getVerifiedExperiences({
            page: targetPage,
            pageSize: PAGE_SIZE,
            category: selectedCategory !== 'All' ? selectedCategory : undefined,
            destination: selectedDestination !== 'All' ? selectedDestination : undefined,
            searchQuery: searchFilter.trim() !== '' ? searchFilter.trim() : undefined,
          });

        // Ignore stale responses
        if (currentReqId !== requestIdRef.current) return;

        if (result.error) {
          setError(result.error);
        } else {
          if (append) {
            setDisplayedItems((prev) => [...prev, ...result.recommendations]);
          } else {
            setDisplayedItems(result.recommendations);
          }
          setTotalCount(result.totalCount);
          setPage(targetPage);
        }
      } catch (err: any) {
        if (currentReqId === requestIdRef.current) {
          setError(err?.message || 'Failed to retrieve verified experiences.');
        }
      } finally {
        if (currentReqId === requestIdRef.current) {
          setIsLoading(false);
          setIsLoadingMore(false);
        }
      }
    },
    [selectedCategory, selectedDestination, searchFilter]
  );

  // Trigger fetch whenever filters change
  useEffect(() => {
    setPage(1);
    loadVerifiedExperiences(1, false);
  }, [selectedCategory, selectedDestination, searchFilter, loadVerifiedExperiences]);

  // Realtime database subscription to automatically update when database changes
  useEffect(() => {
    const unsubscribe = VerifiedExperienceService.subscribeToChanges(() => {
      // Re-fetch current view when matching records are inserted, updated, or deleted
      loadVerifiedExperiences(1, false);
    });

    return () => {
      unsubscribe();
    };
  }, [loadVerifiedExperiences]);

  // Load more pagination handler
  function handleLoadMore() {
    if (isLoadingMore || displayedItems.length >= totalCount) return;
    loadVerifiedExperiences(page + 1, true);
  }

  // Reset all filters
  function handleResetFilters() {
    setSelectedCategory('All');
    setSelectedDestination('All');
    setSearchFilter('');
  }

  const hasActiveFilters =
    selectedCategory !== 'All' ||
    selectedDestination !== 'All' ||
    searchFilter.trim() !== '';

  return (
    <div className="space-y-6 sm:space-y-8 animate-in fade-in duration-300">
      {/* Editorial Welcome Header */}
      <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pt-2">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary-soft dark:bg-primary/20 text-primary mb-2 text-xs font-bold">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Intelligent Local Discovery</span>
          </div>
          <h1 className="font-display font-extrabold text-2xl sm:text-3xl lg:text-4xl tracking-tight text-[#1A1A1A] dark:text-white">
            Namaste, {user?.displayName || 'Traveler'}! 🙏
          </h1>
          <p className="text-sm sm:text-base text-ink-secondary dark:text-slate-400 mt-1 max-w-xl">
            Explore authentic local treasures, taste street secrets, and build your personalized trip in{' '}
            <span className="font-bold text-[#1A1A1A] dark:text-white">{contextDestination}</span>.
          </p>
        </div>

        <Link
          href="/itinerary/create"
          className="self-start sm:self-auto px-5 py-3 rounded-2xl bg-primary hover:bg-primary-dark text-white font-bold text-sm shadow-soft flex items-center gap-2 active:scale-95 transition-all"
        >
          <Compass className="w-4 h-4" />
          <span>Plan Itinerary</span>
        </Link>
      </div>

      {/* Groq AI Smart Search Prompt */}
      <SmartSearchBar />

      {/* Weather Disruption Banner (Active when storm is triggered) */}
      {isStormy && (
        <div className="p-4 sm:p-5 rounded-3xl bg-gradient-to-r from-sky-950 via-slate-900 to-indigo-950 border border-sky-500/50 text-white shadow-floating flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 animate-in slide-in-from-top-4 duration-300">
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-sky-500/20 text-sky-400 flex items-center justify-center shrink-0">
              <CloudRain className="w-6 h-6 animate-bounce" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="px-2 py-0.5 rounded text-[10px] font-extrabold bg-sky-500 text-slate-950 uppercase tracking-wider">
                  Live Monsoon Alert
                </span>
                <span className="text-xs font-semibold text-sky-200">{weather.tempCelsius}</span>
              </div>
              <h4 className="text-base font-bold mt-0.5">Heavy Rain & Thunderstorm Detected</h4>
              <p className="text-xs text-sky-200/80 mt-0.5 max-w-md">
                Indoor artisan cafes, heritage museums, and sheltered food trails have been prioritized for your comfort.
              </p>
            </div>
          </div>

          <Link
            href="/itinerary/create"
            className="px-4 py-2 rounded-xl bg-sky-400 hover:bg-sky-300 text-slate-950 text-xs font-bold transition-all shrink-0 active:scale-95"
          >
            Adapt Route
          </Link>
        </div>
      )}

      {/* Sponsored Local Experiences Carousel */}
      <SponsoredCarousel />

      {/* ========================================================================= */}
      {/* VERIFIED SUPABASE EXPERIENCES SECTION */}
      {/* ========================================================================= */}
      <section className="space-y-4 pt-2">
        {/* Section Header */}
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-3 border-b border-[#EAE8E3] dark:border-slate-800 pb-4">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 text-xs font-bold">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
                <span>Verified Exact Match</span>
              </span>
              <span className="text-xs font-semibold text-ink-muted dark:text-slate-400">
                • {totalCount} {totalCount === 1 ? 'place' : 'places'} verified
              </span>
            </div>
            <h2 className="font-display font-extrabold text-xl sm:text-2xl lg:text-3xl tracking-tight text-[#1A1A1A] dark:text-white">
              Discover Authentic Experiences
            </h2>
            <p className="text-xs sm:text-sm text-ink-secondary dark:text-slate-400 mt-1 max-w-2xl">
              Explore handpicked destinations and experiences with verified real-world photographs.
            </p>
          </div>

          {/* Quick Refresh Button */}
          <div className="flex items-center gap-2 self-start md:self-auto">
            <button
              onClick={() => loadVerifiedExperiences(1, false)}
              disabled={isLoading}
              title="Refresh verified records from Supabase"
              className="p-2.5 rounded-xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 hover:border-primary/40 text-ink-secondary dark:text-slate-300 hover:text-primary transition-all active:scale-95 text-xs font-medium flex items-center gap-1.5 shadow-sm disabled:opacity-50"
            >
              <RotateCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin text-primary' : ''}`} />
              <span className="hidden sm:inline">Refresh</span>
            </button>
            <Link
              href="/explore"
              className="px-3.5 py-2 rounded-xl bg-primary-soft dark:bg-primary/20 text-primary font-bold text-xs hover:bg-primary hover:text-white transition-all flex items-center gap-1"
            >
              <span>Explore All</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>

        {/* Filter Controls: Search by Name, Destination Selector, Category Chips */}
        <div className="space-y-3">
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2.5">
            {/* Search by Name/Keywords */}
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-ink-muted absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={searchFilter}
                onChange={(e) => setSearchFilter(e.target.value)}
                placeholder="Filter verified experiences by name or tags..."
                className="w-full h-10 pl-10 pr-4 rounded-xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 text-xs text-[#1A1A1A] dark:text-white placeholder:text-ink-muted focus:outline-none focus:ring-2 focus:ring-primary/30"
              />
              {searchFilter && (
                <button
                  onClick={() => setSearchFilter('')}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-xs text-ink-muted hover:text-ink"
                >
                  ✕
                </button>
              )}
            </div>

            {/* Destination Selector */}
            <div className="relative sm:w-56">
              <MapPin className="w-3.5 h-3.5 text-primary absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
              <select
                value={selectedDestination}
                onChange={(e) => setSelectedDestination(e.target.value)}
                className="w-full h-10 pl-9 pr-8 rounded-xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 text-xs font-medium text-[#1A1A1A] dark:text-white focus:outline-none focus:ring-2 focus:ring-primary/30 appearance-none cursor-pointer"
              >
                <option value="All">All Destinations</option>
                {availableDestinations.map((d) => (
                  <option key={d} value={d}>
                    {d}
                  </option>
                ))}
              </select>
              <div className="absolute right-3 top-1/2 -translate-y-1/2 pointer-events-none text-ink-muted text-xs">
                ▼
              </div>
            </div>

            {/* Active Filters Clear Button */}
            {hasActiveFilters && (
              <button
                onClick={handleResetFilters}
                className="px-3 h-10 rounded-xl bg-slate-100 dark:bg-slate-700 text-ink-secondary dark:text-slate-300 hover:text-primary text-xs font-semibold transition-colors shrink-0 flex items-center gap-1"
              >
                <Filter className="w-3 h-3" />
                <span>Clear Filters</span>
              </button>
            )}
          </div>

          {/* Category Filter Chips */}
          <CategoryChips
            selectedCategory={selectedCategory}
            onSelectCategory={setSelectedCategory}
          />
        </div>

        {/* Discovery Grid & States */}
        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
            {Array.from({ length: 6 }).map((_, i) => (
              <div
                key={i}
                className="h-80 rounded-3xl bg-black/5 dark:bg-white/5 animate-pulse flex flex-col justify-end p-4"
              >
                <div className="h-4 w-2/3 bg-black/10 dark:bg-white/10 rounded-md mb-2" />
                <div className="h-3 w-1/2 bg-black/10 dark:bg-white/10 rounded-md" />
              </div>
            ))}
          </div>
        ) : error ? (
          <div className="text-center py-12 px-4 rounded-3xl bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-900/50">
            <AlertCircle className="w-8 h-8 text-red-500 mx-auto mb-2" />
            <h3 className="text-base font-bold text-red-900 dark:text-red-200">
              Unable to load verified experiences
            </h3>
            <p className="text-xs text-red-700 dark:text-red-300 mt-1 max-w-md mx-auto">
              {error}
            </p>
            <button
              onClick={() => loadVerifiedExperiences(1, false)}
              className="mt-4 px-4 py-2 rounded-xl bg-red-600 hover:bg-red-700 text-white text-xs font-semibold shadow-sm transition-all"
            >
              Retry Database Connection
            </button>
          </div>
        ) : displayedItems.length > 0 ? (
          <>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 sm:gap-6">
              {displayedItems.map((exp) => (
                <ExperienceCard key={exp.experienceId} experience={exp} />
              ))}
            </div>

            {/* Pagination / Load More Button */}
            {displayedItems.length < totalCount && (
              <div className="flex flex-col items-center justify-center pt-4">
                <button
                  onClick={handleLoadMore}
                  disabled={isLoadingMore}
                  className="px-6 py-3 rounded-2xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 hover:border-primary text-ink dark:text-white font-bold text-xs sm:text-sm shadow-soft hover:shadow-floating transition-all active:scale-95 flex items-center gap-2"
                >
                  {isLoadingMore ? (
                    <>
                      <RotateCw className="w-4 h-4 animate-spin text-primary" />
                      <span>Loading more verified records...</span>
                    </>
                  ) : (
                    <>
                      <span>
                        Load More Experiences ({displayedItems.length} of {totalCount})
                      </span>
                      <ArrowRight className="w-4 h-4 text-primary" />
                    </>
                  )}
                </button>
              </div>
            )}
          </>
        ) : (
          <div className="text-center py-14 px-4 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700">
            <Camera className="w-10 h-10 text-ink-muted dark:text-slate-500 mx-auto mb-2.5 opacity-60" />
            <p className="text-base font-bold text-[#1A1A1A] dark:text-white">
              No verified experiences found
            </p>
            <p className="text-xs text-ink-secondary dark:text-slate-400 mt-1 max-w-md mx-auto">
              {hasActiveFilters
                ? 'No records with verified real photographs match your current filter combination.'
                : 'There are currently no records marked with "verified exact match" in the database.'}
            </p>
            {hasActiveFilters && (
              <button
                onClick={handleResetFilters}
                className="mt-4 px-4 py-2 rounded-xl bg-primary text-white text-xs font-semibold shadow-sm hover:bg-primary-dark transition-all"
              >
                Reset Filters
              </button>
            )}
          </div>
        )}
      </section>

      {/* Bottom Itinerary Synthesis Call-to-Action */}
      <div className="p-6 sm:p-8 rounded-3xl bg-gradient-to-r from-primary via-[#FA7252] to-amber-500 text-white shadow-floating flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <span className="px-3 py-1 rounded-full bg-white/20 backdrop-blur-md text-xs font-bold uppercase tracking-wider">
            AI Journey Optimizer
          </span>
          <h3 className="font-display font-extrabold text-xl sm:text-2xl mt-2 leading-tight">
            Ready to craft your ideal day in {contextDestination}?
          </h3>
          <p className="text-xs sm:text-sm text-white/90 mt-1 max-w-lg">
            Tell us your budget, traveler group, and hours. We will synthesize the optimal geographic route, schedule stops, and coordinate rides.
          </p>
        </div>

        <Link
          href="/itinerary/create"
          className="px-6 py-3.5 rounded-2xl bg-white text-primary hover:bg-[#FAF9F6] font-bold text-sm shadow-md flex items-center gap-2 active:scale-95 transition-all shrink-0"
        >
          <span>Start Trip Planner</span>
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </div>
  );
}
