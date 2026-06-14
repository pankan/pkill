import SwiftUI
import Combine

@MainActor
final class PortStore: ObservableObject {
    @Published var entries: [PortEntry] = []
    @Published var query: String = ""
    @Published var isScanning = false
    @Published var killingIDs: Set<String> = []

    var filtered: [PortEntry] {
        guard !query.isEmpty else { return entries }
        let q = query.lowercased()
        return entries.filter {
            String($0.port).contains(q) ||
            $0.command.lowercased().contains(q) ||
            String($0.pid).contains(q)
        }
    }

    func refresh() {
        isScanning = true
        Task.detached(priority: .userInitiated) {
            let found = PortScanner.scan()
            await MainActor.run {
                self.entries = found
                self.isScanning = false
            }
        }
    }

    func kill(_ entry: PortEntry) {
        killingIDs.insert(entry.id)
        Task.detached(priority: .userInitiated) {
            PortScanner.kill(pid: entry.pid, hard: false)
            // give it a moment, then force if still listening
            try? await Task.sleep(for: .milliseconds(400))
            if PortScanner.isAlive(pid: entry.pid) {
                PortScanner.kill(pid: entry.pid, hard: true)
                try? await Task.sleep(for: .milliseconds(200))
            }
            let found = PortScanner.scan()
            await MainActor.run {
                self.entries = found
                self.killingIDs.remove(entry.id)
            }
        }
    }
}
