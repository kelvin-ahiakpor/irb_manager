// LOCAL RESOURCE: file_picker (native OS file picker)
//
// On Android and iOS, file_picker opens the platform's native document picker.
// This stub exists so the widget can import one interface regardless of
// platform. On web, file_picker_web.dart is loaded instead via the conditional
// import directive in web_submission_form_widget.dart.

import 'package:file_picker/file_picker.dart';

void showFilePicker(void Function(List<PlatformFile>) onPicked) {
  FilePicker.platform
      .pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        withData: true,
      )
      .then((result) {
    if (result != null) onPicked(result.files);
  });
}
