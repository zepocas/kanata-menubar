import Foundation

struct ServiceError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Runs a command as root through a single administrator-privileges prompt.
///
/// This uses `NSAppleScript` in-process (rather than shelling out to `osascript`) so the system
/// prompt is attributed to this app instead of to "osascript".
enum PrivilegedShell {
    static func run(_ command: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let source = "do shell script \"\(command)\" with administrator privileges"
                var errorInfo: NSDictionary?
                NSAppleScript(source: source)?.executeAndReturnError(&errorInfo)

                guard let errorInfo else {
                    continuation.resume()
                    return
                }
                // -128 is AppleScript's code for the user cancelling the password/Touch ID prompt.
                if (errorInfo[NSAppleScript.errorNumber] as? Int) == -128 {
                    continuation.resume(throwing: CancellationError())
                } else {
                    let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    continuation.resume(throwing: ServiceError(message: message))
                }
            }
        }
    }
}
