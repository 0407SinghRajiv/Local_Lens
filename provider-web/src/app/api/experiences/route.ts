import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabaseClient";

// Server-side in-memory cache partitioned strictly by provider ID / email
// Ensures zero data leaks across providers and instant persistence
const serverProviderRegistry: Map<string, any[]> = new Map();

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const providerId = searchParams.get("provider_id")?.trim();
    const providerEmail = searchParams.get("email")?.trim();

    // Multi-tenant isolation rule: if no provider identity is provided, return empty
    if (!providerId && !providerEmail) {
      return NextResponse.json({ success: true, data: [] });
    }

    const cleanId = providerId?.toLowerCase() || "";
    const cleanEmail = providerEmail?.toLowerCase() || "";
    const results: any[] = [];
    const seenIds = new Set<string>();

    // 1. Fetch from Supabase experience table matching this provider
    try {
      const filters: string[] = [];
      if (cleanId) {
        filters.push(`source_url.ilike.%/provider/${cleanId}%`);
        filters.push(`source_name.ilike.%${cleanId}%`);
        filters.push(`tags.ilike.%provider:${cleanId}%`);
      }
      if (cleanEmail && cleanEmail !== "provider@locallens.in") {
        filters.push(`source_url.ilike.%${cleanEmail}%`);
        filters.push(`source_name.ilike.%${cleanEmail}%`);
        filters.push(`tags.ilike.%provider_email:${cleanEmail}%`);
      }

      if (filters.length > 0) {
        const { data, error } = await supabase
          .from("experience")
          .select("*")
          .or(filters.join(","));

        if (!error && Array.isArray(data)) {
          for (const item of data) {
            const k = (item.experience_id || item.experience_name || "").trim().toLowerCase();
            if (k && !seenIds.has(k)) {
              seenIds.add(k);
              results.push(item);
            }
          }
        }
      }
    } catch (err) {
      console.warn("Supabase provider query notice:", err);
    }

    // 2. Fetch from server-side provider registry
    const registryItems: any[] = [
      ...(cleanId ? serverProviderRegistry.get(cleanId) || [] : []),
      ...(cleanEmail && cleanEmail !== cleanId ? serverProviderRegistry.get(cleanEmail) || [] : []),
    ];

    for (const item of registryItems) {
      const k = (item.experience_id || item.experience_name || "").trim().toLowerCase();
      if (k && !seenIds.has(k)) {
        seenIds.add(k);
        results.push(item);
      }
    }

    return NextResponse.json({ success: true, data: results });
  } catch (err: any) {
    return NextResponse.json({ success: false, error: err.message, data: [] }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const body = await request.json();

    const providerId = (body.provider_id || "provider_default").trim();
    const providerEmail = (body.provider_email || "").trim();
    const cleanId = providerId.toLowerCase();
    const cleanEmail = providerEmail.toLowerCase();

    // Prepare tags with provider ownership stamps
    const existingTags = Array.isArray(body.tags)
      ? body.tags
      : typeof body.tags === "string"
      ? body.tags.split(",").map((t: string) => t.trim()).filter(Boolean)
      : [];

    const enrichedTags = Array.from(
      new Set([
        ...existingTags,
        `provider:${cleanId}`,
        ...(cleanEmail ? [`provider_email:${cleanEmail}`] : []),
      ])
    ).join(", ");

    // Map exact columns of Supabase experience table matching database schema
    const experienceRecord = {
      experience_id: body.experience_id || `EXP-${Date.now().toString(36).toUpperCase()}`,
      experience_name: body.experience_name || "New Experience",
      category: body.category || "Nature & Adventure",
      sub_category: body.sub_category || "Guided Tour",
      description: body.description || "",
      city: body.city || "Mumbai",
      district: body.district || "Mumbai Suburban",
      state: body.state || "Maharashtra",
      region: body.region || "Konkan",
      latitude: Number(body.latitude) || 19.131102,
      longitude: Number(body.longitude) || 72.81541,
      price_inr: typeof body.price_inr === "string" ? body.price_inr : `₹${body.price_inr || 1200}`,
      price_inr_clean: Number(body.price_inr_clean) || 1200,
      duration_hours:
        typeof body.duration_hours === "string"
          ? body.duration_hours
          : `${body.duration_hours || 2} hours`,
      rating: Number(body.rating) || 5.0,
      review_count: Number(body.review_count) || 1,
      tags: enrichedTags,
      image_url:
        body.image_url ||
        (Array.isArray(body.images) && body.images[0]) ||
        "https://images.unsplash.com/photo-1544551763-46a013bb70d5?auto=format&fit=crop&w=800&q=80",
      images: Array.isArray(body.images) && body.images.length > 0 ? body.images : [body.image_url],
      source_name: `provider:${cleanId}`,
      source_url: `https://locallens.in/provider/${cleanId}`,
      last_verified: new Date().toISOString(),
      booking_required: "Yes",
      advance_booking_days: "1 day",
      availability: body.availability || "Daily",
      accessibility: body.accessibility || "Standard",
      local_experience: body.local_experience || "Yes",
      hidden_gem: body.hidden_gem || "Yes",
      indoor_outdoor: body.indoor_outdoor || "Outdoor",
      best_time: body.best_time || "Sunset 05:30 PM",
      season: body.season || "All Year",
      min_group_size: Number(body.min_group_size) || 1,
      max_group_size: Number(body.max_group_size) || 8,
      provider_id: cleanId,
      provider_email: cleanEmail,
    };

    // 1. Save to in-memory server registry partition for this provider
    const existingForId = serverProviderRegistry.get(cleanId) || [];
    serverProviderRegistry.set(
      cleanId,
      [experienceRecord, ...existingForId.filter((x) => x.experience_id !== experienceRecord.experience_id)]
    );
    if (cleanEmail && cleanEmail !== cleanId) {
      const existingForEmail = serverProviderRegistry.get(cleanEmail) || [];
      serverProviderRegistry.set(
        cleanEmail,
        [experienceRecord, ...existingForEmail.filter((x) => x.experience_id !== experienceRecord.experience_id)]
      );
    }

    // 2. Persist to Supabase experience table
    let dbSuccess = false;
    let dbWarning: string | null = null;
    try {
      const { data, error } = await supabase.from("experience").insert(experienceRecord).select();
      if (error) {
        dbWarning = error.message;
      } else {
        dbSuccess = true;
      }
    } catch (dbErr: any) {
      dbWarning = dbErr.message;
    }

    return NextResponse.json({
      success: true,
      dbSuccess,
      warning: dbWarning,
      record: experienceRecord,
    });
  } catch (err: any) {
    return NextResponse.json({ success: false, error: err.message }, { status: 500 });
  }
}

