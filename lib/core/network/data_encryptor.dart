import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class DataEncryptor {
  DataEncryptor({required String key, required String iv})
      : _encrypter = Encrypter(
          AES(
            Key.fromUtf8(key),
            mode: AESMode.cbc,
          ),
        ),
        _iv = IV.fromUtf8(iv);

  final Encrypter _encrypter;
  final IV _iv;

  String encrypt(String plaintext) {
    final encrypted = _encrypter.encrypt(plaintext, iv: _iv);
    return encrypted.base64;
  }

  String decrypt(String ciphertext) {
    final decrypted = _encrypter.decrypt64(ciphertext, iv: _iv);
    return decrypted;
  }

  static String md5Hash(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }
}
