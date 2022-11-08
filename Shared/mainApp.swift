//
//  apple_twitchApp.swift
//  Shared
//
//  Created by Adam Solloway on 8/28/22.
//

import SwiftUI

@main
struct apple_twitchApp: App {
    @AppStorage("AccessToken") var accessToken: String = ""
    @ObservedObject var auth = AuthItem()
    @StateObject var updaterViewModel = UpdaterViewModel()

    init() {
        auth.checkAuth()
    }
    
    var body: some Scene {
        WindowGroup {
            if auth.isAuthed {
                ContentView()
                    .navigationTitle(Text(""))
            } else {
                PreferencesView(authItem: auth)
            }
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updaterViewModel: updaterViewModel)
            }
        }
        .windowStyle(.titleBar)
        Settings {
            PreferencesView(authItem: auth)
        }
    }
}
