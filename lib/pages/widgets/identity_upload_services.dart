import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Abstract interface for identity upload image picker
abstract interface class IdentityUploadImagePicker {
  /// Pick image from camera
  Future<String?> pickFromCamera();

  /// Pick image from photo album
  Future<String?> pickFromAlbum();
}

/// Abstract interface for identity upload image compressor
abstract interface class IdentityUploadImageCompressor {
  /// Compress image to target size limit
  Future<String?> compressToLimit(String filePath);
}

/// Default implementation of image picker using image_picker plugin
class DefaultIdentityUploadImagePicker implements IdentityUploadImagePicker {
  DefaultIdentityUploadImagePicker({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<String?> pickFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    return pickedFile?.path;
  }

  @override
  Future<String?> pickFromAlbum() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    return pickedFile?.path;
  }
}

/// Default implementation of image compressor targeting 500KB
class DefaultIdentityUploadImageCompressor
    implements IdentityUploadImageCompressor {
  static const _targetBytes = 500 * 1024; // 500KB

  @override
  Future<String?> compressToLimit(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return null;
    }

    // If already under limit, return original path
    if (file.lengthSync() <= _targetBytes) {
      return filePath;
    }

    var quality = 90;
    File compressedFile = file;

    // Step 1: Reduce quality until under target or quality too low
    while (quality >= 10) {
      final result = await _compressQuality(compressedFile, quality);
      if (result == null) {
        return null;
      }
      compressedFile = result;
      if (compressedFile.lengthSync() <= _targetBytes) {
        return compressedFile.path;
      }
      quality -= 5;
    }

    // Step 2: If quality reduction is not enough, reduce dimensions
    final bytes = await compressedFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    var width = frame.image.width;
    var height = frame.image.height;

    while (width > 100 && height > 100) {
      width = (width * 0.95).toInt();
      height = (height * 0.95).toInt();
      final result = await _compressSize(file, width, height);
      if (result == null) {
        return null;
      }
      compressedFile = result;
      if (compressedFile.lengthSync() <= _targetBytes) {
        return compressedFile.path;
      }
    }

    return compressedFile.path;
  }

  Future<File?> _compressQuality(File file, int quality) async {
    final targetPath = await _targetPath();
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: false,
      keepExif: false,
    );
    return result == null ? null : File(result.path);
  }

  Future<File?> _compressSize(File file, int width, int height) async {
    final targetPath = await _targetPath();
    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      minWidth: width,
      minHeight: height,
      quality: 95,
      format: CompressFormat.jpeg,
    );
    return result == null ? null : File(result.path);
  }

  Future<String> _targetPath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/identity_upload_${DateTime.now().microsecondsSinceEpoch}.jpg';
  }
}
