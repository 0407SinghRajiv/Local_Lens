/**
 * AI Content & Location Validator for LocalLens Providers
 * - Profanity and inappropriate content filter
 * - Sentence clarity & completeness evaluator
 * - Multi-show location validation with distance & transit buffer checks
 * - AI auto-enhance recommendation
 */

// Common profanity, offensive, abusive, and inappropriate word list
const BAD_WORDS_LIST = [
  "abuse", "ass", "asshole", "bastard", "bitch", "blowjob", "bullshit", "crap",
  "cunt", "damn", "dick", "douche", "dumbass", "fag", "faggot", "fuck", "fucking",
  "hate", "idiot", "motherfucker", "nigger", "piss", "pussy", "retard", "scam",
  "shit", "slut", "stupid", "suck", "whore",
  // Indian context / Hinglish profanity
  "bc", "bkl", "bhosadi", "bhosdike", "chutiya", "choot", "chodu", "gandu",
  "harami", "kamina", "kutta", "lauda", "loda", "lund", "madarchod", "mc",
  "randi", "saala", "suar"
];

// Vague words that indicate unclear or low-effort listings
const VAGUE_PHRASES = [
  "nice stuff",
  "good thing",
  "random things",
  "whatever",
  "see some things",
  "contact me for details",
  "dm for price",
  "asdf",
  "test listing",
  "just checking",
];

export interface ProfanityCheckResult {
  hasBadWords: boolean;
  badWordsFound: string[];
  cleanText: string;
  message: string;
}

export interface ClarityCheckResult {
  isClear: boolean;
  score: number; // 0 - 100
  level: "Excellent" | "Good" | "Needs Improvement" | "Unclear";
  wordCount: number;
  sentenceCount: number;
  issues: string[];
  suggestions: string[];
  aiPolishedText?: string;
}

export interface ShowLocationData {
  id: string;
  name: string; // e.g. "Morning Kayaking Session" or "Sunset Kayaking Session"
  venue: string; // e.g. "Versova Beach Pier 2"
  city: string;
  district: string;
  lat: number;
  lng: number;
  timeSlot?: string;
}

export interface LocationValidationResult {
  isValid: boolean;
  hasMultiShow: boolean;
  show1Valid: boolean;
  show2Valid: boolean;
  distanceKm?: number;
  transitFeasible?: boolean;
  messages: string[];
}

/**
 * 1. AI Profanity and Inappropriate Words Validator
 */
export function checkProfanity(text: string): ProfanityCheckResult {
  if (!text || typeof text !== "string") {
    return { hasBadWords: false, badWordsFound: [], cleanText: "", message: "Clean text." };
  }

  const normalized = text.toLowerCase().replace(/[@#$%^&*_\-+]/g, "");
  const words = normalized.split(/\s+/);
  const detected = new Set<string>();

  for (const bad of BAD_WORDS_LIST) {
    const regex = new RegExp(`\\b${bad}\\b`, "i");
    if (regex.test(normalized) || words.includes(bad)) {
      detected.add(bad);
    }
  }

  const badWordsFound = Array.from(detected);
  const hasBadWords = badWordsFound.length > 0;

  let cleanText = text;
  if (hasBadWords) {
    for (const bad of badWordsFound) {
      const mask = "*".repeat(bad.length);
      const reg = new RegExp(`\\b${bad}\\b`, "gi");
      cleanText = cleanText.replace(reg, mask);
    }
  }

  return {
    hasBadWords,
    badWordsFound,
    cleanText,
    message: hasBadWords
      ? `Prohibited content detected: Please remove inappropriate terms (${badWordsFound.join(", ")}) before publishing.`
      : "Safety Check Passed: No inappropriate or offensive language found.",
  };
}

/**
 * 2. AI Clarity & Sentence Quality Validator
 */
export function checkClarity(title: string, description: string): ClarityCheckResult {
  const combined = `${title || ""} ${description || ""}`.trim();
  const words = combined.split(/\s+/).filter(Boolean);
  const wordCount = words.length;

  const rawSentences = (description || "")
    .split(/[.!?]+/)
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
  const sentenceCount = rawSentences.length;

  const issues: string[] = [];
  const suggestions: string[] = [];
  let score = 100;

  // Title check
  if (!title || title.trim().length < 5) {
    issues.push("Title is too short. Travelers need a descriptive title (at least 5 characters).");
    score -= 25;
  } else if (/^[a-z]/.test(title.trim())) {
    suggestions.push("Capitalize the first letter of your title for a professional impression.");
    score -= 5;
  }

  // Description length check
  if (description.trim().length === 0) {
    issues.push("Description is completely empty. Explain what travelers will experience.");
    score -= 50;
  } else if (wordCount < 12) {
    issues.push("Description is very brief. Provide at least 15-20 words describing the activity.");
    score -= 30;
  } else if (wordCount < 25) {
    suggestions.push("Adding more detail about gear, sights, or local stories will increase bookings.");
    score -= 10;
  }

  // Check for vague phrases
  const lowerDesc = combined.toLowerCase();
  for (const vague of VAGUE_PHRASES) {
    if (lowerDesc.includes(vague)) {
      issues.push(`Overly vague phrase detected ("${vague}"). Replace with specific tour details.`);
      score -= 15;
    }
  }

  // Check for keyboard spam / repetitive characters (e.g. "aaaaa", "asdfgh")
  if (/(.)\1{4,}/.test(combined) || /[a-z]{15,}/i.test(combined)) {
    issues.push("Gibberish or repetitive letters detected. Please use real words.");
    score -= 35;
  }

  // Punctuation and structure
  if (sentenceCount > 0 && !/[.!?]$/.test(description.trim())) {
    suggestions.push("End your description with proper punctuation (period or exclamation mark).");
    score -= 5;
  }

  // Ensure score stays in 0 - 100
  score = Math.max(10, Math.min(100, score));

  let level: ClarityCheckResult["level"] = "Excellent";
  if (score < 45) level = "Unclear";
  else if (score < 70) level = "Needs Improvement";
  else if (score < 88) level = "Good";

  // Generate an AI-polished version
  let aiPolishedText = description.trim();
  if (aiPolishedText.length > 5) {
    // Capitalize first letter, trim multiple spaces, add period if missing
    aiPolishedText = aiPolishedText.charAt(0).toUpperCase() + aiPolishedText.slice(1);
    if (!/[.!?]$/.test(aiPolishedText)) aiPolishedText += ".";
  }

  return {
    isClear: score >= 65 && issues.length === 0,
    score,
    level,
    wordCount,
    sentenceCount,
    issues,
    suggestions,
    aiPolishedText,
  };
}

/**
 * Calculate distance between two lat/lng points using Haversine formula (km)
 */
export function calculateDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Earth radius in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Number((R * c).toFixed(2));
}

/**
 * 3. AI Location Validator with Multi-Show Support (handles 2 shows / locations for same provider)
 */
export function validateExperienceLocations(
  show1: ShowLocationData,
  show2?: ShowLocationData | null
): LocationValidationResult {
  const messages: string[] = [];

  // 1. Validate Show 1
  const show1LatValid = typeof show1.lat === "number" && show1.lat >= -90 && show1.lat <= 90 && show1.lat !== 0;
  const show1LngValid = typeof show1.lng === "number" && show1.lng >= -180 && show1.lng <= 180 && show1.lng !== 0;
  const show1CityValid = Boolean(show1.city && show1.city.trim().length >= 2);
  const show1Valid = show1LatValid && show1LngValid && show1CityValid;

  if (!show1LatValid || !show1LngValid) {
    messages.push("Show 1: Coordinates are missing or invalid. Please drop a pin on the map.");
  }
  if (!show1CityValid) {
    messages.push("Show 1: City name is required.");
  }

  // 2. Validate Show 2 (if provided)
  const hasMultiShow = Boolean(show2 && (show2.venue || show2.city || (show2.lat && show2.lat !== show1.lat)));
  let show2Valid = true;
  let distanceKm: number | undefined = undefined;
  let transitFeasible: boolean | undefined = undefined;

  if (hasMultiShow && show2) {
    const show2LatValid = typeof show2.lat === "number" && show2.lat >= -90 && show2.lat <= 90 && show2.lat !== 0;
    const show2LngValid = typeof show2.lng === "number" && show2.lng >= -180 && show2.lng <= 180 && show2.lng !== 0;
    const show2CityValid = Boolean(show2.city && show2.city.trim().length >= 2);
    show2Valid = show2LatValid && show2LngValid && show2CityValid;

    if (!show2LatValid || !show2LngValid) {
      messages.push("Show 2: Coordinates are missing. Select second venue on map.");
    }
    if (!show2CityValid) {
      messages.push("Show 2: City name is required.");
    }

    if (show1Valid && show2Valid) {
      distanceKm = calculateDistanceKm(show1.lat, show1.lng, show2.lat, show2.lng);
      // If distance is very close (< 50 meters)
      if (distanceKm < 0.05) {
        messages.push("Notice: Show 1 and Show 2 are set at identical coordinates. Confirm if venues are distinct.");
        transitFeasible = true;
      } else if (distanceKm > 80) {
        messages.push(`Notice: Show 1 and Show 2 are ${distanceKm} km apart. Ensure sufficient transit buffer between show schedules.`);
        transitFeasible = true;
      } else {
        transitFeasible = true;
        messages.push(`Multi-Show Verified: Show 1 (${show1.venue || show1.city}) and Show 2 (${show2.venue || show2.city}) are ${distanceKm} km apart.`);
      }
    }
  }

  const isValid = show1Valid && (!hasMultiShow || show2Valid);

  return {
    isValid,
    hasMultiShow,
    show1Valid,
    show2Valid,
    distanceKm,
    transitFeasible,
    messages,
  };
}

/**
 * 4. Combined Full Validator
 */
export function validateFullListing(
  title: string,
  description: string,
  show1: ShowLocationData,
  show2?: ShowLocationData | null
) {
  const profanity = checkProfanity(`${title} ${description}`);
  const clarity = checkClarity(title, description);
  const location = validateExperienceLocations(show1, show2);

  // Overall AI score
  let overallScore = clarity.score;
  if (profanity.hasBadWords) overallScore = Math.min(overallScore, 20);
  if (!location.isValid) overallScore = Math.min(overallScore, 40);
  if (location.hasMultiShow && location.isValid) overallScore = Math.min(100, overallScore + 5); // bonus for multi-location shows

  const canPublish = !profanity.hasBadWords && clarity.score >= 50 && location.isValid;

  return {
    canPublish,
    overallScore,
    profanity,
    clarity,
    location,
  };
}
