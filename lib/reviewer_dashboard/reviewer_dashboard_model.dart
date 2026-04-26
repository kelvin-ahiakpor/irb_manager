import '/components/filter_box_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:convert';
import 'dart:ui';
import 'reviewer_dashboard_widget.dart' show ReviewerDashboardWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class ReviewerDashboardModel extends FlutterFlowModel<ReviewerDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Active filter label — matches the FilterBoxWidget label strings.
  String activeFilter = 'ALL';

  // Offline state
  bool isOffline = false;

  // ── Cache helpers ─────────────────────────────────────────────────────────
  //
  // LOCAL RESOURCE: Hive (key 'applications')
  // The full applications list is JSON-encoded and stored on device every time
  // a live Supabase fetch succeeds. When the device is offline, the dashboard
  // and the detail screen both read from here instead of hitting the network.
  // The application detail screen also uses this same key to look up individual
  // applications by ID without needing its own separate cache.

  static const _cacheKey = 'applications';

  /// Save latest applications list to Hive.
  void cacheApplications(List<Map<String, dynamic>> apps) {
    final box = Hive.box('irb_cache');
    box.put(_cacheKey, jsonEncode(apps));
  }

  /// Load cached applications. Returns empty list if nothing cached.
  List<Map<String, dynamic>> loadCachedApplications() {
    final box  = Hive.box('irb_cache');
    final raw  = box.get(_cacheKey) as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  // ── Offline action queue ──────────────────────────────────────────────────
  //
  // LOCAL RESOURCE: Hive (key 'status_update_queue')
  // When a reviewer changes an application status while offline, we can't
  // write to Supabase immediately. Instead we push the update onto a local
  // queue stored in Hive. The dashboard's connectivity listener picks this up
  // the moment the device reconnects and flushes everything to Supabase in
  // order. This means the reviewer never loses a decision just because they
  // were on a slow or missing connection.

  static const _queueKey = 'status_update_queue';

  void enqueueStatusUpdate(String applicationId, String newStatus) {
    final box   = Hive.box('irb_cache');
    final raw   = box.get(_queueKey) as String? ?? '[]';
    final queue = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    queue.add({'application_id': applicationId, 'status': newStatus, 'queued_at': DateTime.now().toIso8601String()});
    box.put(_queueKey, jsonEncode(queue));
  }

  List<Map<String, dynamic>> loadQueue() {
    final box = Hive.box('irb_cache');
    final raw = box.get(_queueKey) as String? ?? '[]';
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  void clearQueue() {
    Hive.box('irb_cache').put(_queueKey, '[]');
  }

  // Model for filter_box component.
  late FilterBoxModel filterBoxModel1;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel2;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel3;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel4;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel5;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel6;

  @override
  void initState(BuildContext context) {
    filterBoxModel1 = createModel(context, () => FilterBoxModel());
    filterBoxModel2 = createModel(context, () => FilterBoxModel());
    filterBoxModel3 = createModel(context, () => FilterBoxModel());
    filterBoxModel4 = createModel(context, () => FilterBoxModel());
    filterBoxModel5 = createModel(context, () => FilterBoxModel());
    filterBoxModel6 = createModel(context, () => FilterBoxModel());
  }

  @override
  void dispose() {
    filterBoxModel1.dispose();
    filterBoxModel2.dispose();
    filterBoxModel3.dispose();
    filterBoxModel4.dispose();
    filterBoxModel5.dispose();
    filterBoxModel6.dispose();
  }
}
