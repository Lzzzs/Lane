import SwiftUI
import LaneCore

@main
struct LaneApp: App {
    @State private var appStore: AppStore
    @State private var timelineStore: TimelineStore = TimelineStore()
    @AppStorage("lane.preferredLanguage") private var preferredLanguage: String = LanePreferredLanguage.system.rawValue

    init() {
        FontRegistration.registerBundledFonts()
        do {
            let url = try Database.defaultStoreURL()
            let pool = try Database.makeFilePool(at: url)
            try Migrations.register().migrate(pool)
            try SeedData.seedIfEmpty(pool: pool)
            _appStore = State(initialValue: AppStore(pool: pool))
        } catch {
            // Fall back to in-memory queue so the app still launches with empty state.
            let fallback = (try? Database.makeInMemoryQueue()) ?? { fatalError("cannot create in-memory DB") }()
            _ = try? Migrations.register().migrate(fallback)
            _appStore = State(initialValue: AppStore(pool: fallback))
        }
    }

    var body: some Scene {
        WindowGroup("Lane") {
            ContentView()
                .environment(appStore)
                .environment(timelineStore)
                .environment(\.locale, currentLocale)
                .task {
                    try? await appStore.load()
                    timelineStore.visibleGroupIds = Set(appStore.groups.map(\.id))
                }
                .frame(minWidth: 1000, minHeight: 540)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }

    private var currentLocale: Locale {
        guard let id = LanePreferredLanguage(rawValue: preferredLanguage)?.localeIdentifier else {
            return Locale.autoupdatingCurrent
        }
        return Locale(identifier: id)
    }
}
