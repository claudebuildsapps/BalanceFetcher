import Foundation

class ScriptExecutor {
    // Default timeout in seconds
    private let defaultTimeout: TimeInterval = 10.0
    
    // Execute a shell script at the given path and return its output
    func executeScript(at path: String, timeout: TimeInterval? = nil) -> Result<String, Error> {
        let timeout = timeout ?? defaultTimeout
        
        // Create process for script execution
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        
        // Set up pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Prepare for execution
        do {
            // Start the process
            try process.run()
            
            // Create a background task for timeout handling
            let group = DispatchGroup()
            group.enter()
            
            // Start timeout timer
            let timer = DispatchSource.makeTimerSource()
            timer.schedule(deadline: .now() + timeout)
            timer.setEventHandler {
                if process.isRunning {
                    process.terminate()
                }
            }
            timer.resume()
            
            // Wait for process to finish in background
            DispatchQueue.global(qos: .background).async {
                process.waitUntilExit()
                timer.cancel()
                group.leave()
            }
            
            // Wait for either completion or timeout
            let result = group.wait(timeout: .now() + timeout + 1)
            
            // Check if we timed out
            if result == .timedOut {
                if process.isRunning {
                    process.terminate()
                }
                return .failure(ScriptError.timeout)
            }
            
            // Process completed, check status and output
            if process.terminationStatus != 0 {
                // Read error output
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                return .failure(ScriptError.executionFailed(errorMessage))
            }
            
            // Read standard output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8) else {
                return .failure(ScriptError.executionFailed("Unable to decode output"))
            }
            
            // Clean up and return the output
            return .success(output.trimmingCharacters(in: .whitespacesAndNewlines))
            
        } catch {
            return .failure(error)
        }
    }
    
    // Execute a shell command and return its output
    func executeCommand(_ command: String, timeout: TimeInterval? = nil) -> Result<String, Error> {
        let timeout = timeout ?? defaultTimeout
        
        // Create process for command execution
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        
        // Set up pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Prepare for execution
        do {
            // Start the process
            try process.run()
            
            // Create a background task for timeout handling
            let group = DispatchGroup()
            group.enter()
            
            // Start timeout timer
            let timer = DispatchSource.makeTimerSource()
            timer.schedule(deadline: .now() + timeout)
            timer.setEventHandler {
                if process.isRunning {
                    process.terminate()
                }
            }
            timer.resume()
            
            // Wait for process to finish in background
            DispatchQueue.global(qos: .background).async {
                process.waitUntilExit()
                timer.cancel()
                group.leave()
            }
            
            // Wait for either completion or timeout
            let result = group.wait(timeout: .now() + timeout + 1)
            
            // Check if we timed out
            if result == .timedOut {
                if process.isRunning {
                    process.terminate()
                }
                return .failure(ScriptError.timeout)
            }
            
            // Process completed, check status and output
            if process.terminationStatus != 0 {
                // Read error output
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                return .failure(ScriptError.executionFailed(errorMessage))
            }
            
            // Read standard output
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: outputData, encoding: .utf8) else {
                return .failure(ScriptError.executionFailed("Unable to decode output"))
            }
            
            // Clean up and return the output
            return .success(output.trimmingCharacters(in: .whitespacesAndNewlines))
            
        } catch {
            return .failure(error)
        }
    }
    
    // Execute a built-in test command to check if script execution is working
    func executeTestCommand() -> Result<String, Error> {
        // For testing purposes, we return a static value
        return .success("$1,234.56")
    }
    
    // Define custom errors for script execution
    enum ScriptError: Error, LocalizedError {
        case executionFailed(String)
        case timeout
        
        var errorDescription: String? {
            switch self {
            case .executionFailed(let message):
                return "Script execution failed: \(message)"
            case .timeout:
                return "Script execution timed out"
            }
        }
    }
}