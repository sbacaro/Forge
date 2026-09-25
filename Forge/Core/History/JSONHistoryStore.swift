import Foundation

/// JSON-file backed history store under Application Support.
final class JSONHistoryStore: HistoryStore {
    private let fileURL: URL
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let queue = DispatchQueue(label: "com.forgeapp.history")

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = Self.appSupportDirectory()
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            self.fileURL = base.appendingPathComponent(AppConstants.historyFileName)
        }
    }

    static func appSupportDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(AppConstants.appSupportDirectoryName, isDirectory: true)
    }

    func entries() async throws -> [HistoryEntry] {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(with: Result { try self.readEntries() })
            }
        }
    }

    func add(_ entry: HistoryEntry) async throws {
        try await mutate { entries in
            entries.insert(entry, at: 0)
        }
    }

    func remove(_ entry: HistoryEntry) async throws {
        try await mutate { entries in
            entries.removeAll { $0.id == entry.id }
        }
    }

    func clear() async throws {
        try await mutate { entries in
            entries.removeAll()
        }
    }

    private func mutate(_ transform: @escaping (inout [HistoryEntry]) -> Void) async throws {
        try await withCheckedThrowingContinuation { continuation in
            queue.async {
                continuation.resume(with: Result {
                    var entries = (try? self.readEntries()) ?? []
                    transform(&entries)
                    try self.write(entries)
                })
            }
        }
    }

    private func readEntries() throws -> [HistoryEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([HistoryEntry].self, from: data)
    }

    private func write(_ entries: [HistoryEntry]) throws {
        let data = try encoder.encode(entries)
        try data.write(to: fileURL, options: .atomic)
    }
}
