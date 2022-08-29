//
//  PreferencesView.swift
//  native_twitch
//
//  Created by Adam Solloway on 7/19/22.
//

import SwiftUI
import Foundation

class AuthItem: ObservableObject {
    @Published var isAuthed = false
    var userLogin = ""
    var userId = ""
    
    func checkAuth() {
        let client = SwiftClient()
        self.isAuthed = validate_token(&client.client)
        if self.isAuthed {
            userLogin = fromCString(str: client.client.user_login) as String
            userId = fromCString(str: client.client.user_login) as String
        }
    }
}

struct FirstBoot: View {
    var isSettings: Bool
    var authItem: AuthItem
    
    init(authItem: AuthItem, isSettings: Bool) {
        self.isSettings = isSettings
        self.authItem = authItem
    }
    
    var body: some View {
        AuthView(authItem: self.authItem)
            .frame(width: 350, height: 150)
    }
}

struct AuthView: View {
    @AppStorage("AccessToken", store: .standard) private var accessToken = ""
    @AppStorage("UserLogin", store: .standard) private var userLogin = ""
    @AppStorage("UserId", store: .standard) private var userId = ""
    @State private var tmp = ""
    @State var tryAgain = false
    var authItem: AuthItem
    
    init(authItem: AuthItem) {
        self.authItem = authItem
    }
    
    var body: some View {
        Form {
            Section {
                VStack {
                    TextField(
                        text: $tmp,
                        prompt: Text("Required")
                    ) {
                        Text("Access token:")
                    }
                    .onSubmit {
                        accessToken = tmp
                        authItem.checkAuth()
                        if authItem.isAuthed {
                            userId = authItem.userId
                            userLogin = authItem.userLogin
                        } else {
                            tryAgain = true
                        }
                    }
                    Text("[Get token](https://twitchtokengenerator.com/quick/ffvXXf6nVX)")
                        .offset(x: 25)
                    if self.tryAgain {
                        Text("Invalid token. Please retry.").foregroundColor(.red)
                    }
                }
                //                .frame(width: 200, alignment: .center)
            }
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("ffzSettings", store: .standard) private var ffz_Path: String = ""
    let authItem: AuthItem
    var body: some View {
        Form {
            Section {
                HStack(alignment: .center) {
                    Text("FFZ Settings")
                    Button("Select FFZ settings") {
                        let panel = NSOpenPanel()
                        panel.allowsMultipleSelection = false
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK {
                            self.ffz_Path = panel.url?.absoluteString ?? ""
                            do {
                                let str = try String(contentsOf: URL(string: ffz_Path)!, encoding: String.Encoding.utf8)
                                ffz_Path = str
                            } catch {
                                print("couldn't")
                            }
                        }
                    }
                }
                AuthView(authItem: self.authItem)
            }
        }
        //        .frame(minWidth: 350, minHeight: 100)
    }
}

struct PreferencesView: View {
    var authItem: AuthItem
    
    private enum Tabs: Hashable {
        case general, advanced
    }
    var body: some View {
        TabView {
            GeneralSettingsView(authItem: authItem)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tabs.general)
            //            AdvancedSettingsView()
            //                            .tabItem {
            //                                Label("Advanced", systemImage: "star")
            //                            }
            //                            .tag(Tabs.advanced)
        }
        //        .padding(20)
        .frame(width: 375, height: 150)
    }
}
