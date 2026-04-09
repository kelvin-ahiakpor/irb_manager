import '/backend/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'document_viewer_model.dart';
export 'document_viewer_model.dart';

class DocumentViewerWidget extends StatefulWidget {
  const DocumentViewerWidget({
    super.key,
    this.storagePath,
    this.fileName,
  });

  final String? storagePath;
  final String? fileName;

  static String routeName = 'DocumentViewer';
  static String routePath = '/documentViewer';

  @override
  State<DocumentViewerWidget> createState() => _DocumentViewerWidgetState();
}

class _DocumentViewerWidgetState extends State<DocumentViewerWidget> {
  late DocumentViewerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  String? _signedUrl;
  bool _loadingUrl = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DocumentViewerModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSignedUrl());
  }

  Future<void> _loadSignedUrl() async {
    final path = widget.storagePath;
    if (path == null || path.isEmpty) {
      safeSetState(() => _loadingUrl = false);
      return;
    }
    try {
      final url = await supabase.storage
          .from('attachments')
          .createSignedUrl(path, 3600);
      safeSetState(() {
        _signedUrl = url;
        _loadingUrl = false;
      });
    } catch (_) {
      safeSetState(() => _loadingUrl = false);
    }
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        child: Stack(
          children: [
            Align(
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 80.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).divider,
                        width: 4.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          24.0, 16.0, 24.0, 16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FlutterFlowIconButton(
                            buttonSize: 44.0,
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: FlutterFlowTheme.of(context)
                                  .primaryBackground,
                              size: 28.0,
                            ),
                            onPressed: () => context.safePop(),
                          ),
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.fileName ?? 'Document',
                                      maxLines: 1,
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.zillaSlab(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: Colors.white,
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                            lineHeight: 1.3,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Opacity(
                                      opacity: 0.8,
                                      child: Text(
                                        _loadingUrl ? 'Loading...' : (_signedUrl != null ? 'Tap open to view in browser' : 'Preview unavailable'),
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
                                              color: Colors.white,
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
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          FlutterFlowIconButton(
                            buttonSize: 40.0,
                            icon: Icon(
                              Icons.open_in_browser_rounded,
                              color: FlutterFlowTheme.of(context)
                                  .primaryBackground,
                              size: 24.0,
                            ),
                            onPressed: _loadingUrl || _signedUrl == null
                                ? null
                                : () => launchUrl(Uri.parse(_signedUrl!)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF525659),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 8.0,
                                color: Color(0x1A000000),
                                offset: Offset(
                                  0.0,
                                  4.0,
                                ),
                                spreadRadius: 0.0,
                              )
                            ],
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).divider,
                              width: 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                fadeInDuration: Duration(milliseconds: 0),
                                fadeOutDuration: Duration(milliseconds: 0),
                                imageUrl:
                                    'https://dimg.dreamflow.cloud/v1/image/scanned document with academic text and signatures',
                                fit: BoxFit.contain,
                              ),
                              Align(
                                alignment: AlignmentDirectional(0.0, 1.0),
                                child: Container(
                                  alignment: AlignmentDirectional(0.0, 1.0),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color(0xAA000000),
                                        borderRadius:
                                            BorderRadius.circular(4.0),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 4.0, 12.0, 4.0),
                                        child: Text(
                                          'Page 3 of 12',
                                          style: FlutterFlowTheme.of(context)
                                              .labelMedium
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelMedium
                                                          .fontStyle,
                                                ),
                                                color: Colors.white,
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
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 24.0, 16.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56.0,
                                        height: 56.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .accent1,
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 2.0,
                                              color: Color(0x1A000000),
                                              offset: Offset(
                                                0.0,
                                                1.0,
                                              ),
                                              spreadRadius: 0.0,
                                            )
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .divider,
                                            width: 3.0,
                                          ),
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.add_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 28.0,
                                        ),
                                      ),
                                      Container(
                                        width: 56.0,
                                        height: 56.0,
                                        decoration: BoxDecoration(
                                          color: FlutterFlowTheme.of(context)
                                              .accent1,
                                          boxShadow: [
                                            BoxShadow(
                                              blurRadius: 2.0,
                                              color: Color(0x1A000000),
                                              offset: Offset(
                                                0.0,
                                                1.0,
                                              ),
                                              spreadRadius: 0.0,
                                            )
                                          ],
                                          borderRadius:
                                              BorderRadius.circular(0.0),
                                          border: Border.all(
                                            color: FlutterFlowTheme.of(context)
                                                .divider,
                                            width: 3.0,
                                          ),
                                        ),
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0),
                                        child: Icon(
                                          Icons.remove_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 28.0,
                                        ),
                                      ),
                                    ].divide(SizedBox(width: 16.0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Container(
                height: 100.0,
                alignment: AlignmentDirectional(0.0, 1.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      height: 80.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondary,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 4.0,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            24.0, 16.0, 24.0, 16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48.0,
                                  height: 48.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(0.0),
                                    border: Border.all(
                                      color:
                                          FlutterFlowTheme.of(context).divider,
                                      width: 3.0,
                                    ),
                                  ),
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 24.0,
                                  ),
                                ),
                                Container(
                                  width: 48.0,
                                  height: 48.0,
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(0.0),
                                    border: Border.all(
                                      color:
                                          FlutterFlowTheme.of(context).divider,
                                      width: 3.0,
                                    ),
                                  ),
                                  alignment: AlignmentDirectional(0.0, 0.0),
                                  child: Icon(
                                    Icons.chevron_right_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 24.0,
                                  ),
                                ),
                              ].divide(SizedBox(width: 8.0)),
                            ),
                            Container(
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).divider,
                                  width: 3.0,
                                ),
                              ),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'GO TO',
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
                                    Text(
                                      '3',
                                      style: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .override(
                                            font: GoogleFonts.zillaSlab(
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 17.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontStyle,
                                            lineHeight: 1.3,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 4.0)),
                                ),
                              ),
                            ),
                            Container(
                              height: 48.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).accent1,
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).divider,
                                  width: 3.0,
                                ),
                              ),
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit_note_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 20.0,
                                    ),
                                    Text(
                                      'ANNOTATE',
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 14.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.bold,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelLarge
                                                    .fontStyle,
                                            lineHeight: 1.3,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 0.0)),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, -1.0),
              child: Container(
                height: 4.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).accent1,
                ),
                alignment: AlignmentDirectional(0.0, -1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
