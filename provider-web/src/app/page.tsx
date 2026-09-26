"use client";

import React from "react";
import { Navbar } from "@/components/landing/Navbar";
import { HeroSection } from "@/components/landing/HeroSection";

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-white text-[#0F172A] font-sans selection:bg-[#059669] selection:text-white flex flex-col justify-between overflow-x-hidden">
      {/* 1. Top Navigation */}
      <Navbar />

      {/* 2. Hero Section with Background, Floating Card, and Bottom Trust Bar */}
      <main className="flex-1 flex flex-col justify-between">
        <HeroSection />
      </main>
    </div>
  );
}