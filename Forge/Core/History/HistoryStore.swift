import Foundation

/// One completed (or attempted) download in the user's history.
struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var sourceURL: URL
    var fileURL: URL
    var format: String
    var downloadedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        sourceURL: URL,
        fileURL: URL,
        format: String,
        downloadedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.sourceURL = sourceURL
        self.fileURL = fileURL
        self.format = format
        self.downloadedAt = downloadedAt
    }
}

/// Storage abstraction for history entries.
protocol HistoryStore: AnyObject, Sendable {
    func entries() async throws -> [HistoryEntry]
    func add(_ entry: HistoryEntry) async throws
    func remove(_ entry: HistoryEntry) async throws
    func clear() async throws
}
