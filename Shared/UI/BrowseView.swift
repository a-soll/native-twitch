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
        self.url = URL(string: String(cString: &game.pointee.box_art_url.0)) ?? URL(string: "")!
        self.title = String(cString: &game.pointee.name.0)
    }
    
    var body: some View {
        VStack {
            GameImage(url: url).image.cornerRadius(12)
            Text(title)
        }
        .padding(EdgeInsets(top: 0, leading: 1, bottom: 0, trailing: 1))
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
    var gridItemLayout: [GridItem] = Array(repeating: .init(.adaptive(minimum: 200)), count: 2)
    
    init(gameSelected: Binding<Bool>) {
        self._gameSelected = gameSelected
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 30) {
                ForEach(0..<browse.items, id: \.self) { i in
                    var game = browse.gameList![i]
                    BrowseItem(game: &game)
                        .onAppear(perform: {
                            if i == browse.items - 1 {
                                browse.fetch()
                            }
                        })
                        .onTapGesture {
                            self.browse.index = i
                            gameSelected = true
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
    var viewerCount: String
    var userLogin: String
    var stream: UnsafeMutablePointer<Channel>
    var client = SwiftClient()
    var thumbnail: ThumbailImage
    @State var animate = false
    
    init(stream: UnsafeMutablePointer<Channel>) {
        self.stream = stream
        self.userName = String(cString: &stream.pointee.user_name.0, encoding: String.Encoding.utf8) ?? "\(String(cString: &stream.pointee.user_name.0, encoding: String.Encoding.unicode)!)"
        self.url = String(cString: &stream.pointee.thumbnail_url.0)
        self.title = String(cString: &stream.pointee.title.0)
        self.viewerCount = String(cString: &stream.pointee.viewer_count.0)
        self.thumbnail = ThumbailImage(url: URL(string: self.url)!)
        self.userLogin = String(cString: &stream.pointee.user_login.0)
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
            selectedStream.set_selection(channel: self.stream)
            video.vid = init_video_player()
            get_video_token(&client.client, &video.vid, selectedStream.channel)
            get_stream_url(&client.client, selectedStream.channel, &video.vid, false)
            video.urlString = String(cString:&video.vid.resolution_list.0.link.0)
            chat.set_channel(channel: selectedStream.channel!)
            video.vid_playing = true
        }
    }
}

struct GameStreamView: View {
    var game: UnsafeMutablePointer<Game>?
    var gameStreams: GameStreams
    var gridItemLayout: [GridItem] = Array(repeating: .init(.adaptive(minimum: 300)), count: 3)
    
    init(game: UnsafeMutablePointer<Game>) {
        self.game = game
        self.gameStreams = GameStreams(game: self.game!)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 30) {
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
    }
}

struct BrowseView: View {
    @Binding var gameSelected: Bool
    @StateObject var browse = Browse()
    
    var body: some View {
        if gameSelected {
            GameStreamView(game: &browse.gameList![browse.index])
        } else {
            CategoryView(gameSelected: $gameSelected).environmentObject(self.browse)
        }
    }
}
