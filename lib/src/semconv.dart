/// OpenTelemetry semantic convention attribute keys (stable / widely used).
/// See: https://opentelemetry.io/docs/specs/semconv/
abstract final class Semconv {
  // Resource
  static const serviceName = 'service.name';
  static const serviceVersion = 'service.version';
  static const serviceInstanceId = 'service.instance.id';
  static const deploymentEnvironment = 'deployment.environment';

  // SDK
  static const telemetrySdkName = 'telemetry.sdk.name';
  static const telemetrySdkLanguage = 'telemetry.sdk.language';
  static const telemetrySdkVersion = 'telemetry.sdk.version';

  // HTTP (client / server)
  static const httpRequestMethod = 'http.request.method';
  static const httpResponseStatusCode = 'http.response.status_code';
  static const urlFull = 'url.full';
  static const urlPath = 'url.path';
  static const urlScheme = 'url.scheme';
  static const serverAddress = 'server.address';
  static const serverPort = 'server.port';

  // Legacy aliases still seen in backends
  static const httpMethodLegacy = 'http.method';
  static const httpUrlLegacy = 'http.url';
  static const httpStatusCodeLegacy = 'http.status_code';

  // Errors (exception.*)
  static const exceptionType = 'exception.type';
  static const exceptionMessage = 'exception.message';

  // Events / UI (application-defined; use consistent prefixes)
  static const eventName = 'event.name';
  static const screenName = 'screen.name';

  /// `{METHOD} {path}` — recommended HTTP span name.
  // OTLP metrics (OpenTelemetry semantic conventions for HTTP client)
  static const metricHttpClientRequestDuration = 'http.client.request.duration';
  static const metricHttpClientRequests = 'http.client.requests';

  static const metricExceptions = 'exception.count';

  static String httpSpanName(String method, String path) {
    final m = method.toUpperCase();
    final p = path.isEmpty ? '/' : path;
    return '$m $p';
  }

  static Map<String, String> httpClientAttributes({
    required String method,
    required Uri url,
    required int statusCode,
  }) {
    return {
      httpRequestMethod: method.toUpperCase(),
      urlFull: url.toString(),
      urlPath: url.path.isEmpty ? '/' : url.path,
      urlScheme: url.scheme,
      if (url.host.isNotEmpty) serverAddress: url.host,
      if (url.hasPort) serverPort: '${url.port}',
      httpResponseStatusCode: statusCode.toString(),
      httpMethodLegacy: method.toUpperCase(),
      httpUrlLegacy: url.toString(),
      httpStatusCodeLegacy: statusCode.toString(),
    };
  }
}
