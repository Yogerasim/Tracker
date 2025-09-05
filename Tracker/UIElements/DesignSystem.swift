import UIKit

enum AppColors {
    static let background = UIColor.white
    static let backgroundBlackButton = UIColor(hex: "#1A1B22")
    static let primaryBlue = UIColor(hex: "#4685FF")
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor(hex: "#8E8E93")
    static let errorRed = UIColor(hex: "#F56B6C")
    static let gray = UIColor(hex: "#AEAFB4")
}

enum AppFonts {
    
    // MARK: - Presets
    static let title = AppFonts.bold(20)
    static let bigTitle = AppFonts.bold(34)
    static let body = AppFonts.medium(16)
    static let caption = AppFonts.regular(14)
    static let headline = AppFonts.semibold(17)
    static let subheadline = AppFonts.medium(15)
    static let plug = AppFonts.medium(12)
    
    // MARK: - System SF Pro
    static func regular(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .regular)
    }

    static func medium(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .medium)
    }

    static func semibold(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .semibold)
    }

    static func bold(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .bold)
    }
}

enum AppLayout {
    static let cornerRadius: CGFloat = 16
    static let padding: CGFloat = 16
}

enum UIConstants {
    static let horizontalPadding: CGFloat = 16.0
 
    static var defaultInsets: UIEdgeInsets {
        UIEdgeInsets(top: 0, left: horizontalPadding, bottom: 0, right: horizontalPadding)
    }
}

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
