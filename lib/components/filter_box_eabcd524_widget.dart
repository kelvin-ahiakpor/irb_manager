import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'filter_box_eabcd524_model.dart';
export 'filter_box_eabcd524_model.dart';

class FilterBoxEabcd524Widget extends StatefulWidget {
  const FilterBoxEabcd524Widget({
    super.key,
    this.selected,
    this.label,
  });

  final bool? selected;
  final String? label;

  @override
  State<FilterBoxEabcd524Widget> createState() =>
      _FilterBoxEabcd524WidgetState();
}

class _FilterBoxEabcd524WidgetState extends State<FilterBoxEabcd524Widget> {
  late FilterBoxEabcd524Model _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FilterBoxEabcd524Model());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2.0),
      child: Container(
        decoration: BoxDecoration(
          color: widget!.selected == false
              ? FlutterFlowTheme.of(context).secondaryBackground
              : FlutterFlowTheme.of(context).primary,
          border: Border.all(
            color: FlutterFlowTheme.of(context).divider,
            width: 2.0,
          ),
        ),
        alignment: AlignmentDirectional(0.0, 0.0),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(4.0, 8.0, 4.0, 8.0),
          child: Text(
            valueOrDefault<String>(
              widget!.label,
              'ALL',
            ),
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                  ),
                  color: widget!.selected == false
                      ? FlutterFlowTheme.of(context).primaryText
                      : FlutterFlowTheme.of(context).primaryBackground,
                  fontSize: 10.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.bold,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                  lineHeight: 1.2,
                ),
          ),
        ),
      ),
    );
  }
}
