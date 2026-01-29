//
//  Constants.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

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
        
        // Adaptive Colors
        static var primary: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(primaryDark) : UIColor(primaryLight)
            })
            #else
            return primaryLight
            #endif
        }
        
        static var primaryAccent: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(primaryAccentDark) : UIColor(primaryAccentLight)
            })
            #else
            return primaryAccentLight
            #endif
        }
        
        static var orange: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(orangeDark) : UIColor(orangeLight)
            })
            #else
            return orangeLight
            #endif
        }
        
        static var green: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(greenDark) : UIColor(greenLight)
            })
            #else
            return greenLight
            #endif
        }
        
        static var red: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(redDark) : UIColor(redLight)
            })
            #else
            return redLight
            #endif
        }
        
        static var background: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(backgroundDark) : UIColor(backgroundLight)
            })
            #else
            return backgroundLight
            #endif
        }
        
        static var cardBackground: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(cardBackgroundDark) : UIColor(cardBackgroundLight)
            })
            #else
            return cardBackgroundLight
            #endif
        }
        
        static var surface: Color { cardBackground }
        
        static var primaryText: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(primaryTextDark) : UIColor(primaryTextLight)
            })
            #else
            return primaryTextLight
            #endif
        }
        
        static var secondaryText: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(secondaryTextDark) : UIColor(secondaryTextLight)
            })
            #else
            return secondaryTextLight
            #endif
        }
        
        static var disabledText: Color {
            #if canImport(UIKit)
            return Color(UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark ? UIColor(disabledTextDark) : UIColor(disabledTextLight)
            })
            #else
            return disabledTextLight
            #endif
        }
    }
    
    // MARK: - Typography
    enum Typography {
        static let h1 = Font.system(size: 28, weight: .bold, design: .default)
        static let h2 = Font.system(size: 24, weight: .semibold, design: .default)
        static let h3 = Font.system(size: 20, weight: .semibold, design: .default)
        static let h4 = Font.system(size: 18, weight: .semibold, design: .default)
        
        static let body = Font.system(size: 17, weight: .regular, design: .default)
        static let caption = Font.system(size: 14, weight: .regular, design: .default)
        static let small = Font.system(size: 12, weight: .regular, design: .default)
        
        static let kanaLarge = Font.system(size: 48, weight: .medium, design: .default)
        static let wordDisplay = Font.system(size: 32, weight: .regular, design: .default)
        
        static let buttonText = Font.system(size: 18, weight: .semibold, design: .default)
    }
    
    // MARK: - Spacing
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
        static let button: CGFloat = 12
    }
    
    // MARK: - Button Dimensions
    enum Button {
        static let height: CGFloat = 50
        static let heightLarge: CGFloat = 56
        static let iconButtonSize: CGFloat = 44
    }
    
    // MARK: - Environment
    enum Environment {
        // n8n URL with fallback to Mac IP (localhost won't work in iOS Simulator)
        static let n8nBaseURL = Bundle.main.object(forInfoDictionaryKey: "N8N_BASE_URL") as? String ?? "http://localhost:5678"
        static let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? ""
        static let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
        static let testEmail = Bundle.main.object(forInfoDictionaryKey: "TEST_EMAIL") as? String ?? ""
        static let testPassword = Bundle.main.object(forInfoDictionaryKey: "TEST_PASSWORD") as? String ?? ""
        static let environment = Bundle.main.object(forInfoDictionaryKey: "ENVIRONMENT") as? String ?? "development"
        
        // Helper to check current environment
        static var isDevelopment: Bool {
            environment == "development"
        }
        
        static var isProduction: Bool {
            environment == "production"
        }
    }
    
    // MARK: - API Endpoints
    enum API {
        static let generateTasks = "/webhook/generate-tasks"
        static let reviewSubmission = "/webhook/review-submission"
        static let generateTest = "/webhook/generate-test"
        static let gradeTest = "/webhook/grade-test"
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
