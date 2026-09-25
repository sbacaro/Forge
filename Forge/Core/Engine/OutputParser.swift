import Foundation

/// Parses yt-dlp CLI output: JSON metadata dumps and progress lines.
struct OutputParser: Sendable {
    /// Video metadata as reported by `yt-dlp -J`.
    struct Metadata: Codable, Equatable, Sendable {
        let id: String?
        let title: String?
        let duration: Double?
        let thumbnail: String?
        let uploader: String?
        let webpageURL: String?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case duration
            case thumbnail
            case uploader
            case webpageURL = "webpage_url"
        }
    }

    /// Progress snapshot from a yt-dlp progress line.
    struct Progress: Equatable, Sendable {
        let fraction: Double
        let downloadedBytes: Double?
        let totalBytes: Double?
        let speedBytesPerSecond: Double?
    }

    private static let percentPattern = #"\[download\]\s+([\d.]+)%"#
    private static let totalBytesPattern = #"of\s+~?\s*([\d.]+)(KiB|MiB|GiB)"#
    private static let speedPattern = #"at\s+([\d.]+)(KiB|MiB|GiB)/s"#

    func parseMetadata(fromJSON data: Data) throws -> Metadata {
        try JSONDecoder().decode(Metadata.self, from: data)
    }

    /// Attempts to interpret a single output line as a progress update.
    /// Returns nil when the line carries no progress information.
    func parseProgress(line: String) -> Progress? {
        guard let percent = Self.capture(line: line, pattern: Self.percentPattern, group: 1)
            .flatMap(Double.init),
            (0.0...100.0).contains(percent) else { return nil }

        return Progress(
            fraction: percent / 100.0,
            downloadedBytes: nil,
            totalBytes: totalBytesValue(line: line),
            speedBytesPerSecond: Self.capture(line: line, pattern: Self.speedPattern, group: 1)
                .flatMap(Double.init)
                .map { value in
                    let unit = Self.capture(line: line, pattern: Self.speedPattern, group: 2) ?? ""
                    return value * Self.multiplier(for: unit)
                }
        )
    }

    private func totalBytesValue(line: String) -> Double? {
        guard let number = Self.capture(line: line, pattern: Self.totalBytesPattern, group: 1).flatMap(Double.init) else {
            return nil
        }
        let unit = Self.capture(line: line, pattern: Self.totalBytesPattern, group: 2) ?? ""
        return number * Self.multiplier(for: unit)
    }

    private static func capture(line: String, pattern: String, group: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, range: range),
              match.numberOfRanges > group,
              let capture = Range(match.range(at: group), in: line) else { return nil }
        return String(line[capture])
    }

    private static func multiplier(for unit: String) -> Double {
        switch unit {
        case "KiB": 1_024
        case "MiB": 1_048_576
        case "GiB": 1_073_741_824
        default: 1
        }
    }
}
