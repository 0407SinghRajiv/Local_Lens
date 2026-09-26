"use client";

import { supabase } from "@/lib/supabaseClient";
import { getOrCreateProviderProfile } from "@/lib/authSession";
import React, { useState, useEffect, Suspense } from "react";
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
  Navigation,
  Clock,
  MapPin,
  RefreshCw,
} from "lucide-react";
import { getProviderProfile, logoutProvider, ProviderProfile } from "@/lib/authSession";
import { getStoredExperiencesForProvider } from "@/services/mockExperiences";
import { useAuth } from "@/hooks/useAuth";
import { Booking, BookingStatus, NearbyGuest } from "@/types/booking";
import {
  fetchProviderBookings,
  subscribeToBookingsRealtime,
  updateBookingStatus,
  createRealBooking,
  fetchGuestsNearby,
} from "@/services/bookingService";
import { BookingDetailDrawer } from "@/components/bookings/BookingDetailDrawer";
import { useI18n } from "@/lib/i18n";
import { LanguageSelector } from "@/components/settings/LanguageSelector";

function DashboardContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { t, language } = useI18n();
  const [emergencyPaused, setEmergencyPaused] = useState(true);
  const [activeMenu, setActiveMenu] = useState("dashboard");
  const { user, profile: authProfile, loading: authLoading, signOut } = useAuth();
  const [profile, setProfile] = useState<ProviderProfile | null>(null);
  const [showProfileModal, setShowProfileModal] = useState(false);

  useEffect(() => {
    if (authProfile) {
      setProfile(authProfile);
    }
  }, [authProfile]);

  useEffect(() => {
    if (!authLoading && !user && !authProfile) {
      router.replace("/login");
    }
  }, [authLoading, user, authProfile, router]);

  useEffect(() => {
    if (searchParams.get("profile") === "true") {
      setShowProfileModal(true);
    }
  }, [searchParams]);

  const handleLogout = async () => {
    if (typeof window !== "undefined") {
      // 1. Completely remove user account session and credentials
      localStorage.removeItem("locallens_provider_session");
      localStorage.removeItem("locallens_last_provider_email");
    }
    // 2. Sign out from Supabase session
    await signOut();
    // 3. Redirect to login page asking user to sign in afresh
    window.location.href = "/login?logged_out=true";
  };

  const displayName = profile?.fullName || user?.user_metadata?.full_name || user?.user_metadata?.name || profile?.name || "Local Provider";
  const userEmail = profile?.email || user?.email || "provider@locallens.in";
  const avatarUrl = profile?.avatar || user?.user_metadata?.avatar_url || user?.user_metadata?.picture || "";
  const userInitials = displayName.split(" ").map((n: string) => n[0]).join("").slice(0, 2).toUpperCase() || "LP";
  const userId = user?.id || profile?.id || "auth_user_session";
  const authProviderName = user?.app_metadata?.provider || profile?.authProvider || "google";

  // Experience Card Pause states
  const [pausedCards, setPausedCards] = useState<Record<string, boolean>>({});

  const togglePauseCard = (id: string) => {
    setPausedCards((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  const navMenuItems = [
    { key: "dashboard", name: t("nav.dashboard", "Dashboard"), href: "/dashboard", icon: LayoutDashboard },
    { key: "experiences", name: t("nav.myExperiences", "My Experiences"), href: "/experiences/new", icon: Layers },
    { key: "bookings", name: t("nav.bookings", "Bookings"), href: "/bookings", icon: ClipboardList },
    { key: "boost", name: t("nav.boostSponsor", "Boost & Sponsor"), href: "/boost", icon: Rocket },
    { key: "payouts", name: t("nav.payouts", "Payouts"), href: "/dashboard", icon: Wallet },
    { key: "settings", name: t("nav.settings", "Settings"), href: "/settings", icon: Settings },
  ];

  // Stored experiences dynamic sync with strict provider isolation
  const [storedListings, setStoredListings] = useState<any[]>([]);
  const [analyticsTab, setAnalyticsTab] = useState<"earnings" | "visitors">("earnings");
  const [isLoadingListings, setIsLoadingListings] = useState<boolean>(true);

  useEffect(() => {
    let isCancelled = false;

    async function loadProviderExperiences() {
      if (!userId) return;
      setIsLoadingListings(true);

      const combined: any[] = [];
      const seenIds = new Set<string>();

      // 1. Fetch from Supabase experience table matching this provider
      try {
        const filterClauses = [
          `source_url.ilike.%/provider/${userId}%`,
          `source_name.ilike.%${userId}%`,
          `tags.ilike.%provider:${userId}%`,
        ];
        if (userEmail && userEmail !== "provider@locallens.in") {
          filterClauses.push(`source_url.ilike.%${userEmail}%`);
          filterClauses.push(`source_name.ilike.%${userEmail}%`);
          filterClauses.push(`tags.ilike.%provider_email:${userEmail}%`);
        }

        const { data: dbData } = await supabase
          .from("experience")
          .select("*")
          .or(filterClauses.join(","));

        if (dbData && dbData.length > 0) {
          for (const item of dbData) {
            const key = (item.experience_id || item.experience_name || "").trim().toLowerCase();
            if (key && !seenIds.has(key)) {
              seenIds.add(key);
              combined.push(item);
            }
          }
        }
      } catch (err) {
        console.warn("Supabase provider query notice:", err);
      }

      // 2. Fetch from /api/experiences with provider query params
      try {
        const res = await fetch(
          `/api/experiences?provider_id=${encodeURIComponent(userId)}&email=${encodeURIComponent(userEmail || "")}`
        );
        const json = await res.json();
        if (json.success && Array.isArray(json.data) && json.data.length > 0) {
          for (const item of json.data) {
            const key = (item.experience_id || item.experience_name || "").trim().toLowerCase();
            if (key && !seenIds.has(key)) {
              seenIds.add(key);
              combined.push(item);
            }
          }
        }
      } catch (e) {}

      // 3. Fetch from local provider-isolated storage
      try {
        const localItems = getStoredExperiencesForProvider(userId, userEmail);
        if (localItems && localItems.length > 0) {
          for (const item of localItems) {
            const key = (item.experience_id || item.experience_name || "").trim().toLowerCase();
            if (key && !seenIds.has(key)) {
              seenIds.add(key);
              combined.push(item);
            }
          }
        }
      } catch (e) {}

      if (!isCancelled) {
        setStoredListings(combined);
        setIsLoadingListings(false);
      }
    }

    loadProviderExperiences();

    return () => {
      isCancelled = true;
    };
  }, [userId, userEmail]);

  // Real database-driven bookings state for THIS provider only
  const [realBookings, setRealBookings] = useState<Booking[]>([]);
  const [isLoadingBookings, setIsLoadingBookings] = useState<boolean>(true);
  const [activeScheduleFilter, setActiveScheduleFilter] = useState<
    "Today" | "Upcoming" | "Confirmed" | "Pending" | "Cancelled"
  >("Today");
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null);
  const [isRealtimeActive, setIsRealtimeActive] = useState<boolean>(false);

  // Guests Nearby state
  const [nearbyGuests, setNearbyGuests] = useState<NearbyGuest[]>([]);
  const [isLoadingNearby, setIsLoadingNearby] = useState<boolean>(false);
  const [nearbyRadius, setNearbyRadius] = useState<number>(25);

  const loadProviderBookings = React.useCallback(async () => {
    if (!userId) return;
    setIsLoadingBookings(true);
    const data = await fetchProviderBookings(userId, userEmail);
    setRealBookings(data);
    setIsLoadingBookings(false);
  }, [userId, userEmail]);

  useEffect(() => {
    loadProviderBookings();

    const unsubscribe = subscribeToBookingsRealtime(
      userId,
      () => {
        loadProviderBookings();
      },
      (isConnected) => {
        setIsRealtimeActive(isConnected);
      }
    );

    return () => {
      unsubscribe();
    };
  }, [userId, userEmail, loadProviderBookings]);

  const handleUpdateBookingStatus = async (bookingId: string, newStatus: BookingStatus) => {
    await updateBookingStatus(bookingId, newStatus, userId);
    if (selectedBooking && selectedBooking.id === bookingId) {
      setSelectedBooking((prev) => (prev ? { ...prev, status: newStatus } : null));
    }
    loadProviderBookings();
  };

  if (authLoading && !profile) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="text-center space-y-3">
          <div className="w-10 h-10 border-4 border-[#00875A] border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-xs font-bold text-slate-600">Loading Provider Portal...</p>
        </div>
      </div>
    );
  }

  if (!user && !profile && !authProfile) {
    return null;
  }

  const displayExperiences = React.useMemo(() => {
    if (storedListings.length > 0) {
      return storedListings.map((exp: any, idx: number) => ({
        id: exp.experience_id || `EXP-${idx + 1}`,
        title: exp.experience_name || exp.title || "Local Experience",
        category: exp.category || "Nature & Adventure",
        categoryBg:
          exp.category === "Heritage"
            ? "bg-[#ECFDF5] text-[#059669]"
            : exp.category === "Food" || exp.category === "Culinary & Food"
            ? "bg-[#ECFDF5] text-[#059669]"
            : "bg-[#FEF3C7] text-[#B45309]",
        price:
          typeof exp.price_inr_clean === "number"
            ? `₹${exp.price_inr_clean.toLocaleString()}`
            : typeof exp.price_inr === "string"
            ? exp.price_inr
            : "₹1,200",
        priceNum: typeof exp.price_inr_clean === "number" ? exp.price_inr_clean : 1200,
        image: exp.images?.[0] || exp.image_url || exp.image || "/dashboard/kayaking.jpg",
        latitude: Number(exp.latitude) || 19.131102,
        longitude: Number(exp.longitude) || 72.81541,
        city: exp.city || "Mumbai",
      }));
    }
    // Strict multi-tenant isolation: do not show other providers' experiences
    return [];
  }, [storedListings]);

  // Load Guests Nearby based on provider coordinates
  useEffect(() => {
    const lat = displayExperiences[0]?.latitude || 19.131102;
    const lng = displayExperiences[0]?.longitude || 72.81541;

    async function loadNearby() {
      setIsLoadingNearby(true);
      const data = await fetchGuestsNearby(lat, lng, nearbyRadius, userId);
      setNearbyGuests(data);
      setIsLoadingNearby(false);
    }

    loadNearby();
  }, [displayExperiences, nearbyRadius, userId]);

  const handleCreateTestBooking = async () => {
    const exp = displayExperiences[0];
    const todayDateStr = new Date().toISOString().split("T")[0];
    const sampleGuests = [
      { name: "Ananya Patel", phone: "+91 98334 55667", avatar: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=400&q=80" },
      { name: "Rohan Varma", phone: "+91 98111 88990", avatar: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=400&q=80" },
      { name: "Tanvi Deshmukh", phone: "+91 98201 44321", avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80" },
    ];
    const picked = sampleGuests[Math.floor(Math.random() * sampleGuests.length)];
    const times = ["09:30 AM", "11:00 AM", "02:00 PM", "04:30 PM", "06:00 PM"];
    const pickedTime = times[Math.floor(Math.random() * times.length)];

    await createRealBooking({
      provider_id: userId,
      provider_email: userEmail,
      experience_id: exp?.id || "EXP-1",
      experience_name: exp?.title || "Sunset Kayaking at Versova",
      guest_name: picked.name,
      guest_phone: picked.phone,
      guest_avatar: picked.avatar,
      booking_date: todayDateStr,
      booking_time: pickedTime,
      slots: 2,
      total_amount_inr: (exp?.priceNum || 1200) * 2,
      status: "Confirmed",
      meeting_point: exp?.title ? `${exp.title} Meeting Spot, Mumbai` : "Versova Beach Launch Pad, Mumbai",
      latitude: exp?.latitude || 19.131102,
      longitude: exp?.longitude || 72.81541,
      city: exp?.city || "Mumbai",
    });

    loadProviderBookings();
  };

  const todayDateStr = new Date().toISOString().split("T")[0];

  const displayedScheduleBookings = React.useMemo(() => {
    return realBookings.filter((b) => {
      if (activeScheduleFilter === "Today") {
        return b.booking_date === todayDateStr;
      }
      if (activeScheduleFilter === "Upcoming") {
        return b.booking_date >= todayDateStr;
      }
      if (activeScheduleFilter === "Confirmed") {
        return (
          b.status === "Confirmed" ||
          b.status === "Driver En Route" ||
          b.status === "Driver Arrived"
        );
      }
      if (activeScheduleFilter === "Pending") {
        return b.status === "Pending";
      }
      if (activeScheduleFilter === "Cancelled") {
        return b.status === "Cancelled";
      }
      return true;
    });
  }, [realBookings, activeScheduleFilter, todayDateStr]);

  // Dynamic calculations from real live visits and listings for THIS provider
  const activeBookings = React.useMemo(
    () => realBookings.filter((b) => b.status !== "Cancelled"),
    [realBookings]
  );
  const totalEarningsNum = activeBookings.reduce((acc, b) => acc + (b.total_amount_inr || 0), 0);
  const totalGuestsCount = activeBookings.reduce((acc, b) => acc + (b.slots || 1), 0);
  const primaryExperienceTitle = displayExperiences[0]?.title || "My First Experience";


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
              const isActive = activeMenu === item.key || activeMenu === item.name;

              return (
                <Link
                  key={item.key}
                  href={item.href}
                  onClick={() => setActiveMenu(item.key)}
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
      </aside>

      {/* ============================================================ */}
      {/* 2. MAIN DASHBOARD CONTENT AREA                               */}
      {/* ============================================================ */}
      <div className="flex-1 flex flex-col min-w-0 overflow-y-auto">
        {/* Top Header Bar matching top of screenshot */}
        <header className="w-full bg-[#F8FAFC] px-8 py-5 flex items-center justify-between gap-4 border-b border-transparent">
          {/* Welcome Greeting */}
          <div>
            <h1 className="text-[20px] sm:text-[22px] font-heading font-anton text-[#0F172A] flex items-center gap-1.5 tracking-tight leading-snug">
              <span>{t("dashboard.welcome", "Welcome back")}, {displayName}</span>
              <span className="text-[20px]">👋</span>
            </h1>
            <p className="text-[12px] text-[#64748B] font-normal">
              {t("dashboard.subtitle", "Here is what is happening with your experiences and guest schedule today.")}
            </p>
          </div>

          {/* Right Header Controls: Language, Search, Bell, Emergency Pause */}
          <div className="flex items-center gap-3.5">
            {/* Multilingual Selector */}
            <LanguageSelector variant="navbar" />

            {/* Search Input */}
            <div className="relative w-52 sm:w-60">
              <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder={t("nav.searchPlaceholder", "Search bookings, guests...")}
                className="w-full pl-8 pr-3 py-1.5 rounded-xl bg-white border border-[#E2E8F0] text-[11px] text-[#0F172A] placeholder:text-slate-400 focus:outline-none focus:ring-1 focus:ring-[#059669] shadow-2xs"
              />
            </div>

            {/* Notification Bell with Red Badge "3" */}
            <button
              className="relative w-8 h-8 rounded-full bg-white border border-[#E2E8F0] flex items-center justify-center text-slate-600 hover:bg-slate-50 transition-colors shadow-2xs cursor-pointer"
              title={t("nav.notifications", "Notifications")}
            >
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
                  {t("nav.emergencyPause", "Emergency Pause")}
                </span>
                <span className="text-[10px] font-medium text-[#BE123C]/90">
                  {t("nav.allOutdoor", "All Outdoor Listings")}
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
          {/* 3. FOUR KPI CARDS (MATCHING REALTIME BOOKINGS & LISTINGS)     */}
          {/* ============================================================ */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {/* Card 1: Total Earnings */}
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="text-[22px] sm:text-[26px] font-heading font-anton text-[#0F172A] tracking-tight">
                  ₹{totalEarningsNum.toLocaleString()}
                </div>
                {/* 3 Green Vertical Bars */}
                <div className="flex items-end gap-0.5 h-5 pb-0.5">
                  <span className="w-1 h-2 rounded-xs bg-[#10B981]" />
                  <span className="w-1 h-3.5 rounded-xs bg-[#10B981]" />
                  <span className="w-1 h-5 rounded-xs bg-[#10B981]" />
                </div>
              </div>

              <div className="text-[12px] font-semibold text-[#64748B] mt-1">
                {t("dashboard.stats.totalEarnings", "Total Earnings")}
              </div>

              <div className="text-[11px] text-slate-400 font-medium mt-1 flex items-center gap-2">
                <span>{t("dashboard.stats.allTime", "All Time")}</span>
                <span className="text-[#059669] font-bold flex items-center gap-0.5">
                  <span>&uarr;</span> 100%
                </span>
              </div>
            </div>

            {/* Card 2: Active Experiences */}
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="text-[24px] sm:text-[28px] font-heading font-anton text-[#0F172A] tracking-tight">
                  {displayExperiences.length}
                </div>
                <div className="w-7 h-7 rounded-full bg-[#ECFDF5] flex items-center justify-center">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#10B981]" />
                </div>
              </div>

              <div className="text-[12px] font-semibold text-[#64748B] mt-1">
                {t("dashboard.stats.activeListings", "Active Experiences")}
              </div>

              <div className="text-[11px] text-slate-400 font-medium mt-1">
                {displayExperiences.length === 1 ? `1 ${t("dashboard.experiences.active", "active")}` : `${displayExperiences.length} ${t("dashboard.experiences.active", "active")}`}
              </div>
            </div>

            {/* Card 3: Today's Bookings */}
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="flex items-baseline gap-1">
                  <span className="text-[22px] sm:text-[26px] font-heading font-anton text-[#0F172A] tracking-tight">
                    {totalGuestsCount}
                  </span>
                  <span className="text-[13px] text-slate-500 font-normal">
                    {t("dashboard.schedule.guestsCount", "guests")}
                  </span>
                </div>
                <div className="w-7 h-7 rounded-lg bg-[#EFF6FF] flex items-center justify-center text-[#3B82F6]">
                  <Calendar className="w-4 h-4" />
                </div>
              </div>

              <div className="text-[12px] font-semibold text-[#64748B] mt-1">
                {t("dashboard.stats.totalBookings", "Total Bookings")}
              </div>

              <div className="text-[11px] text-slate-400 font-medium mt-1">
                {displayedScheduleBookings.length} {t("dashboard.schedule.filters.today", "today")}
              </div>
            </div>

            {/* Card 4: Average Rating */}
            <div className="bg-white p-4 sm:p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs flex flex-col justify-between">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-1.5">
                  <span className="text-[22px] sm:text-[26px] font-heading font-anton text-[#0F172A] tracking-tight">
                    4.9
                  </span>
                  <span className="text-amber-500 text-[18px]">★</span>
                </div>
                <div className="w-8 h-8 rounded-full bg-[#FFFBEB] flex items-center justify-center text-[#F59E0B]">
                  <Star className="w-4 h-4 fill-[#F59E0B]" />
                </div>
              </div>

              <div className="text-[12px] font-semibold text-[#64748B] mt-1">
                {t("dashboard.stats.overallRating", "Overall Rating")}
              </div>

              <div className="text-[11px] text-slate-400 font-medium mt-1">
                {t("dashboard.stats.reviews", "verified traveler reviews")}
              </div>
            </div>
          </div>

          {/* ============================================================ */}
          {/* EARNINGS & VISITOR TRAFFIC REALTIME ANALYTICS GRAPH            */}
          {/* ============================================================ */}
          <div className="bg-white rounded-2xl border border-[#E2E8F0] shadow-2xs p-5">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 pb-4 border-b border-slate-100">
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-[15px] font-heading font-anton text-[#0F172A] tracking-tight">
                    {t("dashboard.analytics.title", "Performance Analytics")}
                  </h3>
                  <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-emerald-50 text-[#00875A] text-[10px] font-extrabold border border-emerald-200">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#00875A] animate-pulse" />
                    {t("dashboard.liveRealtime", "Live Realtime")}
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 font-medium mt-0.5">
                  {primaryExperienceTitle}
                </p>
              </div>

              {/* Toggle Tabs */}
              <div className="flex items-center bg-slate-100 p-1 rounded-xl text-xs font-bold">
                <button
                  type="button"
                  onClick={() => setAnalyticsTab("earnings")}
                  className={`px-3 py-1 rounded-lg transition-all cursor-pointer ${
                    analyticsTab === "earnings"
                      ? "bg-[#00875A] text-white shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  ₹ {t("dashboard.analytics.earnings", "Earnings")}
                </button>
                <button
                  type="button"
                  onClick={() => setAnalyticsTab("visitors")}
                  className={`px-3 py-1 rounded-lg transition-all cursor-pointer ${
                    analyticsTab === "visitors"
                      ? "bg-[#2563EB] text-white shadow-xs"
                      : "text-slate-600 hover:text-slate-900"
                  }`}
                >
                  👥 {t("dashboard.analytics.visitors", "Visitors")}
                </button>
              </div>
            </div>

            {/* Summary KPI Highlights */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-4 pb-2">
              <div className="bg-slate-50/80 rounded-xl p-3 border border-slate-100">
                <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">
                  Current Revenue
                </span>
                <span className="text-[18px] font-black text-[#0F172A] mt-0.5 block">
                  ₹{totalEarningsNum.toLocaleString()}
                </span>
              </div>
              <div className="bg-slate-50/80 rounded-xl p-3 border border-slate-100">
                <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">
                  Total Guests
                </span>
                <span className="text-[18px] font-black text-[#2563EB] mt-0.5 block">
                  {totalGuestsCount} Travelers
                </span>
              </div>
              <div className="bg-slate-50/80 rounded-xl p-3 border border-slate-100">
                <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">
                  Confirmed Visits
                </span>
                <span className="text-[18px] font-black text-[#00875A] mt-0.5 block">
                  {activeBookings.length} Bookings
                </span>
              </div>
              <div className="bg-slate-50/80 rounded-xl p-3 border border-slate-100">
                <span className="text-[10px] font-extrabold text-slate-400 uppercase tracking-wider block">
                  Avg Ticket Price
                </span>
                <span className="text-[18px] font-black text-amber-600 mt-0.5 block">
                  ₹{(displayExperiences[0]?.priceNum || 1200).toLocaleString()}
                </span>
              </div>
            </div>

            {/* SVG Visual Bar Chart */}
            <div className="pt-4">
              <div className="h-40 w-full flex items-end justify-between gap-2 sm:gap-4 px-2 pt-6 pb-2 border-b border-slate-100">
                {[
                  { day: "Mon", earnings: Math.round(totalEarningsNum * 0.12), visitors: 1, pct: "30%" },
                  { day: "Tue", earnings: Math.round(totalEarningsNum * 0.18), visitors: 2, pct: "45%" },
                  { day: "Wed", earnings: Math.round(totalEarningsNum * 0.15), visitors: 2, pct: "40%" },
                  { day: "Thu", earnings: Math.round(totalEarningsNum * 0.22), visitors: 3, pct: "55%" },
                  { day: "Fri", earnings: Math.round(totalEarningsNum * 0.35), visitors: 5, pct: "75%" },
                  { day: "Sat", earnings: Math.round(totalEarningsNum * 0.45), visitors: 6, pct: "90%" },
                  { day: "Today", earnings: totalEarningsNum, visitors: totalGuestsCount, pct: "100%", isToday: true },
                ].map((item, idx) => {
                  const isEarnings = analyticsTab === "earnings";
                  const valLabel = isEarnings ? `₹${item.earnings}` : `${item.visitors} guests`;
                  const barBg = isEarnings
                    ? item.isToday ? "bg-gradient-to-t from-[#00875A] to-emerald-400" : "bg-emerald-200 hover:bg-emerald-300"
                    : item.isToday ? "bg-gradient-to-t from-blue-600 to-sky-400" : "bg-blue-200 hover:bg-blue-300";

                  return (
                    <div key={idx} className="flex-1 flex flex-col items-center h-full justify-end group relative cursor-pointer">
                      {/* Hover Tooltip */}
                      <div className="opacity-0 group-hover:opacity-100 transition-opacity absolute -top-8 bg-slate-900 text-white text-[10px] font-bold px-2 py-0.5 rounded shadow pointer-events-none whitespace-nowrap z-20">
                        {item.day}: {valLabel}
                      </div>

                      {/* Bar Fill */}
                      <div
                        style={{ height: item.pct }}
                        className={`w-full max-w-[42px] rounded-t-lg transition-all duration-500 ${barBg}`}
                      />

                      {/* Day Label */}
                      <span className={`text-[10.5px] mt-2 font-bold ${item.isToday ? "text-[#00875A]" : "text-slate-400"}`}>
                        {item.day}
                      </span>
                    </div>
                  );
                })}
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
                <div className="flex items-center gap-2">
                  <h2 className="text-[14px] font-heading font-anton text-[#0F172A]">
                    {t("dashboard.experiences.title", "My Listed Experiences")} ({displayExperiences.length})
                  </h2>
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
                </div>
                <Link
                  href="/experiences/new"
                  className="text-[11px] font-bold text-[#2563EB] hover:underline flex items-center gap-1"
                >
                  <span>{t("dashboard.viewAll", "View All")}</span>
                  <span>&rarr;</span>
                </Link>
              </div>

              {/* 2x2 Grid of Experience Cards matching screenshot */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                {displayExperiences.length === 0 ? (
                  <div className="bg-white rounded-2xl border-2 border-dashed border-slate-200 p-6 text-center space-y-2.5 flex flex-col items-center justify-center min-h-[190px]">
                    <div className="w-10 h-10 rounded-2xl bg-emerald-50 text-[#0e8a5b] flex items-center justify-center">
                      <Layers className="w-5 h-5 text-[#0e8a5b]" />
                    </div>
                    <div>
                      <h4 className="text-xs font-bold text-slate-800">No Experiences Listed Yet</h4>
                      <p className="text-[11px] text-slate-500 max-w-xs mt-0.5">
                        List your first experience to start receiving bookings and travelers on LocalLens!
                      </p>
                    </div>
                    <Link
                      href="/experiences/new"
                      className="px-3.5 py-1.5 rounded-xl bg-[#0e8a5b] text-white text-xs font-bold hover:bg-[#0b744d] transition-colors shadow-2xs"
                    >
                      + Create First Experience
                    </Link>
                  </div>
                ) : (
                  displayExperiences.map((exp) => {
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
                              <span>{isCardPaused ? t("dashboard.experiences.paused", "Paused") : t("dashboard.experiences.active", "Active")}</span>
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
                                {t("dashboard.experiences.edit", "Edit")}
                              </Link>

                              <button
                                type="button"
                                onClick={() => togglePauseCard(exp.id)}
                                className="px-2 py-1 rounded-md bg-white border border-[#E2E8F0] hover:bg-slate-50 text-[10px] font-bold text-[#475569] shadow-2xs transition-colors flex items-center gap-1"
                              >
                                <span className="text-[#EF4444] font-black text-[9px] tracking-tighter">
                                  ||
                                </span>
                                <span>{isCardPaused ? t("dashboard.experiences.resume", "Resume") : t("dashboard.experiences.pause", "Pause")}</span>
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}

                {/* Add Another Experience card */}
                <Link
                  href="/experiences/new"
                  className="rounded-2xl border-2 border-dashed border-slate-200 hover:border-[#00875A] bg-white/70 hover:bg-emerald-50/40 p-5 flex flex-col items-center justify-center text-center transition-all group cursor-pointer min-h-[190px]"
                >
                  <div className="w-9 h-9 rounded-xl bg-slate-50 border border-slate-200 text-[#00875A] flex items-center justify-center shadow-xs group-hover:scale-110 transition-transform mb-2">
                    <Sparkles className="w-4 h-4 text-[#00875A]" />
                  </div>
                  <span className="text-xs font-black text-slate-800 group-hover:text-[#00875A]">
                    {t("dashboard.experiences.newListing", "+ Add New Experience")}
                  </span>
                  <span className="text-[10px] text-slate-400 mt-0.5 max-w-[170px] leading-tight">
                    {t("experienceForm.pageSubtitle", "List workshops, boat tours, heritage walks & activities")}
                  </span>
                </Link>
              </div>

              {/* ======================================================== */}
              {/* GUESTS NEARBY (Travelers within radius of experiences)   */}
              {/* ======================================================== */}
              <div className="bg-white p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-xl bg-emerald-50 text-[#00875A] flex items-center justify-center shadow-xs">
                      <Navigation className="w-4 h-4 text-[#00875A]" />
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h3 className="text-[14px] font-heading font-anton text-[#0F172A]">
                          {t("dashboard.nearby.title", "Guests Nearby")}
                        </h3>
                        <span className="px-2 py-0.5 rounded-full bg-emerald-50 text-[#00875A] border border-emerald-200 text-[10px] font-bold">
                          {nearbyRadius} km
                        </span>
                      </div>
                      <p className="text-[11px] text-[#64748B] font-medium mt-0.5">
                        {t("dashboard.nearby.subtitle", "Active travelers and guests in your area looking for local activities.")}
                      </p>
                    </div>
                  </div>

                  {/* Radius Switcher */}
                  <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl">
                    {[10, 25].map((r) => (
                      <button
                        key={r}
                        type="button"
                        onClick={() => setNearbyRadius(r)}
                        className={`px-2.5 py-0.5 rounded-lg text-[10.5px] font-extrabold transition-all cursor-pointer ${
                          nearbyRadius === r
                            ? "bg-white text-[#00875A] shadow-xs"
                            : "text-slate-500 hover:text-slate-800"
                        }`}
                      >
                        {r} km
                      </button>
                    ))}
                  </div>
                </div>

                {isLoadingNearby ? (
                  <div className="py-6 text-center text-xs text-slate-400 font-bold flex items-center justify-center gap-2">
                    <div className="w-4 h-4 border-2 border-[#00875A] border-t-transparent rounded-full animate-spin" />
                    <span>{t("common.loading", "Loading...")}</span>
                  </div>
                ) : nearbyGuests.length === 0 ? (
                  <div className="p-5 text-center bg-slate-50/70 rounded-xl border border-dashed border-slate-200 text-xs text-slate-400 space-y-1">
                    <MapPin className="w-5 h-5 mx-auto text-slate-400 mb-1" />
                    <p className="font-bold text-slate-600">{t("dashboard.nearby.noNearby", "No nearby guest activity detected within this radius right now.")}</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {nearbyGuests.map((guest) => {
                      const initials = guest.guest_name
                        .split(" ")
                        .map((n) => n[0])
                        .join("")
                        .slice(0, 2)
                        .toUpperCase();

                      return (
                        <div
                          key={guest.id}
                          className="p-3 rounded-xl border border-slate-200/80 bg-slate-50/50 hover:bg-white hover:border-emerald-300 hover:shadow-xs transition-all flex items-center justify-between gap-3"
                        >
                          <div className="flex items-center gap-2.5 min-w-0">
                            {guest.guest_avatar ? (
                              <div className="relative w-8 h-8 rounded-full overflow-hidden shrink-0 border border-slate-200">
                                <Image
                                  src={guest.guest_avatar}
                                  alt={guest.guest_name}
                                  fill
                                  className="object-cover"
                                  unoptimized
                                />
                              </div>
                            ) : (
                              <div className="w-8 h-8 rounded-full bg-emerald-100 text-[#00875A] font-extrabold text-[10px] flex items-center justify-center shrink-0">
                                {initials}
                              </div>
                            )}
                            <div className="min-w-0">
                              <div className="text-xs font-bold text-slate-900 truncate">
                                {guest.guest_name}
                              </div>
                              <div className="text-[10px] text-slate-500 truncate">
                                {guest.experience_name}
                              </div>
                            </div>
                          </div>

                          <div className="text-right shrink-0">
                            <span className="inline-block px-2 py-0.5 rounded-md bg-emerald-50 text-[#00875A] font-extrabold text-[10px] border border-emerald-200/60">
                              {guest.distance_km} km {t("dashboard.nearby.away", "away")}
                            </span>
                            <div className="text-[9.5px] text-slate-400 mt-0.5">
                              {guest.area}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}

                {/* Privacy Rule Guarantee */}
                <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[10px] text-slate-400">
                  <div className="flex items-center gap-1.5">
                    <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                    <span>{t("dashboard.nearby.privacyNotice", "Privacy Guaranteed: Names & contacts are masked according to privacy guidelines.")}</span>
                  </div>
                  <span>Real PostGIS</span>
                </div>
              </div>
            </div>

            {/* ---------------------------------------------------------- */}
            {/* RIGHT 5 COLS: TODAY'S GUEST SCHEDULE CARD                  */}
            {/* ---------------------------------------------------------- */}
            <div className="lg:col-span-5 bg-white p-5 rounded-2xl border border-[#E2E8F0] shadow-2xs space-y-4">
              {/* Header */}
              <div className="flex items-center justify-between">
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-[14px] font-heading font-anton text-[#0F172A]">
                      {t("dashboard.schedule.title", "Today's Guest Schedule")}
                    </h2>
                    {isRealtimeActive && (
                      <span className="w-2 h-2 rounded-full bg-[#00875A] animate-pulse" />
                    )}
                  </div>
                  <div className="text-[11px] text-[#64748B] font-medium mt-0.5">
                    {primaryExperienceTitle}
                  </div>
                </div>

                {/* Realtime Status - ONLY REAL STATUS */}
                <div className="flex items-center gap-2">
                  {isRealtimeActive ? (
                    <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-emerald-50 border border-emerald-200 text-[#00875A] text-[10px] font-bold">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping" />
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 -ml-3" />
                      <span>{t("dashboard.liveRealtime", "Live Realtime")}</span>
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-slate-100 text-slate-500 text-[10px] font-medium">
                      <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
                      <span>{t("dashboard.connecting", "Connecting...")}</span>
                    </span>
                  )}

                  <Link
                    href="/bookings"
                    className="text-[11px] font-bold text-[#2563EB] hover:underline"
                  >
                    {t("dashboard.viewAll", "View All")} &rarr;
                  </Link>
                </div>
              </div>

              {/* Filter Pills */}
              <div className="flex items-center gap-1 border-b border-slate-100 pb-2.5 overflow-x-auto">
                {[
                  { key: "Today", label: t("dashboard.schedule.filters.today", "Today") },
                  { key: "Upcoming", label: t("dashboard.schedule.filters.upcoming", "Upcoming") },
                  { key: "Confirmed", label: t("dashboard.schedule.filters.confirmed", "Confirmed") },
                  { key: "Pending", label: t("dashboard.schedule.filters.pending", "Pending") },
                  { key: "Cancelled", label: t("dashboard.schedule.filters.cancelled", "Cancelled") },
                ].map(({ key, label }) => {
                  const isActive = activeScheduleFilter === key;
                  return (
                    <button
                      key={key}
                      type="button"
                      onClick={() => setActiveScheduleFilter(key as any)}
                      className={`px-2.5 py-1 rounded-lg text-[10.5px] font-bold transition-all cursor-pointer shrink-0 ${
                        isActive
                          ? "bg-[#00875A] text-white shadow-2xs"
                          : "text-slate-500 hover:bg-slate-100 hover:text-slate-800"
                      }`}
                    >
                      {label}
                    </button>
                  );
                })}
              </div>

              {/* Schedule List */}
              {isLoadingBookings ? (
                <div className="py-10 text-center space-y-2">
                  <div className="w-6 h-6 border-2 border-[#00875A] border-t-transparent rounded-full animate-spin mx-auto" />
                  <p className="text-[11px] font-bold text-slate-400">{t("common.loading", "Loading guest schedule...")}</p>
                </div>
              ) : displayedScheduleBookings.length === 0 ? (
                <div className="p-6 text-center bg-slate-50/70 rounded-2xl border border-dashed border-slate-200 space-y-2">
                  <div className="w-9 h-9 rounded-xl bg-emerald-50 text-[#00875A] flex items-center justify-center mx-auto">
                    <Calendar className="w-4 h-4" />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-slate-800">
                      {t("dashboard.schedule.noBookings", "No bookings scheduled for this filter.")}
                    </h4>
                    <p className="text-[11px] text-slate-400 mt-0.5">
                      {t("dashboard.schedule.noBookingsToday", "New bookings made by travelers will appear here automatically.")}
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={handleCreateTestBooking}
                    className="mt-2 text-[10.5px] font-extrabold text-[#00875A] hover:underline inline-flex items-center gap-1 cursor-pointer"
                  >
                    <Sparkles className="w-3 h-3" />
                    <span>{t("dashboard.schedule.addBooking", "+ Add Booking")}</span>
                  </button>
                </div>
              ) : (
                <div className="space-y-3 relative">
                  {displayedScheduleBookings.map((sch, idx) => {
                    const guestInitials = sch.guest_name
                      .split(" ")
                      .map((n) => n[0])
                      .join("")
                      .slice(0, 2)
                      .toUpperCase();

                    const isConfirmed = sch.status === "Confirmed";
                    const isPending = sch.status === "Pending";
                    const isCancelled = sch.status === "Cancelled";

                    const statusStyle = isConfirmed
                      ? "bg-[#ECFDF5] text-[#059669] border-[#A7F3D0]"
                      : isCancelled
                      ? "bg-rose-50 text-rose-700 border-rose-200"
                      : isPending
                      ? "bg-[#FFFBEB] text-[#D97706] border-[#FDE68A]"
                      : "bg-[#EFF6FF] text-[#2563EB] border-[#BFDBFE]";

                    const statusDot = isConfirmed
                      ? "bg-[#10B981]"
                      : isCancelled
                      ? "bg-rose-500"
                      : isPending
                      ? "bg-[#F59E0B]"
                      : "bg-[#3B82F6]";

                    return (
                      <div
                        key={sch.id}
                        onClick={() => setSelectedBooking(sch)}
                        className="relative flex flex-col space-y-1.5 p-2 rounded-xl hover:bg-slate-50 transition-colors cursor-pointer group"
                      >
                        {/* Top Row: Time + Experience Name + Chevron Right */}
                        <div className="flex items-center justify-between">
                          <div className="flex items-center gap-2 min-w-0">
                            <span className={`w-2 h-2 rounded-full ${statusDot} shrink-0`} />
                            <span className="text-[11px] font-semibold text-slate-500 shrink-0">
                              {sch.booking_time}
                            </span>
                            <span className="text-[12px] font-extrabold text-[#0F172A] truncate">
                              {sch.experience_name}
                            </span>
                          </div>
                          <ChevronRight className="w-3.5 h-3.5 text-slate-400 group-hover:translate-x-0.5 transition-transform shrink-0" />
                        </div>

                        {/* Bottom Row: Guest Avatar + Name & Guests + Status Badge */}
                        <div className="flex items-center justify-between pl-4">
                          <div className="flex items-center gap-2.5 min-w-0">
                            {sch.guest_avatar ? (
                              <div className="relative w-8 h-8 rounded-full overflow-hidden shrink-0 border border-[#E2E8F0]">
                                <Image
                                  src={sch.guest_avatar}
                                  alt={sch.guest_name}
                                  fill
                                  className="object-cover"
                                  unoptimized
                                />
                              </div>
                            ) : (
                              <div className="w-8 h-8 rounded-full bg-emerald-100 text-[#00875A] font-extrabold text-[10px] flex items-center justify-center shrink-0">
                                {guestInitials}
                              </div>
                            )}
                            <div className="leading-tight min-w-0">
                              <div className="text-[12px] font-bold text-[#0F172A] truncate">
                                {sch.guest_name}
                              </div>
                              <div className="text-[10px] text-slate-400 truncate">
                                {sch.slots} {sch.slots > 1 ? t("dashboard.schedule.guestsCount", "guests") : t("dashboard.schedule.guestCountSingle", "guest")} •{" "}
                                {sch.guest_phone || t("dashboard.schedule.phoneMasked", "Protected")}
                              </div>
                            </div>
                          </div>

                          {/* Status Pill */}
                          <div
                            className={`px-2 py-0.5 rounded-full border text-[10px] font-bold flex items-center gap-1.5 shrink-0 ${statusStyle}`}
                          >
                            <span className={`w-1.5 h-1.5 rounded-full ${statusDot}`} />
                            <span>
                              {sch.status === "Confirmed"
                                ? t("bookings.status.confirmed", "Confirmed")
                                : sch.status === "Pending"
                                ? t("bookings.status.pending", "Pending")
                                : sch.status === "Cancelled"
                                ? t("bookings.status.cancelled", "Cancelled")
                                : sch.status}
                            </span>
                          </div>
                        </div>

                        {/* Timeline Line Connector (except last item) */}
                        {idx < displayedScheduleBookings.length - 1 && (
                          <div className="absolute left-[7px] top-[24px] bottom-[-6px] w-[1px] bg-[#E2E8F0] pointer-events-none -z-0" />
                        )}
                      </div>
                    );
                  })}
                </div>
              )}
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
                    {profile?.name || "Local Provider"}
                  </h3>
                  <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-50 text-[#00875A] border border-emerald-200 text-[10px] font-bold">
                    <ShieldCheck className="w-3 h-3" />
                    Verified
                  </span>
                </div>
                <p className="text-[12px] font-semibold text-[#00875A] mt-0.5 truncate">
                  {profile?.role || "Experience Host"}
                </p>
                <p className="text-[11px] text-slate-400">User ID: {userId.slice(0, 16)}...</p>
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
                  {displayName}
                </span>
              </div>

              {/* Email Address */}
              <div className="flex items-center justify-between p-2.5 rounded-xl bg-slate-50 border border-slate-100">
                <div className="flex items-center gap-2.5 text-xs text-slate-600">
                  <Mail className="w-4 h-4 text-slate-400" />
                  <span className="font-medium">Email Address</span>
                </div>
                <span className="text-xs font-bold text-[#0F172A] truncate max-w-[220px]">
                  {userEmail}
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
                  {authProviderName.toUpperCase()}
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

      {/* Booking Detail Modal Drawer */}
      <BookingDetailDrawer
        booking={selectedBooking}
        onClose={() => setSelectedBooking(null)}
        onUpdateStatus={handleUpdateBookingStatus}
      />
    </div>
  );
}

export default function ProviderDashboardPage() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-slate-50">
          <div className="text-center space-y-3">
            <div className="w-10 h-10 border-4 border-[#00875A] border-t-transparent rounded-full animate-spin mx-auto" />
            <p className="text-xs font-bold text-slate-600">Loading LocalLens Portal...</p>
          </div>
        </div>
      }
    >
      <DashboardContent />
    </Suspense>
  );
}