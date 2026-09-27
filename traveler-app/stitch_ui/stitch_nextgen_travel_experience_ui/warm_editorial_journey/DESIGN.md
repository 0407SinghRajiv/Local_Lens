---
name: Warm Editorial Journey
colors:
  surface: '#fcf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#5a413a'
  inverse-surface: '#313030'
  inverse-on-surface: '#f3f0ef'
  outline: '#8e7069'
  outline-variant: '#e3beb6'
  surface-tint: '#b32b01'
  primary: '#af2900'
  on-primary: '#ffffff'
  primary-container: '#d2411a'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb4a2'
  secondary: '#4b6454'
  on-secondary: '#ffffff'
  secondary-container: '#cbe6d3'
  on-secondary-container: '#4f6859'
  tertiary: '#7b542b'
  on-tertiary: '#ffffff'
  tertiary-container: '#966c41'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd2'
  primary-fixed-dim: '#ffb4a2'
  on-primary-fixed: '#3c0800'
  on-primary-fixed-variant: '#891e00'
  secondary-fixed: '#cee9d6'
  secondary-fixed-dim: '#b2cdba'
  on-secondary-fixed: '#082014'
  on-secondary-fixed-variant: '#344c3e'
  tertiary-fixed: '#ffdcbd'
  tertiary-fixed-dim: '#f0bd8b'
  on-tertiary-fixed: '#2c1600'
  on-tertiary-fixed-variant: '#623f18'
  background: '#fcf9f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
typography:
  display-hero:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.03em
  display-hero-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: '0'
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.005em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.5rem
  margin-mobile: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system bridges the editorial warmth of luxury travel publishing with the structural precision of high-utility itinerary tooling. It targets discerning independent travelers, weekend wanderers, and detailed planners who demand functional utility without clinical dryness.

The aesthetic blends **Warm Editorial Minimalism** with **Tactile Modernism**:
- **Canvas-first breathing room:** Generous cream surfaces replace sterile stark whites, creating a grounded, tactile foundation akin to uncoated premium paper stock.
- **Photography-led immersion:** Rich imagery anchored by warm borders and soft ambient diffusion.
- **Structured density:** Itinerary and schedule elements maintain crisp information architecture, balanced by relaxed, inviting typography and gentle organic curves.

## Colors
The palette balances vibrant Mediterranean warmth with grounding earth tones and neutral anchors:

- **Primary Accent (`#E85028`):** Sunkissed terracotta/persimmon. Reserved for primary actions, current trip status markers, and core brand highlights.
- **Secondary Accent (`#5A7363`):** Muted coastal sage. Employed for saved items, nature/outdoor badges, positive progress, and subtle contextual accents.
- **Tertiary Accent (`#D4A373`):** Sunbaked sand. Applied to secondary pill containers, neutral tags, and itinerary connectors.
- **Surfaces & Canvases:**
  - Base canvas: `#FAF9F6` (Alabaster cream)
  - Surface cards: `#FFFFFF` (Pure white) for crisp contrast against cream canvases
  - Surface muted: `#F5F4F0` (Pressed stone) for nested list modules, search tracks, and segmented tab tracks
- **Text & Content:**
  - Ink Primary: `#1A1A1A` (Deep ink charcoal, high-contrast, softened from pure pitch black)
  - Slate Secondary: `#6E6D7A` (Mid-tone slate for supporting subtitles, metadata, and timestamps)
  - Muted Tertiary: `#8A8998` (Footnotes, inactive states, placeholder indicators)
- **Borders & Dividers:**
  - Soft Card Outline: `#EAE8E3` (Warm neutral outline defining card structure without harsh contrast)
  - Subtle Hairline: `#F0EEE9` (Internal module dividers and inactive tab separators)

## Typography
The system balances expressive character with legible micro-details:

- **Plus Jakarta Sans** delivers warm, geometric presence across headlines and titles. Its open apertures and contemporary counters provide an optimistic editorial cadence.
- **Inter** handles high-density utility tasks: day-by-day itinerary schedules, flight details, pricing metrics, and long-form location descriptions.
- **Pairing rules:** Never use Plus Jakarta Sans below 18px; all small interactive metadata, button copy, and status flags switch strictly to Inter medium or semi-bold.
- Line heights across editorial sections maintain relaxed values (+60-65% over font size) to support an unhurried, leisurely reading experience.

## Layout & Spacing
The layout follows a mobile-first fluid model governed by an 8pt baseline rhythm:

- **Mobile Viewport (360px - 430px):**
  - Outer screen horizontal margins: `1.25rem` (20px).
  - Internal card padding: `1rem` (16px) for compact listings; `1.25rem` (20px) for hero trip overviews.
  - Inter-card stacking gaps: `1rem` (16px).
- **Tablet / Responsive Expand (600px - 840px):**
  - Margins expand to `1.5rem` (24px) with a 2-column itinerary view.
- **Horizontal Scroll Carousels:**
  - Bleed edge-to-edge on mobile with snap-stop points aligned precisely with the `1.25rem` margin.
  - End-of-track buffers match the outer screen margin to avoid abrupt cutoffs.
- **Safe Area Insets:**
  - Bottom scroll padding strictly enforces a minimum clearance of `5rem` (80px) to clear the floating bottom navigation bar without overlapping content.

## Elevation & Depth
Depth is constructed through ambient, warm light dispersion paired with low-contrast structural outlines rather than heavy drop shadows:

- **Level 0 (Flat / Canvas):** Surface color `#FAF9F6`. Ground layer with zero shadow.
- **Level 1 (Card Default):** Pure white `#FFFFFF` surface accompanied by a hairline border `1px solid #EAE8E3` and a soft ambient shadow:
  `box-shadow: 0 8px 30px rgba(26, 26, 26, 0.05);`
- **Level 2 (Floating Modals & Active Cards):** Lifted state during dragging or hovering:
  `box-shadow: 0 12px 36px rgba(26, 26, 26, 0.08);`
- **Level 3 (Bottom Navigation & Overlays):**
  `box-shadow: 0 -4px 24px rgba(26, 26, 26, 0.04);`
  Combined with a frosted glass backdrop filter (`backdrop-filter: blur(16px); background: rgba(250, 249, 246, 0.88);`) on navigation components.
- **No pure grey shadows:** All shadow alphas are computed against `#1A1A1A` to preserve warm, daylight undertones.

## Shapes
Geometry is distinctly organic, approachable, and smooth, eliminating aggressive corners:

- **Standard Cards & Module Panels:** `20px` to `24px` border-radius depending on outer surface hierarchy.
- **Interactive Buttons:** `14px` for compact secondary controls; `16px` for primary calls-to-action.
- **Bottom Drawers & Itinerary Sheets:** `28px` top corner radius for an inviting pull-up gesture.
- **Pills, Filters, & Tags:** Fully pill-shaped (`9999px`) to visually contrast against content cards.
- **Map Overlays & Floating Utility Buttons:** Perfectly circular (`50%`) with integrated level 2 ambient shadows.

## Components

### Buttons
- **Primary:** Filled `#E85028` background with `#FFFFFF` text. Height: 52px on mobile. Border radius: 16px. Font: `label-lg`. Active state scales down gently (`scale(0.98)`).
- **Secondary:** Filled `#F5F4F0` background with `#1A1A1A` text. Border radius: 16px. No border.
- **Ghost / Tertiary:** Transparent background, `#1A1A1A` text, hover/press state tinted with `rgba(232, 80, 40, 0.08)`.

### Cards & Itinerary Modules
- **Destination & Accommodation Cards:** White background (`#FFFFFF`), `20px` border-radius, `1px solid #EAE8E3` border, level 1 elevation. Feature full-bleed top imagery with an internal `16:10` aspect ratio and `1rem` inner padding for text content.
- **Timeline / Daily Node Cards:** Vertical connector lines (`2px solid #EAE8E3`) anchored by `12px` solid terracotta or sage dots. Compact cards (`12px` padding, `16px` border-radius) nestled on `#F5F4F0` surfaces.

### Chips & Filter Pills
- **Inactive:** `#FFFFFF` background, `1px solid #EAE8E3`, text `#6E6D7A`, `9999px` radius, padding: `8px 16px`.
- **Active:** `#1A1A1A` background, text `#FFFFFF`, border: `1px solid transparent`.
- **Category Badge:** Pastel tint fill (`rgba(90, 115, 99, 0.12)`) with matching text `#5A7363`.

### Input Fields & Search Trackers
- **Search Bar:** Height: 48px. `#FFFFFF` background with `1px solid #EAE8E3` border. Pill shape (`9999px`) or `16px` radius depending on screen position. Left-aligned search icon tinted `#8A8998`.
- **Form Inputs:** Height: 52px. `#F5F4F0` fill, switching to `#FFFFFF` with a `1.5px solid #E85028` border on focus. No harsh black outlines.

### Bottom Navigation Bar
- Fixed bottom dock featuring 5 targets: **Explore**, **Trips**, **Map**, **Bookings**, **Profile**.
- **Container:** Height: 64px + safe area padding. Background: `rgba(250, 249, 246, 0.92)` with `blur(20px)`. Border top: `1px solid #EAE8E3`.
- **Item Treatment:** 24px stroke icon with 10px `label-sm` text. Active state renders `#E85028` with a tiny 4px bottom dot indicator; inactive state rests at `#8A8998`.

### Bottom Sheets
- Rounded top corners at `28px`. Surface `#FFFFFF`. Top center contains a grab handle: 36px width, 4px height, `#D4A373` at 40% opacity, rounded `9999px`.