import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final _storage = FirebaseStorage.instance;

  /// Uploads a child's profile photo and returns its public download URL.
  Future<String> uploadChildPhoto(String childId, File file) async {
    final ref = _storage.ref('child_photos/$childId.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }
}
