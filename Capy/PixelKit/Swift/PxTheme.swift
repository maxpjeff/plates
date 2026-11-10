// PxTheme.swift
// Pixel style: colors, fonts and per-status styling.
// Add this file to BOTH the app target and the widget target.

import SwiftUI

// MARK: - Hex colors

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1
        )
    }
}

// MARK: - Palette (use ONLY these colors in the UI)

enum Px {
    static let ink = Color(hex: 0x2B2118)          // all text, outlines, drop shadows
    static let paper = Color(hex: 0xFFF4E2)        // app background
    static let gridLine = Color(hex: 0xF3E4CA)     // graph-paper lines
    static let card = Color(hex: 0xFFFDF8)         // cards, white boxes
    static let textSecondary = Color(hex: 0x6B5741)
    static let textMuted = Color(hex: 0x7A6248)

    static let orange = Color(hex: 0xFF9F43)       // primary buttons, today token
    static let orangeSoft = Color(hex: 0xFFB84D)   // posted day tokens
    static let flame = Color(hex: 0xFF7A2F)
    static let yellow = Color(hex: 0xFFD08A)       // streak pill, streak stat card
    static let yellowText = Color(hex: 0x5A3A12)
    static let greenSoft = Color(hex: 0xCFEFB4)
    static let greenText = Color(hex: 0x1F4A0B)
    static let blueSoft = Color(hex: 0xCDE8F7)
    static let blueText = Color(hex: 0x0D3B5C)
    static let pinkSoft = Color(hex: 0xF8D5D9)
    static let pinkText = Color(hex: 0x7A1F2B)

    static let segmentEmpty = Color(hex: 0xEADCC6)
    static let restOutline = Color(hex: 0xA8957A)
    static let photoPlaceholder = Color(hex: 0xCDBBA2)

    static let cameraBg = Color(hex: 0x1E1712)
    static let cameraGrid = Color(hex: 0x2A2019)
    static let cameraPanel = Color(hex: 0x3A2E24)
    static let cameraPreview = Color(hex: 0x4A3C30)
    static let cameraText = Color(hex: 0xE2D5C4)

    static let gridSpacing: CGFloat = 8
}

// MARK: - Fonts (Pixelify Sans only)

enum PxFont {
    enum Weight: String {
        case regular = "PixelifySans-Regular"
        case medium = "PixelifySans-Medium"
        case semibold = "PixelifySans-SemiBold"
        case bold = "PixelifySans-Bold"
    }

    static func make(_ size: CGFloat, _ weight: Weight = .bold, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static let displayName = make(38, .bold, relativeTo: .largeTitle)  // capybara name on Home
    static let screenTitle = make(34, .bold, relativeTo: .title)       // "History", "Biscuit is fed!"
    static let button = make(24, .bold, relativeTo: .title3)           // primary buttons
    static let stat = make(30, .bold, relativeTo: .title2)             // stat card numbers
    static let section = make(22, .bold, relativeTo: .headline)        // NOVEMBER, RECENT FEEDS (caps)
    static let pill = make(17, .bold, relativeTo: .subheadline)        // LOCKED IN, CHUD (caps)
    static let label = make(17, .bold, relativeTo: .subheadline)       // TODAY, STREAK (caps)
    static let dateLine = make(15, .semibold, relativeTo: .footnote)   // MONDAY, NOV 9 (caps)
    static let body = make(17, .medium, relativeTo: .body)
    static let caption = make(14, .medium, relativeTo: .footnote)
    static let micro = make(14, .semibold, relativeTo: .caption)       // weekday letters, day numbers

    /// Call once at launch in DEBUG. If any line says MISSING, the font file
    /// isn't in the target or isn't listed in Info.plist (UIAppFonts).
    static func debugCheck() {
        #if DEBUG
        for w in [Weight.regular, .medium, .semibold, .bold] {
            let ok = UIFont(name: w.rawValue, size: 12) != nil
            print("PxFont \(w.rawValue): \(ok ? "OK" : "MISSING")")
        }
        #endif
    }
}

// MARK: - Status styling
// Map your existing AvatarState to this (see CURSOR_PROMPT.md, Step 4).

enum PxStatus: CaseIterable {
    case lockedIn, recovering, couchMode, streakLost

    var label: String {
        switch self {
        case .lockedIn: return "LOCKED IN"
        case .recovering: return "RECOVERING"
        case .couchMode: return "COUCH MODE"
        case .streakLost: return "CHUD"
        }
    }

    var sprite: String {
        switch self {
        case .lockedIn: return "capy_locked_in"
        case .recovering: return "capy_recovering"
        case .couchMode: return "capy_couch_mode"
        case .streakLost: return "capy_streak_lost"
        }
    }

    var tintSprite: String { sprite + "_tint" }

    /// Background of the scene area behind the capybara.
    var sceneColor: Color {
        switch self {
        case .lockedIn: return Color(hex: 0xE6F4D7)
        case .recovering: return Color(hex: 0xFBE7BE)
        case .couchMode: return Color(hex: 0xE3DAF2)
        case .streakLost: return Color(hex: 0xF8D5D9)
        }
    }

    /// Grid lines inside the scene area (a slightly darker tint).
    var sceneGrid: Color {
        switch self {
        case .lockedIn: return Color(hex: 0xD7ECC3)
        case .recovering: return Color(hex: 0xF3D9A6)
        case .couchMode: return Color(hex: 0xD8CDEC)
        case .streakLost: return Color(hex: 0xEFC3C9)
        }
    }

    var pillColor: Color {
        switch self {
        case .lockedIn: return Px.greenSoft
        case .recovering: return Px.yellow
        case .couchMode: return Color(hex: 0xE3DAF2)
        case .streakLost: return Px.pinkSoft
        }
    }

    var pillText: Color {
        switch self {
        case .lockedIn: return Px.greenText
        case .recovering: return Px.yellowText
        case .couchMode: return Color(hex: 0x3C2A6B)
        case .streakLost: return Px.pinkText
        }
    }

    /// Filled segments in the "Today" bar.
    var barColor: Color {
        switch self {
        case .lockedIn: return Color(hex: 0x7BC043)
        case .recovering: return Color(hex: 0x7FB8DE)
        case .couchMode: return Px.flame
        case .streakLost: return Px.segmentEmpty
        }
    }

    /// Text color for the right side of the "Today" row.
    var accentText: Color {
        switch self {
        case .lockedIn: return Color(hex: 0x2F6B12)
        case .recovering: return Px.blueText
        case .couchMode: return Color(hex: 0x9A3A04)
        case .streakLost: return Px.pinkText
        }
    }
}

// MARK: - Day tokens

extension PxStatus {
    init(_ state: AvatarState) {
        switch state {
        case .lockedIn: self = .lockedIn
        case .recovering: self = .recovering
        case .couchMode: self = .couchMode
        case .streakLost: self = .streakLost
        }
    }
}

enum PxDayKind {
    case posted       // a day with a post
    case rest         // rest day
    case missed       // workout day with no post (past)
    case today        // today, not posted yet
    case todayPosted  // today, posted
    case future
}
