//
//  SearchMenu.swift
//  native_twitch
//
//  Created by Adam Solloway on 10/1/22.
//

import SwiftUI
import Kingfisher

var limitIncriment = 10

class SearchedGameImage: ObservableObject {
    var id = UUID()
    var client = SwiftClient()
    @Published var image: KFImage
    var url: String = ""

    init(url: String) {
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "circle.fill").resizable().frame(width: 30, height: 30) }
        self.url = url
        get_url()
    }

    func get_url() {
        DispatchQueue.global(qos: .background).async { [self] in
            DispatchQueue.main.async { [self] in
                image = KFImage(URL(string: url))
            }
        }
    }
}

class SearchedProfileImage: ObservableObject {
    var id = UUID()
    var client = SwiftClient()
    var channel: UnsafeMutablePointer<SearchedChannel>
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var url: String = ""

    init(channel: UnsafeMutablePointer<SearchedChannel>) {
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "circle.fill").resizable().frame(width: 30, height: 30) }
        self.channel = channel
        if !self.fetched {
            get_url()
        }
    }

    func get_url() {
        DispatchQueue.global(qos: .background).async { [self] in
            var user = User()
            get_user_by_login(&client.client, &user, &channel.pointee.broadcaster_login.0)
            DispatchQueue.main.async { [self] in
                url = CString(str: &user.profile_image_url.0)
                image = KFImage(URL(string: url))
                fetched = true
            }
        }
    }
}

struct SearchGame: View {
    @State var name: String
    @ObservedObject var image: SearchedGameImage
    @EnvironmentObject var gameSelection: GameSelection
    @EnvironmentObject var vidModel: VideoViewModel
    @State var isHover = false
    @Binding var showPopup: Bool
    @Binding var gameSelected: Bool

    init(game: UnsafeMutablePointer<Game>, showPopup: Binding<Bool>, gameSelected: Binding<Bool>) {
        self.name = CString(str: &game.pointee.name.0)
        self._showPopup = showPopup
        self._gameSelected = gameSelected
        image = SearchedGameImage(url: CString(str: &game.pointee.box_art_url.0))
    }

    var body: some View {
        HStack {
            image.image
                .resizable()
                .scaledToFit()
                .clipShape(Rectangle())
                .frame(height: 30)
                .padding(.leading, 10)
            Text(name)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHover ? .gray.opacity(0.1) : .clear)
                .frame(height: 35)
        )
        .onHover(perform: { hover in
            isHover = hover
        })
        .onTapGesture {
            showPopup = false
            let client = SwiftClient()
            var game = Game()
            self.gameSelected = true
            vidModel.vid_playing = false
            get_game_by_name(&client.client, name, &game)
            gameSelection.set_selection(game: game, i:0)
        }
    }
}

struct SearchGameList: View {
    @EnvironmentObject var gameSelection: GameSelection
    @Binding var query: String
    var client = SwiftClient()
    var gameList = GameList()
    @State var gameLimit = limitIncriment
    @Binding var showPopup: Bool
    @Binding var gameSelected: Bool

    init(query: Binding<String>, client: SwiftClient, showPopup: Binding<Bool>, gameSelected: Binding<Bool>) {
        self._query = query
        GameList_init(&self.gameList, _query.wrappedValue)
        self.client = client
        self._showPopup = showPopup
        self._gameSelected = gameSelected
        search_games(&self.client.client, &self.gameList)
        if gameLimit > gameList.len {
            gameLimit = Int(gameList.len)
        }
    }

    var body: some View {
        if gameList.len > 0 {
            ForEach(0..<Int(gameLimit), id: \.self) { i in
                var game = gameList.games[i]
                SearchGame(game: &game, showPopup: $showPopup, gameSelected: $gameSelected)
                if (i == self.gameLimit - 1) {
                    Text("Show more...")
                        .foregroundColor(.purple)
                        .onTapGesture {
                            showMore()
                        }
                }
            }
        }
        else {
            Text("No games found")
        }
    }

    func showMore() {
        if gameLimit + limitIncriment > gameList.len {
            self.gameLimit = Int(gameList.len)
        } else {
            gameLimit += limitIncriment
        }
    }
}

struct SearchItem: View {
    let login: String
    var is_live: Bool
    @State var isHover = false
    @ObservedObject var image: SearchedProfileImage

    init(channel: UnsafeMutablePointer<SearchedChannel>) {
        self.login = CString(str: &channel.pointee.broadcaster_login.0)
        image = SearchedProfileImage(channel: channel)
        self.is_live = channel.pointee.is_live
    }

    var body: some View {
        HStack {
            image.image
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 30, height: 30)
                .padding(.leading, 10)
            Text(login)
            Spacer()
            if self.is_live {
                Image(systemName: "circle.fill").foregroundColor(.red)
                    .padding(.trailing, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHover ? .gray.opacity(0.1) : .clear)
                .frame(height: 35)
        )
        .onHover(perform: { hover in
            isHover = hover
        })
    }
}

class Search: ObservableObject {
    var chanResults = UnsafeMutablePointer<SearchedChannel>?.init(nilLiteral: ())
    var gameResults = GameList()
    @Published var chanCount: Int32 = 0
    var paginator = Paginator()
    var client = SwiftClient()

    deinit {
        self.chanResults?.deallocate()
        GameList_deinit(&self.gameResults)
    }

    func runSearch(keyword: String) {
        GameList_init(&gameResults, keyword)
        chanCount += search_channels(&client.client, keyword, &chanResults, &paginator, chanCount, true)
        search_games(&self.client.client, &self.gameResults)
    }

    func clearSearch() {
        self.chanResults?.deallocate()
        self.chanResults = UnsafeMutablePointer<SearchedChannel>?.init(nilLiteral: ())
        self.paginator.pagination.0 = 0
        self.chanCount = 0
    }
}

struct SearchMenu: View {
    @State var showPopup = false
    @State private var searchText = ""
    @ObservedObject var search = Search()
    @Binding var gameSelected: Bool
    @State var isAnimating = true
    var placeholder = String("Search for channel, user, game, etc")

    var body: some View {
        Text("")
            .searchable(text: $searchText, prompt: "Search for channel, user, game, etc")
            .onSubmit(of: .search, runSearch)
            .popover(isPresented: $showPopup,
                     attachmentAnchor: .point(.bottom),
                     arrowEdge: .bottom) {
                PopView(search: self.search, showPopup: $showPopup, searchText: $searchText, gameSelected: $gameSelected)
                    .frame(minWidth: 360, minHeight: 400)
            }
    }

    func runSearch() {
        showPopup = true
        search.clearSearch()
        self.search.runSearch(keyword: searchText)
    }
}

struct ChannelList: View {
    @EnvironmentObject var vidModel: VideoViewModel
    @EnvironmentObject var selectedStream: StreamSelection
    @EnvironmentObject var chat: Chat
    @State var chanLimit: Int
    var client: SwiftClient
    var search: Search
    @Binding var showPopup: Bool
    @Binding var searchText: String

    init(client: SwiftClient, search: Search, showPopup: Binding<Bool>, searchText: Binding<String>) {
        self.client = client
        self.search = search
        self._showPopup = showPopup
        self._searchText = searchText
        if (limitIncriment > search.chanCount) {
            self.chanLimit = Int(search.chanCount)
        }
        else {
            self.chanLimit = limitIncriment
        }
    }

    var body: some View {
        if search.chanCount > 0 {
            ForEach(0..<Int(chanLimit), id: \.self) { i in
                SearchItem(channel: &search.chanResults![i])
                    .onTapGesture {
                        var stream = TwitchStream()
                        get_stream_by_user_login(&client.client, &stream, &search.chanResults![i].broadcaster_login)
                        selectedStream.set_selection(stream: stream)
                        init_video_player(&vidModel.vid)
                        get_stream_url(&client.client, &selectedStream.stream, &vidModel.vid, false, self.client.useAdblock)
                        vidModel.url = URL(string: CString(str: &vidModel.vid.resolution_list.0.link.0))!
                        chat.set_channel(channel: &stream)
                        vidModel.vid_playing = true
                        showPopup = false
                        DispatchQueue.main.async {
                            NSApp.keyWindow?.makeFirstResponder(nil)
                        }
                        searchText = ""
                    }
                if i == chanLimit - 1 {
                    Text("Show more...")
                        .foregroundColor(.purple)
                        .onTapGesture {
                            showMore()
                        }
                }
            }
            .frame(width: 325)
            .environmentObject(chat)
        }
        else {
            Text("No channels found")
        }
    }

    func showMore() {
        if chanLimit + limitIncriment > search.chanCount {
            self.chanLimit = Int(search.chanCount)
        } else {
            chanLimit += limitIncriment
        }
    }
}

struct PopView: View {
    var search: Search
    @EnvironmentObject var selectedStream: StreamSelection
    @EnvironmentObject var vidModel: VideoViewModel
    @EnvironmentObject var chat: Chat
    @EnvironmentObject var selectedGame: GameSelection
    var client = SwiftClient()
    @Binding var showPopup: Bool
    @Binding var searchText: String
    @State var isHover = false
    @Binding var gameSelected: Bool

    init(search: Search, showPopup: Binding<Bool>, searchText: Binding<String>, gameSelected: Binding<Bool>) {
        self.search = search
        self._showPopup = showPopup
        self._searchText = searchText
        self._gameSelected = gameSelected
    }

    var body: some View {
        List {
            Section(header: Text("Channels")) {
                ChannelList(client: self.client, search: self.search, showPopup: $showPopup, searchText: $searchText)
            }
            Section(header: Text("Games")) {
                SearchGameList(query: $searchText, client: self.client, showPopup: $showPopup, gameSelected: $gameSelected)
            }
        }
    }
}

public struct RemoveFocusOnTapModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
#if os (iOS)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to:nil, from:nil, for:nil)
            }
#elseif os(macOS)
            .onTapGesture {
                DispatchQueue.main.async {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                }
            }
#endif
    }
}

extension View {
    public func removeFocusOnTap() -> some View {
        modifier(RemoveFocusOnTapModifier())
    }
}
