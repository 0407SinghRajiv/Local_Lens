'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useItinerary } from '@/context/ItineraryContext';
import { ExperienceCard } from '@/components/home/ExperienceCard';
import { CategoryChips } from '@/components/home/CategoryChips';
import { Bookmark, Compass } from 'lucide-react';

export default function SavedPage() {
  const { wishlist, recommendations } = useItinerary();
  const [selectedCategory, setSelectedCategory] = useState('All');

  const savedExperiences = recommendations.filter((r) => wishlist.includes(r.experienceId));
  const filtered =
    selectedCategory === 'All'
      ? savedExperiences
      : savedExperiences.filter(
          (item) => item.category.toLowerCase() === selectedCategory.toLowerCase()
        );

  return (
    <div className="space-y-6 pb-12 animate-in fade-in duration-300">
      <div>
        <h1 className="font-display font-extrabold text-2xl sm:text-3xl text-[#1A1A1A] dark:text-white">
          Saved Places & Wishlist
        </h1>
        <p className="text-xs sm:text-sm text-ink-secondary dark:text-slate-400 mt-0.5">
          Your bookmarked hidden gems, street food spots, and nature trails.
        </p>
      </div>

      <CategoryChips selectedCategory={selectedCategory} onSelectCategory={setSelectedCategory} />

      {filtered.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 sm:gap-6">
          {filtered.map((item) => (
            <ExperienceCard key={item.experienceId} experience={item} />
          ))}
        </div>
      ) : (
        <div className="text-center py-20 px-4 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 space-y-3">
          <Bookmark className="w-12 h-12 text-ink-muted dark:text-slate-600 mx-auto" />
          <h3 className="font-display font-bold text-lg text-[#1A1A1A] dark:text-white">
            Your Wishlist is Empty
          </h3>
          <p className="text-xs text-ink-secondary dark:text-slate-400 max-w-xs mx-auto">
            Tap the heart icon on any experience while exploring to save it for your upcoming journey!
          </p>
          <Link
            href="/explore"
            className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-primary text-white text-xs font-bold shadow-soft"
          >
            <Compass className="w-4 h-4" />
            <span>Discover Places</span>
          </Link>
        </div>
      )}
    </div>
  );
}
