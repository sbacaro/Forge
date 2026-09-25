import Foundation

/// Process-based implementation of `ToolEngine`.
final class ProcessEngine: ToolEngine {
    private let readInterval: TimeInterval

    init(readInterval: TimeInterval = AppConstants.processReadInterval) {
        self.readInterval = readInterval
    }

    func run(
        tool: URL,
        arguments: [String],
        environment: [String: String]
    ) async throws -> ToolResult {
        let process = try makeProcess(tool: tool, arguments: arguments, environment: environment)
        return try await execute(process)
    }

    func runStreaming(
        tool: URL,
        arguments: [String],
        environment: [String: String],
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> ToolResult {
        let process = try makeProcess(tool: tool, arguments: arguments, environment: environment)
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        try launch(process)

        return try await withTaskCancellationHandler {
            try await readLoop(
                process: process,
                stdout: stdoutPipe,
                stderr: stderrPipe,
                onOutput: onOutput
            )
        } onCancel: {
            process.terminate()
        }
    }

    private func makeProcess(
        tool: URL,
        arguments: [String],
        environment: [String: String]
    ) throws -> Process {
        guard FileManager.default.fileExists(atPath: tool.path) else {
            throw ToolEngineError.toolNotFound(name: tool.lastPathComponent)
        }

        let process = Process()
        process.executableURL = tool
        process.arguments = arguments
        var env = ProcessInfo.processInfo.environment
        env.merge(environment) { _, new in new }
        process.environment = env
        return process
    }

    private func launch(_ process: Process) throws {
        do {
            try process.run()
        } catch {
            throw ToolEngineError.launchFailed(underlying: error)
        }
    }

    private func runToCompletion(_ process: Process) async throws -> ToolResult {
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        try launch(process)

        return try await withTaskCancellationHandler {
            let stdout = try await collectData(stdoutPipe)
            let stderr = try await collectData(stderrPipe)
            process.waitUntilExit()
            return ToolResult(
                exitCode: process.terminationStatus,
                standardOutput: String(data: stdout, encoding: .utf8) ?? "",
                standardError: String(data: stderr, encoding: .utf8) ?? ""
            )
        } onCancel: {
            process.terminate()
        }
    }

    private func execute(_ process: Process) async throws -> ToolResult {
        try await runToCompletion(process)
    }

    private func readLoop(
        process: Process,
        stdout: Pipe,
        stderr: Pipe,
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> ToolResult {
        // stderr carries errors and warnings; route it through the same
        // callback so bot detection and error reporting see everything.
        stderr.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                onOutput(chunk)
            }
        }

        var buffer = Data()
        stdout.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let chunk = String(data: data, encoding: .utf8) {
                onOutput(chunk)
            }
        }

        while process.isRunning {
            try Task.checkCancellation()
            try await Task.sleep(nanoseconds: UInt64(AppConstants.processReadInterval * 1_000_000_000))
        }
        stdout.fileHandleForReading.readabilityHandler = nil
        stderr.fileHandleForReading.readabilityHandler = nil

        buffer.append(stdout.fileHandleForReading.readDataToEndOfFile())
        let remainingStderr = stderr.fileHandleForReading.readDataToEndOfFile()

        return ToolResult(
            exitCode: process.terminationStatus,
            standardOutput: String(data: buffer, encoding: .utf8) ?? "",
            standardError: String(data: remainingStderr, encoding: .utf8) ?? ""
        )
    }

    private func collectData(_ pipe: Pipe) async throws -> Data {
        pipe.fileHandleForReading.readDataToEndOfFile()
    }
}
