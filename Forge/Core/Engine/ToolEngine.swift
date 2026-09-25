import Foundation

/// Result of running an external tool to completion.
struct ToolResult {
    let exitCode: Int32
    let standardOutput: String
    let standardError: String
}

/// Errors surfaced by the tool execution layer.
enum ToolEngineError: Error, LocalizedError {
    case toolNotFound(name: String)
    case launchFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case let .toolNotFound(name):
            "Required tool '\(name)' is missing from the app bundle."
        case let .launchFailed(underlying):
            "Could not launch tool: \(underlying.localizedDescription)"
        }
    }
}

/// Abstraction over running bundled command-line tools, so higher layers
/// stay testable and implementations can be swapped (e.g. for mocking).
protocol ToolEngine: AnyObject, Sendable {
    /// Runs a tool to completion and collects its output.
    func run(
        tool: URL,
        arguments: [String],
        environment: [String: String]
    ) async throws -> ToolResult

    /// Runs a tool while streaming incremental output to the given handler.
    /// Returns when the process exits.
    func runStreaming(
        tool: URL,
        arguments: [String],
        environment: [String: String],
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> ToolResult
}
