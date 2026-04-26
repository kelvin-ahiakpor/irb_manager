# Ashesi IRB Manager

A Flutter application for managing Institutional Review Board (IRB) research ethics applications at Ashesi University.

---

## What it does

| Role | Platform | Capability |
|------|----------|------------|
| Student | Web (Vercel) | Submit IRB applications via web form or email |
| Student | Web (Vercel) | Look up application status by student ID |
| Reviewer | Android / iOS | Review applications, update status, add notes |
| Reviewer | Android / iOS | Receive push notifications for new submissions |
| System | Supabase Edge Functions | Poll email inbox, send email/SMS/push notifications |

---

## Architecture

```
Flutter app (mobile)     →  Supabase (Postgres + Auth + Storage + Edge Functions)
Flutter app (web/Vercel) →  Supabase
mailbox-poller cron      →  Microsoft Graph API → kelvin.ahiakpor@outlook.com inbox
send-notification        →  Resend (email) + Twilio (SMS) + FCM (push)
```

---

## Running locally

### Prerequisites

- Flutter stable channel
- Supabase CLI
- A `.env` file (copy from `.env.example`, fill in secrets)

### Run the Flutter app

```sh
flutter run --dart-define-from-file=.env
```

In Android Studio, add to the run configuration's additional arguments:

```sh
--dart-define-from-file=.env
```

### Run the web build locally

```sh
flutter run -d chrome --dart-define-from-file=.env
```

---

## Supabase secrets

All Edge Function secrets are managed via the Supabase CLI:

```sh
supabase secrets list          # show which secrets are set (values hidden)
supabase secrets set KEY=value # set or update a secret
```

| Secret | Used by | Purpose |
|--------|---------|---------|
| `AZURE_CLIENT_ID` | mailbox-poller | Azure App Registration client ID |
| `AZURE_CLIENT_SECRET` | mailbox-poller | Azure App Registration client secret |
| `OUTLOOK_REFRESH_TOKEN` | mailbox-poller | Delegated OAuth refresh token for inbox access |
| `IRB_MAILBOX` | mailbox-poller | Email address to poll (`kelvin.ahiakpor@outlook.com`) |
| `RESEND_API_KEY` | send-notification | Resend API key for outbound email |
| `TWILIO_ACCOUNT_SID` | send-notification | Twilio account SID for SMS |
| `TWILIO_AUTH_TOKEN` | send-notification | Twilio auth token |
| `TWILIO_FROM_NUMBER` | send-notification | Twilio sender number |
| `FCM_SERVICE_ACCOUNT_JSON_B64` | send-notification | Base64-encoded Firebase service account |
| `CRON_SECRET` | mailbox-poller | Shared secret used by pg_cron to authenticate cron calls |
| `SB_URL` | both functions | Supabase project URL |
| `SB_SERVICE_ROLE_KEY` | both functions | Supabase service role key |

---

## Mailbox poller

The `mailbox-poller` Edge Function polls `kelvin.ahiakpor@outlook.com` every 5 minutes for unread emails whose subject contains **`IRB Application`** and inserts them as new applications.

It uses Microsoft Graph API with **delegated OAuth** (refresh token flow) — no Azure admin consent required.

### Manually trigger a poll

```sh
curl -s -X POST https://tznryskacildjctzznpe.supabase.co/functions/v1/mailbox-poller \
  -H "x-cron-secret: <CRON_SECRET>"
```

### Email submission format

Students email `kelvin.ahiakpor@outlook.com` with subject:

```
<8-digit-student-id> IRB Application: <research title>
```

Example:
```
47822026 IRB Application: Music Production Influence on Young Teenager Social Lives
```

The poller extracts the student ID from the subject using an 8-digit regex, strips the prefix to store only the research title, and uses the sender display name as `student_name`.

### Refresh token rotation

The refresh token expires after ~90 days. To renew:

1. Visit the auth URL (replace `<CLIENT_ID>` with the app registration client ID):
   ```
   https://login.microsoftonline.com/common/oauth2/v2.0/authorize?client_id=<CLIENT_ID>&response_type=code&redirect_uri=http%3A%2F%2Flocalhost&scope=offline_access%20Mail.Read&response_mode=query
   ```
2. Sign in with `kelvin.ahiakpor@outlook.com`, copy the `code` from the redirect URL
3. Exchange the code:
   ```sh
   curl -X POST https://login.microsoftonline.com/common/oauth2/v2.0/token \
     --data-urlencode "client_id=<CLIENT_ID>" \
     --data-urlencode "client_secret=<CLIENT_SECRET>" \
     --data-urlencode "code=<CODE>" \
     --data-urlencode "redirect_uri=http://localhost" \
     --data-urlencode "grant_type=authorization_code" \
     --data-urlencode "scope=offline_access Mail.Read"
   ```
4. Store the new `refresh_token`:
   ```sh
   supabase secrets set OUTLOOK_REFRESH_TOKEN=<new-refresh-token>
   supabase functions deploy mailbox-poller --no-verify-jwt
   ```

---

## Deploying Edge Functions

```sh
supabase functions deploy mailbox-poller --no-verify-jwt
supabase functions deploy send-notification --no-verify-jwt
```

`--no-verify-jwt` is required because both functions use their own internal auth (`x-cron-secret` and the mobile app's reviewer session) rather than Supabase JWTs.

---

## Web deployment (Vercel)

The Flutter web build is deployed to Vercel. A `vercel.json` catch-all rewrite is required so GoRouter can handle all routes client-side:

```json
{ "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }] }
```

Build and deploy:

```sh
flutter build web --dart-define-from-file=.env
cp vercel.json build/web/vercel.json
cd build/web && vercel --prod
```
