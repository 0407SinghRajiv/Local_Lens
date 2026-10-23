'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useItinerary } from '@/context/ItineraryContext';
import { Calendar, MapPin, Clock, ArrowRight, PlusCircle, CheckCircle2 } from 'lucide-react';

export default function TripsPage() {
  const { savedTrips, generatedItinerary } = useItinerary();
  const [filter, setFilter] = useState<'all' | 'active' | 'completed'>('all');

  const allTrips = savedTrips.length > 0 ? savedTrips : generatedItinerary ? [generatedItinerary] : [];

  const filteredTrips = allTrips.filter((t) => {
    const isDone = t.items.length > 0 && t.items.every((i) => i.isCompleted);
    if (filter === 'completed') return isDone;
    if (filter === 'active') return !isDone;
    return true;
  });

  return (
    <div className="space-y-6 pb-12 animate-in fade-in duration-300">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="font-display font-extrabold text-2xl sm:text-3xl text-[#1A1A1A] dark:text-white">
            My Itineraries & Journeys
          </h1>
          <p className="text-xs sm:text-sm text-ink-secondary dark:text-slate-400 mt-0.5">
            View, resume, and manage your synthesized travel routes.
          </p>
        </div>

        <Link
          href="/itinerary/create"
          className="px-4 py-2.5 rounded-2xl bg-primary hover:bg-primary-dark text-white text-xs font-bold shadow-soft flex items-center gap-1.5 self-start sm:self-auto active:scale-95 transition-all"
        >
          <PlusCircle className="w-4 h-4" />
          <span>New Itinerary</span>
        </Link>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 border-b border-[#EAE8E3] dark:border-slate-800 pb-2">
        {[
          { id: 'all', label: 'All Trips' },
          { id: 'active', label: 'In Progress / Upcoming' },
          { id: 'completed', label: 'Completed' },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setFilter(tab.id as any)}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${
              filter === tab.id
                ? 'bg-[#1A1A1A] text-white dark:bg-primary shadow-sm'
                : 'text-ink-secondary dark:text-slate-400 hover:text-ink'
            }`}
          >
            {tab.label}
          </button>
        ))}
      </div>

      {/* Trips Cards List */}
      {filteredTrips.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {filteredTrips.map((trip) => {
            const completedCount = trip.items.filter((i) => i.isCompleted).length;
            const progress = trip.items.length > 0 ? (completedCount / trip.items.length) * 100 : 0;
            const isCompleted = trip.items.length > 0 && completedCount === trip.items.length;

            return (
              <div
                key={trip.id}
                className="p-5 sm:p-6 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 shadow-soft hover:shadow-floating transition-all flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between mb-3">
                    <span className="px-2.5 py-1 rounded-full bg-primary-soft dark:bg-primary/20 text-primary text-xs font-bold">
                      {trip.destination}
                    </span>
                    <span className="text-xs text-ink-secondary dark:text-slate-400 font-semibold">
                      {trip.tripDate}
                    </span>
                  </div>

                  <h3 className="font-display font-bold text-lg sm:text-xl text-[#1A1A1A] dark:text-white">
                    {trip.destination} Day Itinerary
                  </h3>

                  <div className="flex items-center gap-4 text-xs text-ink-secondary dark:text-slate-400 mt-2">
                    <span className="flex items-center gap-1">
                      <Clock className="w-3.5 h-3.5 text-primary" />
                      {trip.items.length} Stops ({trip.startTime} - {trip.endTime})
                    </span>
                    <span>•</span>
                    <span className="font-bold text-[#1A1A1A] dark:text-white">
                      ₹{trip.totalEstimatedCost}
                    </span>
                  </div>

                  {/* Progress Bar */}
                  <div className="mt-4">
                    <div className="flex items-center justify-between text-xs font-semibold mb-1 text-ink-secondary dark:text-slate-400">
                      <span>Progress</span>
                      <span>
                        {completedCount} of {trip.items.length} completed
                      </span>
                    </div>
                    <div className="w-full h-2 rounded-full bg-surface-muted dark:bg-slate-700 overflow-hidden">
                      <div
                        className="h-full bg-emerald-500 rounded-full transition-all duration-500"
                        style={{ width: `${progress}%` }}
                      />
                    </div>
                  </div>
                </div>

                <div className="mt-5 pt-4 border-t border-[#EAE8E3] dark:border-slate-700 flex items-center justify-between">
                  <span className="text-xs font-semibold text-ink-secondary dark:text-slate-400">
                    {isCompleted ? 'Finished 🎉' : 'Ready to explore'}
                  </span>

                  <Link
                    href={`/itinerary/${trip.id}`}
                    className="px-4 py-2 rounded-xl bg-primary hover:bg-primary-dark text-white text-xs font-bold flex items-center gap-1.5 active:scale-95 transition-all shadow-sm"
                  >
                    <span>View Itinerary</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="text-center py-16 px-4 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700">
          <Calendar className="w-12 h-12 text-ink-muted dark:text-slate-600 mx-auto mb-3" />
          <h3 className="font-display font-bold text-lg text-[#1A1A1A] dark:text-white">
            No Itineraries Yet
          </h3>
          <p className="text-xs text-ink-secondary dark:text-slate-400 mt-1 max-w-xs mx-auto">
            Plan your first custom journey with our intelligent AI itinerary generator!
          </p>
          <Link
            href="/itinerary/create"
            className="mt-4 inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-primary text-white text-xs font-bold"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Create Itinerary</span>
          </Link>
        </div>
      )}
    </div>
  );
}
