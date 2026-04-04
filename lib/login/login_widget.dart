import '/components/brand_header_widget.dart';
import '/components/microsoft_button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());

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
                            wrapWithModel(
                              model: _model.microsoftButtonModel,
                              updateCallback: () => safeSetState(() {}),
                              child: MicrosoftButtonWidget(),
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
