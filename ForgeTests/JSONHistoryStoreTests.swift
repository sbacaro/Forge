import XCTest
@testable import ForgeKit

final class JSONHistoryStoreTests: XCTestCase {
    func testAddAndReadEntriesRoundTrip() async throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        let store = JSONHistoryStore(fileURL: tempFile)

        let entry = HistoryEntry(
            title: "Test",
            sourceURL: URL(string: "https://example.com")!,
            fileURL: URL(fileURLWithPath: "/tmp/test.mp3"),
            format: "MP3"
        )
        try await store.add(entry)
        let entries = try await store.entries()
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.title, "Test")

        try await store.remove(entry)
        let afterRemoval = try await store.entries()
        XCTAssertTrue(afterRemoval.isEmpty)
    }

    func testClearEmptiesStore() async throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".json")
        let store = JSONHistoryStore(fileURL: tempFile)
        try await store.add(HistoryEntry(
            title: "A",
            sourceURL: URL(string: "https://example.com")!,
            fileURL: URL(fileURLWithPath: "/tmp/a"),
            format: "WAV"
        ))
        try await store.clear()
        let entries = try await store.entries()
        XCTAssertTrue(entries.isEmpty)
    }
}
