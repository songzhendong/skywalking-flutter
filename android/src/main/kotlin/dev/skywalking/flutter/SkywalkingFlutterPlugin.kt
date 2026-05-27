package dev.skywalking.flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

// Empty native shell: OTLP export runs in Dart (OtlpAgent).
class SkywalkingFlutterPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {}

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}
