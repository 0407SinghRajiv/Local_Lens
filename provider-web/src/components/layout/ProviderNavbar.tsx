"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  Compass,
  Bell,
  Search,
  Globe,
} from "lucide-react";
import {
  getStoredWeatherPause,
  setStoredWeatherPause,
  getStoredExperiences,
  saveStoredExperiences,
} from "@/services/mockExperiences";

export const ProviderNavbar: React.FC = () => {
  const pathname = usePathname();
  const router = useRouter();
  const [weatherPaused, setWeatherPaused] = useState(false);

  useEffect(() => {
    setWeatherPaused(getStoredWeatherPause());
  }, []);

  const handleToggleSevereWeather = () => {
    const nextState = !weatherPaused;
    setWeatherPaused(nextState);
    setStoredWeatherPause(nextState);

    const list = getStoredExperiences();
    const updated = list.map((exp) => {
      if (exp.indoor_outdoor_clean === "Outdoor") {
        return {
          ...exp,
          status: nextState ? ("paused" as const) : ("active" as const),
        };
      }
      return exp;
    });
    saveStoredExperiences(updated);

    if (typeof window !== "undefined") {
      window.dispatchEvent(new Event("experiences_updated"));
    }
  };

  // If on landing page (public)
  if (pathname === "/") {
    return (
      <header className="w-full bg-white/95 backdrop-blur-md border-b border-slate-100 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 h-20 flex items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center gap-2.5">
            <div className="w-10 h-10 rounded-xl bg-[#0e8a5b] text-white flex items-center justify-center shadow-md">
              <Compass className="w-6 h-6" />
            </div>
            <div>
              <span className="font-extrabold text-xl text-slate-900 tracking-tight block leading-tight">
                LocalLens
              </span>
              <span className="text-[11px] font-bold text-[#0e8a5b] tracking-wider uppercase">
                &mdash; Provider
              </span>
            </div>
          </Link>

          {/* Center Nav */}
          <nav className="hidden md:flex items-center gap-8 text-sm font-semibold text-slate-600">
            <a href="#features" className="hover:text-slate-900 transition-colors">Features</a>
            <a href="#how-it-works" className="hover:text-slate-900 transition-colors">How it Works</a>
            <a href="#pricing" className="hover:text-slate-900 transition-colors">Pricing</a>
            <a href="#faqs" className="hover:text-slate-900 transition-colors">FAQs</a>
          </nav>

          {/* Action CTAs */}
          <div className="flex items-center gap-4">
            <Link
              href="/login"
              className="text-sm font-bold text-slate-700 hover:text-slate-900 px-4 py-2"
            >
              Login
            </Link>
            <Link
              href="/dashboard"
              className="px-5 py-2.5 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white text-sm font-bold shadow-md shadow-emerald-700/20 transition-all flex items-center gap-1.5"
            >
              <span>Join as Host</span>
              <span>&rarr;</span>
            </Link>
          </div>
        </div>
      </header>
    );
  }

  // Provider In-App Top Bar
  return (
    <header className="w-full bg-white border-b border-slate-200/80 sticky top-0 z-40">
      <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
        {/* Left Brand */}
        <Link href="/dashboard" className="flex items-center gap-2.5">
          <div className="w-9 h-9 rounded-xl bg-[#0e8a5b] text-white flex items-center justify-center shadow-sm">
            <Compass className="w-5 h-5" />
          </div>
          <div>
            <span className="font-black text-base text-slate-900 tracking-tight leading-none block">
              Local Lens
            </span>
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              Provider
            </span>
          </div>
        </Link>

        {/* Global Search Bar */}
        <div className="hidden md:flex items-center w-80 relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search bookings, guests..."
            className="w-full pl-9 pr-4 py-2 rounded-xl bg-slate-100/80 border-none text-xs text-slate-700 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/30"
          />
        </div>

        {/* Right Controls */}
        <div className="flex items-center gap-4">
          {/* Notification Bell */}
          <button className="relative p-2 rounded-xl text-slate-500 hover:bg-slate-100 transition-colors">
            <Bell className="w-5 h-5" />
            <span className="absolute top-1 right-1 w-4 h-4 rounded-full bg-rose-500 text-white text-[9px] font-bold flex items-center justify-center">
              3
            </span>
          </button>

          
          {/* Quick link to view public provider website */}
          <Link
            href="/"
            className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-slate-200 text-xs font-bold text-slate-700 hover:text-[#059669] hover:bg-emerald-50/60 hover:border-emerald-200 transition-colors shadow-sm"
          >
            <Globe className="w-3.5 h-3.5 text-[#059669]" />
            <span>View Website</span>
          </Link>
          
          {/* Emergency Pause All Outdoor Switch */}
          <div className="flex items-center gap-3 p-1.5 px-3 rounded-2xl bg-rose-50/70 border border-rose-100">
            <div className="flex flex-col text-right">
              <span className="text-[11px] font-bold text-rose-900 leading-tight">
                Emergency Pause
              </span>
              <span className="text-[9px] text-rose-500 font-medium">
                All Outdoor Listings
              </span>
            </div>
            <button
              type="button"
              onClick={handleToggleSevereWeather}
              className={`w-10 h-5 flex items-center rounded-full p-0.5 cursor-pointer transition-colors duration-200 ${
                weatherPaused ? "bg-rose-600 justify-end" : "bg-slate-300 justify-start"
              }`}
            >
              <span className="w-4 h-4 rounded-full bg-white shadow-md transform transition-transform" />
            </button>
          </div>
        </div>
      </div>
    </header>
  );
};