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
