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
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "person.fill").resizable().frame(width: 100, height: 100) }
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
    @AppStorage("UserId", store: .standard) var userId = ""
    @AppStorage("OAuthToken", store: .standard) var oAuth = ""
    @AppStorage("UserLogin", store: .standard) var userLogin = ""
    @AppStorage("AccessToken", store: .standard) var token = ""
    var user = User()

    func checkAuth() {
        if (userId.isEmpty) {
            userId = "tmp"
        }
        if (userLogin.isEmpty) {
            userLogin = "tmp"
        }
        if (oAuth.isEmpty) {
            oAuth = " "
        }
        var client = SwiftClient()
        self.isAuthed = validate_token(&client.client)

        if self.isAuthed {
            self.userLogin = fromCString(str: &client.client.user_login.0) as String
            self.userId = fromCString(str: &client.client.user_id.0) as String
            get_user_by_id(&client.client, &self.user, userId)
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
    var userLogin = UserDefaults.standard.string(forKey: "UserLogin")
    var userId = UserDefaults.standard.string(forKey: "UserId")
    @AppStorage("OAuthToken", store: .standard) private var oAuthToken = ""
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
                if !authItem.isAuthed {
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

struct PlayerOptions: View {
    @AppStorage("UseAdblock", store: .standard) private var useAdblock = false

    var body: some View {
        Form {
            HStack {
                Text("Use adblock (ttv.lol)")
                Spacer()
                Toggle("", isOn: $useAdblock)
                    .toggleStyle(.switch)
            }
        }
    }
}

struct AuthView: View {
    @AppStorage("AccessToken", store: .standard) private var accessToken = ""
    @AppStorage("UserLogin", store: .standard) private var userLogin = ""
    @AppStorage("UserId", store: .standard) private var userId = ""
    @AppStorage("OAuthToken", store: .standard) private var oAuthToken = ""
    var authItem: AuthItem
    var placeholder = "Paste OAuth token here"
    @FocusState private var hasFocus: Bool

    init(authItem: AuthItem) {
        self.authItem = authItem
    }

    var body: some View {
        Form {
            Section {
                if (!authItem.isAuthed) {
                    TokenInput(authItem: authItem)
                } else {
                    VStack {
                        HStack {
                            Text("Access token")
                            Spacer()
                            Text(accessToken).textSelection(.enabled)
                        }
                        Spacer()
                        HStack {
                            Text("OAuth token")
                            Spacer()
                            TextField("", text: $oAuthToken)
                                .modifier(PlaceholderStyle(showPlaceHolder: oAuthToken.isEmpty||oAuthToken.starts(with: " "), placeholder: "OAuth Token"))
                                .textFieldStyle(.plain)
                                .multilineTextAlignment(.trailing)
                                .onAppear(perform: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        hasFocus = false
                                    }
                                })
                                .focused($hasFocus)
                        }
                    }
                }
            }
        }
    }
}

struct GeneralSettingsView: View {
    @AppStorage("ffzSettings", store: .standard) private var ffz_Path: String = ""
    @ObservedObject var authItem: AuthItem

    var body: some View {
        ScrollView {
            Form {
                VStack {
                    Spacer().frame(height: 10)
                    ProfileView(img: UserImage(userLogin: CString(str: &authItem.user.login.0)), authItem: authItem, user: authItem.user)
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
                    Section {
                        GroupBox(label: Text("Player Settings").font(.headline)) {
                            PlayerOptions()
                        }.padding(EdgeInsets(top: 0, leading: 15, bottom: 0, trailing: 15))
                    }
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

public struct PlaceholderStyle: ViewModifier {
    var showPlaceHolder: Bool
    var placeholder: String

    public func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            if showPlaceHolder {
                Text(placeholder)
                    .padding(.horizontal, 5)
                    .foregroundColor(.gray)
            }
            content
                .foregroundColor(Color.white)
                .padding(5.0)
        }
    }
}
