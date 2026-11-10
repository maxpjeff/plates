# Plates

iOS app for planning lifting and eating together — local-first SwiftUI + SwiftData.

## Open in Xcode

1. Open `Plates.xcodeproj`.
2. Scheme **Plates** → iPhone simulator → **⌘R**.

Regenerate after editing `project.yml`:

```bash
xcodegen generate
```

## Spec and design

- Product spec: [PLATES_SPEC.md](PLATES_SPEC.md)
- Agent rules: [.cursor/rules/plates.mdc](.cursor/rules/plates.mdc)
- Mockups: add PNGs to `design/` (see spec Part 3 kickoff list)

## Phase 0 (current)

Foundation: design system, five-tab shell, SwiftData models, seed exercises/foods. Preview **DesignGalleryView** in Xcode for component QA.

## TestFlight (install on your iPhone)

Step-by-step: [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md) — Apple Developer ($99/yr), App Store Connect, one Archive upload from Xcode.

## GitHub

https://github.com/maxpjeff/plates
