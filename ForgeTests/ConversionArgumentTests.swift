import XCTest
@testable import ForgeKit

final class ConversionArgumentTests: XCTestCase {
    func testLosslessFormatsDoNotUseBitrate() {
        XCTAssertTrue(AudioFormat.wav.isLossless)
        XCTAssertTrue(AudioFormat.flac.isLossless)
        XCTAssertTrue(AudioFormat.aiff.isLossless)
        XCTAssertFalse(AudioFormat.mp3.isLossless)
    }

    func testCodecNamesMatchFormats() {
        XCTAssertEqual(AudioFormat.wav.codecName, "pcm_s16le")
        XCTAssertEqual(AudioFormat.flac.codecName, "flac")
        XCTAssertEqual(AudioFormat.aiff.codecName, "pcm_s16be")
        XCTAssertEqual(AudioFormat.mp3.codecName, "libmp3lame")
    }

    func testVideoMuxers() {
        XCTAssertEqual(VideoFormat.mkv.muxerName, "matroska")
        XCTAssertEqual(VideoFormat.webm.preferredVideoCodec, "libvpx-vp9")
        XCTAssertEqual(VideoFormat.webm.preferredAudioCodec, "libopus")
    }

    func testQualitySelectorsDeriveFromProfile() {
        XCTAssertNotEqual(QualityProfile.best.formatSelector, QualityProfile.efficient.formatSelector)
    }

    func testThumbnailEmbeddingSupport() {
        // yt-dlp only embeds thumbnails into these containers.
        XCTAssertFalse(AudioFormat.wav.supportsEmbeddedThumbnails)
        XCTAssertFalse(AudioFormat.aiff.supportsEmbeddedThumbnails)
        XCTAssertTrue(AudioFormat.mp3.supportsEmbeddedThumbnails)
        XCTAssertTrue(AudioFormat.flac.supportsEmbeddedThumbnails)
        XCTAssertTrue(VideoFormat.mp4.supportsEmbeddedThumbnails)
        XCTAssertTrue(VideoFormat.mkv.supportsEmbeddedThumbnails)
        XCTAssertTrue(VideoFormat.mov.supportsEmbeddedThumbnails)
        XCTAssertFalse(VideoFormat.avi.supportsEmbeddedThumbnails)
    }
}
