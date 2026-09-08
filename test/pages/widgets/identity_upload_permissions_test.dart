import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peso_shield/pages/widgets/identity_upload_services.dart';

class _ImagePicker extends ImagePicker {
  ImageSource? source;
  bool? fullMetadata;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    this.source = source;
    fullMetadata = requestFullMetadata;
    return XFile('/selected/id.jpg');
  }
}

void main() {
  test('album picker disables full photo library metadata access', () async {
    final picker = _ImagePicker();
    final service = DefaultIdentityUploadImagePicker(imagePicker: picker);
    expect(await service.pickFromAlbum(), '/selected/id.jpg');
    expect(picker.source, ImageSource.gallery);
    expect(picker.fullMetadata, isFalse);
  });

  test(
    'iOS retains location declarations without photo library permission',
    () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(
        plist,
        contains('<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>'),
      );
      expect(plist, contains('<key>NSLocationWhenInUseUsageDescription</key>'));
      expect(plist, isNot(contains('NSPhotoLibraryUsageDescription')));
      expect(plist, isNot(contains('NSPhotoLibraryAddUsageDescription')));
    },
  );
}
