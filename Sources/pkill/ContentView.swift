import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PortStore
    @State private var hoveredID: String?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.4)
            content
            footer
        }
        .frame(width: 340)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear { store.refresh() }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("Filter by port, name or PID", text: $store.query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
            if store.isScanning {
                ProgressView().controlSize(.small)
            } else {
                Button {
                    store.refresh()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: List

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                if store.filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(store.filtered) { entry in
                        PortRow(
                            entry: entry,
                            isKilling: store.killingIDs.contains(entry.id),
                            isHovered: hoveredID == entry.id
                        ) {
                            store.kill(entry)
                        }
                        .onHover { hoveredID = $0 ? entry.id : nil }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .frame(height: contentHeight)
    }

    /// ScrollViews have no intrinsic height, so in a self-sizing menu bar
    /// window they collapse to nothing. Size to the rows, clamped.
    private var contentHeight: CGFloat {
        guard !store.filtered.isEmpty else { return 120 }
        let rowHeight: CGFloat = 54
        let total = CGFloat(store.filtered.count) * rowHeight + 16
        return min(max(total, rowHeight), 420)
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: store.query.isEmpty ? "checkmark.circle" : "magnifyingglass")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.secondary)
            Text(store.query.isEmpty ? "No listening ports" : "No matches")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: Footer

    private var footer: some View {
        HStack {
            Button {
                store.query = ""
            } label: {
                HStack(spacing: 4) {
                    Text("\(store.filtered.count) port\(store.filtered.count == 1 ? "" : "s")")
                    if !store.query.isEmpty {
                        Text("· show all \(store.entries.count)")
                            .foregroundStyle(.tint)
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(store.query.isEmpty)
            .help("Show all listening ports")
            Spacer()
            Button {
                NSApp.terminate(nil)
            } label: {
                Text("Quit")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Row

struct PortRow: View {
    let entry: PortEntry
    let isKilling: Bool
    let isHovered: Bool
    let onKill: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(String(entry.port))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 1) {
                Text(entry.command)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                Text("PID \(entry.pid) · \(entry.proto) · \(entry.addr)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)

            killButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.quaternary.opacity(isHovered ? 0.6 : 0.28))
        }
    }

    private var killButton: some View {
        Button(action: onKill) {
            Group {
                if isKilling {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .frame(width: 26, height: 26)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isHovered ? Color.red : .secondary)
        .glassEffect(.regular.interactive(), in: .circle)
        .disabled(isKilling)
        .help("Kill \(entry.command) (PID \(entry.pid))")
    }
}
