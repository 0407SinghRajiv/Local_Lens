"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter, useSearchParams } from "next/navigation";
import {
  Compass,
  LayoutDashboard,
  Layers,
  ClipboardList,
  Rocket,
  Wallet,
  Settings,
  Search,
  Bell,
  CloudRain,
  Calendar,
  Star,
  ChevronRight,
  User,
  CheckCircle2,
  ShieldCheck,
  Mail,
  Phone,
  LogOut,
  X,
  Sparkles,
  ExternalLink,
} from "lucide-react";
import { getProviderProfile, logoutProvider, ProviderProfile } from "@/lib/authSession";

export default function ProviderExecutiveDashboardPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [emergencyPaused, setEmergencyPaused] = useState(true);
  const [activeMenu, setActiveMenu] = useState("Dashboard");
  const [profile, setProfile] = useState<ProviderProfile | null>(null);
  const [showProfileModal, setShowProfileModal] = useState(false);

  useEffect(() => {
    getProviderProfile().then((p) => setProfile(p));
    if (searchParams.get("profile") === "true") { setShowProfileModal(true); }
  }, []);

  const handleLogout = async () => {
    await logoutProvider();
    router.push("/login");
  };

  // Experience Card Pause states
  const [pausedCards, setPausedCards] = useState<Record<string, boolean>>({});

  const togglePauseCard = (id: string) => {
    setPausedCards((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  const navMenuItems = [
    { name: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
    { name: "My Experiences", href: "/experiences/new", icon: Layers },
    { name: "Bookings", href: "/dashboard", icon: ClipboardList },
    { name: "Boost & Sponsor", href: "/boost", icon: Rocket },
    { name: "Payouts", href: "/dashboard", icon: Wallet },
    { name: "Settings", href: "/dashboard", icon: Settings },
  ];

  // 4 Active Experience Cards strictly matching reference image
  const experiences = [
    {
      id: "EXP-1",
      title: "Sunset Kayaking at Versova",
      category: "Adventure",
      categoryBg: "bg-[#FEF3C7] text-[#B45309]",
      price: "₹1,200",
      image: "/dashboard/kayaking.jpg",
    },
    {
      id: "EXP-2",
      title: "Old Mumbai Heritage Walk",
      category: "Heritage",
      categoryBg: "bg-[#ECFDF5] text-[#059669]",
      price: "₹800",
      image: "/dashboard/heritage.jpg",
    },
    {
      id: "EXP-3",
      title: "Pottery Workshop with Locals",
      category: "Art",
      categoryBg: "bg-[#FEF3C7] text-[#B45309]",
      price: "₹1,000",
      image: "/dashboard/pottery.jpg",
    },
    {
      id: "EXP-4",
      title: "Mumbai Street Food Tour",
      category: "Food",
      categoryBg: "bg-[#ECFDF5] text-[#059669]",
      price: "₹900",
      image: "/dashboard/food.jpg",
    },
  ];

  // Timeline Schedule Items strictly matching reference image
  const scheduleItems = [
    {
      id: "SCH-1",
      time: "08:00 AM",
      dotColor: "bg-[#10B981]",
      title: "Sunset Kayaking (Slot 1)",
      name: "Priya Sharma",
      guests: "4 guests",
      avatar: "/dashboard/priya.jpg",
      status: "Driver Arrived",
      statusStyle: "bg-[#ECFDF5] text-[#059669] border-[#A7F3D0]",
      statusDot: "bg-[#10B981]",
    },
    {
      id: "SCH-2",
      time: "11:00 AM",
      dotColor: "bg-[#F59E0B]",
      title: "Heritage Walk",
      name: "Alex Johnson",
      guests: "2 guests",
      avatar: "/dashboard/alex.jpg",
      status: "Driver En Route",
      statusStyle: "bg-[#EFF6FF] text-[#2563EB] border-[#BFDBFE]",
      statusDot: "bg-[#3B82F6]",
    },
    {
      id: "SCH-3",
      time: "03:00 PM",
      dotColor: "bg-[#EF4444]",
      title: "Pottery Workshop",
      name: "Neha Verma",
      guests: "6 guests",
      avatar: "/dashboard/neha.jpg",
      status: "Driver Pending",
      statusStyle: "bg-[#FFFBEB] text-[#D97706] border-[#FDE68A]",
      statusDot: "bg-[#F59E0B]",
    },
    {
      id: "SCH-4",
      time: "05:30 PM",
      dotColor: "bg-[#10B981]",
      title: "Sunset Kayaking (Slot 2)",
      name: "Rahul Mehta",
      guests: "6 guests",
      avatar: "/dashboard/rahul.jpg",
      status: "On Time",
      statusStyle: "bg-[#ECFDF5] text-[#059669] border-[#A7F3D0]",
      statusDot: "bg-[#10B981]",
    },
  ];

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-[#0F172A] font-sans flex antialiased">
      {/* ============================================================ */}
      {/* 1. LEFT SIDEBAR                                             */}
      {/* ============================================================ */}
      <aside className="w-56 shrink-0 bg-white border-r border-[#E2E8F0] flex flex-col justify-between p-4 sticky top-0 h-screen select-none z-20">
        <div className="space-y-6">
          {/* Logo Header matching top-left of screenshot */}
          <Link href="/" className="flex items-center gap-2.5 px-2 pt-1 group">
            <div className="w-8 h-8 rounded-full bg-[#059669] text-white flex items-center justify-center shadow-xs shrink-0">
              <svg viewBox="0 0 24 24" fill="none" className="w-4.5 h-4.5 text-white">
                <path
                  d="M3 18L9.5 7.5L14 14.5L16.5 11L21 18H3Z"
                  fill="white"
                  stroke="white"
                  strokeWidth="1"
                  strokeLinejoin="round"
                />
              </svg>
            </div>
            <div className="flex flex-col">
              <span className="font-extrabold text-[15px] text-[#0F172A] tracking-tight leading-none">
                LocalLens
              </span>
              <span className="text-[11px] font-bold text-[#059669] tracking-wide leading-tight">
                Provider
              </span>
            </div>
          </Link>

          {/* Navigation Menu */}
          <nav className="space-y-1">
            {navMenuItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeMenu === item.name;

              return (
                <Link
                  key={item.name}
                  href={item.href}
                  onClick={() => setActiveMenu(item.name)}
                  className={`w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-[13px] font-bold transition-all ${
                    isActive
                      ? "bg-[#ECFDF5] text-[#059669]"
                      : "text-[#475569] hover:text-[#0F172A] hover:bg-slate-50"
                  }`}
                >
                  <Icon
                    className={`w-4 h-4 ${
                      isActive ? "text-[#059669]" : "text-[#64748B]"
                    }`}
                  />
                  <span>{item.name}</span>
                </Link>
              );
            })}
          </nav>
        </div>

        {/* Bottom Profile Section (Dynamic User Profile) */}
        <div className="pt-3 border-t border-[#F1F5F9] flex items-center gap-3 px-1">
          <button
            onClick={() => setShowProfileModal(true)}
            className="relative w-9 h-9 rounded-full overflow-hidden shrink-0 border border-[#E2E8F0] shadow-sm bg-gradient-to-tr from-[#00875A] to-teal-500 text-white font-black text-xs flex items-center justify-center cursor-pointer hover:scale-105 transition-transform"
          >
            {profile?.avatar && profile.avatar.startsWith("/") ? (
              <Image
                src={profile.avatar}
                alt={profile?.name || "Host Profile"}
                fill
                className="object-cover"
                unoptimized
              />
            ) : (
              <span>{profile?.name ? profile.name.slice(0, 2).toUpperCase() : "HP"}</span>
            )}
          </button>
          <div className="min-w-0 flex-1 leading-tight">
            <div className="text-[12px] font-bold text-[#0F172A] truncate" title={profile?.name}>
              {profile?.name || "Verified Host"}
            </div>
            <div className="text-[10px] text-[#00875A] font-semibold truncate">
              {profile?.role || "Experience Provider"}
            </div>
            <button
              onClick={() => setShowProfileModal(true)}
              className="text-[10px] text-[#2563EB] font-bold hover:underline inline-flex items-center gap-0.5 mt-0.5 cursor-pointer"
            >
              <span>View Profile</span>
              <span className="text-[11px]">&rarr;</span>
            </button>
          </div>
        </div>
      </aside>

      {/* ============================================================ */}
      {/* 2. MAIN DASHBOARD CONTENT AREA                               */}
      {/* ============================================================ */}
      <div className="flex-1 flex flex-col min-w-0 overflow-y-auto">
        {/* Top Header Bar matching top of screenshot */}
        <header className="w-full bg-[#F8FAFC] px-8 py-5 flex items-center justify-between gap-4 border-b border-transparent">
          {/* Welcome Greeting */}
          <div>
            <h1 className="text-[20px] sm:text-[22px] font-black text-[#0F172A] flex items-center gap-1.5 tracking-tight leading-snug">
              <span>Good morning, {profile?.name || "Provider"}</span>
              <span className="text-[20px]">👋</span>
            </h1>
            <p className="text-[12px] text-[#64748B] font-normal">
              Here&apos;s what&apos;s happening with your {profile?.role ? profile.role.toLowerCase() : "experience"} business today.
            </p>
          </div>

          {/* Right Header Controls: Search, Bell, Emergency Pause */}
          <div className="flex items-center gap-3.5">
            {/* Search Input */}
            <div className="relative w-52 sm:w-60">
              <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search bookings, guests..."
                className="w-full pl-8 pr-3 py-1.5 rounded-xl bg-white border border-[#E2E8F0] text-[11px] text-[#0F172A] placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-[#059669] shadow-2xs"
              />
            </div>

            {/* Notification Bell with Red Badge "3" */}
            <button className="relative w-8 h-8 rounded-full bg-white border border-[#E2E8F0] flex items-center justify-center text-slate-600 hover:bg-slate-50 transition-colors shadow-2xs cursor-pointer">
              <Bell className="w-4 h-4 text-slate-700" />
              <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-[#EF4444] text-white text-[9px] font-extrabold flex items-center justify-center shadow-xs">
                3
              </span>
            </button>

            {/* Top Right User Profile Trigger Button */}
            <button
              onClick={() => setShowProfileModal(true)}
              className="flex items-center gap-2 p-1.5 pl-3 rounded-full bg-white border border-[#E2E8F0] hover:border-[#00875A] transition-all shadow-xs cursor-pointer group"
              title="View your Provider Profile"
            >
              <div className="flex flex-col text-right leading-none hidden sm:flex">
                <span className="text-[11.5px] font-extrabold text-[#0F172A] group-hover:text-[#00875A] transition-colors truncate max-w-[120px]">
                  {profile?.name || "Host"}
                </span>
                <span className="text-[9px] font-semibold text-[#00875A] mt-0.5">Verified</span>
              </div>
              <div className="w-7 h-7 rounded-full bg-gradient-to-tr from-[#00875A] to-teal-500 text-white font-black text-[11px] flex items-center justify-center shadow-xs overflow-hidden">
                {profile?.avatar && profile.avatar.startsWith("/") ? (
                  <Image src={profile.avatar} alt="Profile" width={28} height={28} className="object-cover" unoptimized />
                ) : (
                  <span>{profile?.name ? profile.name.slice(0, 2).toUpperCase() : "HP"}</span>
                )}
              </div>
            </button>

            {/* Emergency Pause All Outdoor Listings Toggle */}
            <div className="flex items-center gap-3 p-2 px-3.5 rounded-2xl bg-[#FFF1F2] border border-[#FFE4E6] shadow-2xs">
              {/* Rain cloud icon */}
              <div className="text-[#38BDF8]">
                <CloudRain className="w-5 h-5 text-[#0284C7] fill-[#BAE6FD]" />
              </div>
              <div className="flex flex-col text-left leading-tight">
                <span className="text-[11px] font-extrabold text-[#BE123C]">
                  Emergency Pause
                </span>
                <span className="text-[10px] font-medium text-[#BE123C]/90">
                  All Outdoor Listings
                </span>
              </div>
              {/* Toggle Switch */}
              <button
                type="button"
                onClick={() => setEmergencyPaused(!emergencyPaused)}
                className={`w-9 h-5 flex items-center rounded-full p-0.5 cursor-pointer transition-colors duration-200 ml-1 ${
                  emergencyPaused ? "bg-[#EF4444] justify-end" : "bg-[#CBD5E1] justify-start"
                }`}
              >
                <span className="w-4 h-4 rounded-full bg-white shadow-sm transform transition-transform" />
              </button>
            </div>
          </div>
        </header>

        {/* Dashboard Main Container */}
        <main className="px-8 pb-10 space-y-6">
          {/* ============================================================ */}
          {/* 3. FOUR KPI CARDS (MATCHING SCREENSHOT ROW 1)                 */}
          {/* ============================================================ */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {/* Card 1: Total Earnings */}
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="text-[22px] sm:text-[24px] font-black text-[#0F172A] tracking-tight">
                  ₹48,500
                </div>
                {/* 3 Green Vertical Bars */}
                <div className="flex items-end gap-0.5 h-5 pb-0.5">
                  <span className="w-1 h-2 rounded-xs bg-[#10B981]" />
                  <span className="w-1 h-3.5 rounded-xs bg-[#10B981]" />
                  <span className="w-1 h-5 rounded-xs bg-[#10B981]" />
                </div>
              </div>

              <div className="text-[12px] font-semibold text-[#64748B] mt-1">
                Total Earnings
              </div>

              <div className="text-[11px] text-slate-400 font-medium mt-1 flex items-center gap-2">
                <span>this month</span>
                <span className="text-[#059669] font-bold flex items-center gap-0.5">
                  <span>&uarr;</span> 12%
                </span>
              </div>
            </div>

            {/* Card 2: Active Experiences */}
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="text-[24px] sm:text-[26px] font-black text-[#0F172A] tracking-tight">
                  4
                </div>
                <div className="w-7 h-7 rounded-full bg-[#ECFDF5] flex items-center justify-center">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#10B981]" />
                </div>
              </div>

              <div className="text-[12px] font-semibold text-[#64748B] mt-1">
                Active Experiences
              </div>

              <div className="text-[11px] text-slate-400 font-medium mt-1">
                live on platform
              </div>
            </div>

            {/* Card 3: Today's Bookings */}
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="flex items-baseline gap-1">
                  <span className="text-[22px] sm:text-[24px] font-black text-[#0F172A] tracking-tight">
                    18
                  </span>
                  <span className="text-[13px] text-slate-500 font-normal">
                    guests
                  </span>
                </div>
                <div className="w-7 h-7 rounded-lg bg-[#EFF6FF] flex items-center justify-center text-[#3B82F6]">
                  <Calendar className="w-4 h-4" />
                </div>
              </div>

              <div className="text-[12px] font-semibold text-[#64748B] mt-1">
                Today&apos;s Bookings
              </div>

              <div className="text-[11px] text-slate-400 font-medium mt-1">
                across 3 slots
              </div>
            </div>

            {/* Card 4: Average Rating */}
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  <span className="text-[22px] sm:text-[24px] font-black text-[#0F172A] tracking-tight">
                    4.8
                  </span>
                  <span className="text-amber-500 text-[18px]">★</span>
                </div>
                <div className="w-8 h-8 rounded-full bg-[#FFFBEB] flex items-center justify-center text-[#F59E0B]">
                  <Star className="w-4 h-4 fill-[#F59E0B]" />
                </div>
              </div>

              <div className="text-[12px] font-semibold text-[#64748B] mt-1">
                Average Rating
              </div>

              <div className="text-[11px] text-slate-400 font-medium mt-1">
                from 142 reviews
              </div>
            </div>
          </div>

          {/* ============================================================ */}
          {/* 4. MAIN SPLIT: MY ACTIVE EXPERIENCES vs TODAY'S SCHEDULE     */}
          {/* ============================================================ */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            {/* ---------------------------------------------------------- */}
            {/* LEFT 7 COLS: MY ACTIVE EXPERIENCES (4) (2x2 GRID)          */}
            {/* ---------------------------------------------------------- */}
            <div className="lg:col-span-7 space-y-3.5">
              <div className="flex items-center justify-between">
                <h2 className="text-[14px] font-extrabold text-[#0F172A]">
                  My Active Experiences (4)
                </h2>
                <Link
                  href="/experiences/new"
                  className="text-[11px] font-bold text-[#2563EB] hover:underline flex items-center gap-1"
                >
                  <span>View All</span>
                  <span>&rarr;</span>
                </Link>
              </div>

              {/* 2x2 Grid of Experience Cards matching screenshot */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                {experiences.map((exp) => {
                  const isCardPaused = pausedCards[exp.id] || emergencyPaused;

                  return (
                    <div
                      key={exp.id}
                      className="bg-white rounded-2xl border border-[#E2E8F0] shadow-2xs overflow-hidden flex flex-col justify-between"
                    >
                      {/* Image Thumbnail with Active pill */}
                      <div className="relative aspect-[16/10] w-full bg-slate-100">
                        <Image
                          src={exp.image}
                          alt={exp.title}
                          fill
                          className="object-cover"
                          unoptimized
                        />
                        {/* Top-Right Active Status Pill */}
                        <div className="absolute top-2 right-2">
                          <span
                            className={`px-2 py-0.5 rounded-full text-[9px] font-bold shadow-xs flex items-center gap-1 backdrop-blur-md ${
                              isCardPaused
                                ? "bg-slate-800 text-white"
                                : "bg-white/95 text-[#059669]"
                            }`}
                          >
                            <span
                              className={`w-1.5 h-1.5 rounded-full ${
                                isCardPaused ? "bg-amber-400" : "bg-[#10B981]"
                              }`}
                            />
                            <span>{isCardPaused ? "Paused" : "Active"}</span>
                          </span>
                        </div>
                      </div>

                      {/* Content Info */}
                      <div className="p-3 space-y-1.5">
                        <h3 className="text-[12.5px] font-extrabold text-[#0F172A] leading-snug line-clamp-1">
                          {exp.title}
                        </h3>

                        {/* Category tag */}
                        <div>
                          <span
                            className={`px-2 py-0.5 rounded-md text-[9.5px] font-bold inline-block ${exp.categoryBg}`}
                          >
                            {exp.category}
                          </span>
                        </div>

                        {/* Price & Action Buttons */}
                        <div className="pt-2 flex items-center justify-between border-t border-slate-100">
                          <div className="text-[12px] font-black text-[#059669]">
                            {exp.price}
                            <span className="text-[10px] text-slate-400 font-normal ml-0.5">
                              / person
                            </span>
                          </div>

                          <div className="flex items-center gap-1.5">
                            <Link
                              href="/experiences/new"
                              className="px-2 py-1 rounded-md bg-white border border-[#E2E8F0] hover:bg-slate-50 text-[10px] font-bold text-[#475569] shadow-2xs transition-colors"
                            >
                              Edit
                            </Link>

                            <button
                              type="button"
                              onClick={() => togglePauseCard(exp.id)}
                              className="px-2 py-1 rounded-md bg-white border border-[#E2E8F0] hover:bg-slate-50 text-[10px] font-bold text-[#475569] shadow-2xs transition-colors flex items-center gap-1"
                            >
                              <span className="text-[#EF4444] font-black text-[9px] tracking-tighter">
                                ||
                              </span>
                              <span>Pause</span>
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* ---------------------------------------------------------- */}
            {/* RIGHT 5 COLS: TODAY'S GUEST SCHEDULE CARD                  */}
            {/* ---------------------------------------------------------- */}
            <div className="lg:col-span-5 bg-white p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs space-y-4">
              {/* Header */}
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-[14px] font-extrabold text-[#0F172A]">
                    Today&apos;s Guest Schedule
                  </h2>
                  <div className="text-[11px] text-[#64748B] font-medium mt-0.5">
                    Tue, 24 Sep 2026
                  </div>
                </div>

                <Link
                  href="/dashboard"
                  className="text-[11px] font-bold text-[#2563EB] hover:underline flex items-center gap-1"
                >
                  <span>View All</span>
                  <span>&rarr;</span>
                </Link>
              </div>

              {/* Schedule List Items with Timeline Dots matching screenshot */}
              <div className="space-y-4 relative">
                {scheduleItems.map((sch, idx) => (
                  <div key={sch.id} className="relative flex flex-col space-y-1.5">
                    {/* Top Row: Time + Slot Title + Chevron Right */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        {/* Dot indicator */}
                        <span
                          className={`w-2 h-2 rounded-full ${sch.dotColor} shrink-0`}
                        />
                        <span className="text-[11px] font-semibold text-slate-500">
                          {sch.time}
                        </span>
                        <span className="text-[12px] font-extrabold text-[#0F172A]">
                          {sch.title}
                        </span>
                      </div>
                      <ChevronRight className="w-3.5 h-3.5 text-slate-400" />
                    </div>

                    {/* Bottom Row: Guest Avatar + Name & Guests + Status Badge */}
                    <div className="flex items-center justify-between pl-4">
                      <div className="flex items-center gap-2.5">
                        <div className="relative w-8 h-8 rounded-full overflow-hidden shrink-0 border border-[#E2E8F0]">
                          <Image
                            src={sch.avatar}
                            alt={sch.name}
                            fill
                            className="object-cover"
                            unoptimized
                          />
                        </div>
                        <div className="leading-tight">
                          <div className="text-[12px] font-bold text-[#0F172A]">
                            {sch.name}
                          </div>
                          <div className="text-[10px] text-slate-400">
                            {sch.guests}
                          </div>
                        </div>
                      </div>

                      {/* Status Pill matching screenshot */}
                      <div
                        className={`px-2.5 py-0.5 rounded-full border text-[10.5px] font-bold flex items-center gap-1.5 ${sch.statusStyle}`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${sch.statusDot}`}
                        />
                        <span>{sch.status}</span>
                      </div>
                    </div>

                    {/* Timeline Line Connector (except last item) */}
                    {idx < scheduleItems.length - 1 && (
                      <div className="absolute left-[3px] top-[14px] bottom-[-10px] w-[1px] bg-[#E2E8F0] pointer-events-none -z-0" />
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>
        </main>
      </div>
    
      {/* ============================================================ */}
      {/* USER PROFILE MODAL / DRAWER                                  */}
      {/* ============================================================ */}
      {showProfileModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-200">
          <div className="bg-white rounded-[28px] shadow-2xl border border-slate-100 max-w-[480px] w-full p-6 sm:p-7 relative overflow-hidden animate-in zoom-in-95 duration-200">
            {/* Close button */}
            <button
              onClick={() => setShowProfileModal(false)}
              className="absolute top-5 right-5 text-slate-400 hover:text-slate-700 w-8 h-8 rounded-full flex items-center justify-center hover:bg-slate-100 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>

            {/* Profile Header Banner */}
            <div className="flex items-center gap-4 pb-5 border-b border-slate-100">
              <div className="relative w-16 h-16 rounded-2xl overflow-hidden bg-gradient-to-tr from-[#00875A] to-teal-500 text-white font-black text-xl flex items-center justify-center shadow-md">
                {profile?.avatar && profile.avatar.startsWith("/") ? (
                  <Image src={profile.avatar} alt="Profile avatar" fill className="object-cover" unoptimized />
                ) : (
                  <span>{profile?.name ? profile.name.slice(0, 2).toUpperCase() : "HP"}</span>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h3 className="text-[18px] font-black text-[#0F172A] truncate">
                    {profile?.name || "Local Host"}
                  </h3>
                  <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-50 text-[#00875A] border border-emerald-200 text-[10px] font-bold">
                    <ShieldCheck className="w-3 h-3" />
                    Verified
                  </span>
                </div>
                <p className="text-[12px] font-semibold text-[#00875A] mt-0.5 truncate">
                  {profile?.role || "Experience Host"}
                </p>
                <p className="text-[11px] text-slate-400">Host Member ID: #LL-84920</p>
              </div>
            </div>

            {/* Given Details Grid */}
            <div className="py-4 space-y-3">
              <h4 className="text-[11.5px] font-extrabold text-slate-400 uppercase tracking-wider">
                Account &amp; Contact Details
              </h4>

              {/* Full Name */}
              <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                <div className="flex items-center gap-2.5 text-xs text-slate-600">
                  <User className="w-4 h-4 text-slate-400" />
                  <span className="font-medium">Full Name</span>
                </div>
                <span className="text-xs font-bold text-[#0F172A]">
                  {profile?.fullName || profile?.name || "Verified Host"}
                </span>
              </div>

              {/* Email Address */}
              <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                <div className="flex items-center gap-2.5 text-xs text-slate-600">
                  <Mail className="w-4 h-4 text-slate-400" />
                  <span className="font-medium">Email Address</span>
                </div>
                <span className="text-xs font-bold text-[#0F172A] truncate max-w-[220px]">
                  {profile?.email || "provider@locallens.in"}
                </span>
              </div>

              {/* Phone Number */}
              <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                <div className="flex items-center gap-2.5 text-xs text-slate-600">
                  <Phone className="w-4 h-4 text-slate-400" />
                  <span className="font-medium">Phone Number</span>
                </div>
                <span className="text-xs font-bold text-[#0F172A]">
                  {profile?.phone || "+91 98201 55432"}
                </span>
              </div>

              {/* Host Category / Role */}
              <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                <div className="flex items-center gap-2.5 text-xs text-slate-600">
                  <Compass className="w-4 h-4 text-slate-400" />
                  <span className="font-medium">Host Specialty</span>
                </div>
                <span className="text-xs font-bold text-[#00875A]">
                  {profile?.role || "Tour Guide / Storyteller"}
                </span>
              </div>

              {/* Authentication Option */}
              <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                <div className="flex items-center gap-2.5 text-xs text-slate-600">
                  <Sparkles className="w-4 h-4 text-slate-400" />
                  <span className="font-medium">Signed in with</span>
                </div>
                <span className="text-xs font-bold text-slate-800 capitalize">
                  {profile?.authProvider || "Email & Password"}
                </span>
              </div>
            </div>

            {/* Performance Stats */}
            <div className="grid grid-cols-3 gap-2.5 py-3 border-t border-slate-100">
              <div className="p-2.5 rounded-xl bg-emerald-50/60 text-center">
                <div className="text-[10px] text-emerald-800 font-semibold">Rating</div>
                <div className="text-[14px] font-black text-[#00875A]">4.9 ★</div>
              </div>
              <div className="p-2.5 rounded-xl bg-blue-50/60 text-center">
                <div className="text-[10px] text-blue-800 font-semibold">Experiences</div>
                <div className="text-[14px] font-black text-blue-900">4 Active</div>
              </div>
              <div className="p-2.5 rounded-xl bg-amber-50/60 text-center">
                <div className="text-[10px] text-amber-800 font-semibold">Total Guests</div>
                <div className="text-[14px] font-black text-amber-900">328+</div>
              </div>
            </div>

            {/* Modal Actions */}
            <div className="pt-4 border-t border-slate-100 flex items-center gap-3">
              <button
                type="button"
                onClick={handleLogout}
                className="flex-1 py-2.5 px-4 rounded-xl border border-red-200 bg-red-50 hover:bg-red-100 text-red-700 font-bold text-xs flex items-center justify-center gap-2 transition-colors cursor-pointer"
              >
                <LogOut className="w-3.5 h-3.5" />
                <span>Log Out</span>
              </button>
              <button
                type="button"
                onClick={() => setShowProfileModal(false)}
                className="flex-1 py-2.5 px-4 rounded-xl bg-[#00875A] hover:bg-[#00704A] text-white font-extrabold text-xs transition-colors cursor-pointer"
              >
                Done
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
