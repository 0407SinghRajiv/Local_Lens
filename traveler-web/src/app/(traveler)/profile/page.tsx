'use client';

import React from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import { useTheme } from '@/context/ThemeContext';
import { useItinerary } from '@/context/ItineraryContext';
import {
  User,
  Sparkles,
  MapPin,
  Calendar,
  Bookmark,
  Bell,
  Settings,
  ShieldCheck,
  LogOut,
  ChevronRight,
  Zap,
} from 'lucide-react';

export default function ProfilePage() {
  const router = useRouter();
  const { user, signOut } = useAuth();
  const { isStormy, toggleStormDemo } = useTheme();
  const { savedTrips, wishlist } = useItinerary();

  async function handleSignOut() {
    await signOut();
    router.push('/login');
  }

  const completedTripsCount = savedTrips.filter(
    (t) => t.items.length > 0 && t.items.every((i) => i.isCompleted)
  ).length;

  return (
    <div className="max-w-xl mx-auto space-y-6 pb-20 animate-in fade-in duration-300">
      {/* Profile Header Card */}
      <div className="p-6 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 shadow-soft flex items-center gap-4">
        <div className="relative w-16 h-16 rounded-full overflow-hidden bg-primary text-white flex items-center justify-center font-black text-2xl shrink-0 shadow-soft">
          {user?.photoUrl ? (
            <Image
              src={user.photoUrl}
              alt={user.displayName}
              fill
              className="object-cover"
            />
          ) : (
            <span>{user?.displayName ? user.displayName[0].toUpperCase() : 'T'}</span>
          )}
        </div>

        <div className="flex-1">
          <div className="flex items-center gap-2">
            <h1 className="font-display font-extrabold text-xl text-[#1A1A1A] dark:text-white">
              {user?.displayName || 'Traveler'}
            </h1>
            <span className="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-600 text-[10px] font-bold uppercase">
              Verified
            </span>
          </div>
          <p className="text-xs text-ink-secondary dark:text-slate-400 mt-0.5">{user?.email || 'traveler@locallens.app'}</p>
        </div>
      </div>

      {/* Travel Stats Strip */}
      <div className="grid grid-cols-3 gap-3 p-4 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 shadow-soft text-center">
        <div>
          <span className="text-[11px] font-bold text-ink-secondary dark:text-slate-400 block uppercase">
            Trips
          </span>
          <span className="font-display font-black text-xl text-primary mt-0.5 block">
            {savedTrips.length}
          </span>
        </div>
        <div className="border-x border-[#EAE8E3] dark:border-slate-700">
          <span className="text-[11px] font-bold text-ink-secondary dark:text-slate-400 block uppercase">
            Completed
          </span>
          <span className="font-display font-black text-xl text-[#1A1A1A] dark:text-white mt-0.5 block">
            {completedTripsCount}
          </span>
        </div>
        <div>
          <span className="text-[11px] font-bold text-ink-secondary dark:text-slate-400 block uppercase">
            Wishlist
          </span>
          <span className="font-display font-black text-xl text-[#1A1A1A] dark:text-white mt-0.5 block">
            {wishlist.length}
          </span>
        </div>
      </div>

      {/* Travel Personality Archetype Banner */}
      <Link
        href="/profile/personality"
        className="p-5 rounded-3xl bg-gradient-to-r from-amber-500 via-orange-500 to-primary text-white shadow-soft flex items-center justify-between group active:scale-98 transition-all"
      >
        <div className="flex items-center gap-3.5">
          <div className="w-11 h-11 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center shrink-0">
            <Sparkles className="w-5 h-5 text-white" />
          </div>
          <div>
            <span className="text-[10px] uppercase font-bold tracking-wider text-white/80 block">
              Travel Personality Archetype
            </span>
            <h3 className="font-display font-bold text-base text-white">
              Cultured Heritage Wanderer
            </h3>
          </div>
        </div>
        <ChevronRight className="w-5 h-5 text-white/70 group-hover:translate-x-1 transition-transform" />
      </Link>

      {/* Settings & Preferences List */}
      <div className="p-2 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 shadow-soft divide-y divide-[#EAE8E3] dark:divide-slate-700">
        <button
          onClick={toggleStormDemo}
          className="w-full p-4 flex items-center justify-between hover:bg-black/5 dark:hover:bg-white/5 transition-colors rounded-2xl text-left"
        >
          <div className="flex items-center gap-3">
            <Zap className="w-5 h-5 text-amber-500" />
            <div>
              <span className="text-sm font-bold text-[#1A1A1A] dark:text-white block">
                Atmosphere Mode
              </span>
              <span className="text-xs text-ink-secondary dark:text-slate-400">
                {isStormy ? 'Monsoon Thunderstorm & Raindrops' : 'Daylight Cream Warm Editorial'}
              </span>
            </div>
          </div>
          <span className="text-xs font-bold text-primary">Toggle</span>
        </button>

        <Link
          href="/notifications"
          className="w-full p-4 flex items-center justify-between hover:bg-black/5 dark:hover:bg-white/5 transition-colors rounded-2xl"
        >
          <div className="flex items-center gap-3">
            <Bell className="w-5 h-5 text-primary" />
            <div>
              <span className="text-sm font-bold text-[#1A1A1A] dark:text-white block">
                Notifications
              </span>
              <span className="text-xs text-ink-secondary dark:text-slate-400">
                Trip alerts & weather updates
              </span>
            </div>
          </div>
          <ChevronRight className="w-4 h-4 text-ink-secondary" />
        </Link>

        <Link
          href="/settings"
          className="w-full p-4 flex items-center justify-between hover:bg-black/5 dark:hover:bg-white/5 transition-colors rounded-2xl"
        >
          <div className="flex items-center gap-3">
            <Settings className="w-5 h-5 text-ink-secondary dark:text-slate-400" />
            <div>
              <span className="text-sm font-bold text-[#1A1A1A] dark:text-white block">
                Preferences & Units
              </span>
              <span className="text-xs text-ink-secondary dark:text-slate-400">
                ₹ Indian Rupee • Kilometers (km)
              </span>
            </div>
          </div>
          <ChevronRight className="w-4 h-4 text-ink-secondary" />
        </Link>
      </div>

      {/* Logout Button */}
      <button
        onClick={handleSignOut}
        className="w-full h-13 py-3 rounded-2xl bg-red-500/10 hover:bg-red-500/20 text-red-600 font-bold text-xs flex items-center justify-center gap-2 transition-colors active:scale-98"
      >
        <LogOut className="w-4 h-4" />
        <span>Sign Out of LocalLens</span>
      </button>
    </div>
  );
}
