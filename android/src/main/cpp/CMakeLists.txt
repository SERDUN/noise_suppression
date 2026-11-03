cmake_minimum_required(VERSION 3.18.1)
project(noise_suppression C)

# The C core is one copy, inside the iOS Swift package (SwiftPM cannot reach
# sources outside its package directory); Android builds the same files.
set(CORE "${CMAKE_CURRENT_SOURCE_DIR}/../../../../ios/noise_suppression/Sources/NoiseSuppressionCore")
set(RNN "${CORE}/rnnoise/src")

add_library(noise_suppression SHARED
  noise_suppression_jni.c
  "${CORE}/noise_suppressor.c"
  "${RNN}/celt_lpc.c"
  "${RNN}/denoise.c"
  "${RNN}/kiss_fft.c"
  "${RNN}/pitch.c"
  "${RNN}/rnn.c"
  "${RNN}/rnn_data.c"
)

target_include_directories(noise_suppression PRIVATE "${CORE}/include" "${CORE}/rnnoise/include")

# RNNoise keeps its FFT state in a global called `common`; give it a name no
# other library in the process can collide with.
target_compile_definitions(noise_suppression PRIVATE common=ns_rnnoise_common)

# The engine is optimized in debug builds too; only the JNI entry points are
# exported; the vendored RNNoise sources are compiled as they are.
target_compile_options(noise_suppression PRIVATE -O3 -fvisibility=hidden -w)

target_link_libraries(noise_suppression m)
