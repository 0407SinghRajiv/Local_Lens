'use client';

import React, { useState, useMemo } from 'react';
import dynamic from 'next/dynamic';
import { useItinerary } from '@/context/ItineraryContext';
import { CategoryChips } from '@/components/home/CategoryChips';
import { ExperienceCard } from '@/components/home/ExperienceCard';
import { Search, Map as MapIcon, Grid, SlidersHorizontal } from 'lucide-react';
import { MapMarkerPoint } from '@/components/maps/InteractiveMap';

// Dynamic import Leaflet map to prevent SSR hydration errors
const InteractiveMap = dynamic(
  () => import('@/components/maps/InteractiveMap').then((m) => m.InteractiveMap),
  { ssr: false, loading: () => <div className="h-96 w-full rounded-3xl bg-black/5 animate-pulse" /> }
);

export default function ExplorePage() {
  const { destination, recommendations } = useItinerary();
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('All');
  const [viewMode, setViewMode] = useState<'grid' | 'map'>('grid');

  const filteredItems = useMemo(() => {
    return recommendations.filter((item) => {
      const matchCat =
        selectedCategory === 'All' || item.category.toLowerCase() === selectedCategory.toLowerCase();
      const matchQuery =
        !searchQuery.trim() ||
        item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.location.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.reason.toLowerCase().includes(searchQuery.toLowerCase());
      return matchCat && matchQuery;
    });
  }, [recommendations, selectedCategory, searchQuery]);

  const mapMarkers: MapMarkerPoint[] = useMemo(() => {
    return filteredItems
      .filter((i) => i.latitude && i.longitude)
      .map((i, idx) => ({
        id: i.experienceId,
        name: i.name,
        category: i.category,
        latitude: i.latitude!,
        longitude: i.longitude!,
        orderNumber: idx + 1,
      }));
  }, [filteredItems]);

  return (
    <div className="space-y-6 animate-in fade-in duration-300">
      {/* Title & View Switcher */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="font-display font-extrabold text-2xl sm:text-3xl text-[#1A1A1A] dark:text-white">
            Explore {destination}
          </h1>
          <p className="text-xs sm:text-sm text-ink-secondary dark:text-slate-400 mt-0.5">
            Discover curated spots, hidden gems, and local secrets.
          </p>
        </div>

        {/* View Toggle */}
        <div className="flex items-center gap-1 p-1 rounded-2xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 shadow-sm self-start sm:self-auto">
          <button
            onClick={() => setViewMode('grid')}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
              viewMode === 'grid'
                ? 'bg-primary text-white shadow-soft'
                : 'text-ink-secondary dark:text-slate-400 hover:text-ink'
            }`}
          >
            <Grid className="w-3.5 h-3.5" />
            <span>Grid</span>
          </button>
          <button
            onClick={() => setViewMode('map')}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-bold transition-all ${
              viewMode === 'map'
                ? 'bg-primary text-white shadow-soft'
                : 'text-ink-secondary dark:text-slate-400 hover:text-ink'
            }`}
          >
            <MapIcon className="w-3.5 h-3.5" />
            <span>Interactive Map</span>
          </button>
        </div>
      </div>

      {/* Search Input Bar */}
      <div className="relative">
        <Search className="w-4 h-4 text-ink-muted dark:text-slate-400 absolute left-4 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder={`Search spots, food, activities in ${destination}...`}
          className="w-full h-12 pl-11 pr-4 rounded-2xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 shadow-soft focus:outline-none focus:ring-2 focus:ring-primary/40 text-sm font-medium text-[#1A1A1A] dark:text-white"
        />
      </div>

      {/* Category Chips */}
      <CategoryChips selectedCategory={selectedCategory} onSelectCategory={setSelectedCategory} />

      {/* Main Content Area */}
      {viewMode === 'map' ? (
        <div className="space-y-4">
          <div className="h-[460px] sm:h-[520px] w-full rounded-3xl overflow-hidden border border-[#EAE8E3] dark:border-slate-700 shadow-floating">
            <InteractiveMap
              markers={mapMarkers}
              center={
                mapMarkers.length > 0
                  ? [mapMarkers[0].latitude, mapMarkers[0].longitude]
                  : [19.076, 72.8777]
              }
              zoom={12}
              showPolyline={false}
              className="w-full h-full"
            />
          </div>

          <p className="text-xs text-ink-secondary dark:text-slate-400 text-center">
            Showing {mapMarkers.length} mapped destinations in {destination}. Click any pin to view details.
          </p>
        </div>
      ) : filteredItems.length > 0 ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5 sm:gap-6">
          {filteredItems.map((item) => (
            <ExperienceCard key={item.experienceId} experience={item} />
          ))}
        </div>
      ) : (
        <div className="text-center py-16 px-4 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700">
          <p className="text-base font-bold text-[#1A1A1A] dark:text-white">No experiences found</p>
          <p className="text-xs text-ink-secondary dark:text-slate-400 mt-1">
            Try adjusting your search terms or selecting another category.
          </p>
        </div>
      )}
    </div>
  );
}
