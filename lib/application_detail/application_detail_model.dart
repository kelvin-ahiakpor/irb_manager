import '/components/info_tile_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'application_detail_widget.dart' show ApplicationDetailWidget;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ApplicationDetailModel extends FlutterFlowModel<ApplicationDetailWidget> {
  ///  State fields for stateful widgets in this page.

  // Loaded from Supabase on init.
  Map<String, dynamic>? application;
  List<Map<String, dynamic>> attachments = [];
  bool isLoading = true;
  bool fromCache = false;
  String? errorMessage;

  // Model for info_tile component.
  late InfoTileModel infoTileModel1;
  // Model for info_tile component.
  late InfoTileModel infoTileModel2;
  // Model for info_tile component.
  late InfoTileModel infoTileModel3;

  @override
  void initState(BuildContext context) {
    infoTileModel1 = createModel(context, () => InfoTileModel());
    infoTileModel2 = createModel(context, () => InfoTileModel());
    infoTileModel3 = createModel(context, () => InfoTileModel());
  }

  @override
  void dispose() {
    infoTileModel1.dispose();
    infoTileModel2.dispose();
    infoTileModel3.dispose();
  }
}
