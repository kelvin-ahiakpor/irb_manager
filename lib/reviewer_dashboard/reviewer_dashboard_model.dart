import '/components/filter_box_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'reviewer_dashboard_widget.dart' show ReviewerDashboardWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ReviewerDashboardModel extends FlutterFlowModel<ReviewerDashboardWidget> {
  ///  State fields for stateful widgets in this page.

  // Active filter label — matches the FilterBoxWidget label strings.
  String activeFilter = 'ALL';

  // Model for filter_box component.
  late FilterBoxModel filterBoxModel1;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel2;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel3;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel4;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel5;
  // Model for filter_box component.
  late FilterBoxModel filterBoxModel6;

  @override
  void initState(BuildContext context) {
    filterBoxModel1 = createModel(context, () => FilterBoxModel());
    filterBoxModel2 = createModel(context, () => FilterBoxModel());
    filterBoxModel3 = createModel(context, () => FilterBoxModel());
    filterBoxModel4 = createModel(context, () => FilterBoxModel());
    filterBoxModel5 = createModel(context, () => FilterBoxModel());
    filterBoxModel6 = createModel(context, () => FilterBoxModel());
  }

  @override
  void dispose() {
    filterBoxModel1.dispose();
    filterBoxModel2.dispose();
    filterBoxModel3.dispose();
    filterBoxModel4.dispose();
    filterBoxModel5.dispose();
    filterBoxModel6.dispose();
  }
}
