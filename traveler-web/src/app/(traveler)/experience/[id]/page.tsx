'use client';

import React, { use } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';
import { useItinerary } from '@/context/ItineraryContext';
import { useRide } from '@/context/RideContext';
import {
  ArrowLeft,
  Heart,
  Star,
  Clock,
  MapPin,
  Car,
  Plus,
  Check,
  ShieldCheck,
  Share2,
} from 'lucide-react';

const InteractiveMap = dynamic(
  () => import('@/components/maps/InteractiveMap').then((m) => m.InteractiveMap),
  { ssr: false, loading: () => <div className="h-56 w-full rounded-2xl bg-black/5 animate-pulse" /> }
);

export default function ExperienceDetailsPage({ params }: { params: Promise<{ id: string }> }) {
  const resolvedParams = use(params);
  const router = useRouter();
  const { recommendations, wishlist, toggleWishlist, selectedExperienceIds, toggleExperienceSelection } =
    useItinerary();
  const { setLocations } = useRide();

  const id = resolvedParams.id;
  const experience =
    recommendations.find((r) => r.experienceId === id || r.experienceId.includes(id)) ||
    recommendations[0];

  if (!experience) {
    return (
      <div className="py-20 text-center">
        <h2 className="text-xl font-bold">Experience not found</h2>
        <Link href="/explore" className="text-primary font-semibold mt-2 inline-block">
          Back to Explore
        </Link>
      </div>
    );
  }

  const isSaved = wishlist.includes(experience.experienceId);
  const isSelected = selectedExperienceIds.includes(experience.experienceId);

  const fallbackImages: Record<string, string> = {
    Beach: '/assets/images/destinations/beach_cafe.png',
    Food: '/assets/images/destinations/food_trail.png',
    Adventure: '/assets/images/destinations/waterfall.png',
    Heritage: '/assets/images/destinations/heritage_walk.png',
    Nature: '/assets/images/destinations/waterfall.png',
    Culture: '/assets/images/destinations/heritage_walk.png',
  };

  const rawImage = experience.imageUrl || experience.image || '';
  const isExternal = rawImage.startsWith('http://') || rawImage.startsWith('https://');
  const imageSrc =
    rawImage ||
    fallbackImages[experience.category] ||
    '/assets/images/destinations/food_trail.png';

  function handleBookRide() {
    setLocations({
      pickup: 'My Current Location',
      drop: `${experience.name}, ${experience.location}`,
      dropLat: experience.latitude ?? undefined,
      dropLng: experience.longitude ?? undefined,
    });
    router.push('/rides/book');
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6 pb-12 animate-in fade-in duration-300">
      {/* Top Back Navigation Bar */}
      <div className="flex items-center justify-between">
        <button
          onClick={() => router.back()}
          className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 text-xs font-semibold hover:border-primary/40 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>Back</span>
        </button>

        <div className="flex items-center gap-2">
          <button
            onClick={() => toggleWishlist(experience.experienceId)}
            className="w-9 h-9 rounded-full bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 flex items-center justify-center text-ink-secondary hover:text-red-500 transition-colors"
            title="Save to Wishlist"
          >
            <Heart className={`w-4 h-4 ${isSaved ? 'fill-red-500 text-red-500' : ''}`} />
          </button>
          <button
            onClick={() => {
              if (navigator.share) {
                navigator.share({
                  title: experience.name,
                  text: experience.reason,
                  url: window.location.href,
                });
              }
            }}
            className="w-9 h-9 rounded-full bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 flex items-center justify-center text-ink-secondary hover:text-primary transition-colors"
            title="Share"
          >
            <Share2 className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Hero Image */}
      <div className="relative aspect-[16/9] w-full rounded-3xl overflow-hidden shadow-floating bg-slate-100 dark:bg-slate-900">
        <Image src={imageSrc} alt={experience.name} fill unoptimized={isExternal} className="object-cover" priority />
        <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/25 to-transparent" />

        <div className="absolute top-4 left-4 flex items-center gap-2">
          <span className="px-3 py-1 rounded-full bg-white/90 dark:bg-slate-900/90 backdrop-blur-md text-xs font-bold text-primary shadow-sm">
            {experience.category}
          </span>
          {experience.hiddenGem && (
            <span className="px-3 py-1 rounded-full bg-amber-500 text-white text-xs font-bold shadow-sm">
              Hidden Gem
            </span>
          )}
        </div>

        <div className="absolute bottom-5 left-5 right-5 text-white">
          <div className="flex items-center gap-2 text-xs font-semibold text-amber-300">
            <Star className="w-4 h-4 fill-current" />
            <span className="text-sm font-bold">{experience.rating ?? 4.8}</span>
            <span className="text-white/60">({experience.reviewCount ?? 120} reviews)</span>
          </div>
          <h1 className="font-display font-black text-xl sm:text-3xl text-white mt-1 leading-tight">
            {experience.name}
          </h1>
          <div className="flex items-center gap-1.5 text-xs text-white/80 mt-1">
            <MapPin className="w-3.5 h-3.5 text-primary-light" />
            <span>{experience.location}</span>
          </div>
        </div>
      </div>

      {/* Highlights Metric Bar */}
      <div className="grid grid-cols-3 gap-3 p-4 rounded-2xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 shadow-soft text-center">
        <div>
          <span className="text-[11px] font-bold text-ink-secondary dark:text-slate-400 block uppercase">
            Duration
          </span>
          <span className="font-display font-extrabold text-base sm:text-lg text-[#1A1A1A] dark:text-white flex items-center justify-center gap-1 mt-0.5">
            <Clock className="w-4 h-4 text-primary" />
            {experience.durationHours}h
          </span>
        </div>
        <div className="border-x border-[#EAE8E3] dark:border-slate-700">
          <span className="text-[11px] font-bold text-ink-secondary dark:text-slate-400 block uppercase">
            Price / Person
          </span>
          <span className="font-display font-extrabold text-base sm:text-lg text-primary mt-0.5 block">
            ₹{experience.price}
          </span>
        </div>
        <div>
          <span className="text-[11px] font-bold text-ink-secondary dark:text-slate-400 block uppercase">
            Type
          </span>
          <span className="font-display font-extrabold text-base sm:text-lg text-[#1A1A1A] dark:text-white mt-0.5 block">
            {experience.indoorOutdoor}
          </span>
        </div>
      </div>

      {/* Description & Insider Tips */}
      <div className="p-6 rounded-3xl bg-white dark:bg-slate-800 border border-[#EAE8E3] dark:border-slate-700 shadow-soft space-y-4">
        <h3 className="font-display font-bold text-lg text-[#1A1A1A] dark:text-white">
          About this Local Experience
        </h3>
        <p className="text-sm leading-relaxed text-ink-secondary dark:text-slate-300">
          {experience.reason}
        </p>

        <div className="p-4 rounded-2xl bg-primary-soft dark:bg-primary/10 border border-primary/20 space-y-1.5">
          <div className="flex items-center gap-2 text-primary font-bold text-xs uppercase tracking-wider">
            <ShieldCheck className="w-4 h-4" />
            <span>LocalLens Insider Guidance</span>
          </div>
          <p className="text-xs text-ink-secondary dark:text-slate-300 leading-normal">
            Best experienced during golden morning hours or sunset. Local transit and street food stops are located within 5 minutes walking distance.
          </p>
        </div>
      </div>

      {/* Geographic Map Location */}
      {experience.latitude && experience.longitude && (
        <div className="space-y-2">
          <h3 className="font-display font-bold text-base text-[#1A1A1A] dark:text-white">
            Location & Access
          </h3>
          <div className="h-64 rounded-3xl overflow-hidden border border-[#EAE8E3] dark:border-slate-700 shadow-soft">
            <InteractiveMap
              markers={[
                {
                  id: experience.experienceId,
                  name: experience.name,
                  category: experience.category,
                  latitude: experience.latitude,
                  longitude: experience.longitude,
                },
              ]}
              center={[experience.latitude, experience.longitude]}
              zoom={14}
              showPolyline={false}
              className="w-full h-full"
            />
          </div>
        </div>
      )}

      {/* Bottom Sticky Action Floating Deck */}
      <div className="fixed bottom-0 left-0 right-0 p-4 bg-white/95 dark:bg-slate-900/95 backdrop-blur-xl border-t border-[#EAE8E3] dark:border-slate-800 z-40">
        <div className="max-w-4xl mx-auto flex items-center justify-between gap-4">
          <div>
            <span className="text-[10px] uppercase font-bold text-ink-secondary dark:text-slate-400 block">
              Experience Cost
            </span>
            <span className="font-display font-extrabold text-xl text-primary">
              ₹{experience.price}
            </span>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={handleBookRide}
              className="px-4 py-3 rounded-2xl bg-surface-muted dark:bg-slate-800 hover:bg-black/5 dark:hover:bg-white/10 text-ink dark:text-white font-semibold text-xs flex items-center gap-1.5 active:scale-95 transition-all"
            >
              <Car className="w-4 h-4 text-primary" />
              <span>Book Ride</span>
            </button>

            <button
              onClick={() => toggleExperienceSelection(experience.experienceId)}
              className={`px-6 py-3 rounded-2xl font-bold text-xs flex items-center gap-2 active:scale-95 transition-all shadow-md ${
                isSelected
                  ? 'bg-emerald-600 text-white'
                  : 'bg-primary text-white hover:bg-primary-dark'
              }`}
            >
              {isSelected ? (
                <>
                  <Check className="w-4 h-4" />
                  <span>Added to Itinerary</span>
                </>
              ) : (
                <>
                  <Plus className="w-4 h-4" />
                  <span>Add to Itinerary</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
