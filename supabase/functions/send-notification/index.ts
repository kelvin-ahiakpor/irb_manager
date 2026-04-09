// Ashesi IRB Manager — send-notification Edge Function
//
// Sends email (Graph API) and/or SMS (Twilio) to a student after a status update,
// and/or push notifications (FCM) to reviewers on new applications.
// Runs in MOCK mode when secrets are absent — safe to deploy at any time.
//
// INPUT (JSON body):
//   {
//     application_id: string,
//     channels: ('email' | 'sms' | 'push')[],
//     status: string,                          // new status label
//     reviewer_note?: string                   // optional note from reviewer
//   }
//
// OUTPUT:
//   { ok: true, results: { email?: 'sent'|'mocked'|'failed', sms?: ..., push?: ... } }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ─── Env ─────────────────────────────────────────────────────────────────────

const TENANT_ID     = Deno.env.get('AZURE_TENANT_ID')   ?? ''
const CLIENT_ID     = Deno.env.get('AZURE_CLIENT_ID')   ?? ''
const CLIENT_SECRET = Deno.env.get('AZURE_CLIENT_SECRET') ?? ''
const IRB_MAILBOX   = Deno.env.get('IRB_MAILBOX')        ?? ''

const TWILIO_SID    = Deno.env.get('TWILIO_ACCOUNT_SID')   ?? ''
const TWILIO_TOKEN  = Deno.env.get('TWILIO_AUTH_TOKEN')     ?? ''
const TWILIO_FROM   = Deno.env.get('TWILIO_PHONE_FROM')     ?? ''

const SUPABASE_URL  = Deno.env.get('SB_URL') ?? Deno.env.get('SUPABASE_URL') ?? ''
const SUPABASE_KEY  = Deno.env.get('SB_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY') ?? ''

const MOCK_EMAIL    = !TENANT_ID || !CLIENT_ID || !CLIENT_SECRET || !IRB_MAILBOX
const MOCK_SMS      = !TWILIO_SID || !TWILIO_TOKEN || !TWILIO_FROM
const MOCK_PUSH     = !FCM_SERVER_KEY

// ─── Graph API helpers ────────────────────────────────────────────────────────

async function getAccessToken(): Promise<string> {
  const res = await fetch(
    `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type:    'client_credentials',
        client_id:     CLIENT_ID,
        client_secret: CLIENT_SECRET,
        scope:         'https://graph.microsoft.com/.default',
      }),
    }
  )
  const data = await res.json()
  if (!data.access_token) throw new Error(`Graph auth failed: ${JSON.stringify(data)}`)
  return data.access_token as string
}

async function sendEmail(
  token: string,
  toEmail: string,
  toName: string,
  subject: string,
  status: string,
  note: string
): Promise<void> {
  const body = [
    `Dear ${toName},`,
    '',
    `Your IRB application "${subject}" has been updated to: ${status}.`,
    note ? `\nReviewer note: ${note}` : '',
    '',
    'Please contact the IRB office if you have any questions.',
    '',
    'Ashesi University IRB Committee',
  ].join('\n')

  const res = await fetch(
    `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/sendMail`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          subject: `IRB Application Update: ${status}`,
          body: { contentType: 'Text', content: body },
          toRecipients: [{ emailAddress: { address: toEmail, name: toName } }],
        },
        saveToSentItems: false,
      }),
    }
  )

  if (!res.ok) {
    const text = await res.text()
    throw new Error(`Graph sendMail ${res.status}: ${text}`)
  }
}

// ─── Twilio helper ────────────────────────────────────────────────────────────

async function sendSms(toPhone: string, status: string, subject: string): Promise<void> {
  const message = `Ashesi IRB: Your application "${subject}" status has been updated to: ${status}. Contact the IRB office for details.`

  const res = await fetch(
    `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_SID}/Messages.json`,
    {
      method: 'POST',
      headers: {
        Authorization: 'Basic ' + btoa(`${TWILIO_SID}:${TWILIO_TOKEN}`),
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        From: TWILIO_FROM,
        To:   toPhone,
        Body: message,
      }),
    }
  )

  if (!res.ok) {
    const text = await res.text()
    throw new Error(`Twilio SMS ${res.status}: ${text}`)
  }
}

// ─── FCM helper ───────────────────────────────────────────────────────────────

async function sendPushToTokens(
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string>
): Promise<void> {
  if (tokens.length === 0) return
  const res = await fetch('https://fcm.googleapis.com/fcm/send', {
    method: 'POST',
    headers: {
      Authorization: `key=${FCM_SERVER_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      registration_ids: tokens,
      notification: { title, body },
      data,
    }),
  })
  if (!res.ok) {
    const text = await res.text()
    throw new Error(`FCM ${res.status}: ${text}`)
  }
}

// ─── Entry point ──────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'Method not allowed' }), {
      status: 405,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  let body: {
    application_id: string
    channels: string[]
    status: string
    reviewer_note?: string
  }

  try {
    body = await req.json()
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON body' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const { application_id, channels, status, reviewer_note = '' } = body

  if (!application_id || !channels?.length || !status) {
    return new Response(JSON.stringify({ error: 'Missing required fields: application_id, channels, status' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_KEY)

  // Fetch application details
  const { data: app, error: appErr } = await supabase
    .from('applications')
    .select('student_name, student_email, student_phone, subject')
    .eq('id', application_id)
    .single()

  if (appErr || !app) {
    return new Response(JSON.stringify({ error: `Application not found: ${appErr?.message}` }), {
      status: 404,
      headers: { 'Content-Type': 'application/json' },
    })
  }

  const results: Record<string, string> = {}

  // ── Email ──────────────────────────────────────────────────────────────────

  if (channels.includes('email') && app.student_email) {
    if (MOCK_EMAIL) {
      console.log(`[MOCK] Email to ${app.student_email}: status=${status}`)
      results.email = 'mocked'
    } else {
      try {
        const token = await getAccessToken()
        await sendEmail(token, app.student_email, app.student_name, app.subject, status, reviewer_note)
        results.email = 'sent'
      } catch (err) {
        console.error('Email failed:', (err as Error).message)
        results.email = 'failed'
      }
    }

    await supabase.from('notifications').insert({
      application_id,
      type:      'email',
      recipient: app.student_email,
      message:   `Status updated to ${status}${reviewer_note ? ` — ${reviewer_note}` : ''}. Result: ${results.email}`,
    }).then(({ error }) => {
      if (error) console.error('notifications log (email):', error.message)
    })
  }

  // ── SMS ────────────────────────────────────────────────────────────────────

  if (channels.includes('sms') && app.student_phone) {
    if (MOCK_SMS) {
      console.log(`[MOCK] SMS to ${app.student_phone}: status=${status}`)
      results.sms = 'mocked'
    } else {
      try {
        await sendSms(app.student_phone, status, app.subject)
        results.sms = 'sent'
      } catch (err) {
        console.error('SMS failed:', (err as Error).message)
        results.sms = 'failed'
      }
    }

    await supabase.from('notifications').insert({
      application_id,
      type:      'sms',
      recipient: app.student_phone,
      message:   `Status updated to ${status}. Result: ${results.sms}`,
    }).then(({ error }) => {
      if (error) console.error('notifications log (sms):', error.message)
    })
  }

  // ── Push ───────────────────────────────────────────────────────────────────

  if (channels.includes('push')) {
    // Fetch all reviewer FCM tokens
    const { data: reviewers } = await supabase
      .from('reviewers')
      .select('device_token')
      .not('device_token', 'is', null)

    const tokens = (reviewers ?? [])
      .map((r: { device_token: string }) => r.device_token)
      .filter(Boolean)

    if (MOCK_PUSH) {
      console.log(`[MOCK] Push to ${tokens.length} reviewer(s): status=${status}`)
      results.push = 'mocked'
    } else {
      try {
        await sendPushToTokens(
          tokens,
          `IRB Application Update`,
          `"${app.subject}" → ${status}`,
          { application_id, status }
        )
        results.push = 'sent'
      } catch (err) {
        console.error('Push failed:', (err as Error).message)
        results.push = 'failed'
      }
    }

    await supabase.from('notifications').insert({
      application_id,
      type:      'push',
      recipient: `${tokens.length} reviewer(s)`,
      message:   `Status updated to ${status}. Result: ${results.push}`,
    }).then(({ error }) => {
      if (error) console.error('notifications log (push):', error.message)
    })
  }

  console.log(`send-notification [${application_id}]:`, JSON.stringify(results))

  return new Response(JSON.stringify({ ok: true, results }), {
    headers: { 'Content-Type': 'application/json' },
  })
})
