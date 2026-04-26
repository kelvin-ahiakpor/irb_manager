import '/backend/supabase.dart';
import '/components/info_tile_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'application_detail_model.dart';
export 'application_detail_model.dart';

class ApplicationDetailWidget extends StatefulWidget {
  const ApplicationDetailWidget({super.key, this.applicationId});

  final String? applicationId;

  static String routeName = 'ApplicationDetail';
  static String routePath = '/applicationDetail';

  @override
  State<ApplicationDetailWidget> createState() =>
      _ApplicationDetailWidgetState();
}

class _ApplicationDetailWidgetState extends State<ApplicationDetailWidget> {
  late ApplicationDetailModel _model;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySub;
  bool _isOffline = false;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ApplicationDetailModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApplication());

    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        safeSetState(() => _isOffline = results.every((r) => r == ConnectivityResult.none));
      }
    });

    // When the device reconnects after showing cached data, reload from
    // Supabase so the banner clears and the reviewer sees fresh data.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (mounted) safeSetState(() => _isOffline = !online);
      if (online && _model.fromCache && mounted) {
        _model.fromCache = false;
        _loadApplication();
      }
    });
  }

  Future<void> _loadApplication() async {
    final id = widget.applicationId;
    if (id == null || id.isEmpty) {
      safeSetState(() {
        _model.isLoading = false;
        _model.errorMessage = 'No application ID provided.';
      });
      return;
    }
    try {
      final appData =
          await supabase.from('applications').select().eq('id', id).single();
      final attData = await supabase
          .from('attachments')
          .select()
          .eq('application_id', id)
          .order('uploaded_at', ascending: true);
      final attachments = List<Map<String, dynamic>>.from(attData);
      // Persist attachment metadata so the list shows while offline.
      // Actual PDF bytes are cached lazily — the DocumentViewer saves them to
      // persistent storage the first time each file is opened online.
      Hive.box('irb_cache').put('attachments_$id', jsonEncode(attachments));
      safeSetState(() {
        _model.application = appData;
        _model.attachments = attachments;
        _model.isLoading = false;
      });
    } catch (e) {
      final msg = e.toString();
      final isNotFound = msg.contains('PGRST116') || msg.contains('0 rows');

      if (!isNotFound) {
        // Network error — try Hive cache
        final cached = _loadFromCache(widget.applicationId!);
        if (cached != null) {
          safeSetState(() {
            _model.application = cached;
            _model.attachments = _loadAttachmentsFromCache(id);
            _model.isLoading = false;
            _model.fromCache = true;
          });
          return;
        }
      }

      final isOffline = msg.contains('SocketException') ||
          msg.contains('Failed host lookup') ||
          msg.contains('ClientException');
      safeSetState(() {
        _model.isLoading = false;
        _model.errorMessage =
            isNotFound ? 'not_found' : (isOffline ? 'offline' : msg);
      });
    }
  }

  // LOCAL RESOURCE: Hive — look up a single application from the cached list.
  // The dashboard already writes the full list to Hive every time it gets live
  // data, so we piggyback on that instead of maintaining a separate per-detail
  // cache. If the reviewer taps a card while offline, we scan the list for a
  // matching ID. If we find it, the detail screen loads normally with a banner
  // saying the data is from cache. If we don't find it (e.g. the app was never
  // opened online), we fall through to the "you're offline" error screen.
  Map<String, dynamic>? _loadFromCache(String id) {
    try {
      final box = Hive.box('irb_cache');
      final raw = box.get('applications') as String?;
      if (raw == null) return null;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      final match = list.firstWhere((a) => a['id'] == id, orElse: () => {});
      return match.isEmpty ? null : match;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> _loadAttachmentsFromCache(String id) {
    try {
      final raw = Hive.box('irb_cache').get('attachments_$id') as String?;
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  int _pendingQueuedChanges(String id) {
    try {
      final raw =
          Hive.box('irb_cache').get('status_update_queue') as String? ?? '[]';
      final queue = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return queue.where((item) => item['application_id'] == id).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_model.isLoading) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: FlutterFlowTheme.of(context).primary,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_model.errorMessage != null || _model.application == null) {
      final isNotFound = _model.errorMessage == 'not_found';
      final isOffline = _model.errorMessage == 'offline';
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOffline
                      ? Icons.wifi_off_rounded
                      : isNotFound
                          ? Icons.search_off_rounded
                          : Icons.error_outline_rounded,
                  size: 56,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
                const SizedBox(height: 16),
                Text(
                  isOffline
                      ? 'You\'re Offline'
                      : isNotFound
                          ? 'Application Not Found'
                          : 'Something went wrong',
                  style: FlutterFlowTheme.of(context).titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isOffline
                      ? 'Connect to the internet to view application details.'
                      : isNotFound
                          ? 'This application may have been deleted or is no longer available.'
                          : (_model.errorMessage ?? ''),
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        font: GoogleFonts.inter(),
                        color: FlutterFlowTheme.of(context).secondaryText,
                        letterSpacing: 0.0,
                        lineHeight: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FFButtonWidget(
                  onPressed: () => context.pop(),
                  text: 'Go Back',
                  options: FFButtonOptions(
                    height: 44.0,
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.inter(),
                          color: Colors.white,
                          letterSpacing: 0.0,
                        ),
                    borderRadius: BorderRadius.circular(8.0),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final app = _model.application!;
    final status = _displayStatus(app['status']);
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Stack(
          children: [
            Container(
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, _model.fromCache ? 148.0 : 120.0),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 140.0,
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primary,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).divider,
                            width: 4.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4.0),
                          child: ClipRect(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 0.4,
                                    child: CachedNetworkImage(
                                      fadeInDuration: Duration(milliseconds: 0),
                                      fadeOutDuration:
                                          Duration(milliseconds: 0),
                                      imageUrl:
                                          'https://dimg.dreamflow.cloud/v1/image/abstract academic mural with geometric patterns and figures',
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: AlignmentDirectional(0.0, 1.0),
                                  child: Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        20.0, 0.0, 20.0, 14.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            (app['student_name'] as String?) ??
                                                '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: FlutterFlowTheme.of(context)
                                                .headlineMedium
                                                .override(
                                                  font: GoogleFonts.zillaSlab(
                                                    fontWeight: FontWeight.w900,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineMedium
                                                            .fontStyle,
                                                  ),
                                                  color: Colors.white,
                                                  fontSize: 26.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w900,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .headlineMedium
                                                          .fontStyle,
                                                  lineHeight: 1.05,
                                                ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  12.0, 0.0, 0.0, 2.0),
                                          child: Container(
                                            constraints:
                                                BoxConstraints(maxWidth: 108.0),
                                            decoration: BoxDecoration(
                                              color:
                                                  _statusColor(context, status),
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .divider,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(5.0, 5.0, 5.0, 5.0),
                                              child: Text(
                                                status,
                                                maxLines: 2,
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w900,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primaryBackground,
                                                          fontSize: 10.0,
                                                          letterSpacing: 0.4,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                          lineHeight: 1.05,
                                                        ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'APPLICANT DETAILS',
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                      lineHeight: 1.3,
                                    ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: _infoText(
                                        context,
                                        'STUDENT ID',
                                        (app['student_id'] as String?) ?? '—'),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: _infoText(
                                        context,
                                        'PHONE',
                                        (app['student_phone'] as String?) ??
                                            '—'),
                                  ),
                                ].divide(SizedBox(width: 8.0)),
                              ),
                              _infoText(context, 'EMAIL ADDRESS',
                                  (app['student_email'] as String?) ?? '—'),
                            ].divide(SizedBox(height: 8.0)),
                          ),
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'RESEARCH PROPOSAL',
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                      lineHeight: 1.3,
                                    ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  border: Border.all(
                                    color: FlutterFlowTheme.of(context).divider,
                                    width: 2.0,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              (app['subject'] as String?) ?? '',
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleMedium
                                                  .override(
                                                    font: GoogleFonts.zillaSlab(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    fontSize: 17.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.bold,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleMedium
                                                            .fontStyle,
                                                    lineHeight: 1.3,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(width: 8.0),
                                          Icon(
                                            Icons.language_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 18.0,
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10.0),
                                      Divider(
                                        thickness: 1.0,
                                        color: FlutterFlowTheme.of(context)
                                            .divider,
                                      ),
                                      SizedBox(height: 10.0),
                                      Text(
                                        (app['body'] as String?) ?? '',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight: FontWeight.normal,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              fontSize: 14.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                              lineHeight: 1.5,
                                            ),
                                      ),
                                      SizedBox(height: 14.0),
                                      Text(
                                        'Submitted ${_formatSubmittedDate(app['submitted_at'])} via ${(app['submission_method'] as String?) == 'email' ? 'Email' : 'Web Form'}',
                                        style: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelSmall
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 10.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                              lineHeight: 1.2,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(height: 8.0)),
                          ),
                        ),
                      ),
                      Container(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'ATTACHMENTS (${_model.attachments.length})',
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryText,
                                          fontSize: 12.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                          lineHeight: 1.3,
                                        ),
                                  ),
                                  Text(
                                    'DOWNLOAD ALL',
                                    style: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontStyle,
                                          lineHeight: 1.2,
                                        ),
                                  ),
                                ],
                              ),
                              ..._model.attachments.isEmpty
                                  ? [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 8.0, 0.0, 4.0),
                                        child: Text(
                                          'No attachments.',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium,
                                        ),
                                      )
                                    ]
                                  : _model.attachments
                                      .map((att) =>
                                          _buildAttachmentRow(context, att))
                                      .toList(),
                            ].divide(SizedBox(height: 8.0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, -1.0),
              child: Padding(
                padding: EdgeInsetsDirectional.fromSTEB(4.0, 4.0, 4.0, 0.0),
                child: Container(
                  height: 76.0,
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 8.0,
                          sigmaY: 8.0,
                        ),
                        child: Container(
                          height: 80.0,
                          decoration: BoxDecoration(),
                          alignment: AlignmentDirectional(0.0, 1.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              FlutterFlowIconButton(
                                borderColor:
                                    FlutterFlowTheme.of(context).divider,
                                borderWidth: 2.0,
                                buttonSize: 40.0,
                                fillColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 24.0,
                                ),
                                onPressed: () => context.safePop(),
                              ),
                              Text(
                                'APPLICATION DETAILS',
                                style: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w900,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w900,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .fontStyle,
                                      lineHeight: 1.3,
                                    ),
                              ),
                              FlutterFlowIconButton(
                                borderColor:
                                    FlutterFlowTheme.of(context).divider,
                                borderWidth: 2.0,
                                buttonSize: 40.0,
                                fillColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 24.0,
                                ),
                                onPressed: () {
                                  print('IconButton pressed ...');
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_model.fromCache)
              Positioned(
                left: 0,
                right: 0,
                bottom: 110.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final pending = _pendingQueuedChanges(
                          widget.applicationId ?? '');
                      if (pending == 0) return const SizedBox.shrink();
                      return Container(
                        color: const Color(0xFF78350F),
                        padding: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 6),
                            Text(
                              '$pending pending update${pending > 1 ? 's' : ''} queued',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Container(
                      color: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(
                          vertical: 6.0, horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'Offline — showing cached data',
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600),
                                      color: Colors.white,
                                      letterSpacing: 0.0,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Container(
                height: 110.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).divider,
                    width: 4.0,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: () async {
                            if (_isOffline) {
                              final proceed = await showDialog<bool>(
                                context: context,
                                barrierColor: Colors.black54,
                                builder: (ctx) => Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      border: Border.all(
                                        color:
                                            FlutterFlowTheme.of(context).divider,
                                        width: 3,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          color: const Color(0xFFFEF3C7),
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.wifi_off_rounded,
                                                  size: 18,
                                                  color: Color(0xFF92400E)),
                                              const SizedBox(width: 10),
                                              Text(
                                                'YOU\'RE OFFLINE',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .titleSmall
                                                    .override(
                                                      font: GoogleFonts.zillaSlab(
                                                          fontWeight:
                                                              FontWeight.w800),
                                                      color:
                                                          const Color(0xFF92400E),
                                                      letterSpacing: 0.0,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            'You can still update the status. Your action will be queued and synced automatically when your connection returns.',
                                            style: FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .override(
                                                  font: GoogleFonts.inter(),
                                                  color:
                                                      FlutterFlowTheme.of(context)
                                                          .primaryText,
                                                  letterSpacing: 0.0,
                                                  lineHeight: 1.5,
                                                ),
                                          ),
                                        ),
                                        Divider(
                                            height: 1,
                                            color: FlutterFlowTheme.of(context)
                                                .divider),
                                        IntrinsicHeight(
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      Navigator.pop(ctx, false),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            vertical: 14),
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        top: BorderSide(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .divider,
                                                          width: 2,
                                                        ),
                                                        right: BorderSide(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .divider,
                                                          width: 1,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'CANCEL',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .inter(
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                  color: FlutterFlowTheme
                                                                          .of(
                                                                              context)
                                                                      .secondaryText,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      Navigator.pop(ctx, true),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            vertical: 14),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      border: Border(
                                                        top: BorderSide(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .divider,
                                                          width: 2,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        'CONTINUE',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .inter(
                                                                          fontWeight:
                                                                              FontWeight.bold),
                                                                  color: Colors
                                                                      .white,
                                                                  letterSpacing:
                                                                      0.0,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                              if (proceed != true) return;
                            }
                            await context.pushNamed(
                              'UpdateStatusSheet',
                              queryParameters: {
                                'applicationId': widget.applicationId ?? '',
                                'currentStatus':
                                    (app['status'] as String?) ?? 'PENDING',
                              },
                            );
                            await _loadApplication();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primary,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Stack(
                                alignment: AlignmentDirectional(0.0, 0.0),
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.edit_document,
                                        color: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        size: 16.0,
                                      ),
                                      Text(
                                        'UPDATE STATUS',
                                        style: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                              fontSize: 12.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                              lineHeight: 1.3,
                                            ),
                                      ),
                                      Container(
                                        width: 0.0,
                                        height: 0.0,
                                      ),
                                    ].divide(SizedBox(width: 8.0)),
                                  ),
                                  Container(
                                    width: 0.0,
                                    height: 0.0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 60.0,
                        height: 56.0,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).divider,
                            width: 3.0,
                          ),
                        ),
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: FlutterFlowIconButton(
                          buttonSize: 44.0,
                          icon: Icon(
                            Icons.history_rounded,
                            color: FlutterFlowTheme.of(context).primary,
                            size: 28.0,
                          ),
                          onPressed: () => _showHistory(context),
                        ),
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHistory(BuildContext context) async {
    final id = widget.applicationId;
    if (id == null) return;

    List<Map<String, dynamic>> history = [];
    bool historyFromCache = false;
    try {
      // Try with the reviewer join first; fall back to plain select if the
      // foreign-key relationship isn't exposed in the PostgREST schema cache.
      List<Map<String, dynamic>> rows;
      try {
        rows = List<Map<String, dynamic>>.from(await supabase
            .from('status_history')
            .select('old_status, new_status, note, changed_at, reviewers(email)')
            .eq('application_id', id)
            .order('changed_at', ascending: false));
      } catch (_) {
        rows = List<Map<String, dynamic>>.from(await supabase
            .from('status_history')
            .select('old_status, new_status, note, changed_at')
            .eq('application_id', id)
            .order('changed_at', ascending: false));
      }
      history = rows;
      Hive.box('irb_cache').put('history_$id', jsonEncode(history));
    } catch (_) {
      final raw = Hive.box('irb_cache').get('history_$id') as String?;
      if (raw != null) {
        history = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
        historyFromCache = true;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      color: FlutterFlowTheme.of(context).primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('STATUS HISTORY',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              font: GoogleFonts.inter(fontWeight: FontWeight.w800),
                              letterSpacing: 0.0,
                            )),
                  ),
                  if (historyFromCache)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      color: const Color(0xFFFEF3C7),
                      child: Text(
                        'CACHED',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700),
                              color: const Color(0xFF92400E),
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(color: FlutterFlowTheme.of(context).divider, height: 1),
            Expanded(
              child: history.isEmpty
                  ? Center(
                      child: Text('No status changes yet.',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.inter(),
                                color: FlutterFlowTheme.of(context).secondaryText,
                                letterSpacing: 0.0,
                              )))
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => Divider(
                          color: FlutterFlowTheme.of(context).divider,
                          height: 24),
                      itemBuilder: (_, i) {
                        final h = history[i];
                        final oldS = h['old_status'] as String? ?? '—';
                        final newS = h['new_status'] as String? ?? '—';
                        final note = h['note'] as String?;
                        final changedAt = h['changed_at'] as String?;
                        final reviewer = (h['reviewers'] as Map?)?['email'] as String?;
                        final dt = changedAt != null
                            ? DateTime.tryParse(changedAt)?.toLocal()
                            : null;
                        final dateStr = dt != null
                            ? '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                            : '—';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _statusChip(context, oldS),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.arrow_forward_rounded,
                                      size: 14),
                                ),
                                _statusChip(context, newS),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(dateStr,
                                style: FlutterFlowTheme.of(context)
                                    .bodySmall
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                    )),
                            if (reviewer != null)
                              Text('by $reviewer',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        font: GoogleFonts.inter(),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                        letterSpacing: 0.0,
                                      )),
                            if (note != null && note.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  border: Border.all(
                                      color:
                                          FlutterFlowTheme.of(context).divider),
                                ),
                                child: Text(note,
                                    style: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .override(
                                          font: GoogleFonts.inter(),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          letterSpacing: 0.0,
                                          lineHeight: 1.5,
                                        )),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status) {
    final color = switch (status.toUpperCase()) {
      'PENDING' => const Color(0xFFF59E0B),
      'IN REVIEW' || 'UNDER REVIEW' => FlutterFlowTheme.of(context).primary,
      'CONDITIONALLY APPROVED' => const Color(0xFF8B5CF6),
      'APPROVED' => const Color(0xFF10B981),
      'REJECTED' => FlutterFlowTheme.of(context).error,
      _ => FlutterFlowTheme.of(context).secondaryText,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status,
          style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                color: color,
                fontSize: 10,
                letterSpacing: 0.5,
              )),
    );
  }

  Widget _infoText(BuildContext context, String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        border: Border.all(
          color: FlutterFlowTheme.of(context).divider,
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontSize: 10.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                    lineHeight: 1.2,
                  ),
            ),
            Text(
              value,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).primaryText,
                    fontSize: 14.0,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    lineHeight: 1.4,
                  ),
            ),
          ].divide(SizedBox(height: 4.0)),
        ),
      ),
    );
  }

  String _displayStatus(Object? value) {
    final status = value.toString().trim().toUpperCase();
    return switch (status) {
      'UNDER REVIEW' || 'IN_REVIEW' || 'IN-REVIEW' => 'IN REVIEW',
      'CONDITIONALLY_APPROVED' ||
      'CONDITIONALLY-APPROVED' =>
        'CONDITIONALLY APPROVED',
      _ => status.isEmpty ? 'PENDING' : status,
    };
  }

  Color _statusColor(BuildContext context, String status) {
    return switch (status) {
      'APPROVED' => FlutterFlowTheme.of(context).success,
      'REJECTED' => FlutterFlowTheme.of(context).error,
      'IN REVIEW' => FlutterFlowTheme.of(context).accent1,
      'CONDITIONALLY APPROVED' => const Color(0xFFE06A3B),
      _ => FlutterFlowTheme.of(context).secondary,
    };
  }

  String _formatSubmittedDate(Object? value) {
    final submittedAt = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (submittedAt == null) return 'Unknown date';

    final day = submittedAt.day;
    final suffix = (day >= 11 && day <= 13)
        ? 'th'
        : switch (day % 10) {
            1 => 'st',
            2 => 'nd',
            3 => 'rd',
            _ => 'th',
          };
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '$day$suffix ${months[submittedAt.month - 1]} ${submittedAt.year}';
  }

  Widget _buildAttachmentRow(BuildContext context, Map<String, dynamic> att) {
    final fileName = (att['file_name'] as String?) ?? 'Attachment';
    final storagePath = (att['storage_url'] as String?) ??
        (att['storage_path'] as String?) ??
        '';
    final ext = fileName.split('.').last.toLowerCase();
    final icon = ext == 'pdf'
        ? Icons.picture_as_pdf_rounded
        : (ext == 'docx' || ext == 'doc')
            ? Icons.description_rounded
            : Icons.attach_file_rounded;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          border: Border.all(
            color: FlutterFlowTheme.of(context).divider,
            width: 2.0,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40.0,
                height: 40.0,
                decoration: BoxDecoration(
                  color: Color(0xFFF0F4F8),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).divider,
                    width: 1.0,
                  ),
                ),
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Icon(
                  icon,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 24.0,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontSize: 14.0,
                        letterSpacing: 0.0,
                        fontWeight: FontWeight.w600,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        lineHeight: 1.4,
                      ),
                ),
              ),
              FlutterFlowIconButton(
                buttonSize: 40.0,
                icon: Icon(
                  Icons.open_in_new_rounded,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 20.0,
                ),
                onPressed: () => context.pushNamed(
                  'DocumentViewer',
                  queryParameters: {
                    'storagePath': storagePath,
                    'fileName': fileName,
                  },
                ),
              ),
            ].divide(SizedBox(width: 16.0)),
          ),
        ),
      ),
    );
  }
}
