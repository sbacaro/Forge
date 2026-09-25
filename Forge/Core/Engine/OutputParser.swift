import Foundation

/// Parses yt-dlp CLI output: JSON metadata dumps and structured progress
/// lines emitted via `--progress-template`.
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

    /// Progress snapshot. Byte-based so multi-stream downloads aggregate
    /// smoothly instead of restarting the bar per stream.
    struct Progress: Equatable, Sendable {
        let downloadedBytes: Double?
        let totalBytes: Double?
        let speedBytesPerSecond: Double?

        var fraction: Double? {
            guard let downloaded = downloadedBytes, let total = totalBytes, total > 0 else { return nil }
            return min(downloaded / total, 1)
        }
    }

    /// Template passed to yt-dlp so every progress line is byte-exact:
    /// `PROG|<downloaded>|<total>|<total_estimate>|<speed>` ("NA" = absent).
    static let progressTemplate = "download:PROG|%(progress.downloaded_bytes)s|%(progress.total_bytes)s|%(progress.total_bytes_estimate)s|%(progress.speed)s"
    static let progressTemplateArguments = ["--progress-template", progressTemplate]
    private static let structuredPattern = try! NSRegularExpression(pattern: #"^PROG\|([^|]*)\|([^|]*)\|([^|]*)\|([^|]*)$"#)
    private static let percentPattern = #"\[download\]\s+([\d.]+)%"#
    private static let totalBytesPattern = #"of\s+~?\s*([\d.]+)(KiB|MiB|GiB)"#
    private static let speedPattern = #"at\s+([\d.]+)(KiB|MiB|GiB)/s"#

    func parseMetadata(fromJSON data: Data) throws -> Metadata {
        try JSONDecoder().decode(Metadata.self, from: data)
    }

    /// Parses a structured PROG line. Returns nil for other lines.
    func parseStructuredProgress(line: String) -> Progress? {
        let range = NSRange(line.startIndex..., in: line)
        guard let match = Self.structuredPattern.firstMatch(in: line, range: range),
              match.numberOfRanges >= 5 else { return nil }

        func field(_ group: Int) -> Double? {
            guard let capture = Range(match.range(at: group), in: line) else { return nil }
            let text = String(line[capture])
            return text == "NA" ? nil : Double(text)
        }

        let downloaded = field(1)
        let total = field(2) ?? field(3)
        let speed = field(4)

        guard downloaded != nil || total != nil else { return nil }
        return Progress(
            downloadedBytes: downloaded,
            totalBytes: total,
            speedBytesPerSecond: speed
        )
    }

    /// Fallback parser for human-readable `[download]  42.5% of ~10.00MiB`
    /// lines (used when no template is active, e.g. by tests/tools).
    func parseLegacyProgress(line: String) -> Progress? {
        guard let percent = Self.capture(line: line, pattern: Self.percentPattern, group: 1)
            .flatMap(Double.init),
            (0.0...100.0).contains(percent) else { return nil }

        let totalBytes: Double? = {
            guard let number = Self.capture(line: line, pattern: Self.totalBytesPattern, group: 1).flatMap(Double.init) else {
                return nil
            }
            let unit = Self.capture(line: line, pattern: Self.totalBytesPattern, group: 2) ?? ""
            return number * Self.multiplier(for: unit)
        }()

        // Derive downloaded bytes from the percent so the fraction stays
        // computable even without an absolute byte count.
        let downloaded = totalBytes.map { $0 * percent / 100.0 }

        return Progress(
            downloadedBytes: downloaded,
            totalBytes: totalBytes,
            speedBytesPerSecond: Self.capture(line: line, pattern: Self.speedPattern, group: 1)
                .flatMap(Double.init)
                .map { value in
                    let unit = Self.capture(line: line, pattern: Self.speedPattern, group: 2) ?? ""
                    return value * Self.multiplier(for: unit)
                }
        )
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
