import XCTest

import noise_suppression

// The iOS contract through its protocol only: 1 s of white noise comes out quieter.
class RunnerTests: XCTestCase {

  func testRnnoiseSuppressorDenoisesWhiteNoise() {
    guard let suppressor = NSPRnnoiseSuppressor() else {
      return XCTFail("no engine state")
    }
    let engine: NSPNoiseSuppressor = suppressor
    XCTAssertTrue(engine.initialize(withSampleRate: NSPRnnoiseSuppressor.sampleRate))
    let n = NSPRnnoiseSuppressor.frameSize
    var frame = [Float](repeating: 0, count: n)
    var seed: UInt32 = 12345
    var inRms = 0.0, outRms = 0.0
    for f in 0..<100 {
      for i in 0..<n {
        seed = seed &* 1103515245 &+ 12345
        frame[i] = 3000 * (Float((seed >> 8) & 0xffff) / 32768 - 1)
      }
      let before = sqrt(frame.reduce(0.0) { $0 + Double($1 * $1) } / Double(n))
      let result = frame.withUnsafeMutableBufferPointer {
        engine.processSamples($0.baseAddress!, count: n)
      }
      XCTAssertEqual(result, .processed)
      if f >= 50 {
        inRms += before
        outRms += sqrt(frame.reduce(0.0) { $0 + Double($1 * $1) } / Double(n))
      }
    }
    XCTAssertGreaterThan(20 * log10(inRms / outRms), 10)
    engine.releaseEngine()
  }
}
