'use client';

import React, { useState, useEffect } from 'react';
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
  Sparkles,
  CloudRain,
  Compass,
  ArrowRight,
  TrendingUp,
  MapPin,
} from 'lucide-react';

export default function HomePage() {
  const { user } = useAuth();
  const { isStormy, weather } = useTheme();
  const { destination, recommendations, fetchRecommendations } = useItinerary();

  const [selectedCategory, setSelectedCategory] = useState('All');
  const [displayedItems, setDisplayedItems] = useState<RecommendationModel[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    async function loadData() {
      setIsLoading(true);
      const recs = await fetchRecommendations();
      setDisplayedItems(recs);
      setIsLoading(false);
    }
    loadData();
  }, [destination]);

  useEffect(() => {
    if (selectedCategory === 'All') {
      setDisplayedItems(recommendations);
    } else {
      setDisplayedItems(
        recommendations.filter(
          (item) => item.category.toLowerCase() === selectedCategory.toLowerCase()
        )
      );
    }
  }, [selectedCategory, recommendations]);

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
            <span className="font-bold text-[#1A1A1A] dark:text-white">{destination}</span>.
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

      {/* Category Filter Chips */}
      <div>
        <div className="flex items-center justify-between mb-1">
          <div className="flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-primary" />
            <h2 className="font-display font-bold text-lg sm:text-xl text-[#1A1A1A] dark:text-white">
              Curated Local Experiences
            </h2>
          </div>
          <Link
            href="/explore"
            className="text-xs font-semibold text-primary hover:underline flex items-center gap-1"
          >
            <span>View All</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </Link>
        </div>
        <CategoryChips selectedCategory={selectedCategory} onSelectCategory={setSelectedCategory} />
      </div>

      {/* Discovery Grid */}
      {isLoading ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {Array.from({ length: 6 }).map((_, i) => (
            <div
              key={i}
              className="h-72 rounded-3xl bg-black/5 dark:bg-white/5 animate-pulse"
            />
          ))}
        </div>
      ) : displayedItems.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 sm:gap-6">
          {displayedItems.map((exp) => (
            <ExperienceCard key={exp.experienceId} experience={exp} />
          ))}
        </div>
      ) : (
        <div className="text-center py-12 px-4 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700">
          <p className="text-base font-bold text-[#1A1A1A] dark:text-white">No experiences found</p>
          <p className="text-xs text-ink-secondary dark:text-slate-400 mt-1">
            Try switching category chips or typing another prompt in smart search!
          </p>
          <button
            onClick={() => setSelectedCategory('All')}
            className="mt-4 px-4 py-2 rounded-xl bg-primary text-white text-xs font-semibold"
          >
            Reset Filters
          </button>
        </div>
      )}

      {/* Bottom Itinerary Synthesis Call-to-Action */}
      <div className="p-6 sm:p-8 rounded-3xl bg-gradient-to-r from-primary via-[#FA7252] to-amber-500 text-white shadow-floating flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <span className="px-3 py-1 rounded-full bg-white/20 backdrop-blur-md text-xs font-bold uppercase tracking-wider">
            AI Journey Optimizer
          </span>
          <h3 className="font-display font-extrabold text-xl sm:text-2xl mt-2 leading-tight">
            Ready to craft your ideal day in {destination}?
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
