import '/components/brand_header_widget.dart';
import '/components/microsoft_button_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'login_widget.dart' show LoginWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginModel extends FlutterFlowModel<LoginWidget> {
  ///  State fields for stateful widgets in this page.

  bool isLoading = false;
  String? errorMessage;

  // Model for brand_header component.
  late BrandHeaderModel brandHeaderModel;
  // Model for microsoft_button component.
  late MicrosoftButtonModel microsoftButtonModel;

  @override
  void initState(BuildContext context) {
    brandHeaderModel = createModel(context, () => BrandHeaderModel());
    microsoftButtonModel = createModel(context, () => MicrosoftButtonModel());
  }

  @override
  void dispose() {
    brandHeaderModel.dispose();
    microsoftButtonModel.dispose();
  }
}
