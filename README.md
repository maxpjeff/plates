# Plates

iOS app for meal plans, meal logging, workout plans, and workouts — built to stay in sync day by day.

## Open in Xcode

1. Open `Plates.xcodeproj`.
2. Select the **Plates** scheme and an iPhone simulator.
3. **Product → Run** (⌘R).

### Regenerate the Xcode project

After changing `project.yml`:

```bash
xcodegen generate
```

## Supabase

1. Create a project at [supabase.com](https://supabase.com).
2. Copy `Config/Secrets.example.xcconfig` → `Config/Secrets.xcconfig`.
3. Paste **Project URL** and **anon public** key from Supabase → Project Settings → API.
4. Rebuild the app. The **Today** tab hides the setup hint when keys are valid.

Never commit `Secrets.xcconfig`.

## GitHub

Remote: https://github.com/maxpjeff/plates
