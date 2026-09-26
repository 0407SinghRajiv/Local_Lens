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
  businessName?: string;
  bio?: string;
  language?: "en" | "hi" | "mr" | "bn";
}

const DEFAULT_PROFILE: ProviderProfile = {
  id: "host_default_guest",
  name: "Local Provider",
  fullName: "Local Provider",
  email: "provider@locallens.in",
  phone: "+91 98201 55432",
  role: "Tour Guide / Storyteller",
  providerCategory: "Tour Guide / Storyteller",
  avatar: "",
  authProvider: "google",
  verified: true,
  rating: 4.9,
  totalExperiences: 4,
  totalGuests: 328,
  joinedDate: "Recent Member",
};

/**
 * Builds profile synchronously from Supabase auth user metadata (0ms execution)
 */
export function buildProfileFromAuthUser(user: any): ProviderProfile {
  if (!user) return DEFAULT_PROFILE;

  const meta = user.user_metadata || {};
  const isGoogle = meta.iss?.includes("google") || user.app_metadata?.provider === "google";

  const displayName =
    meta.full_name ||
    meta.name ||
    user.email?.split("@")[0] ||
    "Local Provider";

  const avatarUrl =
    meta.avatar_url ||
    meta.picture ||
    "";

  const userEmail = user.email || meta.email || "provider@locallens.in";

  return {
    id: user.id,
    name: displayName,
    fullName: displayName,
    email: userEmail,
    phone: meta.phone || "+91 98201 55432",
    role: meta.provider_category || meta.role || "Tour Guide / Storyteller",
    providerCategory: meta.provider_category || meta.role || "Tour Guide / Storyteller",
    avatar: avatarUrl,
    authProvider: isGoogle ? "google" : "email",
    verified: true,
    rating: 4.9,
    totalExperiences: 4,
    totalGuests: 328,
    joinedDate: "Recent Member",
  };
}

/**
 * Gets or creates provider profile with non-blocking DB sync for instant response
 */
export async function getOrCreateProviderProfile(user: any): Promise<ProviderProfile> {
  const profile = buildProfileFromAuthUser(user);

  // 1. Immediately persist to localStorage for 0ms retrieval
  if (typeof window !== "undefined") {
    localStorage.setItem("locallens_provider_session", JSON.stringify(profile));
  }

  // 2. Non-blocking background sync with Supabase profiles table (fire and forget)
  try {
    const syncDb = async () => {
      const { data: dbProfile } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", user.id)
        .maybeSingle();

      if (dbProfile) {
        profile.fullName = dbProfile.full_name || profile.fullName;
        profile.name = dbProfile.full_name || profile.name;
        profile.avatar = dbProfile.avatar_url || profile.avatar;
        if (dbProfile.language) {
          profile.language = dbProfile.language;
          if (typeof window !== "undefined") {
            localStorage.setItem("locallens_preferred_language", dbProfile.language);
          }
        }
        if (typeof window !== "undefined") {
          localStorage.setItem("locallens_provider_session", JSON.stringify(profile));
        }
      } else {
        await supabase.from("profiles").upsert({
          id: user.id,
          full_name: profile.fullName,
          avatar_url: profile.avatar,
          language: profile.language || "en",
          updated_at: new Date().toISOString(),
        });
      }
    };

    // Use a fast 800ms race so UI is never blocked by database latency
    await Promise.race([
      syncDb(),
      new Promise((res) => setTimeout(res, 800)),
    ]);
  } catch (err) {
    // Non-fatal, profile is already safely cached in session
  }

  return profile;
}

/**
 * Loads current provider profile with instant synchronous localStorage check first
 */
export async function getProviderProfile(): Promise<ProviderProfile | null> {
  if (typeof window === "undefined") {
    return DEFAULT_PROFILE;
  }

  // Fast path: localStorage
  try {
    const saved = localStorage.getItem("locallens_provider_session");
    if (saved) {
      const parsed = JSON.parse(saved);
      // Validate session in background
      supabase.auth.getSession().then(({ data }) => {
        if (data?.session?.user) {
          getOrCreateProviderProfile(data.session.user);
        }
      }).catch(() => {});
      return parsed;
    }
  } catch (err) {
    console.error("Error reading localStorage profile:", err);
  }

  // Supabase active session check
  try {
    const { data } = await supabase.auth.getSession();
    if (data?.session?.user) {
      return await getOrCreateProviderProfile(data.session.user);
    }
  } catch (err) {
    console.error("Error reading Supabase session:", err);
  }

  return null;
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
