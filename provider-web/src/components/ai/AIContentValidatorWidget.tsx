"use client";

import React, { useState, useMemo, useEffect } from "react";
import {
  Sparkles,
  ShieldCheck,
  AlertTriangle,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Wand2,
  MapPin,
  Lock,
} from "lucide-react";
import {
  checkProfanity,
  checkClarity,
  validateExperienceLocations,
  calculateOverallQualityScore,
  MIN_PUBLISH_AI_SCORE,
  ShowLocationData,
} from "@/lib/aiValidator";

interface AIContentValidatorWidgetProps {
  title: string;
  description: string;
  onApplyPolish?: (polishedText: string) => void;
  onScoreChange?: (score: number, canPublish: boolean) => void;
  show1: ShowLocationData;
  show2?: ShowLocationData | null;
  hasImage?: boolean;
}

export const AIContentValidatorWidget: React.FC<AIContentValidatorWidgetProps> = ({
  title,
  description,
  onApplyPolish,
  onScoreChange,
  show1,
  show2,
  hasImage = true,
}) => {
  const [isExpanded, setIsExpanded] = useState(false);

  // Memoized checks for fast performance without lagging re-renders
  const profanityResult = useMemo(
    () => checkProfanity(`${title} ${description}`),
    [title, description]
  );

  const clarityResult = useMemo(
    () => checkClarity(title, description),
    [title, description]
  );

  const locationResult = useMemo(
    () => validateExperienceLocations(show1, show2),
    [show1, show2]
  );

  // Overall Score calculation (0 - 100) using unified engine
  const overallScore = useMemo(() => {
    return calculateOverallQualityScore(
      clarityResult.score,
      profanityResult.hasBadWords,
      locationResult.isValid,
      locationResult.hasMultiShow,
      hasImage
    );
  }, [clarityResult, profanityResult, locationResult, hasImage]);

  const canPublish =
    overallScore >= MIN_PUBLISH_AI_SCORE &&
    hasImage &&
    !profanityResult.hasBadWords &&
    locationResult.isValid;

  const isPublishBlocked = overallScore < MIN_PUBLISH_AI_SCORE || !hasImage;

  const hasIssues =
    isPublishBlocked ||
    !hasImage ||
    profanityResult.hasBadWords ||
    !locationResult.isValid ||
    clarityResult.score < 50;

  useEffect(() => {
    if (onScoreChange) {
      onScoreChange(overallScore, canPublish);
    }
  }, [overallScore, canPublish, onScoreChange]);

  return (
    <div
      className={`rounded-2xl border transition-all duration-200 overflow-hidden shadow-2xs ${
        isPublishBlocked
          ? "border-rose-300 bg-rose-50/20"
          : "border-slate-200/90 bg-white/95"
      } backdrop-blur-xs`}
    >
      {/* Small Collapsible Header Bar (Default Visible) */}
      <div className="px-4 py-2.5 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2.5 min-w-0">
          <div
            className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 border ${
              isPublishBlocked
                ? "bg-rose-100 text-rose-700 border-rose-300"
                : "bg-emerald-50 text-[#0e8a5b] border-emerald-200/60"
            }`}
          >
            {isPublishBlocked ? (
              <Lock className="w-3.5 h-3.5" />
            ) : (
              <Sparkles className="w-3.5 h-3.5" />
            )}
          </div>

          <div className="flex items-center gap-2 truncate text-xs">
            <span className="font-bold text-slate-800 shrink-0">AI Quality Check:</span>
            <span
              className={`font-black text-xs px-2 py-0.5 rounded-full flex items-center gap-1 ${
                overallScore >= 80
                  ? "bg-emerald-50 text-[#0e8a5b]"
                  : overallScore >= 50
                  ? "bg-amber-50 text-amber-700"
                  : "bg-rose-100 text-rose-700 border border-rose-200"
              }`}
            >
              <span>{overallScore}/100</span>
              {isPublishBlocked && (
                <span className="text-[10px] uppercase font-bold tracking-tight">
                  • Locked (&lt;50)
                </span>
              )}
            </span>
            <span className="text-[11px] text-slate-500 hidden sm:inline truncate">
              {isPublishBlocked
                ? "Score below 50 — Publishing is blocked until listing is improved"
                : hasIssues
                ? "Suggestions available to increase bookings"
                : "All safety & quality checks passed"}
            </span>
          </div>
        </div>

        {/* Action Button: Auto-Polish + Expand/Collapse */}
        <div className="flex items-center gap-2 shrink-0">
          {onApplyPolish && clarityResult.aiPolishedText && (
            <button
              type="button"
              onClick={() => onApplyPolish(clarityResult.aiPolishedText!)}
              className="hidden sm:inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-emerald-50 hover:bg-emerald-100 text-[#0e8a5b] text-[10.5px] font-bold border border-emerald-200 cursor-pointer transition-colors"
            >
              <Wand2 className="w-3 h-3" />
              <span>Auto-Polish</span>
            </button>
          )}

          <button
            type="button"
            onClick={() => setIsExpanded(!isExpanded)}
            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-slate-600 hover:text-slate-900 hover:bg-slate-100 text-xs font-semibold cursor-pointer transition-colors"
          >
            <span>{isExpanded ? "Hide" : "Details"}</span>
            {isExpanded ? (
              <ChevronUp className="w-3.5 h-3.5 text-slate-500" />
            ) : (
              <ChevronDown className="w-3.5 h-3.5 text-slate-500" />
            )}
          </button>
        </div>
      </div>

      {/* Collapsible Details Body */}
      {isExpanded && (
        <div className="px-4 pb-3.5 pt-1 border-t border-slate-100 space-y-2.5 text-xs animate-in fade-in duration-150">
          {/* Prominent Publishing Rule Warning when Score < 50 */}
          {isPublishBlocked && (
            <div className="p-2.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs flex items-start gap-2 shadow-2xs">
              <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0 mt-0.5" />
              <div className="flex-1">
                <span className="font-extrabold block">
                  Publishing Disabled (Current AI Score: {overallScore}/100)
                </span>
                <span className="text-[11px] text-rose-700 leading-snug block mt-0.5">
                  LocalLens requires a minimum AI Quality score of <strong>50/100</strong> to publish an experience listing.
                  Drafts can be saved at any time. To unlock publishing, improve your description, ensure meeting point coordinates are set, and remove any flagged words.
                </span>
              </div>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-3 gap-2.5">
            {/* Item 1: Content Safety */}
            <div
              className={`p-2.5 rounded-xl border ${
                profanityResult.hasBadWords
                  ? "bg-rose-50/70 border-rose-200 text-rose-800"
                  : "bg-slate-50/80 border-slate-200/80 text-slate-700"
              }`}
            >
              <div className="flex items-center justify-between mb-1">
                <span className="font-bold text-[11px] flex items-center gap-1.5">
                  {profanityResult.hasBadWords ? (
                    <AlertTriangle className="w-3.5 h-3.5 text-rose-600" />
                  ) : (
                  <ShieldCheck className="w-3.5 h-3.5 text-[#0e8a5b]" />
                )}
                Safety Guard
              </span>
              <span className="text-[10px] font-extrabold uppercase">
                {profanityResult.hasBadWords ? "Action Required" : "Passed"}
              </span>
            </div>
            <p className="text-[10.5px] text-slate-500 leading-snug">
              {profanityResult.hasBadWords
                ? `Flagged words: ${profanityResult.badWordsFound.join(", ")}`
                : "Content is clean, welcoming, and traveler safe."}
            </p>
          </div>

          {/* Item 2: Clarity */}
          <div className="p-2.5 rounded-xl border bg-slate-50/80 border-slate-200/80 text-slate-700">
            <div className="flex items-center justify-between mb-1">
              <span className="font-bold text-[11px] flex items-center gap-1.5">
                <CheckCircle2 className="w-3.5 h-3.5 text-[#0e8a5b]" />
                Clarity: {clarityResult.level}
              </span>
              <span className="text-[10px] text-slate-400 font-medium">
                {clarityResult.wordCount} words
              </span>
            </div>
            <p className="text-[10.5px] text-slate-500 leading-snug">
              {clarityResult.issues.length > 0
                ? clarityResult.issues[0]
                : "Description is clear and engaging for travelers."}
            </p>
            {onApplyPolish && clarityResult.aiPolishedText && (
              <button
                type="button"
                onClick={() => onApplyPolish(clarityResult.aiPolishedText!)}
                className="mt-1.5 text-[10px] text-[#0e8a5b] font-bold hover:underline flex items-center gap-1 cursor-pointer"
              >
                <Wand2 className="w-2.5 h-2.5" />
                <span>Apply AI Polish</span>
              </button>
            )}
          </div>

          {/* Item 3: Location */}
          <div className="p-2.5 rounded-xl border bg-slate-50/80 border-slate-200/80 text-slate-700">
            <div className="flex items-center justify-between mb-1">
              <span className="font-bold text-[11px] flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-[#0e8a5b]" />
                Location &amp; Pin
              </span>
              <span className="text-[10px] font-extrabold uppercase text-[#0e8a5b]">
                {locationResult.isValid ? "Verified" : "Check Pin"}
              </span>
            </div>
            <p className="text-[10.5px] text-slate-500 leading-snug">
              {show1.venue || "Meeting point set"} • {show1.city || "Mumbai"}
              {show2 ? ` (+ Show 2 in ${show2.city || "Mumbai"})` : ""}
            </p>
          </div>
        </div>
      </div>
      )}
    </div>
  );
};
