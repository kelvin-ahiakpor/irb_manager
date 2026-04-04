import '/components/timeline_node_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'status_history_widget.dart' show StatusHistoryWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class StatusHistoryModel extends FlutterFlowModel<StatusHistoryWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for timeline_node component.
  late TimelineNodeModel timelineNodeModel1;
  // Model for timeline_node component.
  late TimelineNodeModel timelineNodeModel2;
  // Model for timeline_node component.
  late TimelineNodeModel timelineNodeModel3;

  @override
  void initState(BuildContext context) {
    timelineNodeModel1 = createModel(context, () => TimelineNodeModel());
    timelineNodeModel2 = createModel(context, () => TimelineNodeModel());
    timelineNodeModel3 = createModel(context, () => TimelineNodeModel());
  }

  @override
  void dispose() {
    timelineNodeModel1.dispose();
    timelineNodeModel2.dispose();
    timelineNodeModel3.dispose();
  }
}
