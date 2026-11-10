# Plates — product spec

Full build prompt (Parts 1–9, phases, agent rules) lives in the repo history and your exported PDF. This file is the in-repo anchor for Cursor.

## One-line product

Native iPhone app: **your fuel follows your training** — Lift + Fuel meet on Today and Week; targets cycle with heavy/standard/light/rest days.

## Stack (v1)

- Swift 5.9+, SwiftUI, SwiftData, iOS 17+, iPhone portrait
- Local-first; HealthKit, USDA/OFF, StoreKit, Supabase in later phases per Part 8–9
- Fonts: Instrument Serif + Manrope (bundle under `Plates/Resources/Fonts/`)

## Folder layout

```
Plates/App/           PlatesApp, RootTabView
Plates/DesignSystem/  Colors, Typography, components
Plates/Models/        SwiftData @Model types
Plates/Engines/       Pure Swift (Phase 1)
Plates/Features/      Today, Lift, Fuel, Week, Coach, …
Plates/Services/      Seed data, HealthKit, food APIs (later)
Plates/Resources/     SeedData JSON, fonts
PlatesTests/          Engine unit tests
design/               Screen mockups (add PNGs from Figma)
```

## Build phases (order)

| Phase | Scope |
|-------|--------|
| **0** | Design system, 5-tab shell, SwiftData models, seed JSON, DesignGallery preview |
| **1** | TargetsEngine, TrendEngine, WeeklyAdjust, ProgressionEngine, ReadinessEngine, GroceryEngine + tests |
| **2–8** | Lift, active workout, Fuel, Today+Week, onboarding, HealthKit, Premium/AI |

## Phase 0 done when

- App runs with **Today · Lift · Fuel · Week · Coach** (Coach locked)
- Light/dark via asset colors; components match Part 3 tokens
- Seed exercises/foods imported on first launch
- `DesignGalleryView` preview shows components in light and dark

## Design tokens

See Part 3 in the PDF: `bg`, `surface`, `card`, `soft`, `ink`, `muted`, `line`, `accent`, `good`, `gold`, etc. in `Plates/Assets.xcassets`.
