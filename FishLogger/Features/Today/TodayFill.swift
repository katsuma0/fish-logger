import SwiftUI

/// Fill behind white text on Today. High contrast, from the app setting or the system switch, gets
/// the deep system blue so the white text stays readable.
enum TodayFill {
    static func accent(strong: Bool) -> Color {
        strong ? Color(hex: 0x0040DD) : Theme.accentFill
    }
}
