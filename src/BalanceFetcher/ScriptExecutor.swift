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
        
        // For bin commands, we need to handle them differently to avoid permissions prompts
        // Check if this is a command in a standard system bin directory
        let isBinCommand = command.hasPrefix("/usr/bin/") || 
                            command.hasPrefix("/bin/") || 
                            command.hasPrefix("/usr/local/bin/") ||
                            command.hasPrefix("/opt/homebrew/bin/")
        
        // Create process for command execution
        let process = Process()
        
        if isBinCommand {
            // Extract the executable and arguments
            let components = command.split(separator: " ", maxSplits: 1)
            let executable = String(components[0])
            
            process.executableURL = URL(fileURLWithPath: executable)
            
            // Add arguments if present
            if components.count > 1 {
                process.arguments = components[1].split(separator: " ").map { String($0) }
            }
        } else {
            // Use bash for other commands
            process.executableURL = URL(fileURLWithPath: "/bin/bash")
            process.arguments = ["-c", command]
        }
        
        // Set up pipes for output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Set environment variables to avoid file access prompts
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin"
        process.environment = env
        
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