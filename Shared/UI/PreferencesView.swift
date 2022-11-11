//
//  PreferencesView.swift
//  native_twitch
//
//  Created by Adam Solloway on 7/19/22.
//

import SwiftUI
import Foundation
import Kingfisher

class UserImage: ObservableObject {
    var id = UUID()
    var client = SwiftClient()
    var user = User()
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var userLogin: String
    var url: String = ""
    
    init(userLogin: String) {
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "circle.fill").resizable().frame(width: 100, height: 100) }
        self.userLogin = userLogin
        get_url()
    }
    
    func get_url() {
        DispatchQueue.global(qos: .background).async { [self] in
            get_user_by_login(&client.client, &user, userLogin)
            DispatchQueue.main.async { [self] in
                url = CString(str: &user.profile_image_url.0)
                image = KFImage(URL(string: url))
                fetched = true
            }
        }
    }
}

class AuthItem: ObservableObject {
    @Published var isAuthed = false
    var userLogin = ""
    var userId = ""
    var user = User()
    
    func checkAuth() {
        let client = SwiftClient()
        self.isAuthed = validate_token(&client.client)
        if self.isAuthed {
            userLogin = client.userLogin!
            userId = client.userId!
            get_user_by_id(&client.client, &self.user, client.client.user_id)
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

struct ProfileView: View {
    @ObservedObject var img: UserImage
    @ObservedObject var authItem: AuthItem
    @State var user: User
    
    var body: some View {
        VStack {
            if (authItem.isAuthed) {
                img.image
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                Text(CString(str: &user.display_name.0)).font(.headline)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                Text("Not logged in")
            }
        }
    }
}

struct TokenInput: View {
    @ObservedObject var authItem: AuthItem
    @AppStorage("AccessToken", store: .standard) private var accessToken = ""
    @AppStorage("UserLogin", store: .standard) private var userLogin = ""
    @AppStorage("UserId", store: .standard) private var userId = ""
    @State var tryAgain = false
    @State private var tmp = ""
    
    var body: some View {
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
            if self.tryAgain {
                Text("Invalid token. Please retry.").foregroundColor(.red)
            }
        }
    }
}

struct AuthView: View {
    @AppStorage("AccessToken", store: .standard) private var accessToken = ""
    @AppStorage("UserLogin", store: .standard) private var userLogin = ""
    @AppStorage("UserId", store: .standard) private var userId = ""
    var authItem: AuthItem
    
    init(authItem: AuthItem) {
        self.authItem = authItem
    }
    
    var body: some View {
        Form {
            Section {
                if (!authItem.isAuthed) {
                    TokenInput(authItem: authItem)
                } else {
                    HStack {
                        Text("Access token")
                        Spacer()
                        Text(accessToken).textSelection(.enabled)
                    }
                }
            }
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("ffzSettings", store: .standard) private var ffz_Path: String = ""
    @AppStorage("UserLogin", store: .standard) private var userLogin = ""
    @ObservedObject var authItem: AuthItem
    
    var body: some View {
        ScrollView {
            Form {
                VStack {
                    Spacer().frame(height: 10)
                    ProfileView(img: UserImage(userLogin: authItem.userLogin), authItem: authItem, user: authItem.user)
                    Button("Logout", action: {
                        self.authItem.isAuthed = false
                    })
                    Section {
                        GroupBox(label: Text("Authorization").font(.headline)) {
                            HStack {
                                AuthView(authItem: self.authItem)
                            }
                        }
                    }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                    Section {
                        GroupBox(label: Text("FFZ Settings").font(.headline)) {
                            HStack {
                                Text("FFZ Settings Json")
                                Spacer()
                                Button("Select...") {
                                    let panel = NSOpenPanel()
                                    panel.allowsMultipleSelection = false
                                    panel.canChooseDirectories = false
                                    if panel.runModal() == .OK {
                                        self.ffz_Path = panel.url?.absoluteString ?? ""
                                        do {
                                            let str = try String(contentsOf: URL(string: ffz_Path)!, encoding: String.Encoding.utf8)
                                            ffz_Path = str
                                        } catch {
                                        }
                                    }
                                }
                            }
                        }
                    }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                }
            }
        }
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
        .frame(minWidth: 375, minHeight: 150)
    }
}
