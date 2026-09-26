"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { supabase } from "@/lib/supabaseClient";
import { saveProviderProfile } from "@/lib/authSession";

export default function AuthCallbackPage() {
  const router = useRouter();

  useEffect(() => {
    async function handleAuth() {
      try {
        const { data, error } = await supabase.auth.getSession();
        if (data?.session?.user) {
          const u = data.session.user;
          const meta = u.user_metadata || {};
          const name = meta.full_name || meta.name || u.email?.split("@")[0] || "Google Host";
          
          saveProviderProfile({
            id: u.id,
            name: name,
            fullName: name,
            email: u.email || "host@gmail.com",
            phone: meta.phone || "+91 98201 55432",
            role: meta.provider_category || meta.role || "Tour Guide / Storyteller",
            avatar: meta.avatar_url || meta.picture || "/dashboard/ramesh.jpg",
            authProvider: "google",
            verified: true,
          });
        }
      } catch (e) {
        console.error("Callback error:", e);
      } finally {
        router.push("/dashboard");
      }
    }

    handleAuth();
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50">
      <div className="text-center p-8 bg-white rounded-2xl shadow-lg border border-slate-100 max-w-sm">
        <div className="w-10 h-10 border-4 border-[#00875A] border-t-transparent rounded-full animate-spin mx-auto mb-4" />
        <h3 className="font-extrabold text-[#0F172A] text-lg">Authenticating with Google...</h3>
        <p className="text-xs text-slate-500 mt-1">Connecting your LocalLens Provider credentials</p>
      </div>
    </div>
  );
}
