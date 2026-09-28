import Foundation
import MenubarCore

/// Polls `launchctl` for kanata's state and reports it when it changes.
@MainActor
final class ServiceWatcher {
    private(set) var status: KanataStatus = .unknown
    var onChange: ((KanataStatus) -> Void)?

    private let services: ServiceController
    private var timer: Timer?

    init(services: ServiceController) {
        self.services = services
    }

    func start(interval: TimeInterval = 3) {
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        // .common keeps polling while the menu is open.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        poll()
    }

    func poll() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let status = await services.fetchStatus()
            guard status != self.status else { return }
            self.status = status
            self.onChange?(status)
        }
    }
}
