import Foundation
import CoreText

enum FontRegistration {
    static func registerBundledFonts() {
        let names = [
            "GeneralSans-Regular",
            "GeneralSans-Medium",
            "GeneralSans-Semibold",
            "JetBrainsMono-Regular"
        ]
        let urls: [URL] = names.compactMap { name in
            Bundle.main.url(forResource: name, withExtension: "otf")
                ?? Bundle.main.url(forResource: name, withExtension: "ttf")
        }
        guard !urls.isEmpty else { return }

        CTFontManagerRegisterFontURLs(urls as CFArray, .process, true) { errors, _ in
            if let errs = errors as? [Error], !errs.isEmpty {
                NSLog("Lane font registration: \(errs.count) error(s); first: \(errs[0])")
            }
            return true
        }
    }
}
