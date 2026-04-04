import '/components/file_item_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'web_submission_form_widget.dart' show WebSubmissionFormWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WebSubmissionFormModel extends FlutterFlowModel<WebSubmissionFormWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for file_item component.
  late FileItemModel fileItemModel1;
  // Model for file_item component.
  late FileItemModel fileItemModel2;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;

  @override
  void initState(BuildContext context) {
    fileItemModel1 = createModel(context, () => FileItemModel());
    fileItemModel2 = createModel(context, () => FileItemModel());
  }

  @override
  void dispose() {
    fileItemModel1.dispose();
    fileItemModel2.dispose();
  }
}
