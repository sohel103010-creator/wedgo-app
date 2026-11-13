# WedGo — Flutter App (Android)

Production Flutter client for the WedGo 18+ matrimony platform.
Backend: Supabase (PostgreSQL + Auth + Realtime + Storage + Edge Functions).
Bangla-first UI, Riverpod state, WebRTC calls, FLAG_SECURE on sensitive screens.

**Package:** `com.wedgo.matrimony` — never change after Play release.

## 1. Prerequisites

- Flutter SDK ≥ 3.22 (Dart ≥ 3.3)
- Android SDK 34, JDK 17
- A Supabase project with the migrations in `../supabase/migrations/` applied
  and the Edge Functions in `../supabase/functions/` deployed.

## 2. Configure (no hardcoded secrets — and no rebuild required)

**Option A — in-app Setup screen (recommended for a prebuilt APK):**
install the APK, and on first launch paste `SUPABASE_URL` and
`SUPABASE_ANON_KEY` into the Setup screen. Values are stored in secure
storage, a connection test runs, and the app connects immediately.
Change them anytime via **Settings → Backend Setup**.

**Option B — build-time defaults via `--dart-define`:**

```bash
export SUPABASE_URL="https://xyzcompany.supabase.co"
export SUPABASE_ANON_KEY="eyJ..."
```

Resolution order: secure-storage override → `--dart-define` defaults →
Setup screen. The Setup screen can always override build defaults.

## 3. Install / analyze / test

```bash
cd flutter
flutter pub get
flutter analyze
flutter test   # (add widget tests under test/ as features land)
```

## 4. Run (debug)

```bash
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

## 5. Release builds

```bash
# Debug APK (for device testing)
flutter build apk --debug \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Signed release APK — requires keystore env (see §8)
flutter build apk --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Play Store App Bundle
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# Checksums
sha256sum build/app/outputs/flutter-apk/app-release.apk \
          build/app/outputs/bundle/release/app-release.aab
```

## 6. Backend setup (Supabase)

1. Create a project at https://supabase.com, then run every migration in
   `../supabase/migrations/` **in filename order** (Supabase CLI or SQL editor).
2. Deploy Edge Functions: `send-message`, `initiate-call`, `end-call`,
   `approve-payment`, `request-withdrawal` (+ `resolve-login`, see §7).
3. Create Storage buckets (private): `profile-images`, `verification-files`,
   `chat-media`, `payment-proofs`, `support-attachments` — see migration `010`.
4. Seed packages/tiers/payment numbers via the seed script in
   `../supabase/` (admin-editable afterwards; the app never hardcodes prices).
5. The app reads `packages`, `payment_settings`, `webrtc_config` at runtime —
   no app release needed to change pricing or payment numbers.

## 7. REQUIRED external pieces (never faked — clear setup states in-app)

| Feature | Status without setup |
|---|---|
| Phone+password login | Shows "requires setup" — needs the `resolve-login` Edge Function.<br>**Contract:** `POST {phone}` → `{email}` or `{error:"not_found"}`.<br>It must use the service role and never enumerate users to callers (rate-limit). Email+password login works without it. |
| Push notifications (FCM) | App runs without push; `fcm_token` stays null (no fake tokens). Add `firebase_messaging`, `google-services.json`, and follow the Firebase console setup to enable. |
| Admin Google Sign-In | Needs `GOOGLE_WEB_CLIENT_ID` (`--dart-define`) **and** the Google provider enabled in Supabase Auth with the same web client ID. Role check is server-side (`is_admin` RPC) — no email hardcoded. |
| TURN server | `webrtc_config.turn_*` empty by default → P2P via STUN only. Add a TURN (e.g. coturn/cloud) credential row for production reliability. |

## 8. Release signing (keystore)

Generate once, back up securely, **never commit**:

```bash
keytool -genkeypair -v -keystore ~/wedgo-release.keystore \
  -alias wedgo -keyalg RSA -keysize 2048 -validity 9125
```

Then build with:

```bash
export WEDGO_KEYSTORE=~/wedgo-release.keystore
export WEDGO_KEY_ALIAS=wedgo
export WEDGO_STORE_PASSWORD='...'
export WEDGO_KEY_PASSWORD='...'
flutter build appbundle --release --dart-define=...
```

Use the **same keystore + `com.wedgo.matrimony`** for every future release
so updates preserve users/data. Play Console: upload the `.aab`.

## 9. Play Store notes

- `versionCode`/`versionName`: bump in `pubspec.yaml` (`1.0.0+1` → `1.0.1+2`…).
- 64-bit: Flutter builds arm64 + x86_64 by default. ✅
- Target SDK 34 (update as Play requires).
- Data safety form + 18+ (Mature) content rating required (matrimony/dating).
- Camera/mic permission purpose is declared in-app at call time and in the
  Play listing; POST_NOTIFICATIONS is requested on first relevant event.
- Privacy policy URL: publish the `privacy` legal page (editable in admin CMS).

## 10. Screenshots / screen recording protection

`CallScreen` and `VerificationScreen` enable Android `FLAG_SECURE` via the
`wedgo/secure` MethodChannel in `MainActivity.kt`. No perfect prevention on
rooted devices or external cameras — documented in-app where relevant.

## 11. Project layout

```
lib/
  main.dart  app.dart  config.dart
  l10n/strings.dart            # bn/en maps — add locales here
  models/                      # profile, package, subscription, message, call
  services/                    # supabase_client, api (Edge Function wrappers)
  providers/                   # auth, packages, subscription (Riverpod)
  utils/age_gate.dart           # hard 18+ check (server re-validates)
  widgets/                     # blurred_card, premium_gate, secure_screen
  screens/                     # 18 screens (splash → admin_login)
android/                       # com.wedgo.matrimony, permissions, FLAG_SECURE
```

## 12. Known gaps / next steps

- Backend migrations currently lack: `handle_new_user` trigger (or users
  INSERT policy) and INSERT policies on `conversations`/`conversation_members`.
  Registration and new-chat creation surface clear "requires setup" errors
  until these are added — see code comments in `register.dart` /
  `profile_detail.dart`.
- `resolve-login` Edge Function not yet deployed (phone login shows setup state).
- FCM wiring not yet added (documented above; token stays null until then).
- Incoming-call push: receiver currently learns via Realtime `calls` subscription;
  wire FCM data messages for background wake-up.
- Add widget tests under `test/`; run `flutter test` in CI.
- Bundle Noto Sans Bengali under `assets/fonts/` for fully offline typography
  (system fonts render Bangla correctly on stock Android in the meantime).
