//
//  BrowseView.swift
//  apple-twitch
//
//  Created by Adam Solloway on 8/28/22.
//

import SwiftUI

struct BrowseItem: View {
    var url: URL
    var title: String
    @State var animate = false

    init(game: UnsafeMutablePointer<Game>) {
        self.url = URL(string: CString(str: &game.pointee.box_art_url.0)) ?? URL(string: "https://static-cdn.jtvnw.net/ttv-static/404_boxart.jpg")!
        self.title = CString(str: &game.pointee.name.0)
    }

    var body: some View {
        VStack {
            GameImage(url: url).image.cornerRadius(12)
            Text(title)
        }
        .padding(EdgeInsets(top: 17, leading: 0, bottom: 0, trailing: 0))
        .scaleEffect(x: animate ? 1.1 : 1, y: animate ? 1.1 : 1)
        .animation(.easeIn(duration: 0.1), value: animate)
        .onHover(perform: { hover in
            animate = hover
        })
    }
}

struct CategoryView: View {
    @Binding var gameSelected: Bool
    @EnvironmentObject var gameSelection: GameSelection
    @EnvironmentObject var browse: Browse
    var gridItemLayout = [GridItem(.adaptive(minimum: 250))]

    init(gameSelected: Binding<Bool>) {
        self._gameSelected = gameSelected
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 10) {
                ForEach(0..<Int(browse.gameList.len), id: \.self) { i in
                    var game = browse.gameList.games![i]
                    BrowseItem(game: &game)
                        .onAppear(perform: {
                            if i == browse.gameList.len - 1 {
                                browse.fetch()
                            }
                        })
                        .onTapGesture {
                            self.browse.index = i
                            gameSelected = true
                            gameSelection.set_selection(game: game, i: browse.index)
                        }
                }
            }
        }
    }
}

struct GameStreamItem: View {
    @EnvironmentObject var video: VideoViewModel
    @EnvironmentObject var chat: Chat
    @EnvironmentObject var selectedStream: StreamSelection
    var userName: String
    var title: String
    var url: String
    var viewerCount: Int
    var userLogin: String
    var stream: TwitchStream
    var client = SwiftClient()
    var thumbnail: ThumbailImage
    @State var animate = false

    init(stream: inout TwitchStream) {
        self.stream = stream
        self.userName = CString(str: &stream.user_name.0)
        self.url = CString(str: &stream.thumbnail_url.0)
        self.title = CString(str: &stream.title.0)
        self.viewerCount = Int(stream.viewer_count)
        self.thumbnail = ThumbailImage(url: URL(string: self.url)!)
        self.userLogin = CString(str: &stream.user_login.0)
    }

    var body: some View {
        VStack {
            ZStack {
                thumbnail.image.cornerRadius(12)
                Text("\(viewerCount) viewers")
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: 2, leading: 5, bottom: 2, trailing: 5))
                    .background(.black.opacity(0.9))
                    .alignmentGuide(HorizontalAlignment.center, computeValue: { dimension in 160
                    })
                    .alignmentGuide(VerticalAlignment.center, computeValue: { dimension in -65
                    })
            }
            VStack(alignment: .leading) {
                Text(title)
                    .frame(maxWidth: thumbnail.size.width, alignment: .leading)
                    .font(.body.bold())
                Text(userName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(alignment: .leading)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
        .scaleEffect(x: animate ? 1.1 : 1, y: animate ? 1.1 : 1)
        .animation(.easeIn(duration: 0.1), value: animate)
        .onHover(perform: { hover in
            animate = hover
        })
        .onTapGesture {
            selectedStream.set_selection(stream: self.stream)
            init_video_player(&video.vid)
            get_stream_url(&client.client, &selectedStream.stream, &video.vid, false, self.client.useAdblock)
            video.url = URL(string: CString(str: &video.vid.resolution_list.0.link.0))!
            chat.set_channel(channel: &selectedStream.stream)
            video.vid_playing = true
        }
    }
}

struct GameStreamView: View {
    @EnvironmentObject var gameSelection: GameSelection
    var game: UnsafeMutablePointer<Game>?
    @ObservedObject var gameStreams = GameStreams()
    var gridItemLayout = [GridItem(.adaptive(minimum: 380))]
    @State var first_fetch = true
    @State var foundStreams = true

    init(game: UnsafeMutablePointer<Game>) {
    }

    func getStreams() {
        self.gameStreams.iterator = paginator_init()
        self.gameStreams.setGame(game: gameSelection.game)
        if gameStreams.items == 0 {
            foundStreams = false
        } else {
            foundStreams = true
        }
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 10) {
                ForEach(0..<gameStreams.items, id: \.self) { i in
                    GameStreamItem(stream: &gameStreams.streams![i])
                        .onAppear(perform: {
                            if i == gameStreams.items - 1 {
                                gameStreams.fetch()
                            }
                        })
                }
            }
        }
        .onAppear(perform: {
            if first_fetch {
                getStreams()
                first_fetch = false
            }
        })
        .onReceive(gameSelection.$game) { flag in
            if first_fetch {
                self.gameStreams.items = 0
                getStreams()
            }
        }
    }
}

struct BrowseView: View {
    @Binding var gameSelected: Bool
    @StateObject var browse = Browse()
    @EnvironmentObject var selectedGame: GameSelection

    var body: some View {
        if gameSelected {
            GameStreamView(game: &browse.gameList.games![browse.index])
                .environmentObject(self.selectedGame)
        } else {
            CategoryView(gameSelected: $gameSelected)
                .environmentObject(self.browse)
                .environmentObject(self.selectedGame)
        }
    }
}
