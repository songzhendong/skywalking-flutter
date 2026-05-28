import 'dart:math';

/// Generates W3C-compatible trace/span ids for OTLP JSON (hex-encoded).
class IdGenerator {
  /// Creates an ID generator; uses [random] in tests, otherwise secure random.
  IdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Returns a new 128-bit trace id as 32 lowercase hex characters.
  String traceId() => _hex(16);

  /// Returns a new 64-bit span id as 16 lowercase hex characters.
  String spanId() => _hex(8);

  String _hex(int byteLength) {
    final buffer = StringBuffer();
    for (var i = 0; i < byteLength; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
