import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// A file the member picked, already loaded in memory so the same upload path
/// works on mobile, web and desktop.
class PickedAttachment {
  const PickedAttachment({
    required this.name,
    required this.mime,
    required this.bytes,
  });

  final String name;
  final String mime;
  final Uint8List bytes;

  int get sizeBytes => bytes.length;
}

/// What kind of file the composer asked for.
enum PickKind { image, audio, any }

/// Opens the platform picker and returns the chosen file, or null if the
/// member cancelled.
Future<PickedAttachment?> pickAttachment(PickKind kind) async {
  final result = await FilePicker.platform.pickFiles(
    type: switch (kind) {
      PickKind.image => FileType.image,
      PickKind.audio => FileType.audio,
      PickKind.any => FileType.any,
    },
    // Bytes are required on web and make desktop/mobile behave identically.
    withData: true,
    allowMultiple: false,
  );
  final file = result?.files.firstOrNull;
  if (file == null) return null;
  final bytes = file.bytes;
  if (bytes == null) return null;
  return PickedAttachment(
    name: file.name,
    mime: mimeForFileName(file.name),
    bytes: bytes,
  );
}

const _mimeByExtension = <String, String>{
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'gif': 'image/gif',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
  'aac': 'audio/aac',
  'wav': 'audio/wav',
  'ogg': 'audio/ogg',
  'opus': 'audio/opus',
  'mp4': 'video/mp4',
  'pdf': 'application/pdf',
  'doc': 'application/msword',
  'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'csv': 'text/csv',
  'txt': 'text/plain',
  'md': 'text/markdown',
};

/// Best-effort content type from the file name, used for the Storage metadata
/// (the Storage rules only accept the types listed in `storage.rules`).
String mimeForFileName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot == -1 || dot == name.length - 1) return 'application/octet-stream';
  return _mimeByExtension[name.substring(dot + 1).toLowerCase()] ??
      'application/octet-stream';
}

/// Human-readable byte size, shared by the composer and the attachment chips.
String readableBytes(int bytes) {
  if (bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var i = 0;
  while (size >= 1024 && i < units.length - 1) {
    size /= 1024;
    i++;
  }
  return '${size.toStringAsFixed(size < 10 && i > 0 ? 1 : 0)} ${units[i]}';
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
