import Foundation
import Darwin

struct PortEntry: Identifiable, Hashable {
    var id: String { "\(pid)-\(port)-\(proto)" }
    let port: Int
    let pid: Int32
    let command: String
    let proto: String   // TCP / UDP
    let addr: String    // *, 127.0.0.1, [::1] ...
}

enum PortScanner {
    /// Lists listening sockets via `lsof` and returns one entry per (pid, port).
    static func scan() -> [PortEntry] {
        let tcp = run(["-nP", "-iTCP", "-sTCP:LISTEN", "-FpcnPt"])
        let udp = run(["-nP", "-iUDP", "-FpcnPt"])
        var seen = Set<String>()
        let entries = (parse(tcp) + parse(udp)).filter { e in
            seen.insert(e.id).inserted
        }
        return entries.sorted { $0.port < $1.port }
    }

    private static func run(_ args: [String]) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        proc.waitUntilExit()
        return String(data: data, encoding: .utf8) ?? ""
    }

    /// Parses `lsof -F` field output. Process records start with `p`,
    /// file records start with `f`; the name field `n` closes a record.
    private static func parse(_ output: String) -> [PortEntry] {
        var result: [PortEntry] = []
        var pid: Int32 = 0
        var command = ""
        var proto = ""
        for line in output.split(separator: "\n") {
            guard let key = line.first else { continue }
            let value = String(line.dropFirst())
            switch key {
            case "p": pid = Int32(value) ?? 0
            case "c": command = value
            case "P": proto = value
            case "n":
                guard let (addr, port) = splitAddress(value) else { continue }
                result.append(PortEntry(port: port, pid: pid, command: command,
                                        proto: proto.isEmpty ? "TCP" : proto, addr: addr))
            default: break
            }
        }
        return result
    }

    /// Turns `*:3000`, `127.0.0.1:8080`, `[::1]:5000` into (addr, port).
    private static func splitAddress(_ name: String) -> (String, Int)? {
        guard let colon = name.lastIndex(of: ":") else { return nil }
        let addr = String(name[..<colon])
        let portStr = String(name[name.index(after: colon)...])
        guard let port = Int(portStr) else { return nil }
        return (addr, port)
    }

    /// Sends SIGTERM, then SIGKILL after a grace period if still alive.
    @discardableResult
    static func kill(pid: Int32, hard: Bool = false) -> Bool {
        let signal = hard ? SIGKILL : SIGTERM
        return Darwin.kill(pid, signal) == 0
    }

    static func isAlive(pid: Int32) -> Bool {
        Darwin.kill(pid, 0) == 0 || errno == EPERM
    }
}
