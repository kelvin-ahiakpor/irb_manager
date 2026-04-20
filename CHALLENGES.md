# Implementation Challenges

A record of bugs, root causes, and fixes encountered during development of the Ashesi IRB Manager mobile app.

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
