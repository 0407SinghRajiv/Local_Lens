import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabaseClient";
import { SponsorCampaign } from "@/types/sponsor";

// Server-side persistent storage partitioned strictly by user ID / email
export const serverCampaignsRegistry: Map<string, SponsorCampaign[]> = new Map();

// Helper to sanitize UUID
function ensureUuid(id?: string): string {
  if (!id) return crypto.randomUUID();
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (uuidRegex.test(id)) return id;
  // Deterministic or clean UUID
  return crypto.randomUUID();
}

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const userId = searchParams.get("user_id")?.trim();
    const email = searchParams.get("email")?.trim();

    if (!userId && !email) {
      return NextResponse.json({ success: true, data: [] });
    }

    const cleanUser = userId?.toLowerCase() || "";
    const cleanEmail = email?.toLowerCase() || "";
    const seenIds = new Set<string>();
    const results: SponsorCampaign[] = [];

    // 1. Fetch from Supabase sponsor_campaigns table
    try {
      const filters: string[] = [];
      if (cleanUser) filters.push(`user_id.eq.${cleanUser}`);
      if (cleanEmail && cleanEmail !== cleanUser) filters.push(`user_id.eq.${cleanEmail}`);

      if (filters.length > 0) {
        const { data: dbData, error } = await supabase
          .from("sponsor_campaigns")
          .select("*")
          .or(filters.join(","));

        if (!error && Array.isArray(dbData)) {
          for (const item of dbData) {
            if (!seenIds.has(item.id)) {
              seenIds.add(item.id);
              results.push(item as SponsorCampaign);
            }
          }
        }
      }
    } catch (err) {
      console.warn("Supabase sponsor_campaigns query notice:", err);
    }

    // 2. Fetch from server in-memory provider registry
    const registryItems: SponsorCampaign[] = [
      ...(cleanUser ? serverCampaignsRegistry.get(cleanUser) || [] : []),
      ...(cleanEmail && cleanEmail !== cleanUser ? serverCampaignsRegistry.get(cleanEmail) || [] : []),
    ];

    for (const item of registryItems) {
      if (!seenIds.has(item.id)) {
        seenIds.add(item.id);
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

    const userId = (body.user_id || "provider_default").trim();
    const userEmail = (body.email || "").trim();
    const listingId = body.listing_id || ensureUuid();
    const businessId = body.business_id || ensureUuid();

    const now = new Date();
    const startAtDate = body.start_at ? new Date(body.start_at) : now;
    
    // Default package duration: 7 days
    let durationDays = 7;
    if (body.sponsor_package?.toLowerCase().includes("spark") || body.package_days === 3) durationDays = 3;
    if (body.sponsor_package?.toLowerCase().includes("surge") || body.package_days === 14) durationDays = 14;

    const endAtDate = body.end_at ? new Date(body.end_at) : new Date(startAtDate.getTime() + durationDays * 86400000);

    const campaignId = ensureUuid(body.id);

    // Initial state: pending payment, draft status (frontend CANNOT mark paid)
    const newCampaign: SponsorCampaign = {
      id: campaignId,
      user_id: userId,
      business_id: businessId,
      listing_id: listingId,
      owner_name: body.owner_name || "Verified Provider",
      shop_name: body.shop_name || "Local Experience Host",
      listing_name: body.listing_name || "Local Experience",
      sponsor_type: body.sponsor_type || "boost",
      sponsor_package: body.sponsor_package || "Weekly Push (7 Days)",
      amount: Number(body.amount) || 999,
      offer_type: body.offer_type || "percentage_discount",
      offer_value: Number(body.offer_value) || 20,
      offer_price: Number(body.offer_price) || 960,
      offer_description: body.offer_description || `${body.offer_value || 20}% OFF Special`,
      start_at: startAtDate.toISOString(),
      end_at: endAtDate.toISOString(),
      timezone: body.timezone || "Asia/Kolkata",
      payment_method: body.payment_method || "upi",
      payment_status: "pending", // Strict rule: starts pending
      payment_transaction_id: undefined,
      campaign_status: "draft",
      created_at: now.toISOString(),
      updated_at: now.toISOString(),
      experience_details: body.experience_details,
    };

    // Save in server registry partition
    const key = userId.toLowerCase();
    const existing = serverCampaignsRegistry.get(key) || [];
    serverCampaignsRegistry.set(
      key,
      [newCampaign, ...existing.filter((c) => c.id !== newCampaign.id)]
    );
    if (userEmail && userEmail.toLowerCase() !== key) {
      const emailKey = userEmail.toLowerCase();
      const existingEmail = serverCampaignsRegistry.get(emailKey) || [];
      serverCampaignsRegistry.set(
        emailKey,
        [newCampaign, ...existingEmail.filter((c) => c.id !== newCampaign.id)]
      );
    }

    // Attempt to persist in Supabase sponsor_campaigns table
    let dbSuccess = false;
    let dbNotice: string | null = null;
    try {
      const { data, error } = await supabase.from("sponsor_campaigns").insert({
        id: newCampaign.id,
        user_id: newCampaign.user_id,
        business_id: newCampaign.business_id,
        listing_id: newCampaign.listing_id,
        owner_name: newCampaign.owner_name,
        shop_name: newCampaign.shop_name,
        listing_name: newCampaign.listing_name,
        sponsor_type: newCampaign.sponsor_type,
        sponsor_package: newCampaign.sponsor_package,
        amount: newCampaign.amount,
        start_at: newCampaign.start_at,
        end_at: newCampaign.end_at,
        timezone: newCampaign.timezone,
        payment_method: newCampaign.payment_method,
        payment_status: "pending",
        campaign_status: "draft",
      }).select();

      if (error) {
        dbNotice = error.message;
      } else {
        dbSuccess = true;
      }
    } catch (dbErr: any) {
      dbNotice = dbErr.message;
    }

    return NextResponse.json({
      success: true,
      campaign: newCampaign,
      dbSuccess,
      notice: dbNotice,
    });
  } catch (err: any) {
    return NextResponse.json({ success: false, error: err.message }, { status: 500 });
  }
}
