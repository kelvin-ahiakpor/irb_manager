// LOCAL RESOURCE: dart:html (browser file system API)
//
// Flutter web's CanvasKit renderer draws everything onto a canvas element.
// When file_picker tries to open a file dialog, it programmatically clicks
// a hidden <input type="file"> — but by the time that click fires, the
// browser has already decided the tap didn't come from a direct user gesture,
// so it silently blocks the dialog. This happens in production builds; debug
// mode is more lenient.
//
// The fix is to create the <input> element ourselves and click it directly
// inside the onTap handler, before any async gaps. The browser sees this as
// a proper user-initiated action and allows the dialog to open.
//
// This file is only compiled for web targets. Native Android/iOS uses
// file_picker_stub.dart instead (selected via the conditional import in the
// widget file).

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

void showFilePicker(void Function(List<PlatformFile>) onPicked) {
  final input = html.FileUploadInputElement()
    ..accept = '.pdf,.docx'
    ..multiple = true;

  input.onChange.listen((event) async {
    final files = input.files;
    if (files == null || files.isEmpty) return;
    final platformFiles = <PlatformFile>[];
    for (final file in files) {
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        completer.complete(
          result is List<int> ? Uint8List.fromList(result) : Uint8List(0),
        );
      });
      reader.readAsArrayBuffer(file);
      final bytes = await completer.future;
      platformFiles.add(PlatformFile(
        name: file.name,
        size: file.size,
        bytes: bytes,
      ));
    }
    onPicked(platformFiles);
  });

  input.click();
}
