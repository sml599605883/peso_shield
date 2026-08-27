import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:peso_shield/core/network/network_error.dart';

class PayloadEncryption {
  PayloadEncryption({required String aesKey, required String aesIv})
      : _cipher = aesKey.isEmpty && aesIv.isEmpty
            ? null
            : Encrypter(AES(Key.fromUtf8(aesKey), mode: AESMode.cbc)),
        _ivValue = aesKey.isEmpty && aesIv.isEmpty ? null : IV.fromUtf8(aesIv);

  final Encrypter? _cipher;
  final IV? _ivValue;

  bool get isAvailable => _cipher != null && _ivValue != null;

  String encryptPlainText(String plain) {
    final cipher = _ensureAvailable();
    return cipher.encrypt(plain, iv: _ivValue!).base64;
  }

  String encryptJsonData(Object? data) {
    return encryptPlainText(jsonEncode(data));
  }

  String decryptCipherText(String cipher) {
    final encrypter = _ensureAvailable();
    return encrypter.decrypt64(cipher, iv: _ivValue!);
  }

  Encrypter _ensureAvailable() {
    final cipher = _cipher;
    if (cipher == null || _ivValue == null) {
      throw const NetworkError(
        type: NetworkErrorType.configuration,
        message: 'Encryption not configured',
      );
    }
    return cipher;
  }
}
