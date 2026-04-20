# Ashesi IRB Manager — Test Plan

> For emulator / device testing. Not committed to repo.

---

## Prerequisites

- Android emulator or physical device with the debug APK installed
- Twilio account active (SMS live)
- Firebase project active (push live)
- At least one reviewer seeded in `reviewers` table in Supabase
- Web build deployed to Vercel (for student-side tests)

---

## Phase 1 — Splash & Navigation

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 1.1 | Launch app on mobile | Splash screen shows, transitions to Login screen after ~2s | |
| 1.2 | Navigate to web URL `/` | Submission form loads directly, no login prompt | |

---

## Phase 2 — Reviewer Login (Mobile)

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 2.1 | Tap "Sign in with Microsoft" | External browser opens Microsoft OAuth | |
| 2.2 | Sign in with an email NOT in `reviewers` table | Access denied error banner shows, user signed out | |
| 2.3 | Sign in with an authorised reviewer email | Redirected to Reviewer Dashboard | |
| 2.4 | Kill app and reopen | Still logged in — goes directly to dashboard | |
| 2.5 | Check Supabase `reviewers` table | `device_token` column populated with FCM token | |

---

## Phase 3 — Reviewer Dashboard

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 3.1 | Dashboard loads with applications | List shows all submitted applications sorted by date | |
| 3.2 | Tap filter "PENDING" | Only PENDING applications shown | |
| 3.3 | Tap filter "APPROVED" | Only APPROVED applications shown | |
| 3.4 | Tap filter "ALL" | All applications shown | |
| 3.5 | Turn off Wi-Fi / mobile data | Red "You're offline. Showing cached data." banner appears | |
| 3.6 | While offline, dashboard still shows data | Cached applications visible | |
| 3.7 | Turn Wi-Fi back on | Offline banner disappears | |

---

## Phase 4 — Application Detail

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 4.1 | Tap an application card | Application detail screen opens | |
| 4.2 | Detail shows correct student name, ID, email, status | Data matches Supabase record | |
| 4.3 | Attachments section shows count | Count matches `attachments` table rows for that application | |
| 4.4 | Tap an attachment | Document viewer opens | |
| 4.5 | Document viewer shows file name and share button | Tapping share opens the signed URL | |
| 4.6 | Tap back arrow | Returns to dashboard | |

---

## Phase 5 — Status Update

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 5.1 | Tap "UPDATE STATUS" on detail screen | Status update sheet opens | |
| 5.2 | Status options shown: PENDING, UNDER REVIEW, CONDITIONALLY APPROVED, APPROVED, REJECTED | All options visible and selectable | |
| 5.3 | Tap a status — confirm button activates | Confirm button changes color | |
| 5.4 | Toggle notify switch OFF, confirm | Status updated in DB, no notification sent | |
| 5.5 | Toggle notify switch ON, confirm | Status updated in DB, notification triggered | |
| 5.6 | Check Supabase `status_history` table | New row inserted with correct status and reviewer ID | |
| 5.7 | Check Supabase `notifications` table | Row(s) inserted for email/sms channels | |

---

## Phase 6 — Notifications (Email & SMS)

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 6.1 | Status updated with notify ON (student has email) | Student receives email from IRB mailbox | |
| 6.2 | Status updated with notify ON (student has phone) | Student receives SMS from Twilio number | |
| 6.3 | Check Supabase `notifications` table | `status` column shows `sent` (not `mocked`) for email and sms | |
| 6.4 | Status updated with notify ON (no phone on record) | Email sent, SMS skipped silently | |

> **Note:** Email will show `mocked` until Azure admin consent is granted for the IRB mailbox. SMS should show `sent` if Twilio secrets are set correctly.

---

## Phase 7 — Push Notifications (FCM)

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 7.1 | New application submitted (see Phase 9) | Reviewer device receives push notification | |
| 7.2 | Tap push notification | App opens (or foregrounds) to dashboard | |
| 7.3 | Check Supabase `notifications` table | Row with `type = push` and `status = sent` | |

---

## Phase 8 — Student Submission Form (Web)

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 8.1 | Open web URL `/` | Submission form loads | |
| 8.2 | Submit with empty Student ID | Error snackbar: "Please fill in Student ID, Email, and Research Title" | |
| 8.3 | Fill all required fields, tap SUBMIT APPLICATION | Loading state shows on button | |
| 8.4 | After submission | Success snackbar, fields cleared | |
| 8.5 | Check Supabase `applications` table | New row with `submission_method = form` and `status = PENDING` | |
| 8.6 | Check reviewer mobile app | New application appears on dashboard in real-time (StreamBuilder) | |
| 8.7 | Reviewer receives push notification | Push arrives with "New application submitted via form" | |

---

## Phase 9 — Offline Action Queue

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 9.1 | Turn off network, open Update Status sheet | Sheet opens normally | |
| 9.2 | Confirm a status update while offline | Success — action queued locally | |
| 9.3 | Check dashboard while offline | Shows stale cached data with offline banner | |
| 9.4 | Turn network back on | Queued status update syncs automatically to Supabase | |
| 9.5 | Check Supabase `applications` table | Status reflects the offline update | |

---

## Phase 10 — Student Status Lookup

| # | Test | Expected | Pass/Fail |
|---|------|----------|-----------|
| 10.1 | Navigate to student status lookup screen | Search field visible | |
| 10.2 | Enter a valid student ID and tap CHECK STATUS | Matching applications shown with status badges | |
| 10.3 | Enter a student ID with no applications | "No applications found" message | |
| 10.4 | Enter a partial/invalid ID | No results or appropriate message | |

---

## Known Limitations (Demo Context)

- **Email sending** is mocked until Azure admin grants Mail.Send consent for the IRB mailbox
- **Mailbox poller** is mocked — student form replaces email intake for demo purposes
- **Twilio trial** can only SMS verified numbers — upgrade required for arbitrary student phones
- **FCM push** requires `FCM_SERVER_KEY` secret set in Supabase (done via service account)
