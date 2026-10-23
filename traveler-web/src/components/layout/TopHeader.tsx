'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/context/AuthContext';
import { useTheme } from '@/context/ThemeContext';
import { useItinerary } from '@/context/ItineraryContext';
import { WeatherModal } from '@/components/home/WeatherModal';
import {
  MapPin,
  Sun,
  CloudRain,
  Sunset,
  Cloud,
  LogOut,
  Bell,
  Sparkles,
} from 'lucide-react';

export function TopHeader() {
  const pathname = usePathname();
  const router = useRouter();
  const { user, signOut } = useAuth();
  const { isStormy, weather, toggleStormDemo } = useTheme();
  const { destination, setDestination } = useItinerary();
  const [isWeatherOpen, setIsWeatherOpen] = useState(false);
  const [isCityDropdownOpen, setIsCityDropdownOpen] = useState(false);

  const majorCities = ['Mumbai', 'Navi Mumbai', 'Alibaug', 'Lonavala', 'Goa', 'Jaipur', 'Pune'];

  const WeatherIcon =
    weather.iconName === 'CloudRain'
      ? CloudRain
      : weather.iconName === 'Sunset'
      ? Sunset
      : weather.iconName === 'Cloud'
      ? Cloud
      : Sun;

  return (
    <>
      <header
        className={`sticky top-0 z-30 w-full backdrop-blur-xl border-b transition-colors duration-300 ${
          isStormy
            ? 'bg-[#0F172A]/90 border-slate-800 text-white'
            : 'bg-[#FAF9F6]/90 border-[#EAE8E3] text-[#1A1A1A]'
        }`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
          {/* Left: Brand Identity & Location */}
          <div className="flex items-center gap-3 sm:gap-6">
            <Link href="/home" className="flex items-center gap-2.5 group">
              <div className="w-9 h-9 rounded-xl bg-primary text-white flex items-center justify-center shadow-soft group-hover:scale-105 transition-transform overflow-hidden">
                <Image
                  src="/assets/images/logo.png"
                  alt="LocalLens Logo"
                  width={28}
                  height={28}
                  className="object-contain"
                />
              </div>
              <div className="flex flex-col">
                <span className="font-display font-extrabold text-lg sm:text-xl tracking-tight leading-none text-primary">
                  LocalLens
                </span>
                <span className="text-[10px] uppercase font-bold tracking-widest text-ink-secondary dark:text-slate-400">
                  Traveler
                </span>
              </div>
            </Link>

            {/* City Destination Switcher */}
            <div className="relative">
              <button
                onClick={() => setIsCityDropdownOpen(!isCityDropdownOpen)}
                className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-surface-muted dark:bg-slate-800 hover:bg-black/5 dark:hover:bg-white/10 transition-all text-xs font-semibold"
              >
                <MapPin className="w-3.5 h-3.5 text-primary" />
                <span className="max-w-[90px] sm:max-w-[140px] truncate">{destination}</span>
              </button>

              {isCityDropdownOpen && (
                <div className="absolute top-full left-0 mt-2 w-48 bg-white dark:bg-slate-800 rounded-2xl shadow-floating border border-[#EAE8E3] dark:border-slate-700 py-2 z-50 animate-in fade-in zoom-in-95">
                  <div className="px-3 py-1.5 text-[10px] font-bold uppercase tracking-wider text-ink-secondary dark:text-slate-400">
                    Select Destination
                  </div>
                  {majorCities.map((city) => (
                    <button
                      key={city}
                      onClick={() => {
                        setDestination(city);
                        setIsCityDropdownOpen(false);
                      }}
                      className={`w-full px-3 py-2 text-left text-xs font-medium hover:bg-primary-soft dark:hover:bg-primary/20 hover:text-primary transition-colors flex items-center justify-between ${
                        destination.toLowerCase() === city.toLowerCase()
                          ? 'text-primary font-bold'
                          : 'text-[#1A1A1A] dark:text-white'
                      }`}
                    >
                      {city}
                      {destination.toLowerCase() === city.toLowerCase() && (
                        <span className="w-1.5 h-1.5 rounded-full bg-primary" />
                      )}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Center: Desktop Navigation Bar */}
          <nav className="hidden md:flex items-center gap-1 lg:gap-2">
            {[
              { label: 'Explore', href: '/home' },
              { label: 'Trips', href: '/trips' },
              { label: 'Plan Itinerary', href: '/itinerary/create' },
              { label: 'Lens Rides', href: '/rides/book' },
              { label: 'Saved', href: '/saved' },
            ].map((link) => {
              const active = pathname === link.href || (link.href !== '/home' && pathname.startsWith(link.href));
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className={`px-3 py-1.5 rounded-xl text-sm font-semibold transition-all ${
                    active
                      ? 'bg-primary text-white shadow-soft'
                      : isStormy
                      ? 'text-slate-300 hover:text-white hover:bg-white/5'
                      : 'text-ink-secondary hover:text-ink hover:bg-surface-muted'
                  }`}
                >
                  {link.label}
                </Link>
              );
            })}
          </nav>

          {/* Right: Weather Pill, Simulation Trigger & User Avatar */}
          <div className="flex items-center gap-2 sm:gap-3">
            {/* Live Weather Pill */}
            <button
              onClick={() => setIsWeatherOpen(true)}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-full border transition-all active:scale-95 ${
                isStormy
                  ? 'bg-sky-950/60 border-sky-500/40 text-sky-300'
                  : 'bg-amber-500/10 border-amber-200 text-amber-700'
              }`}
            >
              <WeatherIcon className="w-4 h-4 animate-pulse" />
              <span className="text-xs font-bold">{weather.tempCelsius}</span>
            </button>

            {/* Quick Storm Toggle Badge */}
            <button
              onClick={toggleStormDemo}
              title="Click to toggle live Storm & Rain atmosphere"
              className={`hidden sm:flex items-center gap-1.5 px-2.5 py-1.5 rounded-full text-xs font-semibold border transition-all ${
                isStormy
                  ? 'bg-sky-500/20 border-sky-400 text-sky-300'
                  : 'bg-black/5 dark:bg-white/10 border-transparent text-ink-secondary dark:text-slate-300 hover:border-black/20'
              }`}
            >
              <Sparkles className="w-3.5 h-3.5 text-amber-500" />
              <span>{isStormy ? 'Storm Active' : 'Rain Sim'}</span>
            </button>

            {/* Notifications */}
            <Link
              href="/notifications"
              className="p-2 rounded-full hover:bg-black/5 dark:hover:bg-white/10 transition-colors relative"
              title="Notifications"
            >
              <Bell className="w-5 h-5 text-ink-secondary dark:text-slate-400" />
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-primary" />
            </Link>

            {/* User Profile Avatar with storm glow */}
            <Link
              href="/profile"
              className={`relative rounded-full p-0.5 transition-all ${
                isStormy ? 'ring-2 ring-sky-400 ring-offset-2 ring-offset-slate-900' : 'ring-1 ring-[#1A1A1A]/20'
              }`}
            >
              <div className="w-8 h-8 rounded-full overflow-hidden bg-white flex items-center justify-center font-bold text-primary text-sm">
                {user?.photoUrl ? (
                  <Image
                    src={user.photoUrl}
                    alt={user.displayName}
                    width={32}
                    height={32}
                    className="w-full h-full object-cover"
                  />
                ) : (
                  <span>{user?.displayName ? user.displayName[0].toUpperCase() : 'T'}</span>
                )}
              </div>
            </Link>
          </div>
        </div>
      </header>

      <WeatherModal isOpen={isWeatherOpen} onClose={() => setIsWeatherOpen(false)} />
    </>
  );
}
