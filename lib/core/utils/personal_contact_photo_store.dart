import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class PersonalContactPhotoStore {
  const PersonalContactPhotoStore._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickFromGallery() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 82,
    );
    return image?.path;
  }

  static Future<String> savePhoto({
    required String sourcePath,
    required String contactId,
  }) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final photosDirectory = Directory(
      path.join(appDirectory.path, 'personal_emergency_contact_photos'),
    );
    if (!photosDirectory.existsSync()) {
      await photosDirectory.create(recursive: true);
    }

    final extension = path.extension(sourcePath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final destination = path.join(
      photosDirectory.path,
      '${contactId}_${DateTime.now().microsecondsSinceEpoch}$safeExtension',
    );
    return File(sourcePath).copy(destination).then((file) => file.path);
  }

  static Future<void> deletePhoto(String photoPath) async {
    if (photoPath.trim().isEmpty) return;
    final file = File(photoPath);
    if (!file.existsSync()) return;
    if (!photoPath.contains('personal_emergency_contact_photos')) return;
    await file.delete();
  }
}
