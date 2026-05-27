import 'dart:convert';

import 'package:http/http.dart' as http;

/// Shared OTLP/HTTP JSON POST helper.
class OtlpHttpSender {
  OtlpHttpSender({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _contentType = 'application/json';

  Future<OtlpExportResult> postJson(String url, Map<String, Object?> body) async {
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: const {'Content-Type': _contentType},
        body: jsonEncode(body),
      );
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      return OtlpExportResult(
        success: ok,
        statusCode: response.statusCode,
        body: response.body,
      );
    } catch (e) {
      return OtlpExportResult(success: false, error: e);
    }
  }

  void close() => _client.close();
}

class OtlpExportResult {
  const OtlpExportResult({
    required this.success,
    this.statusCode,
    this.body,
    this.error,
  });

  final bool success;
  final int? statusCode;
  final String? body;
  final Object? error;
}
