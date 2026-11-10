# Pixel UI rebuild — instructions for Cursor

We are rebuilding the app's LOOK from a clean slate using a ready-made pixel UI kit (this folder).
The design is already written in SwiftUI in `Swift/`. Your job is to add the kit, delete the old
pixel UI, and connect the kit's screens to the app's EXISTING logic. Do not redesign anything.

Work through the steps in order. Build and run after every step.

---

## Rules (read first)

1. Do NOT change the look of anything in `Swift/Px*.swift`. No new sizes, colors, fonts, corner radii or spacing.
   The only allowed edits to those files are fixes for compile errors (these files were written without
   a compiler, so a small fix may be needed). Keep every fix minimal and tell me what you changed.
2. Never use: `cornerRadius`, `RoundedRectangle`, `Capsule`, `Circle` (except iOS-forced widget shapes),
   SF Symbols (`Image(systemName:)`), `.font(.system...)`, `.font(.title)` etc., or colors not in `Px`.
3. All text uses `PxFont`. All colors use `Px` or `PxStatus`. All boxes use `.pixelBox(...)`.
   All buttons use `PixelButtonStyle`, `PixelPrimaryButton` or `PixelIconButton`. All icons use `PixelIcon`.
4. Keep ALL existing logic: status rules (day-based), streak, notifications, storage, camera session,
   photo picking, widget timeline, rest-day settings, onboarding flow. Only the views change.
5. If something is too tall on small iPhones, the ONLY allowed fix is lowering the `PixelScene` height on Home
   (240 → 190) and the Fed `hero` height (290 → 240).

---

## Step 1 — Clean slate

- Delete (or move into an `_old` folder excluded from the targets) every view, modifier and style that was
  created for the previous pixel attempt: old pixel boxes, grid backgrounds, segmented bars, pixel icons,
  pixel buttons, restyled Home/Camera/Fed/History views.
- Do NOT delete: the status/streak engine, data models, storage, camera session/capture code, PhotosPicker
  logic, notification scheduling, the widget timeline provider/snapshot code, onboarding and settings logic.
- Remove Fredoka/Nunito font files and any old font helpers.

## Step 2 — Add the kit

**Swift files (`Swift/`)**
| File | Targets |
| --- | --- |
| PxTheme.swift | App + Widget |
| PxComponents.swift | App + Widget |
| PxHomeView.swift | App |
| PxCameraView.swift | App |
| PxFedView.swift | App |
| PxHistoryView.swift | App |
| PxWidgetViews.swift | Widget only |

**Fonts (`Fonts/`)** — add all 4 files to App + Widget targets, and list them in BOTH Info.plists under
"Fonts provided by application" (UIAppFonts):
`PixelifySans-Regular.ttf`, `PixelifySans-Medium.ttf`, `PixelifySans-SemiBold.ttf`, `PixelifySans-Bold.ttf`
Their PostScript names are already correct: `PixelifySans-Regular`, `PixelifySans-Medium`,
`PixelifySans-SemiBold`, `PixelifySans-Bold`.

**Icons (`Icons/`)** — drag the 9 SVGs into Assets.xcassets (shared by App + Widget). For EACH image set:
Attributes inspector → **Preserve Vector Data: ON**, **Render As: Original Image**, **Scales: Single Scale**.
Names must stay exactly: `pixel_flame`, `pixel_gear`, `pixel_camera`, `pixel_calendar`, `pixel_back`,
`pixel_close`, `pixel_check`, `pixel_flip`, `pixel_photos`. (The PNGs are only a visual reference.)

**Sprites (`Sprites/`)** — replace the 8 capybara image sets with these files (same names):
`capy_locked_in`, `capy_recovering`, `capy_couch_mode`, `capy_streak_lost` and the 4 `_tint` versions.
Render As: Original Image. App + Widget targets.

## Step 3 — Verify fonts

Call `PxFont.debugCheck()` once at app launch (DEBUG only). All 4 lines must print `OK`.
If any says `MISSING`, the file isn't in the target or isn't listed in Info.plist. Fix before continuing:
otherwise SwiftUI silently falls back to the system font.

Then open the `#Preview`s in PxHomeView, PxCameraView, PxFedView and PxHistoryView. They must show the
pixel font, the capybara sprites, notched-corner boxes and the graph-paper background.

## Step 4 — Connect the status

The kit uses `PxStatus` (`.lockedIn`, `.recovering`, `.couchMode`, `.streakLost`). Add one mapping
function from the existing status type, e.g.:

```swift
extension PxStatus {
    init(_ s: AvatarState) {
        switch s {
        case .lockedIn: self = .lockedIn
        case .recovering: self = .recovering
        case .couchMode: self = .couchMode
        case .streakLost: self = .streakLost
        }
    }
}
```

The labels (LOCKED IN, RECOVERING, COUCH MODE, CHUD), sprites and colors all come from `PxStatus`.

## Step 5 — Replace the screens

**Home** → `PxHomeView(model:onFeed:onHistory:onSettings:)`. Build `PxHomeModel` from the existing view model:
- `name`: capybara name
- `dateLine`: today formatted `"EEEE, MMM d"` (the view uppercases it)
- `status`: `PxStatus(currentStatus)`
- `streak`: current streak
- `caption`: Locked in → `"Posted at 6:42 PM"` (time of today's last post) · Recovering → `"Rest day. Enjoy it."` ·
  Couch mode → `"Haven't posted today"` · Chud → `"One photo starts a new streak"`
- `todayFraction`: Locked in / Recovering → `1` · Couch mode → hours left until midnight ÷ 24 · Chud → `0`
- `todayText`: `"Done for today"` / `"Rest day"` / `"8 hrs left today"` / `"Streak lost"`
- `last7`: the last 7 days, oldest → today, `PxDay(letter: "M", kind: ...)`:
  past day with a post → `.posted`, rest day → `.rest`, missed workout day → `.missed`,
  today posted → `.todayPosted`, today not posted → `.today`
- Keep the existing 60-second refresh / foreground refresh so the model stays current.

**Camera** → `PxCameraView(...) { <existing live camera preview> }`
- Pass the existing AVCaptureVideoPreviewLayer `UIViewRepresentable` as the trailing `preview` closure.
- `lastPhotoThumbnail`: newest photo from the library if available, otherwise nil.
- `cameraAvailable`: false when camera permission is denied.
- `onShutter` → existing capture; `onLibrary` → present the existing PhotosPicker; `onFlip` → switch camera;
  `onOpenSettings` → open `UIApplication.openSettingsURLString`; `onClose` → dismiss.
- After a photo is taken or picked, keep the existing confirm step but style it: full-screen photo on
  `PixelBackground(dark: true)`, bottom row with two buttons side by side:
  `Button("Retake")` using `PixelButtonStyle(fill: Px.card, size: .large)` with `PxFont.button` text, and
  `PixelPrimaryButton(title: "Feed <Name>", icon: "pixel_camera")`.

**Fed** → `PxFedView(model:onDone:)` with `PxFedModel`:
- `photo`: the photo just posted (`Image(uiImage:)`)
- `timeText`: `"EEE h:mm a"` (e.g. "Mon 6:42 PM")
- `dayNumber` and `streak`: the new streak day
- `subtitle`: `"Locked in for today. See you tomorrow."`, or `"Locked in. Enjoy your rest day tomorrow."`
  if tomorrow is a rest day, or `"Day 1. New streak started."` for a new streak.

**History** → `PxHistoryView(model:...)` with `PxHistoryModel`:
- `streak`, `best`, `totalFeeds`
- `monthTitle` ("November"), `monthFeeds` (posts this month)
- `leadingBlanks`: weekday index of day 1 (Sunday = 0)
- `days`: one `PxDayKind` per day of the month (same mapping as Home; days after today → `.future`)
- `recent`: newest posts first (`Image(uiImage:)` + label "Today" / weekday short name)
- Wire prev/next month and `onSelectFeed` to the existing full-screen photo view (style that view with
  `PixelBackground(dark: true)`, a `PixelIconButton(icon: "pixel_close", ...)` and the delete action as a
  `PixelButtonStyle(fill: Px.pinkSoft, size: .small)` button).

## Step 6 — Widgets

- In the widget's entry view, build a `PxWidgetModel` from the existing snapshot and return
  `PxWidgetEntryView(model:)`. Field mapping is the same as Home, plus:
  `shortText`: `"DONE"` / `"REST"` / `"8H"` (hours left until midnight) / `"LOST"`,
  `last7Letters`: weekday letters for the same 7 days.
- On the WidgetConfiguration add `.contentMarginsDisabled()` and keep
  `.supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])`.
- Remove any old widget views.

## Step 7 — Onboarding & Settings (restyle with the kit, same flow and copy)

Use only kit pieces:
- Background: `PixelBackground()`.
- Titles `PxFont.screenTitle`, body `PxFont.body`, captions `PxFont.caption` in `Px.textSecondary`.
- Capybara images: `CapySprite(status: ..., maxHeight: 220)` (step 1 uses `.lockedIn`, the reminders step uses `.couchMode`).
- Progress indicator: 5 squares, 10×10 pt, 6 pt apart — current = `Px.orange` with `.pixelBox(fill: Px.orange, size: .widget)`,
  others = `Px.segmentEmpty`.
- Name text field: `TextField` with `PxFont.make(24, .bold)`, padding 14, `.pixelBox(fill: Px.card, size: .small)`.
- Name suggestion chips and the 7 weekday chips: square `Button`s, 40×40 for weekdays, using
  `PixelButtonStyle(fill: selected ? Px.orange : Px.card, size: .small)` with `PxFont.make(18, .bold)` text.
- Primary actions: `PixelPrimaryButton(title: ..., icon: nil, ...)`.
  Secondary text buttons ("Not now", "No rest days"): plain `Button` with `PxFont.make(17, .semibold)`, `Px.textSecondary`, underlined.
- Settings rows: each row is an `HStack` inside `.pixelBox(fill: Px.card, size: .large)` with 14 pt padding;
  toggles use `.tint(Px.orange)`. "Start over" uses `PixelButtonStyle(fill: Px.pinkSoft, size: .small)`.
- Back/close buttons: `PixelIconButton(icon: "pixel_back" / "pixel_close", ...)`.

## Done when

- [ ] `PxFont.debugCheck()` prints OK for all 4 weights, and no text anywhere looks like the system font.
- [ ] Every screen and widget uses the graph-paper background, notched-corner boxes and pixel icons.
- [ ] No rounded corners, capsules, circles or SF Symbols remain in the app UI.
- [ ] Capybara sprites are sharp at every size and never cropped (the couch sprite fits fully).
- [ ] Home, Camera, Fed and History match their `#Preview`s.
- [ ] All behavior is unchanged: day-based statuses (including CHUD), streak, 12 PM reminder, camera + photo library, rest days.
