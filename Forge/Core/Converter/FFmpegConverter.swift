import Foundation

/// FFmpeg-based converter using the bundled static binaries.
final class FFmpegConverter: MediaConverter {
    private let toolEngine: ToolEngine
    private let toolLocator: ToolLocator

    init(toolEngine: ToolEngine = ProcessEngine(), toolLocator: ToolLocator = BundleToolLocator()) {
        self.toolEngine = toolEngine
        self.toolLocator = toolLocator
    }

    func convert(
        _ job: ConversionJob,
        to audioFormat: AudioFormat
    ) async throws -> URL {
        var args = ["-y", "-i", job.sourceURL.path]
        args += ["-vn", "-c:a", audioFormat.codecName]
        if let sampleRate = job.settings.sampleRateHz {
            args += ["-ar", String(sampleRate)]
        }
        if let bitrate = job.settings.audioBitrateKbps, !audioFormat.isLossless {
            args += ["-b:a", "\(bitrate)k"]
        }
        if let channels = job.settings.channelCount {
            args += ["-ac", String(channels)]
        }
        let destination = job.destinationURL.appendingPathExtension(audioFormat.outputExtension)
        args += [destination.path]

        let result = try await runFFmpeg(args: args)
        guard result.exitCode == 0 else {
            throw ConversionError.ffmpegFailed(message: lastLine(result.standardError))
        }
        return destination
    }

    func convert(
        _ job: ConversionJob,
        to videoFormat: VideoFormat
    ) async throws -> URL {
        var args = ["-y", "-i", job.sourceURL.path]
        args += ["-c:v", videoFormat.preferredVideoCodec]
        if let crf = job.settings.videoCRF {
            args += ["-crf", String(crf)]
        }
        args += ["-c:a", videoFormat.preferredAudioCodec]
        if let bitrate = job.settings.audioBitrateKbps {
            args += ["-b:a", "\(bitrate)k"]
        }
        args += ["-f", videoFormat.muxerName]
        let destination = job.destinationURL.appendingPathExtension(videoFormat.fileExtension)
        args += [destination.path]

        let result = try await runFFmpeg(args: args)
        guard result.exitCode == 0 else {
            throw ConversionError.ffmpegFailed(message: lastLine(result.standardError))
        }
        return destination
    }

    private func runFFmpeg(args: [String]) async throws -> ToolResult {
        guard let tool = toolLocator.url(forTool: .ffmpeg) else {
            throw ConversionError.toolMissing(name: BundledTool.ffmpeg.rawValue)
        }
        return try await toolEngine.run(tool: tool, arguments: args, environment: [:])
    }

    private func lastLine(_ text: String) -> String {
        text.split(separator: "\n").map(String.init).last { !$0.trimmingCharacters(in: .whitespaces).isEmpty } ?? "Unknown ffmpeg failure."
    }
}

enum ConversionError: Error, LocalizedError {
    case toolMissing(name: String)
    case ffmpegFailed(message: String)

    var errorDescription: String? {
        switch self {
        case let .toolMissing(name):
            "Required tool '\(name)' is missing."
        case let .ffmpegFailed(message):
            message
        }
    }
}
