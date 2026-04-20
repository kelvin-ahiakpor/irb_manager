// Ashesi IRB Manager — mailbox-poller (LIVE / Graph API implementation)
//
// This is the production version. Use this when an M365 mailbox with
// Application-level Mail.Read permission + admin consent is available.
//
// TO ACTIVATE:
//   cp index.live.ts index.ts
//   supabase functions deploy mailbox-poller
//
// PREREQUISITES (Azure Portal):
//   - App registration → API permissions → Microsoft Graph
//   - Add: Mail.Read (Application), Mail.ReadBasic (Application)
//   - Grant admin consent for your tenant
//   - IRB_MAILBOX must be a work/school account on your Azure AD tenant
//     (personal @outlook.com accounts are NOT supported by client credentials flow)
//
// SECRETS REQUIRED (already set via `supabase secrets set`):
//   AZURE_TENANT_ID, AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, IRB_MAILBOX
//   SB_URL, SB_SERVICE_ROLE_KEY, CRON_SECRET

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const TENANT_ID            = Deno.env.get('AZURE_TENANT_ID')!
const CLIENT_ID            = Deno.env.get('AZURE_CLIENT_ID')!
const CLIENT_SECRET        = Deno.env.get('AZURE_CLIENT_SECRET')!
const IRB_MAILBOX          = Deno.env.get('IRB_MAILBOX')!
const SUPABASE_URL         = Deno.env.get('SB_URL') ?? Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const CRON_SECRET          = Deno.env.get('CRON_SECRET')!

// ─── Types ────────────────────────────────────────────────────────────────────

interface GraphMessage {
  id: string
  subject: string
  bodyPreview: string
  body: { contentType: string; content: string }
  from: { emailAddress: { name: string; address: string } }
  receivedDateTime: string
  hasAttachments: boolean
}

interface GraphAttachment {
  id: string
  name: string
  contentType: string
  contentBytes: string   // base64
  size: number
}

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
  if (!data.access_token) {
    throw new Error(`Graph auth failed: ${JSON.stringify(data)}`)
  }
  return data.access_token as string
}

async function fetchUnreadEmails(token: string): Promise<GraphMessage[]> {
  const params = new URLSearchParams({
    '$filter':  'isRead eq false',
    '$select':  'id,subject,body,bodyPreview,from,receivedDateTime,hasAttachments',
    '$top':     '20',
    '$orderby': 'receivedDateTime asc',
  })
  const res  = await fetch(
    `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/mailFolders/inbox/messages?${params}`,
    { headers: { Authorization: `Bearer ${token}` } }
  )
  const text = await res.text()
  if (!res.ok) {
    throw new Error(`Graph messages API ${res.status}: ${text}`)
  }
  const data = JSON.parse(text)
  if (!Array.isArray(data.value)) {
    throw new Error(`Unexpected Graph response: ${text}`)
  }
  return data.value
}

async function fetchAttachments(token: string, messageId: string): Promise<GraphAttachment[]> {
  const res  = await fetch(
    `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/messages/${messageId}/attachments?$select=id,name,contentType,contentBytes,size`,
    { headers: { Authorization: `Bearer ${token}` } }
  )
  const data = await res.json()
  return (data.value ?? []).filter((a: GraphAttachment) => a.contentBytes)
}

async function markAsRead(token: string, messageId: string): Promise<void> {
  await fetch(
    `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/messages/${messageId}`,
    {
      method:  'PATCH',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body:    JSON.stringify({ isRead: true }),
    }
  )
}

// ─── Parsing helpers ──────────────────────────────────────────────────────────

function stripHtml(html: string): string {
  return html
    .replace(/<style[^>]*>[\s\S]*?<\/style>/gi, '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/\s{2,}/g, ' ')
    .trim()
}

function extractStudentId(subject: string, bodyText: string): string {
  const match = (subject + ' ' + bodyText).match(/\b\d{8}\b/)
  return match ? match[0] : ''
}

// ─── Core processor ───────────────────────────────────────────────────────────

async function processEmail(
  email: GraphMessage,
  token: string,
  supabase: ReturnType<typeof createClient>
): Promise<{ messageId: string; status: 'inserted' | 'skipped' | 'error'; detail?: string }> {
  const messageId = email.id

  try {
    const senderEmail = email.from.emailAddress.address
    const senderName  = email.from.emailAddress.name || senderEmail

    const { data: existing } = await supabase
      .from('applications')
      .select('id')
      .eq('student_email', senderEmail)
      .eq('subject', email.subject)
      .eq('submission_method', 'email')
      .maybeSingle()

    if (existing) {
      await markAsRead(token, messageId)
      return { messageId, status: 'skipped', detail: 'duplicate' }
    }

    const bodyText  = email.body.contentType === 'html'
      ? stripHtml(email.body.content)
      : email.body.content

    const studentId = extractStudentId(email.subject, bodyText)

    const { data: app, error: appErr } = await supabase
      .from('applications')
      .insert({
        student_id:        studentId || senderEmail,
        student_name:      senderName,
        student_email:     senderEmail,
        subject:           email.subject,
        body:              bodyText,
        status:            'PENDING',
        submission_method: 'email',
        submitted_at:      email.receivedDateTime,
      })
      .select('id')
      .single()

    if (appErr) throw new Error(`Insert application: ${appErr.message}`)

    await supabase.from('status_history').insert({
      application_id: app.id,
      changed_by:     null,
      old_status:     null,
      new_status:     'PENDING',
      note:           'Application received via email',
    })

    if (email.hasAttachments) {
      const attachments = await fetchAttachments(token, messageId)

      for (const att of attachments) {
        const binary      = atob(att.contentBytes)
        const bytes       = new Uint8Array(binary.length)
        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)

        const storagePath = `${app.id}/${Date.now()}_${att.name}`

        const { error: uploadErr } = await supabase.storage
          .from('attachments')
          .upload(storagePath, bytes, { contentType: att.contentType, upsert: false })

        if (uploadErr) {
          console.error(`Attachment upload failed (${att.name}):`, uploadErr.message)
          continue
        }

        await supabase.from('attachments').insert({
          application_id: app.id,
          file_name:      att.name,
          file_type:      att.contentType,
          storage_url:    storagePath,
        })
      }
    }

    await markAsRead(token, messageId)
    return { messageId, status: 'inserted', detail: app.id }

  } catch (err) {
    console.error(`Error processing message ${messageId}:`, err)
    return { messageId, status: 'error', detail: (err as Error).message }
  }
}

// ─── Entry point ──────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  try {
    if (!CRON_SECRET || req.headers.get('x-cron-secret') !== CRON_SECRET) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const token    = await getAccessToken()
    const emails   = await fetchUnreadEmails(token)
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)

    const results = []
    for (const email of emails) {
      const result = await processEmail(email, token, supabase)
      results.push(result)
    }

    const summary = {
      polled_at: new Date().toISOString(),
      total:     emails.length,
      inserted:  results.filter(r => r.status === 'inserted').length,
      skipped:   results.filter(r => r.status === 'skipped').length,
      errors:    results.filter(r => r.status === 'error').length,
      results,
    }

    console.log('mailbox-poller:', JSON.stringify(summary))

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
