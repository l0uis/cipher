import SwiftUI

enum CipherStyle {
    // MARK: - Colors
    enum Colors {
        static let background = Color("CipherBackground")
        static let cream = Color("CipherCream")
        static let primaryText = Color("CipherPrimaryText")
    }

    // MARK: - Layout
    enum Layout {
        static let cardAspectRatio: CGFloat = 3.0 / 4.0
    }

    // MARK: - Fonts
    enum Fonts {
        /// Sorts Mill Goudy — used for titles
        static func title(_ size: CGFloat) -> Font {
            .custom("SortsMillGoudy-Regular", size: size)
        }

        static func titleItalic(_ size: CGFloat) -> Font {
            .custom("SortsMillGoudy-Italic", size: size)
        }

        /// REM — used for body/UI text
        static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
            .custom("REM", size: size).weight(weight)
        }

        // Preset sizes
        static let largeTitle = title(34)
        static let title1 = title(28)
        static let title2 = title(22)
        static let title3 = title(20)
        static let headline = body(17, weight: .semibold)
        static let bodyText = body(15)
        static let subheadline = body(13)
        static let caption = body(11)
    }
}
