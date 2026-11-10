# Build the Plates v1 UI in SwiftUI — exact spec

You are restyling my existing SwiftUI app "Plates" (training + fueling planner) to match four finished mockups **one-to-one**. Every color, size, radius, spacing value and string you need is in this document. The folder `plates-mockups-html/` contains the original HTML source of each mockup (`Today.html`, `Fuel.html`, `Plan.html`, `Session.html`). **If anything here is unclear, read the HTML; if this doc and the HTML disagree, the HTML wins.**

## Rules

1. Match the mockups exactly. Do not invent extra UI, change copy, add shadows/gradients, or "improve" the design.
2. Build in this order, and stop after each step so I can check it:
   1. `DesignSystem.swift` (tokens)
   2. `Components/` (reusable views)
   3. `MockData.swift` (the exact data shown below)
   4. The four screens, each with a `#Preview` using `MockData`
   5. Wire screens to my existing models/data (keep my existing logic; only replace the views)
3. All sizes are in points (1 CSS px in the HTML = 1 pt). Mockups are drawn at 390 pt wide (iPhone 15/16).
4. Use SF Symbols for icons (mapping given below).
5. Numbers use `.monospacedDigit()`.
6. Light mode for Today, Fuel and Plan. The Live Session screen is **always dark** (it is presented full-screen, no tab bar).

---

## 1. Design tokens (`DesignSystem.swift`)

Add a `Color(hex:)` initializer and define these:

### Colors — light screens
| Token | Hex | Use |
|---|---|---|
| `bg` | #F2F2F4 | screen background, chip background, progress track |
| `card` | #FFFFFF | cards |
| `ink` | #111111 | primary text, tab bar, dark session card, selected day pill |
| `inkSecondary` | #6B6B70 | secondary text, labels |
| `chipText` | #3A3A3F | text inside chips |
| `divider` | #EFEFF2 | food-row dividers |
| `timelineLine` | #DCDCE0 | timeline rail line |
| `nodeEmpty` | #C7C7CC | border of upcoming timeline node; inactive tab icons |
| `checkEmpty` | #D1D1D6 | border of un-eaten check circle |
| `onDarkSecondary` | #A1A1A6 | secondary text on #111 surfaces |
| `darkTile` | #2A2A2E | icon tiles inside the dark session card |

### Accent (orange) — means "you / act here" only
| Token | Hex |
|---|---|
| `accent` | #FF6B1A (text/icons ON accent are always #111111) |
| `accentTint` | #FFF1E8 (gap-suggestion card bg, PT-guided chip bg) |
| `accentTintText` | #5A4A40 (body text on accentTint card) |
| `ptChipText` | #7A3A12 |

### Day Load colors (blue) — mean training load only
```swift
enum DayLoadLabel { case high, moderate, low, rest }
```
| Label | Fill | Text on it | Date-strip dot |
|---|---|---|---|
| High | #1D4ED8 | #FFFFFF | #1D4ED8 |
| Moderate | #60A5FA | #0B1B3F | #60A5FA |
| Low | #BFDBFE | #0B1B3F | #BFDBFE |
| Rest | #E5E5EA | #3A3A3F | #D1D1D6 |

### Macro colors
Protein = `accent` (#FF6B1A) · Carbs = #F5B700 · Fat = #8B5CF6

### Colors — Live Session (dark)
| Token | Hex |
|---|---|
| `sessionBg` | #0B0B0C |
| `sessionSurface` | #151517 (block card) |
| `sessionRow` | #1C1C1F (rep rows, pills, keys, top buttons) |
| `sessionRaised` | #2A2A2E (rest pill, progress track) |
| `sessionActiveRow` | #1F1A17 (active rep row bg) |
| `sessionMuted` | #5A5A60 (cursor underscore) |
| `sessionDim` | #8E8E93 (pending rep dash) |
| text | #FFFFFF primary, #A1A1A6 secondary, #D1D1D6 pill text |

### Typography
Font: **Inter** (bundle Inter-Regular/Medium/SemiBold/Bold/ExtraBold from Google Fonts, register in Info.plist). Make a helper `Font.inter(_ size: CGFloat, _ weight: Font.Weight)`. Weights: 500 = medium, 600 = semibold, 700 = bold, 800 = heavy.

| Style | Size / weight | Tracking | Color |
|---|---|---|---|
| Screen title | 34 / 800 | -0.68 | ink |
| Screen overline (date above title) | 14 / 500 | 0 | inkSecondary |
| Hero number (Today) | 46 / 800 | -1.38 | ink |
| Hero number (Fuel) | 52 / 800 | -1.56 | ink |
| Section heading | 22 / 800 (Today "Your day"), 20 / 800 ("Today's food"), 17 / 800 ("Day Load") | -0.2 | ink |
| Caps label | 11 / 700, UPPERCASE | +0.66 | inkSecondary |
| Macro caps label (Fuel) | 12 / 700, UPPERCASE | +0.6 | inkSecondary |
| Card title | 16 / 600 (meal) · 16 / 700 (day card) · 15 / 600 (food row) | 0 | ink |
| Body secondary | 13–15 / 500 | 0 | inkSecondary |
| Chip | 12 / 600 | 0 | chipText |

### Radii
- 24: summary card, session card (Today), food list card, Day Load card, Fuel calorie card
- 22: Live Session block card
- 20: meal card, macro card, day card, gap card
- 18: Save rep button
- 16: day pill, Start session button, search/scan buttons, number keys, rep rows
- 14: food icon tile
- 10: session-block icon tile
- Capsule: chips, badges, tab bar, tab active pill, progress bars, pills

### Layout
- Screen horizontal padding: 20. Content starts ~4 pt below the top safe area.
- Bottom padding on scrolling content: 120 (clears the floating tab bar).
- Vertical gap between top-level sections: Today 18 · Fuel 16 · Plan 14 · Session 14.
- No shadows anywhere except the Fuel "+" button: `shadow(color: .black.opacity(0.15), radius: 10, y: 8)`.

---

## 2. Components (`Components/`)

**ScreenHeader** — VStack(alignment: .leading, spacing: 2): overline (14/500 secondary), title (34/800). Trailing accessory bottom-aligned (varies per screen).

**DayPill** — width 44, padding top 10 / bottom 9, radius 16, bg white. VStack spacing 5: weekday 12/500 secondary · date 17/700 ink · dot 6×6 circle in load dot color. **Selected:** bg #111, weekday #A1A1A6, date white, dot fill #60A5FA with a 2 pt #1D4ED8 ring (`.overlay(Circle().stroke(...))` outside).
**DayStrip** — HStack of 7 DayPills, `.frame(maxWidth: .infinity)` with spacing distributing evenly (space-between).

**LoadBadge(label, size)** — capsule. Large: 13/700, padding v5 h11 (Fuel header uses v6 h12). Small (day cards): 11/700, padding v3 h9. Fill/text from DayLoadLabel table. Text: "High day" on Today/Fuel; "High", "Moderate", "Low", "Rest" in day cards.

**Chip(text)** — capsule bg #F2F2F4, text 12/600 #3A3A3F, padding v4 h9 (Today) / v3 h8 (Fuel, Plan). Wrap in a flow layout with spacing 6 (Today) / 5 (Fuel, Plan).

**MacroBar(percent, color)** — height 6 capsule, track #F2F2F4, fill capsule at `percent` width.

**CalorieRing(progress, size, lineWidth, center)** — two `Circle().trim` strokes, track #F2F2F4, progress = accent, `lineCap: .round`, starts at 12 o'clock (rotate -90°).
- Today: 84×84, lineWidth 10, center "28%" 15/800 ink.
- Fuel: 112×112, lineWidth 12, center "1,580" 21/800 ink + "LEFT" 11/600 secondary tracking +0.66, spacing ~2.

**TabBar** (custom floating, hide the system tab bar) — HStack, `.frame(height: 68)`, horizontal padding 8, capsule #111, placed with 20 pt side insets, 28 pt above the bottom edge of the screen (respect home indicator). Items spaced evenly (space-around). Inactive item: 52×52 hit area, icon 22 pt #C7C7CC. Active item: white capsule height 52, padding h18, HStack spacing 8: icon 20 pt + label 14/700, both #111.
Tabs: Today `house` · Plan `calendar` · Fuel `fork.knife` · Progress `chart.bar` (Progress has no screen yet — just a placeholder).

**PrimaryButton(title)** — accent bg, text #111 16/700, height 52, radius 16, full width.

**TimelineRow** — HStack(alignment: .top, spacing: 8):
1. Time column: width 58, text 12/600 secondary, top padding 17 (session row's time is ink).
2. Rail: width 16, VStack centered: node with top padding 19 → circle 12×12 (eaten: filled accent · upcoming: 2 pt #C7C7CC border, filled #F2F2F4 · session: 14×14 filled #111), then a 2 pt wide #DCDCE0 line, 4 pt below node, extending to the row's bottom. **Last row has no line.**
3. Content (fills width), bottom padding 12.

**MealCard** — white, radius 20, padding v14 h16, HStack(alignment: .top, spacing: 12):
- VStack(alignment: .leading): role caps (11/700), name 16/600 (top 2, bottom 8), chips row: "420 kcal", "P 18g", "C 72g", "F 9g".
- Trailing check circle 26×26: eaten = accent fill + `checkmark` 13 pt bold #111; not eaten = 2 pt #D1D1D6 border, clear.

**SessionCard (Today)** — bg #111, radius 24, padding 18, VStack(alignment: .leading, spacing: 14):
- Caps "SESSION · 3 BLOCKS · ~75 MIN" (11/700, #A1A1A6) then title "Speed + Lower" 22/800 white (3 pt below).
- Block rows VStack spacing 10; each HStack spacing 10: icon tile 32×32 radius 10 #2A2A2E with 18 pt white SF Symbol; VStack: name 14/700 white, detail 13/400 #A1A1A6.
- PrimaryButton "Start session" → presents Live Session full-screen.

**MacroCard (Fuel)** — white, radius 20, padding 14: caps label 12/700 · value 24/800 tracking -0.48 with "/126g" 13/500 secondary inline (6 top / 10 bottom) · MacroBar · "106g left" 12/500 secondary, 8 top.

**FoodRow** — HStack spacing 12, padding v12, bottom divider 1 pt #EFEFF2 (not on last row): icon tile 44×44 radius 14 bg #F2F2F4 with 22 pt #111 icon · VStack: name 15/600 (6 below), chips (P/C/F) · trailing VStack(alignment: .trailing): kcal 17/800, time 11/500 secondary. Planned (not eaten) rows: `.opacity(0.55)` and name suffixed " · planned".

**DayCard (Plan)** — white, radius 20, padding v14 h16, HStack spacing 14:
- Date column width 40 centered: weekday 12/600 secondary, date 22/800 (line height ~1.1). For today the weekday reads "Today" in ink.
- Middle: title 16/700 (6 below), chips row.
- Trailing VStack(alignment: .trailing): small LoadBadge, then "2,190 kcal" 12/600 secondary, 6 top.
- Today's card: 2 pt accent inner stroke on the rounded rect.

**LoadBarChart (Plan)** — inside the Day Load card. HStack space-between, bottom-aligned, total height 150. Each column VStack spacing 8: capsule bar width 34 with given height + label 12/600 secondary. Today's bar: 3 pt white ring then 2 pt accent ring around it (two stacked strokes), label 12/800 ink.

---

## 3. Mock data (`MockData.swift`) — use these exact values

Week of Nov 1–7. Today = Wed Nov 4.

| Day | Load | Plan title | Chips | kcal | Bar height |
|---|---|---|---|---|---|
| Sun 1 | Rest | Rest day | Walk + mobility | 1,900 | 18 |
| Mon 2 | High | Speed + Upper | Sprint, Lift | 2,190 | 118 |
| Tue 3 | Moderate | Tempo run | Run · 4 mi, via Strava | 2,110 | 74 |
| Wed 4 (today) | High | Speed + Lower | Sprint, Plyo, Lift | 2,180 | 112 |
| Thu 5 | Low | Mobility + core | Lift, PT-guided (accentTint bg, #7A3A12 text) | 1,980 | 40 |
| Fri 6 | High | Jumps + Pull | Jumps · short approach, Lift | 2,200 | 124 |
| Sat 7 | Low | Easy run | Run · 3 mi | 2,050 | 46 |

Today's meals:
| Time | Role | Name | kcal | P | C | F | Eaten |
|---|---|---|---|---|---|---|---|
| 8:00 AM | Breakfast | Oats & berries bowl | 420 | 18 | 72 | 9 | yes |
| 10:45 AM | Pre-session | Banana & honey | 180 | 2 | 44 | 0 | yes |
| 2:00 PM | Post-session | Chicken & rice | 620 | 52 | 78 | 10 | no |
| 4:30 PM | Snack | Greek yogurt parfait | 310 | 28 | 36 | 6 | no |
| 7:30 PM | Dinner | Salmon & quinoa | 560 | 38 | 48 | 22 | no |

Today's session (12:00 PM), "Speed + Lower":
- Sprint (`bolt`): "4 × 30 m fly @ 95% · 4 min rest"
- Plyo (`arrow.up`): "Pogos + bounds · 60 contacts"
- Lift (`dumbbell`): "Front squat 4 × 3 · Nordics 3 × 5"

Targets: 2,180 kcal · Protein 126 g · Carbs 246 g · Fat 77 g. Eaten: 600 kcal · P 20 · C 116 · F 9.

---

## 4. Screens

### Today (`TodayView`) — light, ScrollView, sections spaced 18
1. **Header**: overline "Wednesday, Nov 4", title "Today". Trailing: 40×40 #111 circle with "M" 15/700 white (profile).
2. **DayStrip**, Wed selected.
3. **Summary card** (white, radius 24, padding 20, VStack spacing 18):
   - Row: LoadBadge "High day" (large) + "Speed + Lower · 12:00 PM" 14/500 secondary, spacing 10.
   - Row (space-between, centered): left VStack: "1,580" hero 46/800, then 6 pt below "kcal to go · 600 of 2,180 eaten" 14/500 secondary. Right: CalorieRing 84 at 28%.
   - 3-column grid, spacing 14. Each: label 12/600 secondary ("Protein", "Carbs", "Fat"), value 17/700 "20" + "/126 g" 13/500 secondary (3 top / 7 bottom), MacroBar. Protein 16% accent · Carbs 47% #F5B700 · Fat 12% #8B5CF6.
4. **Section header** (6 pt extra top): "Your day" 22/800, trailing "5 meals · 1 session" 13/500 secondary, baseline aligned.
5. **Timeline**: Breakfast (eaten) → Pre-session (eaten) → **SessionCard** at "12:00 PM" → Post-session → Snack → Dinner (last, no line).
6. **TabBar** with Today active.

### Fuel (`FuelView`) — light, ScrollView, sections spaced 16
1. **Header**: overline "Goal · Lean gain", title "Fuel". Trailing: LoadBadge "High day" (padding v6 h12).
2. **DayStrip**, Wed selected.
3. **Calorie card** (white, radius 24, padding 22, HStack space-between, centered):
   - Left: caps "CALORIES" (12/700 +0.6) · "600" 52/800 (6 top) · "of 2,180 eaten" 15/500 secondary (4 top) · "Base 1,900 + 280 for today's session" 12/500 secondary (10 top).
   - Right: CalorieRing 112, progress 28%, center "1,580" / "LEFT".
4. **Macro cards**: 3-column grid spacing 10 — Protein 20/126g "106g left" (16%) · Carbs 116/246g "130g left" (47%) · Fat 9/77g "68g left" (12%).
5. **Gap card**: bg #FFF1E8, radius 20, padding v14 h16, HStack spacing 12: VStack — "Plan is 90 kcal short" 14/700 ink, "Add a banana to your 4:30 snack (+105 kcal)" 13/500 #5A4A40 (2 top). Trailing button "Add": height 38, padding h16, capsule #111, text 14/700 white.
6. **Search / Scan row**: 2-column grid spacing 10. Buttons height 50, radius 16, white, HStack spacing 8: icon 18 pt (`magnifyingglass`, `barcode.viewfinder`) + 15/600 ink "Search foods" / "Scan barcode".
7. **Food list card**: white, radius 24, padding top 6 / sides 18 / bottom 4. Header row padding v12/4: "Today's food" 20/800 + trailing "2 eaten · 3 planned" 13/500 secondary. Then 5 FoodRows (same meals; last 3 at 55% opacity with " · planned"). Icons: `takeoutbag.and.cup.and.straw` or `cup.and.saucer` for oats (any bowl-like), `leaf` for banana, `fork.knife` for chicken & rice, `cup.and.saucer` for parfait, `fish` for salmon.
8. **Floating "+" button**: 60×60 accent circle, `plus` 26 pt bold #111, 24 pt from the right edge, 112 pt above the bottom of the screen (sits just above the tab bar), with the one shadow.
9. **TabBar** with Fuel active.

### Plan (`PlanView`) — light, ScrollView, sections spaced 14
1. **Header**: overline "Nov 1 – Nov 7", title "This week". Trailing: 44×44 accent circle with `plus` 22 pt bold #111 (add session).
2. **Day Load card** (white, radius 24, padding 20, VStack spacing 16):
   - Row: "Day Load" 17/800 + trailing "3 high · 2 moderate-low · 1 rest" 13/500 secondary.
   - LoadBarChart with day letters S M T W T F S and heights from the table; bar color = load fill.
   - Legend HStack spacing 14 (wrap): 10×10 circle + label 12/600 #3A3A3F for High, Moderate, Low, Rest.
3. **Seven DayCards**, Sun → Sat, from the week table. Wed card: weekday text "Today", accent 2 pt stroke.
4. **TabBar** with Plan active.

### Live Session (`LiveSessionView`) — ALWAYS DARK, full-screen cover, no tab bar, sections spaced 14, bg #0B0B0C, horizontal padding 20
1. **Top bar** (space-between, centered): back button 40×40 circle #1C1C1F with `chevron.left` 20 pt white (dismisses) · timer "18:42" 17/700 monospaced white · "Finish" button height 40, padding h18, capsule #1C1C1F, 14/700 white.
2. **Title block**: "Speed + Lower" 26/800 tracking -0.52 white · "Block 1 of 3 · Sprint" 13/600 #A1A1A6 (4 top) · segmented progress (10 top): 3 equal capsules height 5, spacing 6, track #2A2A2E; first segment 55% filled accent.
3. **Block card**: bg #151517, radius 22, padding 16, VStack spacing 8:
   - Header row (space-between, top aligned, 4 bottom): "30 m fly @ 95%" 18/800 white + "Target 3.05 s · PR 2.90 s (FAT)" 13/500 #A1A1A6 (3 top). Trailing pill "Rest 0:48": capsule #2A2A2E, padding v6 h11, 12/700 #D1D1D6 monospaced.
   - Rep rows (radius 16, bg #1C1C1F, padding v11 h14, HStack spacing 12): rep label width 52, 13/600 #A1A1A6 · value 20/800 white, fills width · trailing meta.
     - Rep 1: "3.08 s", trailing "Hand · +0.8" 12/600 #A1A1A6
     - Rep 2: "3.03 s", trailing badge "On target" (accent capsule, padding v3 h8, 11/800 #111)
     - Rep 3 (active): bg #1F1A17 + 2 pt accent inner stroke; label white; value "3.0" 30/800 + "_" in #5A5A60; trailing "s" 12/600 #A1A1A6
     - Rep 4: opacity 0.45, value "—" #8E8E93
4. **Pills row** (spacing 8): "Hand" (selected: white bg, #111 text), "FAT", "Laser", then spacer, "Wind +1.2". Pills: height 36, padding h14, capsule #1C1C1F, 13/600 #D1D1D6.
5. **Number pad**: 3-column grid spacing 8; keys height 56, radius 16, bg #1C1C1F, 24/700 white: 1–9, ".", 0, delete (`delete.left` 24 pt).
6. **Save button**: "Save rep · start rest", height 56, radius 18, accent, 17/800 #111, full width.

---

## 5. Navigation
- Root: custom TabBar switching Today / Plan / Fuel (Progress = empty placeholder for now).
- "Start session" on Today → `.fullScreenCover` LiveSessionView; back chevron and Finish dismiss it.

## 6. Done = all of these are true
- [ ] Side-by-side with the HTML mockups, spacing, sizes and colors match within 1–2 pt.
- [ ] Orange appears only on actions/progress/today highlights; blue only on load.
- [ ] No system tab bar visible; floating capsule tab bar matches.
- [ ] Every screen has a `#Preview` with MockData.
- [ ] Inter font actually loads (check: the "1,580" hero is heavy and tight, not SF).
