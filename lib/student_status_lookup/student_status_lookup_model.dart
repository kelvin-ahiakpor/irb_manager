import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'student_status_lookup_widget.dart' show StudentStatusLookupWidget;
import 'package:flutter/material.dart';

class StudentStatusLookupModel
    extends FlutterFlowModel<StudentStatusLookupWidget> {
  TextEditingController studentIdController = TextEditingController();
  List<Map<String, dynamic>> results = [];
  // Most recent reviewer note per application ID (null = no note).
  Map<String, String?> notes = {};
  bool isSearching = false;
  bool hasSearched = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    studentIdController.dispose();
  }
}
