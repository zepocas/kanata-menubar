import Foundation

public enum LaunchdOverrides {
    /// Parses `launchctl print-disabled <domain>`: whether `label` is disabled, i.e. launchd won't
    /// load it (at boot or otherwise). Labels that aren't listed use the default, enabled. Older
    /// macOS prints `=> true` for disabled instead of `=> disabled`.
    public static func isDisabled(_ label: String, inPrintDisabled output: String) -> Bool {
        output.split(separator: "\n").contains { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed == "\"\(label)\" => disabled" || trimmed == "\"\(label)\" => true"
        }
    }
}
