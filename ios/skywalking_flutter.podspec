Pod::Spec.new do |s|
  s.name             = 'skywalking_flutter'
  s.version          = '0.1.0'
  s.summary          = 'OpenTelemetry OTLP/HTTP agent for Flutter'
  s.description      = <<-DESC
SkyWalking-compatible OTLP traces and metrics for Flutter (Dart implementation).
                       DESC
  s.homepage         = 'https://github.com/songzhendong/skywalking-flutter'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'songzhendong' => 'xiaodong12315@qq.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency       'Flutter'
  s.platform         = :ios, '12.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'
  }
  s.swift_version = '5.0'
end
