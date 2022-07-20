//
//  native_twitchApp.swift
//  native_twitch
//
//  Created by Adam Solloway on 3/7/22.
//

import SwiftUI
import Foundation

@main
struct native_twitchApp: App {
    @AppStorage("AccessToken") var accessToken: String = ""
    @ObservedObject var auth = AuthItem()
    
    init() {
        auth.checkAuth()
    }
    
    var body: some Scene {
        WindowGroup {
            if auth.isAuthed {
                ContentView()
                    .navigationTitle(Text(""))
            } else {
                FirstBoot(authItem: auth, isSettings: false)
            }
        }
        .windowStyle(.titleBar)
        Settings {
            PreferencesView(authItem: auth)
        }
    }
}
