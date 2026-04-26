import '/backend/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/login/login_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  static String routeName = 'Settings';
  static String routePath = '/settings';

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() => _isSigningOut = true);
    try {
      await Hive.box('irb_cache').delete('reviewer_email');
      await supabase.auth.signOut();
      if (!mounted) return;
      context.go(LoginWidget.routePath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign out failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? 'Reviewer';

    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).primary,
                border: Border.all(
                  color: FlutterFlowTheme.of(context).divider,
                  width: 4.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 0.0,
                      buttonSize: 40.0,
                      fillColor: const Color(0x22FFFFFF),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24.0,
                      ),
                      onPressed: () => context.safePop(),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SETTINGS',
                            style: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .override(
                                  font: GoogleFonts.zillaSlab(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  color: Colors.white,
                                  fontSize: 24.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            email,
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(),
                                      color: const Color(0xE6FFFFFF),
                                      letterSpacing: 0.0,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E2D6),
                  border: Border.all(
                    color: FlutterFlowTheme.of(context).divider,
                    width: 3.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).error,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).divider,
                        width: 2.0,
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 20.0,
                    ),
                  ),
                  title: Text(
                    'Log Out',
                    style: FlutterFlowTheme.of(context).titleMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w700),
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  subtitle: Text(
                    'End this reviewer session on the device.',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                        ),
                  ),
                  trailing: _isSigningOut
                      ? SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                        )
                      : Icon(
                          Icons.chevron_right_rounded,
                          color: FlutterFlowTheme.of(context).primaryText,
                        ),
                  onTap: _isSigningOut ? null : _signOut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
