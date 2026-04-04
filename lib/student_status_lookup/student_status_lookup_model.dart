import '/components/result_card_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'student_status_lookup_widget.dart' show StudentStatusLookupWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class StudentStatusLookupModel
    extends FlutterFlowModel<StudentStatusLookupWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for result_card component.
  late ResultCardModel resultCardModel1;
  // Model for result_card component.
  late ResultCardModel resultCardModel2;

  @override
  void initState(BuildContext context) {
    resultCardModel1 = createModel(context, () => ResultCardModel());
    resultCardModel2 = createModel(context, () => ResultCardModel());
  }

  @override
  void dispose() {
    resultCardModel1.dispose();
    resultCardModel2.dispose();
  }
}
