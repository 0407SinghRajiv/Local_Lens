"use client";

import React, { useState, useMemo } from "react";
import {
  Sparkles,
  ShieldCheck,
  AlertTriangle,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Wand2,
  MapPin,
} from "lucide-react";
import {
  checkProfanity,
  checkClarity,
  validateExperienceLocations,
  ShowLocationData,
} from "@/lib/aiValidator";

interface AIContentValidatorWidgetProps {
  title: string;
  description: string;
  onApplyPolish?: (polishedText: string) => void;
  show1: ShowLocationData;
  show2?: ShowLocationData | null;
}

export const AIContentValidatorWidget: React.FC<AIContentValidatorWidgetProps> = ({
  title,
  description,
  onApplyPolish,
  show1,
  show2,
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

  // Overall Score calculation (0 - 100)
  const overallScore = useMemo(() => {
    let score = clarityResult.score;
    if (profanityResult.hasBadWords) score = Math.min(score, 20);
    if (!locationResult.isValid) score = Math.min(score, 45);
    if (locationResult.hasMultiShow && locationResult.isValid) {
      score = Math.min(100, score + 5);
    }
    return Math.max(0, Math.min(100, score));
  }, [clarityResult, profanityResult, locationResult]);

  const hasIssues = profanityResult.hasBadWords || !locationResult.isValid || clarityResult.score < 50;

  return (
    <div className="rounded-2xl border border-slate-200/90 bg-white/95 backdrop-blur-xs shadow-2xs overflow-hidden transition-all duration-200">
      {/* Small Collapsible Header Bar (Default Visible) */}
      <div className="px-4 py-2.5 flex items-center justify-between gap-3">
        <div className="flex items-center gap-2.5 min-w-0">
          <div className="w-7 h-7 rounded-lg bg-emerald-50 text-[#0e8a5b] flex items-center justify-center shrink-0 border border-emerald-200/60">
            <Sparkles className="w-3.5 h-3.5" />
          </div>

          <div className="flex items-center gap-2 truncate text-xs">
            <span className="font-bold text-slate-800 shrink-0">AI Quality Check:</span>
            <span
              className={`font-black text-xs px-2 py-0.5 rounded-full ${
                overallScore >= 80
                  ? "bg-emerald-50 text-[#0e8a5b]"
                  : overallScore >= 60
                  ? "bg-amber-50 text-amber-700"
                  : "bg-rose-50 text-rose-700"
              }`}
            >
              {overallScore}/100
            </span>
            <span className="text-[11px] text-slate-500 hidden sm:inline truncate">
              {hasIssues
                ? "Suggestions available"
                : "All safety & clarity checks passed"}
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
        <div className="px-4 pb-3.5 pt-1 border-t border-slate-100 grid grid-cols-1 md:grid-cols-3 gap-2.5 text-xs animate-in fade-in duration-150">
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
      )}
    </div>
  );
};
