import CoreText
import SwiftUI

@main
struct ExquisiteCorpseApp: App {
    init() {
        // Space Mono ships inside the app; register it so Font.custom can find it
        if let url = Bundle.main.url(forResource: "SpaceMono-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
