Pod::Spec.new do |s|
  s.name             = 'noise_suppression'
  s.version          = '0.0.1'
  s.summary          = 'Background noise suppression for 10 ms voice frames (RNNoise).'
  s.description      = 'A noise suppressor with its own interface, independent of any audio stack.'
  s.homepage         = 'https://github.com/SERDUN/noise_suppression'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Dmytro Serdun' => 'dmitriiserdun@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'noise_suppression/Sources/**/*.{h,m,c}'
  s.public_header_files = [
    'noise_suppression/Sources/noise_suppression/include/noise_suppression/*.h',
    'noise_suppression/Sources/NoiseSuppressionCore/include/*.h',
  ]
  s.resource_bundles = { 'noise_suppression_privacy' => ['noise_suppression/Sources/noise_suppression/PrivacyInfo.xcprivacy'] }
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/noise_suppression/Sources/NoiseSuppressionCore/include" "${PODS_TARGET_SRCROOT}/noise_suppression/Sources/NoiseSuppressionCore/rnnoise/include"',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'common=ns_rnnoise_common',
    'WARNING_CFLAGS' => '-w',
  }
end
