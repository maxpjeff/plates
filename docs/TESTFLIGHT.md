# TestFlight setup for Plates

TestFlight lets you install Plates on your iPhone without keeping Xcode open every day. You still need **one Mac session** to enroll, sign, and upload the first build (or use GitHub Actions later so uploads happen in the cloud).

**Bundle ID:** `com.maxpjeff.plates`  
**App name:** Plates

---

## 1. Apple Developer Program (required)

1. Go to [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll).
2. Enroll as an **Individual** (or Organization if you have a company).
3. Pay **$99 USD / year** and wait for approval (often same day, sometimes 24–48 hours).

You need this for TestFlight and App Store distribution. A free Apple ID alone only runs on your own device via USB from Xcode—it does **not** enable TestFlight.

---

## 2. App Store Connect — create the app

1. Sign in at [appstoreconnect.apple.com](https://appstoreconnect.apple.com).
2. **Apps** → **+** → **New App**.
3. **Platforms:** iOS  
4. **Name:** Plates  
5. **Primary language:** English (U.S.)  
6. **Bundle ID:** pick **com.maxpjeff.plates**  
   - If it’s missing: [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) → **+** → **App IDs** → **App** → description `Plates`, bundle ID **Explicit** `com.maxpjeff.plates` → enable any capabilities you need later (none required for v1).
7. **SKU:** `plates-ios` (any unique string you’ll never change).
8. **User access:** Full access.

You do **not** need screenshots or full App Store listing to use TestFlight.

---

## 3. Signing on your Mac (one-time)

### A. Team ID in the project

1. On the Mac, open **Xcode** → **Settings** → **Accounts** → add your Apple ID → select your **Team**. Note the **Team ID** (10 characters, e.g. `AB12CD34EF`).

2. In the Plates repo:

```bash
cp Config/Signing.example.xcconfig Config/Signing.xcconfig
```

3. Edit `Config/Signing.xcconfig` and set:

```
DEVELOPMENT_TEAM = YOUR_TEAM_ID_HERE
```

4. Regenerate the Xcode project:

```bash
cd ~/Projects/plates
xcodegen generate
```

5. Open `Plates.xcodeproj` → select **Plates** target → **Signing & Capabilities**:
   - **Automatically manage signing:** ON  
   - **Team:** your team  
   - Confirm bundle ID **com.maxpjeff.plates**

### B. If signing errors

- **“Failed to register bundle identifier”** — create the App ID in the developer portal (step 2).
- **“No profiles found”** — leave automatic signing on; Xcode creates them.

---

## 4. Upload the first build (slow Mac tips)

1. In Xcode, device selector → **Any iOS Device (arm64)** (not a simulator).
2. **Product → Archive** (Release). First archive can take several minutes on a slow Mac—plug in power, close other apps.
3. When the **Organizer** opens → **Distribute App** → **App Store Connect** → **Upload** → follow prompts (defaults are fine).
4. **Export compliance:** Plates sets `ITSAppUsesNonExemptEncryption = NO` (standard HTTPS only)—in Connect you can usually answer **No** for custom encryption.

Processing in App Store Connect: **15–45 minutes** (sometimes up to a few hours). You’ll get an email when the build is ready.

---

## 5. Install on your iPhone

1. Install **TestFlight** from the App Store on your phone.
2. In App Store Connect → **Apps** → **Plates** → **TestFlight**.
3. **Internal Testing** → **+** → add your Apple ID email as an **internal tester** (up to 100, no beta review).
4. Open the email on your phone → **View in TestFlight** → **Install**.

Internal builds are the fastest path for just you (and family on the team).

**External testers** (friends, public link) need a short **Beta App Review** the first time—skip until you want that.

---

## 6. Every new version you upload

Before each upload, bump the build number in `project.yml`:

```yaml
CURRENT_PROJECT_VERSION: "2"   # increment: 3, 4, 5…
# MARKETING_VERSION: "1.0.0"  # user-facing version when you ship features
```

Then:

```bash
xcodegen generate
```

Archive → Upload again (step 4). TestFlight updates on your phone from the TestFlight app.

---

## 7. Optional: upload from GitHub (spares your Mac)

After the first manual upload works, you can add CI so **push to GitHub** builds on Apple’s servers in the cloud:

- **Xcode Cloud** (App Store Connect → **Xcode Cloud** → connect repo `maxpjeff/plates`) — easiest if you use GitHub.
- **GitHub Actions** on `macos-latest` with App Store Connect API key — see [Apple’s CI docs](https://developer.apple.com/documentation/appstoreconnectapi).

Say **“set up Xcode Cloud”** or **“GitHub Action for TestFlight”** in Cursor when you’re ready; that needs your Team ID and an App Store Connect API key (.p8).

---

## Checklist

- [ ] Apple Developer Program active  
- [ ] App **Plates** in App Store Connect with bundle `com.maxpjeff.plates`  
- [ ] `Config/Signing.xcconfig` with Team ID  
- [ ] **Archive → Upload** succeeded  
- [ ] Internal tester added; TestFlight installed on iPhone  

---

## Windows + Cursor workflow (unchanged)

Edit on Windows → **push** → on Mac (when you can): **pull** → bump build if needed → **Archive → Upload**. Or use cloud CI so you rarely archive locally.
