import '/backend/supabase.dart';
import '/components/result_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_status_lookup_model.dart';
export 'student_status_lookup_model.dart';

class StudentStatusLookupWidget extends StatefulWidget {
  const StudentStatusLookupWidget({super.key});

  static String routeName = 'StudentStatusLookup';
  static String routePath = '/studentStatusLookup';

  @override
  State<StudentStatusLookupWidget> createState() =>
      _StudentStatusLookupWidgetState();
}

class _StudentStatusLookupWidgetState extends State<StudentStatusLookupWidget> {
  late StudentStatusLookupModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StudentStatusLookupModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
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
      body: SingleChildScrollView(
        primary: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4.0,
                    color: Color(0x1A000000),
                    offset: Offset(
                      0.0,
                      2.0,
                    ),
                    spreadRadius: 0.0,
                  )
                ],
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 4.0,
                ),
              ),
              child: Stack(
                children: [
                Padding(
                padding: EdgeInsetsDirectional.fromSTEB(16.0, 32.0, 16.0, 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'ASHESI IRB',
                      style:
                          FlutterFlowTheme.of(context).headlineMedium.override(
                                font: GoogleFonts.zillaSlab(
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                fontSize: 26.0,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w900,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineMedium
                                    .fontStyle,
                                lineHeight: 1.2,
                              ),
                    ),
                    Text(
                      'STUDENT STATUS PORTAL',
                      style: FlutterFlowTheme.of(context).labelLarge.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontStyle,
                            ),
                            color: Colors.white,
                            fontSize: 14.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontStyle,
                            lineHeight: 1.3,
                          ),
                    ),
                  ].divide(SizedBox(height: 8.0)),
                ),
              ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => context.pushNamed('WebSubmissionForm'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'SUBMIT APPLICATION',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860.0),
                child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            color: Color(0x1A000000),
                            offset: Offset(
                              0.0,
                              2.0,
                            ),
                            spreadRadius: 0.0,
                          )
                        ],
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 3.0,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Track your application',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.zillaSlab(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 17.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                    lineHeight: 1.3,
                                  ),
                            ),
                            Text(
                              'Enter your student ID to view the current status of your research ethics application.',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodySmall
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Student ID',
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
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
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
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context).secondaryBackground,
                                            border: Border.all(
                                              color: FlutterFlowTheme.of(context).divider,
                                              width: 2.0,
                                            ),
                                          ),
                                          child: Container(
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(8.0, 8.0, 8.0, 8.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.badge_rounded,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    size: 16.0,
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: TextField(
                                                      controller: _model.studentIdController,
                                                      keyboardType: TextInputType.number,
                                                      decoration: InputDecoration(
                                                        hintText: 'e.g. 88292024',
                                                        border: InputBorder.none,
                                                        isDense: true,
                                                        contentPadding: EdgeInsets.zero,
                                                      ),
                                                      style: FlutterFlowTheme.of(context).bodyMedium,
                                                    ),
                                                  ),
                                                ].divide(SizedBox(width: 8.0)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 0.0,
                                          height: 0.0,
                                        ),
                                      ].divide(SizedBox(height: 6.0)),
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(width: 8.0)),
                            ),
                            GestureDetector(
                              onTap: _model.isSearching
                                  ? null
                                  : () async {
                                      final query = _model.studentIdController.text.trim();
                                      if (query.isEmpty) return;
                                      safeSetState(() => _model.isSearching = true);
                                      try {
                                        final data = await supabase
                                            .from('applications')
                                            .select()
                                            .eq('student_id', query)
                                            .order('submitted_at', ascending: false);
                                        final results = List<Map<String, dynamic>>.from(data);

                                        // Batch-fetch the most recent reviewer note
                                        // per application so the student can see
                                        // any feedback left on their submission.
                                        final Map<String, String?> notes = {};
                                        if (results.isNotEmpty) {
                                          final ids = results
                                              .map((r) => r['id']?.toString())
                                              .whereType<String>()
                                              .toList();
                                          try {
                                            final histRows = await supabase
                                                .from('status_history')
                                                .select('application_id, note')
                                                .filter('application_id', 'in', '(${ids.join(',')})')
                                                .not('note', 'is', null)
                                                .order('changed_at', ascending: false);
                                            for (final row in histRows) {
                                              final id = row['application_id'] as String?;
                                              if (id != null && !notes.containsKey(id)) {
                                                notes[id] = row['note'] as String?;
                                              }
                                            }
                                          } catch (_) {}
                                        }

                                        safeSetState(() {
                                          _model.results = results;
                                          _model.notes = notes;
                                          _model.hasSearched = true;
                                          _model.isSearching = false;
                                        });
                                      } catch (_) {
                                        safeSetState(() {
                                          _model.isSearching = false;
                                          _model.hasSearched = true;
                                        });
                                      }
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _model.isSearching ? Icons.hourglass_empty_rounded : Icons.search_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryBackground,
                                          size: 16.0,
                                        ),
                                        Text(
                                          _model.isSearching ? 'Searching...' : 'Check Status',
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
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                    if (_model.hasSearched && _model.results.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No applications found for that student ID.',
                          textAlign: TextAlign.center,
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                      ),
                    ..._model.results.map((app) {
                      final appId = app['id']?.toString() ?? '';
                      final status = (app['status'] as String?) ?? 'PENDING';
                      final note = _model.notes[appId];
                      final statusBg = status == 'APPROVED'
                          ? 'success'
                          : status == 'REJECTED'
                              ? 'error'
                              : 'accent';
                      return ResultCardWidget(
                        name: (app['student_name'] as String?) ?? '',
                        id: (app['student_id'] as String?) ?? '',
                        status_bg: statusBg,
                        status: status,
                        title: (app['subject'] as String?) ?? '',
                        has_notes: note != null && note.isNotEmpty,
                        notes: note,
                      );
                    }).toList(),
                    Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFE8E2D6),
                        borderRadius: BorderRadius.circular(0.0),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_rounded,
                              color: const Color(0xFF4A4A4A),
                              size: 24.0,
                            ),
                            Expanded(
                              flex: 1,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Need Help?',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                      fontSize: 14.0,
                                      height: 1.3,
                                    ),
                                  ),
                                  Text(
                                    'If you cannot find your application or have questions, please contact the IRB coordinator at irb@ashesi.edu.gh',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.normal,
                                      color: const Color(0xFF4A4A4A),
                                      fontSize: 12.0,
                                      height: 1.4,
                                    ),
                                  ),
                                ].divide(SizedBox(height: 4.0)),
                              ),
                            ),
                          ].divide(SizedBox(width: 16.0)),
                        ),
                      ),
                    ),
                  ].divide(SizedBox(height: 24.0)),
                ),
              ),
              ),
            ),
            Container(
              height: 80.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).secondary,
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 4.0,
                ),
              ),
              alignment: AlignmentDirectional(0.0, 0.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'OFFICIAL ASHESI UNIVERSITY IRB',
                    style: FlutterFlowTheme.of(context).labelSmall.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          fontSize: 10.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.bold,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelSmall.fontStyle,
                          lineHeight: 1.2,
                        ),
                  ),
                  Opacity(
                    opacity: 0.8,
                    child: Text(
                      '© 2024 RESEARCH ETHICS COMMITTEE',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            fontSize: 10.0,
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.bold,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.2,
                          ),
                    ),
                  ),
                ].divide(SizedBox(height: 4.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
