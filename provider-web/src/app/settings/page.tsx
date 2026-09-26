"use client";

import React, { useState, useEffect } from "react";
import Link from "next/link";
import {
  Compass,
  ArrowLeft,
  User,
  Mail,
  Phone,
  Building,
  CheckCircle2,
  Save,
  Globe,
  Bell,
  ShieldCheck,
  LogOut,
} from "lucide-react";
import { useI18n } from "@/lib/i18n";
import { LanguageSelector } from "@/components/settings/LanguageSelector";
import { getProviderProfile, saveProviderProfile, ProviderProfile } from "@/lib/authSession";
import { supabase } from "@/lib/supabaseClient";

export default function SettingsPage() {
  const { t, language } = useI18n();
  const [profile, setProfile] = useState<ProviderProfile | null>(null);
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [businessName, setBusinessName] = useState("");
  const [providerCategory, setProviderCategory] = useState("Tour Guide / Storyteller");
  const [bio, setBio] = useState("");

  const [isSaving, setIsSaving] = useState(false);
  const [statusMessage, setStatusMessage] = useState<{ type: "success" | "error"; text: string } | null>(null);

  useEffect(() => {
    getProviderProfile().then((p) => {
      if (p) {
        setProfile(p);
        setFullName(p.fullName || p.name || "");
        setEmail(p.email || "");
        setPhone(p.phone || "");
        setBusinessName(p.businessName || "");
        setProviderCategory(p.providerCategory || "Tour Guide / Storyteller");
        setBio(p.bio || "");
      }
    });
  }, []);

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    setStatusMessage(null);

    try {
      const updated = saveProviderProfile({
        fullName,
        name: fullName,
        phone,
        businessName,
        providerCategory,
        bio,
      });
      setProfile(updated);

      // Background DB sync if authenticated
      const { data } = await supabase.auth.getSession();
      const userId = data?.session?.user?.id;
      if (userId) {
        await supabase
          .from("profiles")
          .update({
            full_name: fullName,
            phone: phone,
            updated_at: new Date().toISOString(),
          })
          .eq("id", userId);
      }

      setStatusMessage({
        type: "success",
        text: t("settings.saveSuccess", "Settings saved successfully!"),
      });
      setTimeout(() => setStatusMessage(null), 4000);
    } catch (err: any) {
      setStatusMessage({
        type: "error",
        text: err?.message || t("settings.saveError", "Failed to update settings. Please try again."),
      });
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 font-sans text-slate-800 pb-24">
      {/* Top Navigation Bar */}
      <header className="w-full bg-white border-b border-slate-200 sticky top-0 z-40">
        <div className="max-w-5xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/dashboard"
              className="p-2 rounded-xl text-slate-500 hover:text-slate-900 hover:bg-slate-100 transition-colors flex items-center gap-2 text-xs font-bold"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>{t("common.back", "Back to Dashboard")}</span>
            </Link>
            <div className="h-4 w-px bg-slate-200 hidden sm:block" />
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-lg bg-[#0e8a5b] text-white flex items-center justify-center">
                <Compass className="w-4 h-4" />
              </div>
              <span className="font-extrabold text-sm text-slate-900 tracking-tight">
                {t("nav.brand", "Local Lens")}
              </span>
            </div>
          </div>

          <LanguageSelector variant="navbar" />
        </div>
      </header>

      {/* Main Content Area */}
      <main className="max-w-5xl mx-auto px-6 pt-8">
        {/* Page Header */}
        <div className="mb-8">
          <h1 className="text-3xl sm:text-4xl font-heading text-slate-900 tracking-tight">
            {t("settings.title", "Account & System Settings")}
          </h1>
          <p className="text-sm text-slate-500 mt-1 max-w-2xl">
            {t("settings.subtitle", "Manage your profile, language preferences, payout accounts, and notifications.")}
          </p>
        </div>

        {statusMessage && (
          <div
            className={`mb-6 p-4 rounded-2xl flex items-center gap-3 text-sm font-semibold border ${
              statusMessage.type === "success"
                ? "bg-emerald-50 text-emerald-800 border-emerald-200"
                : "bg-rose-50 text-rose-800 border-rose-200"
            }`}
          >
            <CheckCircle2 className="w-5 h-5 shrink-0" />
            <span>{statusMessage.text}</span>
          </div>
        )}

        <div className="space-y-8">
          {/* SECTION 0: HOST IDENTITY & PROFILE CARD (Moved from navigation) */}
          <section className="bg-white rounded-2xl border border-slate-200/90 p-5 sm:p-6 shadow-sm">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
              <div className="flex items-center gap-4">
                <div className="relative w-14 h-14 rounded-full overflow-hidden shrink-0 border-2 border-emerald-500 shadow-md bg-gradient-to-tr from-[#00875A] to-teal-500 text-white font-black text-lg flex items-center justify-center">
                  {profile?.avatar && profile.avatar.startsWith("/") ? (
                    <img
                      src={profile.avatar}
                      alt={profile?.name || "Host Profile"}
                      className="w-full h-full object-cover"
                    />
                  ) : (
                    <span>{profile?.name ? profile.name.slice(0, 1).toUpperCase() : "N"}</span>
                  )}
                </div>
                <div>
                  <div className="flex items-center gap-2">
                    <h2 className="text-lg font-bold text-[#0F172A] tracking-tight">
                      {profile?.name || fullName || "Krishnkumar Gupta"}
                    </h2>
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-[#00875A] border border-emerald-200">
                      Verified Host
                    </span>
                  </div>
                  <div className="text-xs text-[#00875A] font-semibold mt-0.5">
                    {profile?.role || providerCategory || "Tour Guide / Storyteller"}
                  </div>
                  <div className="text-xs text-slate-500 mt-0.5">
                    {email || "provider@locallens.in"}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-3 w-full sm:w-auto">
                <button
                  type="button"
                  onClick={async () => {
                    if (confirm("Are you sure you want to sign out of LocalLens?")) {
                      try {
                        await supabase.auth.signOut();
                      } catch {}
                      if (typeof window !== "undefined") {
                        localStorage.removeItem("locallens_provider_session");
                      }
                      window.location.href = "/login";
                    }
                  }}
                  className="px-4 py-2 rounded-xl border border-rose-200 bg-rose-50 hover:bg-rose-100 text-rose-700 font-bold text-xs flex items-center justify-center gap-2 transition-colors cursor-pointer w-full sm:w-auto"
                >
                  <LogOut className="w-3.5 h-3.5 text-rose-600" />
                  <span>{t("nav.logout", "Log Out")}</span>
                </button>
              </div>
            </div>
          </section>

          {/* SECTION 1: MANDATORY MULTILINGUAL LANGUAGE SETTINGS */}
          <section id="language-section">
            <div className="mb-2">
              <span className="text-xs font-bold uppercase tracking-wider text-[#0e8a5b]">
                {t("settings.language", "Language Settings")}
              </span>
            </div>
            <LanguageSelector variant="settings" />
          </section>

          {/* SECTION 2: PROFILE DETAILS */}
          <section>
            <div className="bg-white rounded-2xl border border-slate-200/90 p-6 md:p-8 shadow-sm">
              <div className="flex items-center gap-3 pb-6 border-b border-slate-100 mb-6">
                <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
                  <User className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-slate-900 tracking-tight">
                    {t("settings.profileSettings", "Profile Details")}
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    {t("settings.profileSubtitle", "Update your public provider profile and contact credentials.")}
                  </p>
                </div>
              </div>

              <form onSubmit={handleSaveProfile} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {/* Full Name */}
                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                      {t("settings.fullName", "Full Name")}
                    </label>
                    <div className="relative">
                      <User className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        value={fullName}
                        onChange={(e) => setFullName(e.target.value)}
                        className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 bg-white text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/30"
                        placeholder="e.g. Rahul Sharma"
                      />
                    </div>
                  </div>

                  {/* Email (Readonly) */}
                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                      {t("settings.emailAddress", "Email Address")}
                    </label>
                    <div className="relative">
                      <Mail className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="email"
                        value={email}
                        disabled
                        className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50 text-sm text-slate-500 cursor-not-allowed"
                      />
                    </div>
                  </div>

                  {/* Phone */}
                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                      {t("settings.phoneNumber", "Phone Number")}
                    </label>
                    <div className="relative">
                      <Phone className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                        className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 bg-white text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/30"
                        placeholder="+91 98201 55432"
                      />
                    </div>
                  </div>

                  {/* Business Name */}
                  <div>
                    <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                      {t("settings.businessName", "Business / Tour Company Name")}
                    </label>
                    <div className="relative">
                      <Building className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        value={businessName}
                        onChange={(e) => setBusinessName(e.target.value)}
                        className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 bg-white text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/30"
                        placeholder="e.g. Bombay Heritage Trails"
                      />
                    </div>
                  </div>
                </div>

                {/* Bio */}
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-2">
                    {t("settings.bio", "Bio / About You")}
                  </label>
                  <textarea
                    rows={3}
                    value={bio}
                    onChange={(e) => setBio(e.target.value)}
                    className="w-full p-4 rounded-xl border border-slate-200 bg-white text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-[#0e8a5b]/30 resize-none"
                    placeholder="Tell guests about your background, experience, and local expertise..."
                  />
                </div>

                <div className="flex justify-end pt-4 border-t border-slate-100">
                  <button
                    type="submit"
                    disabled={isSaving}
                    className="flex items-center gap-2 px-6 py-2.5 rounded-xl bg-[#0e8a5b] hover:bg-[#0b744d] text-white text-sm font-bold shadow-md shadow-emerald-700/20 transition-all disabled:opacity-50"
                  >
                    <Save className="w-4 h-4" />
                    <span>{isSaving ? t("settings.saving", "Saving...") : t("settings.saveChanges", "Save Changes")}</span>
                  </button>
                </div>
              </form>
            </div>
          </section>

          {/* SECTION 3: NOTIFICATION PREFERENCES */}
          <section>
            <div className="bg-white rounded-2xl border border-slate-200/90 p-6 md:p-8 shadow-sm">
              <div className="flex items-center gap-3 pb-6 border-b border-slate-100 mb-6">
                <div className="w-10 h-10 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
                  <Bell className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-lg font-bold text-slate-900 tracking-tight">
                    {t("settings.notificationsSection", "Notification Preferences")}
                  </h3>
                  <p className="text-xs text-slate-500 mt-0.5">
                    {t("settings.subtitle", "Choose which alerts you receive.")}
                  </p>
                </div>
              </div>

              <div className="space-y-4">
                {[
                  { title: t("settings.bookingAlerts", "Instant SMS / WhatsApp booking alerts"), defaultChecked: true },
                  { title: t("settings.emailDigest", "Weekly earnings digest and reviews"), defaultChecked: true },
                  { title: t("settings.emergencyAlerts", "Weather and emergency closure alerts"), defaultChecked: true },
                ].map((item, idx) => (
                  <label key={idx} className="flex items-center justify-between p-4 rounded-xl border border-slate-100 hover:bg-slate-50 cursor-pointer transition-colors">
                    <span className="text-sm font-medium text-slate-800">{item.title}</span>
                    <input
                      type="checkbox"
                      defaultChecked={item.defaultChecked}
                      className="w-4 h-4 rounded text-[#0e8a5b] focus:ring-[#0e8a5b]"
                    />
                  </label>
                ))}
              </div>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}
