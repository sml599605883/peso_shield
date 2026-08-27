import 'dart:convert';

import 'package:crypto/crypto.dart';

class RequestSigner {
  const RequestSigner(this.secret);

  final String secret;

  String sign(Map<String, Object?> params) {
    // Match Fund Nexus: sort keys, concatenate key + value (including empty
    // values), and calculate an HMAC-SHA256 using the shared secret.
    final sortedKeys = params.keys.toList()..sort();
    final source = sortedKeys.map((key) => '$key${params[key] ?? ''}').join();

    return Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(source)).toString();
  }
}
