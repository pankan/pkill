import Foundation
import Darwin

struct PortEntry: Identifiable, Hashable {
    var id: String { "\(pid)-\(port)-\(proto)" }
    let port: Int
    let pid: Int32
    let command: String
    let proto: String   // TCP / UDP
    let addr: String    // *, 127.0.0.1, [::1] ...
    let uid: Int32          // owning user id
    let execPath: String    // absolute path to the executable, "" if unknown

    /// Apple/OS-managed locations. Binaries here are launchd-managed daemons and
    /// agents — killing them is futile (they relaunch) or needs elevated rights.
    private static let systemPrefixes = [
        "/System/", "/usr/libexec/", "/usr/sbin/", "/usr/bin/",
        "/sbin/", "/bin/", "/Library/Apple/",
    ]

    /// A process is "system" if it runs as root/a system user (uid < 500; regular
    /// accounts start at 501) or its executable lives in an OS location above.
    /// These are flagged and the kill button is disabled.
    var isSystem: Bool {
        if uid < 500 { return true }
        return Self.systemPrefixes.contains { execPath.hasPrefix($0) }
    }
}

enum PortScanner {
    /// Lists listening sockets via `lsof` and returns one entry per (pid, port).
    static func scan() -> [PortEntry] {
        let tcp = run(["-nP", "-iTCP", "-sTCP:LISTEN", "-FpcunPt"])
        let udp = run(["-nP", "-iUDP", "-FpcunPt"])
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
        var uid: Int32 = 0
        var execPath = ""
        for line in output.split(separator: "\n") {
            guard let key = line.first else { continue }
            let value = String(line.dropFirst())
            switch key {
            case "p":
                pid = Int32(value) ?? 0
                execPath = path(for: pid)
            case "c": command = value
            case "u": uid = Int32(value) ?? 0
            case "P": proto = value
            case "n":
                guard let (addr, port) = splitAddress(value) else { continue }
                result.append(PortEntry(port: port, pid: pid, command: command,
                                        proto: proto.isEmpty ? "TCP" : proto, addr: addr,
                                        uid: uid, execPath: execPath))
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

    /// Absolute path to a process's executable, or "" if it can't be read
    /// (e.g. the process isn't owned by us). Used to classify system processes.
    private static func path(for pid: Int32) -> String {
        var buf = [UInt8](repeating: 0, count: 4096)   // PROC_PIDPATHINFO_MAXSIZE
        let n = proc_pidpath(pid, &buf, UInt32(buf.count))
        guard n > 0 else { return "" }
        return String(decoding: buf.prefix(Int(n)), as: UTF8.self)
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
