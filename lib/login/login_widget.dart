import '/backend/supabase.dart';
import '/components/brand_header_widget.dart';
import '/index.dart' show ReviewerDashboardWidget;
import '/components/microsoft_button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;
  late final StreamSubscription<AuthState> _authSubscription;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

    _authSubscription = supabase.auth.onAuthStateChange.listen(
      _handleAuthChange,
      onError: _handleAuthError,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = supabase.auth.currentSession;
      if (session != null) {
        _handleSignedInSession(session);
      }
    });
  }

  Future<void> _handleAuthChange(AuthState state) async {
    if (state.event != AuthChangeEvent.signedIn) return;
    await _handleSignedInSession(state.session);
  }

  Future<void> _handleSignedInSession(Session? session) async {
    final email = session?.user.email;
    if (email == null) {
      await _safeSignOut();
      safeSetState(
          () => _model.errorMessage = 'Could not retrieve your account email.');
      return;
    }

    safeSetState(() {
      _model.isLoading = true;
      _model.errorMessage = null;
    });

    try {
      final row = await supabase
          .from('reviewers')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (!mounted) return;

      if (row != null) {
        if (!kIsWeb) {
          try {
            final token = await FirebaseMessaging.instance.getToken();
            if (token != null) {
              await supabase
                  .from('reviewers')
                  .update({'device_token': token}).eq('email', email);
            }
          } catch (_) {}
        }
        if (!mounted) return;
        context.go(ReviewerDashboardWidget.routePath);
      } else {
        await _safeSignOut();
        safeSetState(() {
          _model.isLoading = false;
          _model.errorMessage =
              'Access denied. $email is not an authorized IRB reviewer.';
        });
      }
    } catch (e) {
      debugPrint('IRB login error: $e');
      if (_isRetryableNetworkError(e)) {
        safeSetState(() {
          _model.isLoading = false;
          _model.errorMessage =
              'Could not reach Supabase. Check your internet connection and try again.';
        });
        return;
      }

      await _safeSignOut();
      safeSetState(() {
        _model.isLoading = false;
        _model.errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  void _handleAuthError(Object error, StackTrace stackTrace) {
    debugPrint('Supabase auth callback error: $error');
    debugPrintStack(stackTrace: stackTrace);

    if (supabase.auth.currentSession != null) {
      return;
    }

    safeSetState(() {
      _model.isLoading = false;
      _model.errorMessage = _isRetryableNetworkError(error)
          ? 'Could not reach Supabase. Check your internet connection and try again.'
          : error is AuthException
              ? 'Sign-in failed: ${error.message}'
              : 'Sign-in failed. Please try again.';
    });
  }

  bool _isRetryableNetworkError(Object error) {
    if (error is AuthRetryableFetchException) return true;
    final message = error.toString();
    return message.contains('Failed host lookup') ||
        message.contains('SocketException') ||
        message.contains('Connection timed out');
  }

  Future<void> _safeSignOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('Supabase sign-out failed: $e');
    }
  }

  Future<void> _signInWithMicrosoft() async {
    safeSetState(() => _model.errorMessage = null);
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.azure,
        redirectTo: 'gh.edu.ashesi.irbmanager://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
        scopes: 'email profile openid',
      );
    } catch (e) {
      safeSetState(() =>
          _model.errorMessage = 'Could not launch sign-in. Please try again.');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
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
            Transform.rotate(
              angle: 15.0 * (math.pi / 180),
              child: Opacity(
                opacity: 0.1,
                child: Align(
                  alignment: AlignmentDirectional(1.0, -1.0),
                  child: Container(
                    width: 200.0,
                    height: 200.0,
                    alignment: AlignmentDirectional(1.0, -1.0),
                    child: Icon(
                      Icons.account_balance_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 180.0,
                    ),
                  ),
                ),
              ),
            ),
            Transform.rotate(
              angle: -10.0 * (math.pi / 180),
              child: Opacity(
                opacity: 0.1,
                child: Align(
                  alignment: AlignmentDirectional(-1.0, 1.0),
                  child: Container(
                    width: 150.0,
                    height: 150.0,
                    alignment: AlignmentDirectional(-1.0, 1.0),
                    child: Icon(
                      Icons.description_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 140.0,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              child: Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 32.0, 24.0, 32.0),
                  child: SingleChildScrollView(
                    primary: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 32.0,
                        ),
                        wrapWithModel(
                          model: _model.brandHeaderModel,
                          updateCallback: () => safeSetState(() {}),
                          child: BrandHeaderWidget(),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (_model.isLoading)
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                  color: FlutterFlowTheme.of(context).primary,
                                  strokeWidth: 2.0,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: _signInWithMicrosoft,
                                child: wrapWithModel(
                                  model: _model.microsoftButtonModel,
                                  updateCallback: () => safeSetState(() {}),
                                  child: MicrosoftButtonWidget(),
                                ),
                              ),
                            Text(
                              'Use your Ashesi Microsoft 365 account',
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
                          ].divide(SizedBox(height: 16.0)),
                        ),
                        Container(
                          height: 32.0,
                        ),
                        if (_model.errorMessage != null)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                24.0, 0.0, 24.0, 0.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                border: Border.all(
                                  color: Color(0xFFC0392B),
                                  width: 2.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.block_rounded,
                                        color: Color(0xFFC0392B), size: 20.0),
                                    SizedBox(width: 12.0),
                                    Expanded(
                                      child: Text(
                                        _model.errorMessage!,
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
                                              color: Color(0xFFC0392B),
                                              fontSize: 11.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                              lineHeight: 1.4,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 0.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(0.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).divider,
                                width: 2.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_rounded,
                                    color:
                                        FlutterFlowTheme.of(context).secondary,
                                    size: 20.0,
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      'Access is restricted to authorized Ashesi IRB committee members only.',
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
                                            lineHeight: 1.4,
                                          ),
                                    ),
                                  ),
                                ].divide(SizedBox(width: 16.0)),
                              ),
                            ),
                          ),
                        ),
                      ].divide(SizedBox(height: 32.0)),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional(0.0, 1.0),
              child: Container(
                height: 12.0,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).primary,
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).divider,
                    width: 3.0,
                  ),
                ),
                alignment: AlignmentDirectional(0.0, 1.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondary,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondary,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).accent1,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondary,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
                        ),
                      ),
                    ),
                    Container(
                      width: 40.0,
                      height: 12.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).divider,
                          width: 2.0,
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
    );
  }
}
