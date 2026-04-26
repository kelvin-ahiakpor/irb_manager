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
//   - Add: Mail.Read (Delegated), offline_access (Delegated)
//   - Supported account types: personal Microsoft accounts (or All)
//   - No admin consent needed — just user consent via the one-time OAuth flow
//
// ONE-TIME SETUP to get OUTLOOK_REFRESH_TOKEN — see README or ask Claude.
//
// SECRETS REQUIRED (set via `supabase secrets set`):
//   AZURE_CLIENT_ID, AZURE_CLIENT_SECRET, OUTLOOK_REFRESH_TOKEN, IRB_MAILBOX
//   SB_URL, SB_SERVICE_ROLE_KEY, CRON_SECRET

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CLIENT_ID            = Deno.env.get('AZURE_CLIENT_ID')!
const CLIENT_SECRET        = Deno.env.get('AZURE_CLIENT_SECRET')!
const REFRESH_TOKEN        = Deno.env.get('OUTLOOK_REFRESH_TOKEN')!
const IRB_MAILBOX          = Deno.env.get('IRB_MAILBOX')!
const SUPABASE_URL         = Deno.env.get('SB_URL') ?? Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_KEY = Deno.env.get('SB_SERVICE_ROLE_KEY') ?? Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const CRON_SECRET          = Deno.env.get('CRON_SECRET')!
const SEND_NOTIFICATION_URL = `${SUPABASE_URL}/functions/v1/send-notification`

// ─── Types ────────────────────────────────────────────────────────────────────

interface GraphMessage {
  id: string
  subject: string
  bodyPreview: string
  body: { contentType: string; content: string }
  from: { emailAddress: { name: string; address: string } }
  receivedDateTime: string
  hasAttachments: boolean
  isRead: boolean
}

interface GraphAttachment {
  id: string
  name: string
  contentType: string
  contentBytes: string   // base64
  size: number
  '@odata.type'?: string
}

// ─── Graph API helpers ────────────────────────────────────────────────────────

async function getAccessToken(): Promise<string> {
  const res = await fetch(
    'https://login.microsoftonline.com/common/oauth2/v2.0/token',
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type:    'refresh_token',
        client_id:     CLIENT_ID,
        client_secret: CLIENT_SECRET,
        refresh_token: REFRESH_TOKEN,
        scope:         'Mail.Read offline_access',
      }),
    }
  )
  const data = await res.json()
  if (!data.access_token) {
    throw new Error(`Token refresh failed: ${JSON.stringify(data)}`)
  }
  return data.access_token as string
}

const IRB_SUBJECT_PREFIX = 'IRB Application'

async function fetchUnreadEmails(token: string): Promise<GraphMessage[]> {
  const params = new URLSearchParams({
    '$filter':  `isRead eq false and contains(subject,'${IRB_SUBJECT_PREFIX}')`,
    '$select':  'id,subject,body,bodyPreview,from,receivedDateTime,hasAttachments,isRead',
    '$top':     '20',
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
  // Secondary guard in case Graph filtering behaves differently than expected.
  return data.value.filter((m: GraphMessage) =>
    !m.isRead && m.subject?.includes(IRB_SUBJECT_PREFIX)
  )
}

async function fetchAttachments(token: string, messageId: string): Promise<GraphAttachment[]> {
  const res  = await fetch(
    `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/messages/${messageId}/attachments?$select=id,name,contentType,size`,
    { headers: { Authorization: `Bearer ${token}` } }
  )
  const text = await res.text()
  if (!res.ok) {
    throw new Error(`Graph attachments API ${res.status}: ${text}`)
  }
  const data = JSON.parse(text)
  if (!Array.isArray(data.value)) {
    throw new Error(`Unexpected Graph attachments response: ${text}`)
  }
  const metadata = data.value as GraphAttachment[]
  console.log(`mailbox-poller attachments [${messageId}]: graph returned ${metadata.length}`)
  const supported: GraphAttachment[] = []

  for (const att of metadata) {
    console.log(
      `mailbox-poller attachments [${messageId}]: name="${att.name}" type="${att.contentType}" size=${att.size ?? 'unknown'} odataType=${att['@odata.type'] ?? 'unknown'}`
    )

    const detailRes = await fetch(
      `https://graph.microsoft.com/v1.0/users/${IRB_MAILBOX}/messages/${messageId}/attachments/${att.id}`,
      { headers: { Authorization: `Bearer ${token}` } }
    )
    const detailText = await detailRes.text()
    if (!detailRes.ok) {
      console.error(`mailbox-poller attachments [${messageId}]: detail fetch failed for "${att.name}" (${detailRes.status}) ${detailText}`)
      continue
    }

    const detail = JSON.parse(detailText) as GraphAttachment
    console.log(
      `mailbox-poller attachments [${messageId}]: detail for "${att.name}" hasContentBytes=${Boolean(detail.contentBytes)}`
    )
    if (!detail.contentBytes) {
      continue
    }

    supported.push({
      id: detail.id,
      name: detail.name,
      contentType: detail.contentType,
      contentBytes: detail.contentBytes,
      size: detail.size,
      '@odata.type': detail['@odata.type'],
    })
  }

  console.log(`mailbox-poller attachments [${messageId}]: usable contentBytes attachments ${supported.length}`)
  return supported
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

function extractStudentPhone(bodyText: string): string | null {
  const compact = bodyText.replace(/[\s()-]/g, '')
  const intlMatch = compact.match(/\+233\d{9}\b/)
  if (intlMatch) return intlMatch[0]

  const localMatch = compact.match(/\b0\d{9}\b/)
  if (localMatch) {
    return `+233${localMatch[0].slice(1)}`
  }

  return null
}

function extractResearchTitle(subject: string): string {
  // Strip leading student ID if present: "47822026 IRB Application: ..."
  const withoutId = subject.replace(/^\d{6,10}\s+/, '').trim()
  // Strip "IRB Application:" / "IRB Application —" prefix
  const withoutPrefix = withoutId.replace(/^IRB Application[\s:—–-]+/i, '').trim()
  return withoutPrefix || withoutId
}

function normaliseName(name: string): string {
  return name.replace(/\s+/g, ' ').trim()
}

async function triggerSubmissionNotifications(applicationId: string): Promise<void> {
  const res = await fetch(SEND_NOTIFICATION_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${SUPABASE_SERVICE_KEY}`,
    },
    body: JSON.stringify({
      application_id: applicationId,
      channels: ['push', 'email', 'sms'],
      status: 'PENDING',
      reviewer_note: 'Application received via email.',
    }),
  })

  if (!res.ok) {
    const text = await res.text()
    throw new Error(`send-notification ${res.status}: ${text}`)
  }
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
    const senderName  = normaliseName(email.from.emailAddress.name || senderEmail)
    const bodyText  = email.body.contentType === 'html'
      ? stripHtml(email.body.content)
      : email.body.content

    const studentId     = extractStudentId(email.subject, bodyText)
    const studentPhone  = extractStudentPhone(bodyText)
    const researchTitle = extractResearchTitle(email.subject)

    const { data: existing } = await supabase
      .from('applications')
      .select('id')
      .eq('student_email', senderEmail)
      .eq('subject', researchTitle)
      .eq('submission_method', 'email')
      .maybeSingle()

    if (existing) {
      await markAsRead(token, messageId)
      return { messageId, status: 'skipped', detail: 'duplicate' }
    }

    const { data: app, error: appErr } = await supabase
      .from('applications')
      .insert({
        student_id:        studentId || senderEmail,
        student_name:      senderName,
        student_email:     senderEmail,
        student_phone:     studentPhone,
        subject:           researchTitle,
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
    })

    console.log(`mailbox-poller [${messageId}]: hasAttachments=${Boolean(email.hasAttachments)}`)

    if (email.hasAttachments) {
      const attachments = await fetchAttachments(token, messageId)
      console.log(`mailbox-poller [${messageId}]: processing ${attachments.length} fetched attachment(s)`)

      for (const att of attachments) {
        const binary      = atob(att.contentBytes)
        const bytes       = new Uint8Array(binary.length)
        for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i)

        const storagePath = `${app.id}/${Date.now()}_${att.name}`
        console.log(`mailbox-poller [${messageId}]: uploading "${att.name}" to storage path "${storagePath}"`)

        const { error: uploadErr } = await supabase.storage
          .from('attachments')
          .upload(storagePath, bytes, { contentType: att.contentType, upsert: false })

        if (uploadErr) {
          console.error(`Attachment upload failed (${att.name}):`, uploadErr.message)
          continue
        }

        console.log(`mailbox-poller [${messageId}]: upload succeeded for "${att.name}"`)

        const { error: attachmentInsertErr } = await supabase.from('attachments').insert({
          application_id: app.id,
          file_name:      att.name,
          file_type:      att.contentType,
          storage_url:    storagePath,
        })
        if (attachmentInsertErr) {
          console.error(`Attachment row insert failed (${att.name}):`, attachmentInsertErr.message)
          continue
        }

        console.log(`mailbox-poller [${messageId}]: attachment row inserted for "${att.name}"`)
      }
    } else {
      console.log(`mailbox-poller [${messageId}]: email reported no attachments`)
    }

    try {
      await triggerSubmissionNotifications(app.id)
      console.log(`mailbox-poller [${messageId}]: send-notification triggered for ${app.id}`)
    } catch (notificationErr) {
      console.error(`mailbox-poller [${messageId}]: send-notification failed`, notificationErr)
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
