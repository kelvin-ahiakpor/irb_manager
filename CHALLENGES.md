# Implementation Challenges

A record of bugs, root causes, and fixes encountered during development of the Ashesi IRB Manager mobile app.

---

## Local Resources

Local resources are device-side storage mechanisms that persist data without a network connection. The IRB Manager uses two:

### Hive
**Docs:** https://docs.hivedb.dev

Hive is a lightweight key-value store for Flutter. It stores data as boxes (like tables) containing key-value pairs. Data persists on the device after the app is closed. Used in this app for:
- Caching the applications list so the reviewer dashboard works offline
- Queuing status updates made while offline so they sync when connectivity returns
- (Planned) Storing reviewer identity so the app can skip login when offline

**How it's used here:**
- `Hive.initFlutter()` and `Hive.openBox('irb_cache')` called in `main.dart` before the app starts
- `reviewer_dashboard_model.dart` has helpers: `cacheApplications()`, `loadCachedApplications()`, `enqueueStatusUpdate()`, `loadQueue()`, `clearQueue()`
- Cache key: `applications` — stores JSON-encoded list of application maps
- Queue key: `status_update_queue` — stores JSON-encoded list of pending status updates

### SharedPreferences
Used internally by `supabase_flutter` to persist the PKCE code verifier across the OAuth browser redirect. Not used directly by app code.

---

## 1. Syntax Error Crashing the Entire App

**Phase affected:** Phase 3 (Reviewer Dashboard)

**Symptom:** App crashed immediately on launch with "ashesi irb manager keeps stopping." No Dart output — the process died before the Flutter engine could connect.

**Root cause:** A `children: [` list inside a `Row` widget in `reviewer_dashboard_widget.dart` (line ~260) was never closed. The missing `],` and `),` caused a compile error that propagated silently through all subsequent commits, meaning every phase built on top of it inherited the crash.

**Discovery method:** `git bisect` — binary searched 20 commits in 4 steps to isolate the exact first bad commit (`b7b22a2`).

**Fix:** Added the missing `],` and `),` to close the Row's children list before the Column's `.divide()` call.

---

## 2. Deprecated API: `app_links` Package

**Phase affected:** Phase 7 (Microsoft OAuth Login)

**Symptom:** Build error — `The method 'getInitialAppLink' isn't defined for the type 'AppLinks'`.

**Root cause:** The `app_links` package upgraded from v5.x to v6.x, which renamed `getInitialAppLink()` to `getInitialLink()`. The code was written against the old API.

**Fix:** Renamed all calls from `appLinks.getInitialAppLink()` to `appLinks.getInitialLink()` in `lib/main.dart`.

---

## 3. Deprecated API: `LaunchMode.externalBrowser`

**Phase affected:** Phase 7 (Microsoft OAuth Login)

**Symptom:** Build error — `Member not found: 'externalBrowser'`.

**Root cause:** The `url_launcher` package renamed `LaunchMode.externalBrowser` to `LaunchMode.externalApplication` in a minor version update. The old name was used in `login_widget.dart` for launching the Microsoft OAuth flow.

**Fix:** Updated `LaunchMode.externalBrowser` → `LaunchMode.externalApplication` in `lib/login/login_widget.dart`.

---

## 4. Firebase Crashing on Web Platform

**Phase affected:** Phase 8 (Push Notifications / Firebase)

**Symptom:** Web build crashed at startup with `FirebaseOptions cannot be null`. Firebase requires platform-specific configuration files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS) which don't apply to web.

**Root cause:** `Firebase.initializeApp()` and `FirebaseMessaging` were being called unconditionally in `main()` and `login_widget.dart`, including on the web platform where no Firebase config exists.

**Fix:** Wrapped all Firebase and FCM calls in `if (!kIsWeb)` guards using `package:flutter/foundation.dart`'s `kIsWeb` constant.

---

## 5. Package Name Mismatch with Firebase

**Phase affected:** Phase 8 (Firebase Setup)

**Symptom:** Gradle build failed — `No matching client found for package name 'com.mycompany.ashesiirbmanager' in google-services.json`.

**Root cause:** The original FlutterFlow project used the default package name `com.mycompany.ashesiirbmanager`. Firebase was registered under a new package name `com.ashesi.ashesi_irb_manager`. The `build.gradle` and `AndroidManifest.xml` still had the old name.

**Fix:** Updated `namespace`, `applicationId` in `android/app/build.gradle` and `package` in `AndroidManifest.xml` to `com.ashesi.ashesi_irb_manager`.

---

## 6. FCM Legacy Server Key Deprecated

**Phase affected:** Phase 8B (Push Notifications)

**Symptom:** Push notifications not delivered; HTTP 401 from Firebase FCM endpoint.

**Root cause:** Firebase deprecated the legacy FCM server key API in June 2024. The original implementation used the old `https://fcm.googleapis.com/fcm/send` endpoint with a server key, which no longer works.

**Fix:** Switched to FCM v1 API (`https://fcm.googleapis.com/v1/projects/{project}/messages:send`) with OAuth2 JWT authentication using a Firebase service account. The service account JSON was base64-encoded and stored as a Supabase Edge Function secret to avoid newline issues with the private key.

---

## 7. Gradle Cache Corruption

**Phase affected:** During development iteration

**Symptom:** Build failed with `Cannot invoke "org.gradle.cache.FileLock.writeFile(...)" because the return value ... is null`. The error pointed to Flutter's internal Gradle build file, not project code.

**Root cause:** Gradle's local cache became corrupted after repeated interrupted builds and branch switches. This is a known issue with the Android Gradle plugin when builds are killed mid-execution.

**Fix:** `cd android && ./gradlew --stop && cd .. && flutter clean && flutter run`

---

## 8. Vercel Blank Page (Flutter Web SPA Routing)

**Phase affected:** Web deployment

**Symptom:** Navigating directly to any route (e.g. `/webSubmissionForm`) on the Vercel deployment returned a blank page or 404.

**Root cause:** Flutter web compiles to a single-page application where all routing is handled client-side by GoRouter. Vercel's default behaviour serves a 404 for any path that doesn't map to a static file.

**Fix:** Added a `vercel.json` file in `build/web/` with a catch-all rewrite rule:
```json
{ "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }] }
```

---

## 9. Firebase Incompatibility with Android 16 (API 36)

**Phase affected:** Phase 8 (Firebase / Push Notifications)

**Symptom:** App installs successfully but crashes immediately on launch — "ashesi irb manager keeps stopping." The Flutter debug connection never establishes, meaning the crash occurs before any Dart code runs.

**Root cause:** Firebase has a native `FirebaseInitProvider` ContentProvider that auto-initializes before `main()` is called. Android 16 (API 36) is still in developer preview, and Firebase BoM 34.11.0 appears to crash during this native initialization on that API level. The same code runs correctly on API 34.

**Options considered:**
- Test on API 34 emulator (confirmed fix)
- Disable Firebase entirely and rely on email/SMS notifications only (note as known limitation)
- Replace with `flutter_local_notifications` (in-app only — cannot trigger remotely when app is closed)

**Current decision:** Firebase removed while debugging. The crash was later confirmed to be caused by a wrong `MainActivity.kt` path (see Challenge #10), not Firebase itself. Firebase has not been re-added yet — push notifications remain a known limitation for now. Future path: re-add Firebase with correct package setup, or use `flutter_local_notifications` with a background service.

---

## 10. Wrong MainActivity.kt Package Path (Real Root Cause of App Crash)

**Phase affected:** Phase 8 (package name change)

**Symptom:** App installed successfully but crashed immediately on every launch — "ashesi irb manager keeps stopping." Flutter debug connection never established. Blamed on Firebase for a long time.

**Root cause:** When the Android package name was changed from `com.mycompany.ashesiirbmanager` to `com.ashesi.ashesi_irb_manager`, the `build.gradle`, `AndroidManifest.xml`, and `debug/AndroidManifest.xml` were all updated — but the `MainActivity.kt` file was never moved to the matching directory. It remained at `kotlin/com/mycompany/ashesi_irb_manager/MainActivity.kt` with the wrong package declaration, while Android was looking for `com.ashesi.ashesi_irb_manager.MainActivity`. Android couldn't find the app's entry point and crashed before any Flutter code ran.

**Why it was hard to find:** The crash happened before Dart started, producing no Flutter output — only "keeps stopping." Firebase was added around the same time and was wrongly suspected as the cause. Two emulator API levels (34 and 36) were tested, Firebase was removed entirely, and multiple other fixes were attempted before the Kotlin file path was checked.

**Fix:** Created `MainActivity.kt` at the correct path `kotlin/com/ashesi/ashesi_irb_manager/MainActivity.kt` with the correct package declaration.

**Lesson:** When changing an Android package name in Flutter, four things must all match:
1. `namespace` and `applicationId` in `android/app/build.gradle`
2. `package` attribute in `android/app/src/main/AndroidManifest.xml`
3. `package` attribute in `android/app/src/debug/AndroidManifest.xml`
4. The `package` declaration and **folder path** of `MainActivity.kt`

---

## 11. Microsoft OAuth — PKCE Flow State Not Found

**Phase affected:** Reviewer login (Azure OAuth)

**Symptom:** After Microsoft sign-in succeeds and the deep link callback arrives with `?code=...`, Supabase throws `AuthApiException: invalid flow state, no valid flow state found (404, flow_state_not_found)`. App signs the user out and returns to login screen.

**Root cause (ongoing investigation):** Supabase uses PKCE flow for OAuth. When `signInWithOAuth` is called, a code verifier is stored and a flow state is created server-side. When the app receives the deep link callback, `exchangeCodeForSession` must match the code to that flow state. The flow state is not being found — possible causes:
- The flow state expired between OAuth initiation and callback
- The PKCE code verifier stored in SharedPreferences is lost when Android kills and restarts the app process during the external browser redirect
- The deep link is being handled twice (removed our manual `app_links` handler — supabase_flutter handles it internally — but the error persists)

**Steps taken so far:**
- Fixed wrong redirect URL in `signInWithOAuth` (`ashesiirbmanager://` → `gh.edu.ashesi.irbmanager://login-callback/`)
- Added `scopes: 'email profile openid'` to fix "Error getting user email from external provider"
- Removed manual `app_links` deep link handling from `main.dart` (was double-consuming the PKCE code)
- Fixed Azure app registration: correct Client ID, tenant URL set to `/common`, supported accounts set to multitenant, `requestedAccessTokenVersion` set to 2
- Fixed Android manifest deep link intent filter scheme to match `gh.edu.ashesi.irbmanager`

**Testing setup:** Android emulator (sdk gphone64 arm64, API 34) running via Android Studio. App launched in debug mode with `flutter run`. Logs monitored in Android Studio's Logcat. Also tested on a physical Android device via the arm64-v8a release APK (AirDropped from Mac). Both emulator and physical device show the same `flow_state_not_found` error.

**Resolution:** Two separate issues were conflated:

1. **PKCE flow state** — was actually succeeding once `launchMode` was changed to `singleTask` and `flutter_deeplinking_enabled` set to `false` in the manifest. This prevented Flutter's router from consuming the OAuth callback before Supabase's handler could. Added a `_LoggingPkceStorage` wrapper in `supabase.dart` to confirm the verifier was present (`present=true`) on callback.

2. **Real blocker — RLS policy querying `auth.users`** — after the session exchange succeeded, the reviewer lookup `supabase.from('reviewers').select('id').eq('email', email)` failed with `PostgrestException: permission denied for table users (403)`. The existing RLS policy was reading from `auth.users` directly, which PostgREST blocks for non-service-role clients.

**Fix:** Added migration `supabase/migrations/20260420_fix_reviewer_rls_jwt_email.sql` — replaced the `auth.users` dependency with a `public.current_user_email()` helper that reads the email from the JWT claim (`auth.jwt() ->> 'email'`). Applied directly to Supabase via psql.

**Status:** RESOLVED. Reviewer login works end-to-end.

---

## 12. Offline Startup and Session Resume Routing

**Phase affected:** Offline support / reviewer login

**Symptom:** When the app was opened without internet, the splash screen still routed to login and the login page could show a spinner indefinitely. Closing and reopening the app also sometimes sent a previously signed-in reviewer back to Microsoft login instead of the dashboard.

**Root cause:** The offline checks only treated `ConnectivityResult.none` as offline. That misses cases where the device reports Wi-Fi/mobile connectivity but DNS or internet access is unavailable. The login page then attempted `supabase.from('reviewers').select('id').eq('email', email).maybeSingle()` and could wait on a network failure. Splash also ignored an already restored Supabase session and did not use the cached `reviewer_email` aggressively enough before routing to login.

**Fix:**
- Splash now checks `supabase.auth.currentSession?.user.email` first and routes directly to the reviewer dashboard when a persisted session exists.
- Splash writes the session email back to Hive under `reviewer_email`.
- If there is no restored session but `reviewer_email` exists, splash routes to dashboard when connectivity is definitely offline or Supabase cannot be reached within a short timeout.
- Login now wraps the reviewer authorization query in an 8-second timeout.
- Login treats timeout, DNS, socket, and connection-timeout failures as retryable network errors.
- If the cached reviewer email matches the restored session email, login routes to dashboard instead of hanging or signing out during network failure.

**Status:** FIXED. Needs physical-device regression testing: sign in online once, force-close, turn internet off, reopen, and confirm splash routes to dashboard using cached data.

---

## 13. Reviewer Dashboard Filters Showing Wrong Cards During Testing

**Phase affected:** Reviewer dashboard / test data

**Symptom:** Tapping a filter button such as `PENDING` could still show cards with other statuses. Early fixes corrected the `IN REVIEW` status comparison and stabilized the Supabase stream, but the test still failed when using demo data.

**Root cause:** The dashboard had two data paths:
- Live/cache data rendered through the `StreamBuilder` and filter logic.
- Old hardcoded demo card widgets rendered separately below the stream output.

The hardcoded demo cards bypassed the filter entirely. When the database was empty or Hive only contained a few cached rows, this made it look like filtering was broken even if the dynamic list was filtering correctly.

**Fix:**
- Converted demo applications into structured `Map<String, dynamic>` rows in `_demoApplications`.
- Demo rows now flow through the same `_normalizeStatus`, filter, and `_buildApplicationCard` path as Supabase/Hive data.
- Added `_withDemoCoverage()` so demo rows fill missing statuses during testing while preserving any real or cached rows already present.
- Disabled the old hardcoded generated demo card block so it no longer renders unfiltered cards.
- Normalized status variants such as `UNDER REVIEW`, `IN_REVIEW`, and `CONDITIONALLY_APPROVED`.

**Relation to local resources:** Related but not caused by local resources. Hive cache affected which rows appeared during testing, but the actual bug was that mock/demo cards bypassed the filtered data pipeline.

**Status:** FIXED. With an empty or partial database, filters can now be tested against structured demo rows that behave like real application records.

---

## 14. Application Detail Fails for Demo Dashboard Cards

**Phase affected:** Phase 4 - Application Detail

**Symptom:** Tapping some dashboard cards opened the application detail route but showed `PostgrestException(message: invalid input syntax for type uuid: "demo-review-1", code: 22P02)`.

**Root cause:** The filter test fallback rows used local demo IDs such as `demo-review-1`. The detail screen queries `public.applications.id`, which is a UUID column, so Supabase rejected the non-UUID value before it could return a record. A second issue was found in the attachment flow: the database schema and mailbox poller use `attachments.storage_url`, but the detail screen was reading `storage_path`.

**Fix:**
- Added a defensive dashboard guard so non-UUID fallback demo cards do not navigate into the Supabase-backed detail route.
- Updated the application detail attachment row builder to read `storage_url`, with `storage_path` kept only as a compatibility fallback.
- Normalized detail status display so database `UNDER REVIEW` is shown as `IN REVIEW`.
- Seeded real Phase 4 test records in Supabase for `UNDER REVIEW`, `CONDITIONALLY APPROVED`, `APPROVED`, and `REJECTED`, plus one attachment object/row for the `UNDER REVIEW` test record. These rows use real UUIDs, so Phase 4 detail testing now exercises the production query path instead of local-only demo data.

**Status:** FIXED for Phase 4 testing. Use the seeded Supabase rows when testing application detail and document viewer behavior; fallback demo cards are only for dashboard/filter visual coverage.

---

## 15. Phase 5 Status Updates Reached Supabase but Failed or Looked Broken in the App

**Phase affected:** Phase 5 - Status Update

**Symptoms:**
- Confirming a status update initially failed with `status_history_changed_by_fkey`.
- Turning notifications on produced `FunctionException(status: 401, ... UNAUTHORIZED_UNSUPPORTED_TOKEN_ALGORITHM, Unsupported JWT alg ES256)`.
- After a successful database update, the detail screen and dashboard could still show the old status until the user navigated around manually.
- Notification tests showed email rows but no SMS rows for some applications.

**Root causes:**
- The app was inserting `supabase.auth.currentUser.id` into `status_history.changed_by`, but that foreign key references `public.reviewers.id`, not `auth.users.id`.
- The `send-notification` Edge Function was deployed with JWT verification enabled, so the mobile app's token was rejected before the function body ran.
- The application detail screen loaded data once on entry and did not refetch after the update sheet closed. The dashboard also relied too heavily on the live stream/cache path, so newer manual refresh data could be visually overwritten by stale in-memory state.
- SMS notification rows were only created when `student_phone` existed. Some seeded test applications had email addresses but no phone numbers, so only email rows appeared.

**Fix:**
- Added reviewer lookup by email and inserted the matching `reviewers.id` into `status_history.changed_by`.
- Updated status history inserts to use the current schema fields: `old_status` and `new_status`.
- Passed the current status into the update sheet so the current option is preselected and the sheet reflects the real database value.
- Refetched the application record after returning from the update sheet, and refreshed/merged dashboard application rows after returning from detail so the latest status shows immediately.
- Deployed `send-notification` with `--no-verify-jwt` so notification requests from the mobile app can reach the function.
- Confirmed that SMS testing requires a real `student_phone`; seeded `+233505538564` for the Phase 5 test record so both email and SMS notification rows could be verified.

**Frontend note:** A few small UI adjustments were made during Phase 5/5+ detail testing so status and proposal content fit better on narrow screens, but the main Phase 5 blockers were data flow, auth/configuration, and refresh behavior rather than styling.

**Status:** FIXED. Phase 5 status update testing now passes: status changes persist, `status_history` rows are written with the correct reviewer ID, and email/SMS notification rows are inserted when the corresponding contact fields exist.

---

## Summary Table

| # | Issue | Phase | Impact |
|---|-------|-------|--------|
| 1 | Unclosed `children: []` in Row | 3 | App crashed on every launch |
| 2 | `app_links` API renamed | 7 | Build failure |
| 3 | `LaunchMode` renamed | 7 | Build failure |
| 4 | Firebase on web (no kIsWeb guard) | 8 | Web crash at startup |
| 5 | Package name mismatch with Firebase | 8 | Gradle build failure |
| 6 | FCM legacy API deprecated | 8B | Push notifications not delivered |
| 7 | Gradle cache corruption | Various | Build failure (environment issue) |
| 8 | Flutter web SPA routing on Vercel | Web deploy | Blank page on direct URL access |
| 12 | Offline startup/session resume routing | Offline support | Login spinner / unnecessary re-login |
| 13 | Dashboard filters bypassed by hardcoded demo cards | Reviewer dashboard | Filter tests showed wrong statuses |
| 14 | Demo dashboard IDs sent to UUID detail query | Application detail | Some cards opened detail errors instead of records |
| 15 | Status update flow used wrong reviewer key and stale refresh path | Phase 5 | Status save/notification tests failed or looked inconsistent |
