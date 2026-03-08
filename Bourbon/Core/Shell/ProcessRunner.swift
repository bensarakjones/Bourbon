import Foundation

// MARK: - Result
struct ProcessResult {
    let exitCode: Int32
    let stdout:   String
    let stderr:   String
    
    var succeeded: Bool   { exitCode == 0 }
    var output:    String { stdout.isEmpty ? stderr : stdout }
}

// MARK: - Runner
enum ProcessRunner {
    
    /// Run a command and wait for it to finish
    static func run(
        _ args: [String],
        environment: [String: String] = [:],
        workingDirectory: URL? = nil
    ) async throws -> ProcessResult {
        
        try await withCheckedThrowingContinuation { continuation in
            
            let process    = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            
            process.executableURL  = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments      = args
            process.standardOutput = stdoutPipe
            process.standardError  = stderrPipe
            
            if let dir = workingDirectory {
                process.currentDirectoryURL = dir
            }
            
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
            
            process.terminationHandler = { p in
                let out = String(
                    data: stdoutPipe.fileHandleForReading
                        .readDataToEndOfFile(),
                    encoding: .utf8
                ) ?? ""
                
                let err = String(
                    data: stderrPipe.fileHandleForReading
                        .readDataToEndOfFile(),
                    encoding: .utf8
                ) ?? ""
                
                continuation.resume(returning: ProcessResult(
                    exitCode: p.terminationStatus,
                    stdout:   out,
                    stderr:   err
                ))
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(
                    throwing: BourbonError.processFailure(
                        error.localizedDescription
                    )
                )
            }
        }
    }
    
    /// Run a command and stream output live as it runs
    static func runStreaming(
        _ args: [String],
        environment: [String: String] = [:],
        onOutput: @escaping @Sendable (String) -> Void
    ) async throws -> Int32 {
        
        try await withCheckedThrowingContinuation { continuation in
            
            let process = Process()
            let pipe    = Pipe()
            
            process.executableURL  = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments      = args
            process.standardOutput = pipe
            process.standardError  = pipe
            
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env
            
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty,
                      let text = String(data: data, encoding: .utf8)
                else { return }
                DispatchQueue.main.async { onOutput(text) }
            }
            
            process.terminationHandler = { p in
                pipe.fileHandleForReading.readabilityHandler = nil
                continuation.resume(returning: p.terminationStatus)
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(
                    throwing: BourbonError.processFailure(
                        error.localizedDescription
                    )
                )
            }
        }
    }
}
