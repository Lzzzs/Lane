import SwiftUI
import LaneCore

@main
struct LaneApp: App {
    init() {
        FontRegistration.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup("Lane") {
            ContentView()
                .frame(minWidth: 720, minHeight: 480)
        }
        .windowStyle(.titleBar)
    }
}
