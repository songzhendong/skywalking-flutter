import 'dart:math';

/// Generates W3C-compatible trace/span ids for OTLP JSON (hex-encoded).
class IdGenerator {
  IdGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String traceId() => _hex(16);

  String spanId() => _hex(8);

  String _hex(int byteLength) {
    final buffer = StringBuffer();
    for (var i = 0; i < byteLength; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
