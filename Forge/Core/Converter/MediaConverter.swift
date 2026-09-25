import Foundation

/// Abstraction over media conversion so implementations can be swapped or
/// mocked. Progress is reported as a 0–1 fraction when known.
protocol MediaConverter: AnyObject {
    func convert(
        _ job: ConversionJob,
        to audioFormat: AudioFormat
    ) async throws -> URL

    func convert(
        _ job: ConversionJob,
        to videoFormat: VideoFormat
    ) async throws -> URL
}
