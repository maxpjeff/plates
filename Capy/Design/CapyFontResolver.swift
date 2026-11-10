import UIKit

enum CapyFontResolver {
    static var fredokaBold: String { CapyFontLoader.postScriptName(fileBase: "Fredoka-Bold") }
    static var fredokaSemiBold: String { CapyFontLoader.postScriptName(fileBase: "Fredoka-SemiBold") }
    static var nunitoSemiBold: String { CapyFontLoader.postScriptName(fileBase: "Nunito-SemiBold") }
    static var nunitoBold: String { CapyFontLoader.postScriptName(fileBase: "Nunito-Bold") }
    static var nunitoExtraBold: String { CapyFontLoader.postScriptName(fileBase: "Nunito-ExtraBold") }
}
