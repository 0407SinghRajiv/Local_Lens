import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabaseClient";
import { validateFullListing, MIN_PUBLISH_AI_SCORE } from "@/lib/aiValidator";

// Server-side fallback registry strictly partitioned by provider ID / email
const serverProviderRegistry: Map<string, any[]> = new Map();

// Exact valid column schema of public.experience in Supabase
const VALID_EXPERIENCE_COLUMNS = new Set([
  "experience_id",
  "experience_name",
  "city",
  "district",
  "state",
  "region",
  "latitude",
  "longitude",
  "category",
  "sub_category",
  "description",
  "tags",
  "price_inr",
  "price_inr_clean",
  "duration_hours",
  "duration_hours_clean",
  "best_for",
  "min_group_size",
  "max_group_size",
  "rating",
  "review_count",
  "best_time",
  "season",
  "indoor_outdoor",
  "indoor_outdoor_clean",
  "booking_required",
  "advance_booking_days",
  "availability",
  "accessibility",
  "local_experience",
  "hidden_gem",
  "local_experience_bool",
  "hidden_gem_bool",
  "image_url",
  "source_name",
  "source_url",
  "last_verified",
]);

function formatExperienceForFrontend(item: any) {
  const images =
    Array.isArray(item.images) && item.images.length > 0
      ? item.images
      : item.image_url
      ? [item.image_url]
      : [];

  const rawTags =
    typeof item.tags === "string"
      ? item.tags.split(",").map((s: string) => s.trim()).filter(Boolean)
      : Array.isArray(item.tags)
      ? item.tags
      : [];

  const priceClean =
    Number(item.price_inr_clean) ||
    (typeof item.price_inr === "string"
      ? parseFloat(item.price_inr.replace(/[^\d.]/g, ""))
      : Number(item.price_inr)) ||
    1200;

  const durationClean =
    Number(item.duration_hours_clean) ||
    (typeof item.duration_hours === "string"
      ? parseFloat(item.duration_hours.replace(/[^\d.]/g, ""))
      : Number(item.duration_hours)) ||
    2;

  return {
    experience_id: item.experience_id,
    experience_name: item.experience_name,
    category: item.category || "Nature & Adventure",
    sub_category: item.sub_category || "Guided Tour",
    city: item.city || "Mumbai",
    district: item.district || "Mumbai Suburban",
    state: item.state || "Maharashtra",
    region: item.region || "Konkan",
    latitude: Number(item.latitude) || 19.131102,
    longitude: Number(item.longitude) || 72.81541,
    price_inr: typeof item.price_inr === "string" ? item.price_inr : `₹${priceClean}`,
    price_inr_clean: priceClean,
    duration_hours: typeof item.duration_hours === "string" ? item.duration_hours : `${durationClean} hours`,
    duration_hours_clean: durationClean,
    rating: Number(item.rating) || 5.0,
    review_count: Number(item.review_count) || 1,
    description: item.description || "",
    tags: rawTags,
    images: images,
    image_url: item.image_url || (images.length > 0 ? images[0] : ""),
    meeting_point: item.meeting_point || item.city || "Mumbai",
    inclusions: rawTags.filter(
      (t: string) =>
        !t.startsWith("provider:") &&
        !t.startsWith("provider_email:") &&
        !t.startsWith("lat:") &&
        !t.startsWith("lng:") &&
        !t.startsWith("google_map:")
    ),
    rules: ["Valid government ID required", "Arrive 10 minutes before start time"],
    cancellation_policy: "100% refund up to 24 hours prior",
    status: item.status || "active",
    health_score: item.health_score || 85,
    earnings_generated_inr: item.earnings_generated_inr || 0,
    bookings_count: item.bookings_count || 0,
    local_experience_bool: item.local_experience_bool ?? true,
    hidden_gem_bool: item.hidden_gem_bool ?? true,
    indoor_outdoor_clean: item.indoor_outdoor_clean || item.indoor_outdoor || "Outdoor",
    availability: item.availability || "Daily",
    source_name: item.source_name,
    source_url: item.source_url,
  };
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const providerId = searchParams.get("provider_id")?.trim();
    const providerEmail = searchParams.get("email")?.trim();
    const fetchAll = searchParams.get("all") === "true" || providerId === "all";

    const cleanId = providerId?.toLowerCase() || "";
    const cleanEmail = providerEmail?.toLowerCase() || "";
    const results: any[] = [];
    const seenIds = new Set<string>();

    // 1. Fetch from Supabase experience table
    try {
      let query = supabase.from("experience").select("*");

      if (!fetchAll && (cleanId || cleanEmail)) {
        const filters: string[] = [];
        if (cleanId && cleanId !== "all") {
          filters.push(`source_name.ilike.%${cleanId}%`);
          filters.push(`tags.ilike.%provider:${cleanId}%`);
          filters.push(`source_url.ilike.%${cleanId}%`);
        }
        if (cleanEmail && cleanEmail !== "provider@locallens.in") {
          filters.push(`source_name.ilike.%${cleanEmail}%`);
          filters.push(`tags.ilike.%provider_email:${cleanEmail}%`);
        }
        if (filters.length > 0) {
          query = query.or(filters.join(","));
        }
      }

      const { data, error } = await query.order("experience_id", { ascending: false });

      if (!error && Array.isArray(data)) {
        for (const item of data) {
          const k = (item.experience_id || item.experience_name || "").trim().toLowerCase();
          if (k && !seenIds.has(k)) {
            seenIds.add(k);
            results.push(formatExperienceForFrontend(item));
          }
        }
      } else if (error) {
        console.warn("Supabase experience SELECT warning:", error.message);
      }
    } catch (err) {
      console.warn("Supabase experience query notice:", err);
    }

    // 2. Fallback merge from server in-memory provider registry (prevents blank screen during migrations)
    const registryItems: any[] = fetchAll
      ? Array.from(serverProviderRegistry.values()).flat()
      : [
          ...(cleanId ? serverProviderRegistry.get(cleanId) || [] : []),
          ...(cleanEmail && cleanEmail !== cleanId ? serverProviderRegistry.get(cleanEmail) || [] : []),
        ];

    for (const item of registryItems) {
      const k = (item.experience_id || item.experience_name || "").trim().toLowerCase();
      if (k && !seenIds.has(k)) {
        seenIds.add(k);
        results.push(formatExperienceForFrontend(item));
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

    // 1. Enforce compulsory shop or listing image
    const rawImage =
      body.image_url ||
      body.shop_image ||
      body.image ||
      (Array.isArray(body.images) && body.images.length > 0 && body.images[0]) ||
      (Array.isArray(body.photos) && body.photos.length > 0 && body.photos[0]);

    const imageStr = typeof rawImage === "string" ? rawImage.trim() : "";

    if (!imageStr) {
      return NextResponse.json(
        {
          success: false,
          error:
            "An image of the shop or experience listing is compulsory. Please upload or provide a valid shop/listing image.",
        },
        { status: 400 }
      );
    }

    // 2. Quality Audit Check: Enforce minimum score of 50 to publish
    const show1 = {
      id: "show-1",
      name: "Primary Show",
      venue: body.meeting_point || body.city || "Mumbai",
      city: body.city || "Mumbai",
      district: body.district || "Mumbai Suburban",
      lat: Number(body.latitude) || 19.131102,
      lng: Number(body.longitude) || 72.81541,
    };
    const qualityAudit = validateFullListing(
      body.experience_name || "",
      body.description || "",
      show1,
      null,
      Boolean(imageStr)
    );
    const computedScore = body.health_score !== undefined ? Number(body.health_score) : qualityAudit.overallScore;

    const isPublishing = body.status === "active" || !body.status || body.status === "boosted";

    // 3. Provider Verification Gate: unverified providers cannot publish listings
    if (isPublishing && body.verified === false) {
      return NextResponse.json(
        {
          success: false,
          error:
            "Provider is unverified. Aadhaar Card OCR verification is compulsory before publishing experience listings.",
          unverified: true,
        },
        { status: 403 }
      );
    }

    if (isPublishing && computedScore < MIN_PUBLISH_AI_SCORE) {
      return NextResponse.json(
        {
          success: false,
          error: `Experience listing cannot be published: AI Quality Check score is ${computedScore}/100. A minimum score of ${MIN_PUBLISH_AI_SCORE}/100 is required to publish an experience listing.`,
          score: computedScore,
          minRequired: MIN_PUBLISH_AI_SCORE,
        },
        { status: 400 }
      );
    }

    const priceClean = Number(body.price_inr_clean) || 1200;
    const durationClean = Number(body.duration_hours_clean) || 2;

    // Database record containing strictly valid columns for public.experience
    const dbRecord: Record<string, any> = {
      experience_id: body.experience_id || `EXP-${Date.now().toString(36).toUpperCase()}`,
      experience_name: body.experience_name || "New Experience",
      city: body.city || "Mumbai",
      district: body.district || "Mumbai Suburban",
      state: body.state || "Maharashtra",
      region: body.region || "Konkan",
      latitude: Number(body.latitude) || 19.131102,
      longitude: Number(body.longitude) || 72.81541,
      category: body.category || "Nature & Adventure",
      sub_category: body.sub_category || "Guided Tour",
      description: body.description || "",
      tags: enrichedTags,
      price_inr: typeof body.price_inr === "string" ? body.price_inr : `₹${priceClean}`,
      price_inr_clean: priceClean,
      duration_hours:
        typeof body.duration_hours === "string"
          ? body.duration_hours
          : `${durationClean} hours`,
      duration_hours_clean: durationClean,
      best_for: body.best_for || "Travelers & Explorers",
      min_group_size: Number(body.min_group_size) || 1,
      max_group_size: Number(body.max_group_size) || 8,
      rating: Number(body.rating) || 5.0,
      review_count: Number(body.review_count) || 1,
      best_time: body.best_time || "Sunset 05:30 PM",
      season: body.season || "All Year",
      indoor_outdoor: body.indoor_outdoor || "Outdoor",
      indoor_outdoor_clean: body.indoor_outdoor_clean || body.indoor_outdoor || "Outdoor",
      booking_required: body.booking_required || "Yes",
      advance_booking_days: body.advance_booking_days || "1 day",
      availability: body.availability || "Daily",
      accessibility: body.accessibility || "Standard",
      local_experience: body.local_experience || "Yes",
      hidden_gem: body.hidden_gem || "Yes",
      local_experience_bool: body.local_experience_bool !== undefined ? Boolean(body.local_experience_bool) : true,
      hidden_gem_bool: body.hidden_gem_bool !== undefined ? Boolean(body.hidden_gem_bool) : true,
      image_url: imageStr,
      source_name: `provider:${cleanId}`,
      source_url:
        body.source_url ||
        `https://www.google.com/maps?q=${Number(body.latitude) || 19.131102},${Number(body.longitude) || 72.81541}`,
      last_verified: new Date().toISOString(),
    };

    // Filter strictly to valid columns of Supabase experience table
    const sanitizedDbPayload: Record<string, any> = {};
    for (const [k, v] of Object.entries(dbRecord)) {
      if (VALID_EXPERIENCE_COLUMNS.has(k)) {
        sanitizedDbPayload[k] = v;
      }
    }

    // Full frontend record (includes UI-specific fields like images, status, health_score)
    const frontendRecord = {
      ...formatExperienceForFrontend(dbRecord),
      images: Array.isArray(body.images) && body.images.length > 0 ? body.images : [imageStr],
      status: body.status || "active",
      health_score: computedScore,
      provider_id: cleanId,
      provider_email: cleanEmail,
    };

    // 1. Save in server registry partition for immediate availability
    const existingForId = serverProviderRegistry.get(cleanId) || [];
    serverProviderRegistry.set(
      cleanId,
      [frontendRecord, ...existingForId.filter((x) => x.experience_id !== frontendRecord.experience_id)]
    );
    if (cleanEmail && cleanEmail !== cleanId) {
      const existingForEmail = serverProviderRegistry.get(cleanEmail) || [];
      serverProviderRegistry.set(
        cleanEmail,
        [frontendRecord, ...existingForEmail.filter((x) => x.experience_id !== frontendRecord.experience_id)]
      );
    }

    // 2. Persist to Supabase experience table
    let dbSuccess = false;
    let dbWarning: string | null = null;
    try {
      const { data, error } = await supabase.from("experience").insert(sanitizedDbPayload).select();
      if (error) {
        dbWarning = error.message;
        console.warn("Supabase experience INSERT error:", error.message);
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
      record: frontendRecord,
    });
  } catch (err: any) {
    return NextResponse.json({ success: false, error: err.message }, { status: 500 });
  }
}
