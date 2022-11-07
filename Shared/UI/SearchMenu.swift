//
//  SearchMenu.swift
//  native_twitch
//
//  Created by Adam Solloway on 10/1/22.
//

import SwiftUI
import Kingfisher

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
                url = String(cString: &user.profile_image_url.0)
                image = KFImage(URL(string: url))
                fetched = true
            }
        }
    }
}

struct SearchItem: View {
    let login: String
    var is_live: Bool
    @ObservedObject var image: SearchedProfileImage
    
    init(channel: UnsafeMutablePointer<SearchedChannel>) {
        self.login = String(cString: &channel.pointee.broadcaster_login.0)
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
            Text(login)
            if self.is_live {
                Image(systemName: "circle.fill").foregroundColor(.red)
            }
        }
    }
}

class Search: ObservableObject {
    var chanResults = UnsafeMutablePointer<SearchedChannel>?.init(nilLiteral: ())
    @Published var count: Int32 = 0
    var paginator = Paginator()
    var client = SwiftClient()
    
    deinit {
        self.chanResults?.deallocate()
    }
    
    func runSearch(keyword: String) {
        count += search_channels(&client.client, keyword, &chanResults, &paginator, count, true)
    }
    
    func clearSearch() {
        self.chanResults?.deallocate()
        self.chanResults = UnsafeMutablePointer<SearchedChannel>?.init(nilLiteral: ())
        self.paginator.pagination.0 = 0
        self.count = 0
    }
}

struct SearchMenu: View {
    @State var showPopup = false
    @State private var searchText = ""
    @ObservedObject var search = Search()
    
    var body: some View {
        Text("")
            .searchable(text: $searchText, prompt: "Search for channel, user, game, etc")
            .onSubmit(of: .search, runSearch)
            .popover(isPresented: $showPopup,
                     attachmentAnchor: .point(.bottom),
                     arrowEdge: .bottom) {
                PopView(search: self.search, showPopup: $showPopup, searchText: $searchText)
            }
    }
    
    func runSearch() {
        showPopup = true
        search.clearSearch()
        self.search.runSearch(keyword: searchText)
    }
}

struct PopView: View {
    var search: Search
    @EnvironmentObject var selectedStream: StreamSelection
    @EnvironmentObject var vidModel: VideoViewModel
    @EnvironmentObject var chat: Chat
    var client = SwiftClient()
    @Binding var showPopup: Bool
    @Binding var searchText: String
    
    init(search: Search, showPopup: Binding<Bool>, searchText: Binding<String>) {
        self.search = search
        self._showPopup = showPopup
        self._searchText = searchText
    }
    
    var body: some View {
        List(0..<Int(search.count), id: \.self) {i in
            SearchItem(channel: &search.chanResults![i])
                .onTapGesture {
                    var stream = TwitchStream()
                    get_stream_by_user_login(&client.client, &stream, &search.chanResults![i].broadcaster_login)
                    selectedStream.set_selection(stream: stream)
                    vidModel.vid = init_video_player()
                    get_video_token(&client.client, &vidModel.vid, &selectedStream.stream)
                    get_stream_url(&client.client, &selectedStream.stream, &vidModel.vid, false)
                    vidModel.url = URL(string: String(cString: &vidModel.vid.resolution_list.0.link.0))!
                    chat.set_channel(channel: &stream)
                    vidModel.vid_playing = true
                    showPopup = false
                    DispatchQueue.main.async {
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                    searchText = ""
                }
        }
        .environmentObject(chat)
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
