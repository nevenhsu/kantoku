//
//  kantokuApp.swift
//  kantoku
//
//  Created by NAI WEN HSU on 2026/1/23.
//

import SwiftUI

@main
struct kantokuApp: App {
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                MainTabView()
            } else {
                // TODO: 實作登入頁面
                Text("登入頁面")
            }
        }
    }
}
