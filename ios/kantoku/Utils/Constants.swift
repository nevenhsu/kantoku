//
//  Constants.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI
import UIKit

enum Constants {
    // MARK: - Colors
    enum Colors {
        // Light Mode - Primary
        static let primaryLight = Color(hex: "1A237E")
        static let primaryAccentLight = Color(hex: "3F51B5")
        
        // Light Mode - Secondary
        static let orangeLight = Color(hex: "FF6F00")
        static let greenLight = Color(hex: "2E7D32")
        static let redLight = Color(hex: "C62828")
        
        // Light Mode - Background
        static let backgroundLight = Color(hex: "F5F5F5")
        static let cardBackgroundLight = Color.white
        
        // Light Mode - Text
        static let primaryTextLight = Color(hex: "212121")
        static let secondaryTextLight = Color(hex: "757575")
        static let disabledTextLight = Color(hex: "BDBDBD")
        
        // Dark Mode - Primary
        static let primaryDark = Color(hex: "5C6BC0")
        static let primaryAccentDark = Color(hex: "7986CB")
        
        // Dark Mode - Secondary
        static let orangeDark = Color(hex: "FF9800")
        static let greenDark = Color(hex: "66BB6A")
        static let redDark = Color(hex: "EF5350")
        
        // Dark Mode - Background
        static let backgroundDark = Color(hex: "121212")
        static let cardBackgroundDark = Color(hex: "1E1E1E")
        static let emphasisBackgroundDark = Color(hex: "263238")
        
        // Dark Mode - Text
        static let primaryTextDark = Color.white
        static let secondaryTextDark = Color(hex: "B0B0B0")
        static let disabledTextDark = Color(hex: "6E6E6E")
        
        // Adaptive Colors (自动适配 Light/Dark Mode)
        static var primary: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(primaryDark) : UIColor(primaryLight)
            })
        }
        
        static var primaryAccent: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(primaryAccentDark) : UIColor(primaryAccentLight)
            })
        }
        
        static var orange: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(orangeDark) : UIColor(orangeLight)
            })
        }
        
        static var green: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(greenDark) : UIColor(greenLight)
            })
        }
        
        static var red: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(redDark) : UIColor(redLight)
            })
        }
        
        static var background: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(backgroundDark) : UIColor(backgroundLight)
            })
        }
        
        static var cardBackground: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(cardBackgroundDark) : UIColor(cardBackgroundLight)
            })
        }
        
        static var primaryText: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(primaryTextDark) : UIColor(primaryTextLight)
            })
        }
        
        static var secondaryText: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(secondaryTextDark) : UIColor(secondaryTextLight)
            })
        }
        
        static var disabledText: Color {
            Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(disabledTextDark) : UIColor(disabledTextLight)
            })
        }
    }
    
    // MARK: - Typography
    enum Typography {
        // Titles (SF Pro Display)
        static let h1 = Font.system(size: 28, weight: .bold, design: .default)
        static let h2 = Font.system(size: 24, weight: .semibold, design: .default)
        static let h3 = Font.system(size: 20, weight: .semibold, design: .default)
        
        // Body (SF Pro Text)
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let caption = Font.system(size: 14, weight: .regular, design: .default)
        static let small = Font.system(size: 12, weight: .regular, design: .default)
        
        // Japanese (Hiragino Sans - System will fallback automatically)
        static let kanaLarge = Font.system(size: 48, weight: .medium, design: .default)
        static let wordDisplay = Font.system(size: 32, weight: .regular, design: .default)
    }
    
    // MARK: - Spacing (8pt Grid System)
    enum Spacing {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
    
    // MARK: - Button Dimensions
    enum Button {
        static let height: CGFloat = 50
        static let iconButtonSize: CGFloat = 44
    }
    
    // MARK: - Environment
    enum Environment {
        static let n8nBaseURL = "http://localhost:5678" // Development
        static let supabaseURL = "YOUR_SUPABASE_URL" // TODO: Replace with actual URL
        static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY" // TODO: Replace with actual key
    }
    
    // MARK: - API Endpoints
    enum API {
        static let generateTasks = "/webhook/generate-tasks"
        static let reviewSubmission = "/webhook/review-submission"
        static let generateTest = "/webhook/generate-test"
        static let gradeTest = "/webhook/grade-test"
    }
}

// MARK: - Color Extension (Hex Support)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
