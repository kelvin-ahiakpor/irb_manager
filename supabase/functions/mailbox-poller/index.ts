// Ashesi IRB Manager — mailbox-poller Edge Function
//
// ⚠️  MOCK MODE — real Graph API call is stubbed out.
// Waiting on IT/lecturer to provision a test M365 mailbox with
// Application-level Mail.Read permission + admin consent.
//
// TO SWITCH TO LIVE:
//   cp supabase/functions/mailbox-poller/index.live.ts \
//      supabase/functions/mailbox-poller/index.ts
//   supabase functions deploy mailbox-poller
//
// The full Graph API implementation is in index.live.ts.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const SUPABASE_URL         = Deno.env.get('SB_URL') ?? Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

// ─── Mock email payloads ──────────────────────────────────────────────────────
// These simulate what the real Graph API would return from the IRB inbox.
// Each run inserts one new application so we can test the dashboard + status flow.

const MOCK_EMAILS = [
  {
    studentName:  'Kojo Mensah',
    studentEmail: 'kojo.mensah@ashesi.edu.gh',
    studentId:    '88292024',
    studentPhone: '+233 24 123 4567',
    subject:      'IRB Application — Impact of FinTech on Rural Savings in Central Ghana',
    body:         'Dear IRB Committee,\n\nI am submitting my research ethics application for review. My study investigates the impact of mobile money platforms on savings behaviour among rural households in the Ashanti and Central regions of Ghana.\n\nParticipant pool: 120 adults (18+), recruited via community leaders.\nData collection: structured interviews, anonymised.\nRisk level: minimal.\n\nPlease find attached my full protocol and consent form.\n\nRegards,\nKojo Mensah\nStudent ID: 88292024',
    attachments: [
      { name: 'IRB_Protocol_KojoMensah.pdf',  contentType: 'application/pdf' },
      { name: 'Consent_Form_KojoMensah.pdf',  contentType: 'application/pdf' },
    ],
  },
  {
    studentName:  'Aba Williams',
    studentEmail: 'aba.williams@ashesi.edu.gh',
    studentId:    '11022025',
    studentPhone: '+233 20 987 6543',
    subject:      'IRB Application — Mental Health Awareness in Secondary Schools',
    body:         'Dear IRB Committee,\n\nI am requesting approval to conduct research on mental health awareness among JHS and SHS students in the Greater Accra region.\n\nParticipant pool: 200 students (13–18), parental consent obtained.\nData collection: anonymous questionnaire.\nRisk level: minimal.\n\nAttached are the full protocol, survey instrument, and parental consent form.\n\nBest,\nAba Williams\nStudent ID: 11022025',
    attachments: [
      { name: 'Protocol_AbaWilliams.pdf',      contentType: 'application/pdf' },
      { name: 'Survey_Instrument.pdf',          contentType: 'application/pdf' },
      { name: 'Parental_Consent_Form.pdf',      contentType: 'application/pdf' },
    ],
  },
  {
    studentName:  'Nana Adjei',
    studentEmail: 'nana.adjei@ashesi.edu.gh',
    studentId:    '55671923',
    studentPhone: '+233 27 456 7890',
    subject:      'IRB Application — AI-Assisted Diagnostics in Rural Clinics',
    body:         'Dear Committee,\n\nThis application seeks ethical clearance for a study evaluating AI-assisted diagnostic tools in three rural clinics in the Eastern Region.\n\nParticipant pool: 50 clinic staff + 300 patients.\nData: de-identified diagnostic records + staff interviews.\nRisk: low — no experimental interventions.\n\nFull protocol and data management plan attached.\n\nSincerely,\nNana Adjei\nStudent ID: 55671923',
    attachments: [
      { name: 'AI_Diagnostics_Protocol.pdf',   contentType: 'application/pdf' },
      { name: 'Data_Management_Plan.docx',      contentType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' },
    ],
  },
]

// ─── Helpers ──────────────────────────────────────────────────────────────────

function pickMockEmail() {
  // Rotate through mock emails based on minute so repeated calls give variety
  const index = Math.floor(Date.now() / 60000) % MOCK_EMAILS.length
  return MOCK_EMAILS[index]
}

// ─── Entry point ──────────────────────────────────────────────────────────────

Deno.serve(async (_req) => {
  try {
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
    const mock     = pickMockEmail()

    // ── MOCK DATA (replace this block with real Graph API calls) ──────────────
    // REAL IMPLEMENTATION lives at the bottom of this file.
    // When M365 mailbox is ready:
    //   1. Uncomment the Graph API section below
    //   2. Delete everything between these two comment markers
    //   3. Replace `const emails = [mockToEmail(mock)]` with `const emails = await fetchUnreadEmails(token)`

    const mockEmail = {
      id:               `mock-${Date.now()}`,
      studentName:      mock.studentName,
      studentEmail:     mock.studentEmail,
      studentId:        mock.studentId,
      studentPhone:     mock.studentPhone,
      subject:          mock.subject,
      body:             mock.body,
      hasAttachments:   mock.attachments.length > 0,
      attachments:      mock.attachments,
      receivedDateTime: new Date().toISOString(),
    }
    // ── END MOCK DATA ─────────────────────────────────────────────────────────

    // Check for duplicate (same email + subject already imported)
    const { data: existing } = await supabase
      .from('applications')
      .select('id')
      .eq('student_email', mockEmail.studentEmail)
      .eq('subject', mockEmail.subject)
      .maybeSingle()

    if (existing) {
      return new Response(
        JSON.stringify({ polled_at: new Date().toISOString(), total: 0, inserted: 0, skipped: 1, note: 'mock email already imported' }),
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Insert application
    const { data: app, error: appErr } = await supabase
      .from('applications')
      .insert({
        student_id:        mockEmail.studentId,
        student_name:      mockEmail.studentName,
        student_email:     mockEmail.studentEmail,
        student_phone:     mockEmail.studentPhone,
        subject:           mockEmail.subject,
        body:              mockEmail.body,
        status:            'PENDING',
        submission_method: 'email',
        submitted_at:      mockEmail.receivedDateTime,
      })
      .select('id')
      .single()

    if (appErr) throw new Error(`Insert application: ${appErr.message}`)

    // Initial status history entry
    await supabase.from('status_history').insert({
      application_id: app.id,
      changed_by:     null,
      old_status:     null,
      new_status:     'PENDING',
      note:           'Application received via email (mock)',
    })

    // Insert attachment metadata (no real file upload in mock mode)
    for (const att of mockEmail.attachments) {
      await supabase.from('attachments').insert({
        application_id: app.id,
        file_name:      att.name,
        file_type:      att.contentType,
        storage_url:    `mock/${app.id}/${att.name}`,
      })
    }

    const summary = {
      polled_at:  new Date().toISOString(),
      mode:       'mock',
      total:      1,
      inserted:   1,
      skipped:    0,
      errors:     0,
      application_id: app.id,
    }

    console.log('mailbox-poller (mock):', JSON.stringify(summary))

    return new Response(JSON.stringify(summary), {
      headers: { 'Content-Type': 'application/json' },
    })

  } catch (err) {
    const msg = (err as Error).message
    console.error('mailbox-poller fatal:', msg)
    return new Response(JSON.stringify({ error: msg }), {
      status:  500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})


// =============================================================================
// REAL GRAPH API IMPLEMENTATION → see index.live.ts
// =============================================================================
//
// const TENANT_ID    = Deno.env.get('AZURE_TENANT_ID')!
// const CLIENT_ID    = Deno.env.get('AZURE_CLIENT_ID')!
// const CLIENT_SECRET = Deno.env.get('AZURE_CLIENT_SECRET')!
// const IRB_MAILBOX  = Deno.env.get('IRB_MAILBOX')!
//
// async function getAccessToken(): Promise<string> {
//   const res = await fetch(
//     `https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token`,
//     {
//       method: 'POST',
//       headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
//       body: new URLSearchParams({
//         grant_type:    'client_credentials',
//         client_id:     CLIENT_ID,
//         client_secret: CLIENT_SECRET,
//         scope:         'https://graph.microsoft.com/.default',
//       }),
//     }
//   )
//   const data = await res.json()
//   if (!data.access_token) throw new Error(`Graph auth failed: ${JSON.stringify(data)}`)
//   return data.access_token
// }
//
// async function fetchUnreadEmails(token: string) {
//   const params = new URLSearchParams({
//     '$filter':  'isRead eq false',
//     '$select':  'id,subject,body,from,receivedDateTime,hasAttachments',
//     '$top':     '20',
//     '$orderby': 'receivedDateTime asc',
//   })
//   const res  = await fetch(
//     `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/mailFolders/inbox/messages?${params}`,
//     { headers: { Authorization: `Bearer ${token}` } }
//   )
//   const text = await res.text()
//   if (!res.ok) throw new Error(`Graph messages API ${res.status}: ${text}`)
//   return JSON.parse(text).value ?? []
// }
//
// async function fetchAttachments(token: string, messageId: string) {
//   const res  = await fetch(
//     `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/messages/${messageId}/attachments`,
//     { headers: { Authorization: `Bearer ${token}` } }
//   )
//   const data = await res.json()
//   return (data.value ?? []).filter((a: any) => a.contentBytes)
// }
//
// async function markAsRead(token: string, messageId: string) {
//   await fetch(
//     `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/messages/${messageId}`,
//     {
//       method:  'PATCH',
//       headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
//       body:    JSON.stringify({ isRead: true }),
//     }
//   )
// }
