# Local Resources Evidence

## 1) Offline Data Cache
Library: **hive_flutter**

### Import and usage evidence

```dart
// lib/main.dart
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('irb_cache');
  runApp(MyApp());
}
```

```dart
// lib/reviewer_dashboard/reviewer_dashboard_model.dart
import 'package:hive_flutter/hive_flutter.dart';

static const _cacheKey = 'applications';

void cacheApplications(List<Map<String, dynamic>> apps) {
  final box = Hive.box('irb_cache');
  box.put(_cacheKey, jsonEncode(apps));
}

List<Map<String, dynamic>> loadCachedApplications() {
  final box = Hive.box('irb_cache');
  final raw = box.get(_cacheKey) as String?;
  if (raw == null) return [];
  final list = jsonDecode(raw) as List<dynamic>;
  return list.cast<Map<String, dynamic>>();
}
```

```dart
// lib/reviewer_dashboard/reviewer_dashboard_widget.dart — StreamBuilder
if (snapshot.hasData) {
  _model.cacheApplications(snapshot.data!);  // write to cache on fetch
}
// On cold start offline — load from cache instead of hanging
final cached = _model.loadCachedApplications();
if (cached.isNotEmpty) {
  all = cached;
}
```

```dart
// lib/login/login_widget.dart — save reviewer identity on login
Hive.box('irb_cache').put('reviewer_email', email);
```

```dart
// lib/splash_screen/splash_screen_widget.dart — bypass login when offline
final results = await Connectivity().checkConnectivity();
final offline = results.every((r) => r == ConnectivityResult.none);
final cachedEmail = Hive.box('irb_cache').get('reviewer_email') as String?;
if (offline && cachedEmail != null) {
  context.go(ReviewerDashboardWidget.routePath);
} else {
  context.go(LoginWidget.routePath);
}
```

How it was used:
- Applications list is written to Hive every time a live Supabase fetch succeeds.
- On cold start with no internet, the splash screen detects offline state and skips login entirely if a reviewer has previously signed in, going straight to the dashboard.
- The dashboard loads cached applications from Hive instead of hanging on a failed network request.
- A pending status-update queue is also stored in Hive and flushed to Supabase when connectivity returns.

---

## 2) Offline Action Queue
Library: **hive_flutter** (same box, different key)

### Import and usage evidence

```dart
// lib/reviewer_dashboard/reviewer_dashboard_model.dart
static const _queueKey = 'status_update_queue';

void enqueueStatusUpdate(String applicationId, String newStatus) {
  final box = Hive.box('irb_cache');
  final raw = box.get(_queueKey) as String? ?? '[]';
  final queue = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  queue.add({
    'application_id': applicationId,
    'status': newStatus,
    'queued_at': DateTime.now().toIso8601String(),
  });
  box.put(_queueKey, jsonEncode(queue));
}

void clearQueue() {
  Hive.box('irb_cache').put(_queueKey, '[]');
}
```

```dart
// lib/reviewer_dashboard/reviewer_dashboard_widget.dart — flush queue on reconnect
if (!offline) {
  final queue = _model.loadQueue();
  if (queue.isNotEmpty) {
    for (final item in queue) {
      await supabase
          .from('applications')
          .update({'status': item['status']})
          .eq('id', item['application_id']);
    }
    _model.clearQueue();
  }
}
```

How it was used:
- When a reviewer updates an application status while offline, the update is queued locally in Hive.
- When the device reconnects, the dashboard automatically flushes the queue to Supabase.

---

## 3) Temporary In-App PDF Render File
Libraries: **path_provider**, **dart:io**, **flutter_pdfview**

### Import and usage evidence

```dart
// lib/document_viewer/document_viewer_widget.dart
import 'dart:io';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
```

```dart
// lib/document_viewer/document_viewer_widget.dart
final bytes = await supabase.storage.from('attachments').download(path);
final cacheDir = await getTemporaryDirectory();
final fileName = _safeFileName(widget.fileName ?? path.split('/').last);
final file = File('${cacheDir.path}/irb_attachment_$fileName');
await file.writeAsBytes(bytes, flush: true);
```

```dart
// lib/document_viewer/document_viewer_widget.dart
return PDFView(
  filePath: path,
  enableSwipe: true,
  swipeHorizontal: false,
  onViewCreated: (controller) {
    _pdfController = controller;
  },
  onRender: (pages) {
    safeSetState(() => _pageCount = pages ?? 0);
  },
  onPageChanged: (page, _) {
    safeSetState(() => _currentPage = page ?? 0);
  },
);
```

How it was used:
- Private Supabase Storage remains the source of truth for attachment files.
- When a reviewer opens an attachment, the app downloads the PDF bytes from the private `attachments` bucket.
- The app writes a temporary local copy using `getTemporaryDirectory()` so the native PDF viewer can render from a device file path.
- The temporary directory is intentionally used here because this is only a render copy. The operating system may clear it, and the app should be able to recreate it by downloading the attachment again.
- Page count, current page, and previous/next navigation are handled inside the app through `flutter_pdfview`.

Why this is a local resource:
- The app creates and reads a local file on the device using `dart:io`.
- The file is stored in the app's temporary/cache area through `path_provider`.
- This is local file usage for in-app rendering, not yet full offline attachment persistence.

---

## 4) Platform-Assisted Attachment Opening
Library: **url_launcher**

### Import and usage evidence

```dart
// lib/document_viewer/document_viewer_widget.dart
import 'package:url_launcher/url_launcher.dart';
```

```dart
// lib/document_viewer/document_viewer_widget.dart
final url = await supabase.storage
    .from('attachments')
    .createSignedUrl(path, 3600);

launchUrl(Uri.parse(_signedUrl!));
```

How it was used:
- The app creates a short-lived signed URL for a private Supabase attachment.
- The open-in-browser button launches that URL using the device platform.
- On Android this can appear as an in-app browser/custom tab instead of a full external browser app.

Why this is documented here:
- This is not offline storage and not a persistent local file resource.
- It is still a device/platform integration because the app delegates document viewing to a local platform capability through `url_launcher`.
- This is the baseline document-opening path. The in-app PDF renderer is the stronger implementation for reviewer workflow because the reviewer stays inside the app.

---

## Planned: Persistent Attachment File Cache
Libraries: **path_provider**, **dart:io**, likely **hive_flutter** for metadata

This is not fully implemented yet. The current document viewer uses `getTemporaryDirectory()` for a render-only copy. True offline attachment access should use `getApplicationDocumentsDirectory()` because files in the documents directory survive app restarts and are only cleared when the app is deleted.

Planned storage design:
- Store attachment file bytes as files in the app documents directory, not inside Hive.
- Use Hive only for metadata such as `application_id`, `file_name`, `storage_url`, local file path, file size, cached timestamp, and last opened timestamp.
- Keep Supabase Storage as the source of truth and treat local files as cached copies.

Planned cache limits:
- Per-file size limit: cache only files at or below a defined threshold, for example 10 MB to match the current submission UI limit.
- Total cache limit: enforce a maximum total attachment cache size, for example 250 MB, to avoid uncontrolled device storage growth.
- Date window: cache attachments for active/recent applications only, for example submissions from today back to the previous 2 months.
- Eviction policy: delete oldest or least recently opened cached files first when the total cache exceeds the limit.
- Offline messaging: if a file was too large or too old to cache, show a clear offline message such as `This attachment was not cached for offline viewing because it exceeds the offline cache limit. Connect to the internet to open it.`

Reasoning:
- Hive is appropriate for small structured metadata and queues.
- PDF/Word files can be large binary assets, so they should be stored as files on disk.
- The documents directory is appropriate only when the product requirement is offline persistence. The temporary directory is better for one-time preview copies.
