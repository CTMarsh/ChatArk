import Foundation
import Network

@MainActor
@Observable
final class NetworkMonitor {
    static let shared = NetworkMonitor()

    var isConnected = true
    var connectionType: ConnectionType = .unknown

    enum ConnectionType: Sendable {
        case wifi, cellular, wired, unknown
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.chrismarsh.chatark.networkmonitor")

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wired
                } else {
                    self.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }
}
