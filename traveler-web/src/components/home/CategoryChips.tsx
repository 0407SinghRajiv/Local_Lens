'use client';

import React from 'react';
import {
  Utensils,
  Landmark,
  Compass,
  Trees,
  Castle,
  Waves,
  ShoppingBag,
  Moon,
  Sparkles,
} from 'lucide-react';

export const CATEGORIES = [
  { id: 'All', label: 'All', icon: Sparkles },
  { id: 'Food', label: 'Food & Dining', icon: Utensils },
  { id: 'Culture', label: 'Culture & Temples', icon: Landmark },
  { id: 'Adventure', label: 'Adventure & Treks', icon: Compass },
  { id: 'Nature', label: 'Nature & Parks', icon: Trees },
  { id: 'Heritage', label: 'Heritage & Forts', icon: Castle },
  { id: 'Beach', label: 'Beaches & Coast', icon: Waves },
  { id: 'Shopping', label: 'Bazaars & Crafts', icon: ShoppingBag },
  { id: 'Nightlife', label: 'Nightlife & Lounges', icon: Moon },
];

interface CategoryChipsProps {
  selectedCategory: string;
  onSelectCategory: (category: string) => void;
}

export function CategoryChips({ selectedCategory, onSelectCategory }: CategoryChipsProps) {
  return (
    <div className="flex items-center gap-2 overflow-x-auto no-scrollbar py-2">
      {CATEGORIES.map((cat) => {
        const Icon = cat.icon;
        const isSelected = selectedCategory === cat.id;

        return (
          <button
            key={cat.id}
            onClick={() => onSelectCategory(cat.id)}
            className={`flex items-center gap-2 px-4 py-2.5 rounded-full text-xs font-semibold shrink-0 transition-all active:scale-95 ${
              isSelected
                ? 'bg-[#1A1A1A] text-white dark:bg-primary shadow-sm'
                : 'bg-white dark:bg-slate-800 text-ink-secondary dark:text-slate-300 border border-[#EAE8E3] dark:border-slate-700 hover:border-primary/40'
            }`}
          >
            <Icon className={`w-3.5 h-3.5 ${isSelected ? 'text-primary dark:text-white' : 'text-primary'}`} />
            <span>{cat.label}</span>
          </button>
        );
      })}
    </div>
  );
}
