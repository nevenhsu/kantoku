//
//  kantokuApp.swift
//  kantoku
//
//  Created by NAI WEN HSU on 2026/1/23.
//

import SwiftUI
import Auth

@main
struct kantokuApp: App {
    @StateObject private var authService = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
        }
    }
}
