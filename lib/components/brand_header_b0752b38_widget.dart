import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'brand_header_b0752b38_model.dart';
export 'brand_header_b0752b38_model.dart';

class BrandHeaderB0752b38Widget extends StatefulWidget {
  const BrandHeaderB0752b38Widget({super.key});

  @override
  State<BrandHeaderB0752b38Widget> createState() =>
      _BrandHeaderB0752b38WidgetState();
}

class _BrandHeaderB0752b38WidgetState extends State<BrandHeaderB0752b38Widget> {
  late BrandHeaderB0752b38Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BrandHeaderB0752b38Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(60.0),
          child: Container(
            width: 120.0,
            height: 120.0,
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
              borderRadius: BorderRadius.circular(60.0),
              border: Border.all(
                color: FlutterFlowTheme.of(context).divider,
                width: 4.0,
              ),
            ),
            child: Container(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CachedNetworkImage(
                  fadeInDuration: Duration(milliseconds: 0),
                  fadeOutDuration: Duration(milliseconds: 0),
                  imageUrl:
                      'https://dimg.dreamflow.cloud/v1/image/Ashesi%20University%20crest%20academic%20logo',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Text(
          'IRB MANAGER',
          style: FlutterFlowTheme.of(context).headlineLarge.override(
                font: GoogleFonts.zillaSlab(
                  fontWeight: FontWeight.w900,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                fontSize: 32.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w900,
                fontStyle: FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                lineHeight: 1.1,
              ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).accent1,
              border: Border.all(
                color: FlutterFlowTheme.of(context).divider,
                width: 2.0,
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 12.0, 4.0),
              child: Text(
                'OFFICIAL COMMITTEE PORTAL',
                style: FlutterFlowTheme.of(context).labelLarge.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.bold,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      lineHeight: 1.3,
                    ),
              ),
            ),
          ),
        ),
      ].divide(SizedBox(height: 16.0)),
    );
  }
}
