import { supabase } from "./supabaseClient";

export interface ProviderProfile {
  id?: string;
  name: string;
  fullName?: string;
  email: string;
  phone?: string;
  role: string;
  providerCategory?: string;
  avatar?: string;
  authProvider?: "google" | "apple" | "email" | "demo";
  verified?: boolean;
  rating?: number;
  totalExperiences?: number;
  totalGuests?: number;
  joinedDate?: string;
}

const DEFAULT_PROFILE: ProviderProfile = {
  id: "host_default_ramesh",
  name: "Ramesh Tours",
  fullName: "Ramesh Sharma",
  email: "ramesh@mumbaiculturals.com",
  phone: "+91 98201 55432",
  role: "Tour Guide / Storyteller",
  providerCategory: "Tour Guide / Storyteller",
  avatar: "/dashboard/ramesh.jpg",
  authProvider: "demo",
  verified: true,
  rating: 4.9,
  totalExperiences: 4,
  totalGuests: 328,
  joinedDate: "January 2024",
};

/**
 * Loads current provider profile from Supabase session or localStorage fallback
 */
export async function getProviderProfile(): Promise<ProviderProfile> {
  if (typeof window === "undefined") {
    return DEFAULT_PROFILE;
  }

  // Check URL parameters for direct profile sync
  try {
    const params = new URLSearchParams(window.location.search);
    if (params.get("name") || params.get("email")) {
      const paramProfile: ProviderProfile = {
        ...DEFAULT_PROFILE,
        name: params.get("name") || DEFAULT_PROFILE.name,
        fullName: params.get("fullName") || params.get("name") || DEFAULT_PROFILE.fullName,
        email: params.get("email") || DEFAULT_PROFILE.email,
        phone: params.get("phone") || DEFAULT_PROFILE.phone,
        role: params.get("role") || DEFAULT_PROFILE.role,
        providerCategory: params.get("role") || DEFAULT_PROFILE.role,
        authProvider: (params.get("provider") as any) || "google",
        verified: true,
      };
      localStorage.setItem("locallens_provider_session", JSON.stringify(paramProfile));
      return paramProfile;
    }
  } catch (e) {}

  // 1. Try Supabase active session
  try {
    const { data } = await supabase.auth.getSession();
    if (data?.session?.user) {
      const user = data.session.user;
      const meta = user.user_metadata || {};
      const provider = user.app_metadata?.provider || "email";

      const name =
        meta.full_name ||
        meta.name ||
        user.email?.split("@")[0] ||
        "Verified Provider";

      const profile: ProviderProfile = {
        id: user.id,
        name: name,
        fullName: name,
        email: user.email || "provider@locallens.in",
        phone: meta.phone || "+91 98201 55432",
        role: meta.provider_category || meta.role || "Tour Guide / Storyteller",
        providerCategory: meta.provider_category || meta.role || "Tour Guide / Storyteller",
        avatar: meta.avatar_url || meta.picture || DEFAULT_PROFILE.avatar,
        authProvider: (provider as any) || "google",
        verified: true,
        rating: 4.9,
        totalExperiences: 4,
        totalGuests: 328,
        joinedDate: "Recent Member",
      };

      // Also persist to localStorage for offline / fast sync
      localStorage.setItem("locallens_provider_session", JSON.stringify(profile));
      return profile;
    }
  } catch (err) {
    console.error("Error reading Supabase session:", err);
  }

  // 2. Try localStorage session
  try {
    const saved = localStorage.getItem("locallens_provider_session");
    if (saved) {
      const parsed = JSON.parse(saved);
      return {
        ...DEFAULT_PROFILE,
        ...parsed,
        name: parsed.fullName || parsed.providerName || parsed.name || parsed.email?.split("@")[0] || DEFAULT_PROFILE.name,
      };
    }
  } catch (err) {
    console.error("Error reading localStorage profile:", err);
  }

  return DEFAULT_PROFILE;
}

/**
 * Saves provider profile to localStorage and updates state
 */
export function saveProviderProfile(profile: Partial<ProviderProfile>): ProviderProfile {
  if (typeof window === "undefined") return DEFAULT_PROFILE;

  const currentStr = localStorage.getItem("locallens_provider_session");
  const current = currentStr ? JSON.parse(currentStr) : DEFAULT_PROFILE;
  const updated: ProviderProfile = {
    ...current,
    ...profile,
    name: profile.fullName || profile.name || current.name,
  };

  localStorage.setItem("locallens_provider_session", JSON.stringify(updated));
  return updated;
}

/**
 * Clears provider session and logs out
 */
export async function logoutProvider(): Promise<void> {
  if (typeof window !== "undefined") {
    localStorage.removeItem("locallens_provider_session");
  }
  try {
    await supabase.auth.signOut();
  } catch (err) {
    console.error("Error signing out from Supabase:", err);
  }
}
