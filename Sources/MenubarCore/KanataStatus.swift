import Foundation

public enum KanataStatus: Equatable, Sendable {
    case running
    case loadedNotRunning
    case notLoaded
    case unknown

    public var isLoaded: Bool { self == .running || self == .loadedNotRunning }

    public var label: String {
        switch self {
        case .running: return "Kanata — running"
        case .loadedNotRunning: return "Kanata — loaded, not running"
        case .notLoaded: return "Kanata — stopped"
        case .unknown: return "Kanata — status unknown"
        }
    }

    /// Parses `launchctl print system/<label>`. A non-zero exit means the job isn't bootstrapped
    /// into launchd at all (`bootout` was run, or it was never loaded).
    public static func parse(exitCode: Int32, output: String) -> KanataStatus {
        guard exitCode == 0 else { return .notLoaded }
        guard let stateLine = output
            .split(separator: "\n")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .first(where: { $0.hasPrefix("state = ") })
        else { return .unknown }
        return stateLine == "state = running" ? .running : .loadedNotRunning
    }
}
