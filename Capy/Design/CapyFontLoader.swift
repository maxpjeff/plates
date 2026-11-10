import CoreText
import UIKit

/// Registers bundled fonts and exposes their real PostScript names (not always the filename).
enum CapyFontLoader {
    private static var didLoad = false

    static func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        let resources = [
            "Fredoka-Bold",
            "Fredoka-SemiBold",
            "Nunito-SemiBold",
            "Nunito-Bold",
            "Nunito-ExtraBold",
        ]

        for resource in resources {
            guard let url = Bundle.main.url(forResource: resource, withExtension: "ttf") else { continue }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }

        #if DEBUG
        assert(UIFont(name: CapyFontResolver.fredokaBold, size: 12) != nil, "Fredoka failed to load")
        assert(UIFont(name: CapyFontResolver.nunitoBold, size: 12) != nil, "Nunito failed to load")
        #endif
    }

    static func postScriptName(fileBase: String) -> String {
        guard let url = Bundle.main.url(forResource: fileBase, withExtension: "ttf"),
              let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let name = CTFontDescriptorCopyAttribute(descriptors[0], kCTFontNameAttribute) as? String
        else { return fileBase }
        return name
    }
}
