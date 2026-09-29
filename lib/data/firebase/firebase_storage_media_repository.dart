import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/models/models.dart';
import '../../domain/repositories/repositories.dart';

/// Cloud Storage implementation of [MediaRepository].
///
/// Files land under `chat/{channelId}/...` or `tasks/{taskId}/...`, which is
/// exactly what `firebase/storage.rules` allows (signed-in members, 25 MB,
/// image / audio / pdf / document / text content types).
class FirebaseStorageMediaRepository implements MediaRepository {
  FirebaseStorageMediaRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  @override
  Future<Attachment> upload({
    required String folder,
    required String fileName,
    required String mime,
    required Uint8List bytes,
    int? durationMs,
    void Function(double progress)? onProgress,
  }) async {
    if (bytes.length > MediaRepository.maxBytes) {
      throw MediaTooLargeException(bytes.length);
    }
    final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: mime));

    final sub = task.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    onProgress?.call(1);

    return Attachment(
      url: await ref.getDownloadURL(),
      name: fileName,
      mime: mime,
      sizeBytes: bytes.length,
      durationMs: durationMs,
    );
  }

  /// Cloud Storage attachments are always remote, so there is nothing local.
  @override
  Uint8List? localBytes(String url) => null;

  @override
  Future<void> delete(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException {
      // Already gone, or the member is not allowed to remove it: nothing to do.
    }
  }
}
