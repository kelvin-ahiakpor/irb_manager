import '/components/std_switch_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'update_status_sheet_widget.dart' show UpdateStatusSheetWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class UpdateStatusSheetModel extends FlutterFlowModel<UpdateStatusSheetWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for std_switch component.
  late StdSwitchModel stdSwitchModel;

  @override
  void initState(BuildContext context) {
    stdSwitchModel = createModel(context, () => StdSwitchModel());
  }

  @override
  void dispose() {
    stdSwitchModel.dispose();
  }
}
