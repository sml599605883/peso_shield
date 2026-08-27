import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class ProxyConfigurer {
  static void configure(
    Dio dio, {
    required String host,
    required int port,
    bool allowInsecure = false,
  }) {
    final adapter = dio.httpClientAdapter;
    if (adapter is IOHttpClientAdapter) {
      adapter.createHttpClient = () {
        final client = HttpClient();
        client.findProxy = (uri) => 'PROXY $host:$port';

        if (allowInsecure) {
          client.badCertificateCallback = (cert, host, port) => true;
        }

        return client;
      };
    }
  }
}
