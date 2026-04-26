import '/backend/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/login/login_widget.dart';
import '/reviewer_dashboard/reviewer_dashboard_widget.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'splash_screen_model.dart';
export 'splash_screen_model.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({super.key});

  static String routeName = 'SplashScreen';
  static String routePath = '/splashScreen';

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget> {
  late SplashScreenModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SplashScreenModel());

    Future.delayed(const Duration(seconds: 2), _routeAfterStartup);

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  Future<void> _routeAfterStartup() async {
    if (!mounted) return;

    // LOCAL RESOURCE: Hive — check if a reviewer has previously signed in.
    // If Supabase still has an active session we trust that and update the
    // cached email while we're at it. The cached email is the fallback for
    // when there's no session and no network — it lets the reviewer skip login
    // and go straight to the cached dashboard.
    final cachedEmail = Hive.box('irb_cache').get('reviewer_email') as String?;
    final sessionEmail = supabase.auth.currentSession?.user.email;

    if (sessionEmail != null) {
      Hive.box('irb_cache').put('reviewer_email', sessionEmail);
      if (!mounted) return;
      context.go(ReviewerDashboardWidget.routePath);
      return;
    }

    // LOCAL RESOURCE: connectivity_plus — check network state before deciding
    // whether to show login. If the device is offline and we have a cached
    // email, we skip login entirely. Forcing login when offline would be a dead
    // end because Supabase auth needs the network.
    final offline = await _isDefinitelyOffline();
    if (cachedEmail != null && (offline || !await _canReachSupabase())) {
      if (!mounted) return;
      context.go(ReviewerDashboardWidget.routePath);
      return;
    }

    if (!mounted) return;
    context.go(LoginWidget.routePath);
  }

  // LOCAL RESOURCE: connectivity_plus — reads the OS-level network interfaces.
  // Returns true only when every interface reports no connection, so a device
  // on WiFi with no actual internet still passes through to _canReachSupabase.
  Future<bool> _isDefinitelyOffline() async {
    try {
      final results = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 2));
      return results.every((r) => r == ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  Future<bool> _canReachSupabase() async {
    try {
      await supabase
          .from('reviewers')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 3));
      return true;
    } catch (e) {
      final message = e.toString();
      return !(e is TimeoutException ||
          message.contains('Failed host lookup') ||
          message.contains('SocketException') ||
          message.contains('Connection timed out'));
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
            Opacity(
              opacity: 0.05,
              child: Container(
                child: GridView(
                  padding: EdgeInsets.zero,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 32.0,
                    mainAxisSpacing: 32.0,
                    childAspectRatio: 1.0,
                  ),
                  shrinkWrap: true,
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 80.0,
                    ),
                    Icon(
                      Icons.description_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 80.0,
                    ),
                    Icon(
                      Icons.school_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 80.0,
                    ),
                    Icon(
                      Icons.assignment_turned_in_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 80.0,
                    ),
                    Icon(
                      Icons.policy_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 80.0,
                    ),
                    Icon(
                      Icons.verified_user_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 80.0,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              alignment: AlignmentDirectional(0.0, 0.0),
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
                          blurRadius: 8.0,
                          color: Color(0x1A000000),
                          offset: Offset(
                            0.0,
                            4.0,
                          ),
                          spreadRadius: 0.0,
                        )
                      ],
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 4.0,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: Color(0xFFFDFCFB),
                              borderRadius: BorderRadius.circular(50.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).accent1,
                                width: 3.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CachedNetworkImage(
                                fadeInDuration: Duration(milliseconds: 0),
                                fadeOutDuration: Duration(milliseconds: 0),
                                imageUrl:
                                    'https://dimg.dreamflow.cloud/v1/image/Ashesi University crest shield logo academic',
                                width: 80.0,
                                height: 80.0,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ASHESI IRB',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context)
                            .headlineLarge
                            .override(
                              font: GoogleFonts.zillaSlab(
                                fontWeight: FontWeight.w900,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .headlineLarge
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontSize: 32.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w900,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .headlineLarge
                                  .fontStyle,
                              lineHeight: 1.1,
                            ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).accent1,
                          border: Border.all(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              16.0, 4.0, 16.0, 4.0),
                          child: Text(
                            'MANAGER',
                            style: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  font: GoogleFonts.zillaSlab(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 17.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                  lineHeight: 1.2,
                                ),
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 8.0)),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularPercentIndicator(
                        percent: 1.0,
                        radius: 20.0,
                        lineWidth: 6.0,
                        animation: true,
                        animationDuration: 1800,
                        animateFromLastPercent: true,
                        progressColor: FlutterFlowTheme.of(context).primary,
                      ),
                      Text(
                        'INITIALIZING SECURE PORTAL',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 14.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontStyle,
                              lineHeight: 1.3,
                            ),
                      ),
                    ].divide(SizedBox(height: 16.0)),
                  ),
                ].divide(SizedBox(height: 32.0)),
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Container(
                height: 120.0,
                alignment: AlignmentDirectional(0.0, 1.0),
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Divider(
                        thickness: 4.0,
                        indent: 60.0,
                        endIndent: 60.0,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      Container(
                        height: 4.0,
                      ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: FlutterFlowTheme.of(context).secondaryText,
                              size: 18.0,
                            ),
                            Text(
                              'OFFICIAL COMMITTEE ACCESS ONLY',
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    fontSize: 10.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                            ),
                          ].divide(SizedBox(width: 8.0)),
                        ),
                      ),
                      Text(
                        '© 2024 ASHESI UNIVERSITY',
                        style: FlutterFlowTheme.of(context).labelSmall.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).primaryText,
                              fontSize: 10.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                              lineHeight: 1.2,
                            ),
                      ),
                    ].divide(SizedBox(height: 4.0)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
