import CoreText
import SwiftData
import SwiftUI

@main
struct ExquisiteCorpseApp: App {
    let container: ModelContainer

    init() {
        // Space Mono ships inside the app; register it so Font.custom can find it
        if let url = Bundle.main.url(forResource: "SpaceMono-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }

        // The gallery. With the iCloud capability on, this syncs through the user's iCloud.
        // If iCloud isn't set up, fall back to saving on the device only rather than failing.
        do {
            container = try ModelContainer(for: Drawing.self)
        } catch {
            container = try! ModelContainer(
                for: Drawing.self,
                configurations: ModelConfiguration(cloudKitDatabase: .none)
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
