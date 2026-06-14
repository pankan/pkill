import SwiftUI

@main
struct PkillApp: App {
    @StateObject private var store = PortStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(store)
        } label: {
            Image(systemName: "powerplug.portrait")
        }
        .menuBarExtraStyle(.window)
    }
}
