//
//  GameView.swift
//  native_twitch
//
//  Created by Adam Solloway on 7/18/22.
//

import SwiftUI
import Kingfisher

class SwiftStreamIterator {
    var iterator = init_paginator()
}

class GameCategory: ObservableObject {
    @Published var streams: UnsafeMutablePointer<Channel>?
    var iterator = SwiftStreamIterator()
    var items: Int32 = 0
    var client = SwiftClient()
    var game: UnsafeMutablePointer<Game>
    
    init(game: UnsafeMutablePointer<Game>) {
        self.game = game
        fetch()
    }
    
    func fetch() {
        self.items = get_game_streams(&client.client, game, &streams, &iterator.iterator, items)
    }
}

class ThumbailImage: ObservableObject {
    var id = UUID()
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var size = CGSize(width: 344.0, height: 194.0)
    var url: String = ""
    
    init(url: URL) {
        image = KFImage(url).placeholder { Image(systemName: "square.fill").resizable().frame(width: 344, height: 194) }
    }
}

struct GameItem: View {
    @EnvironmentObject var viewModel: VideoViewModel
    var client = SwiftClient()
    var vid = SwiftVideo()
    var title: String
    var url: URL
    var Thumbnail: ThumbailImage
    var userName: String
    var vidUrl = ""
    var userLogin: String
    var channel: UnsafeMutablePointer<Channel>?
    @State var animate = false
    
    init(title: String, url: String, userName: String, userLogin: String, channel: UnsafeMutablePointer<Channel>) {
        self.title = title
        self.url = URL(string: url)!
        self.userName = userName
        self.userLogin = userLogin
        self.channel = channel
        Thumbnail = ThumbailImage(url: self.url)
    }
    
    var body: some View {
        VStack {
            Thumbnail.image
                .cornerRadius(12)
            VStack(alignment: .leading) {
                Text(self.title)
                    .frame(maxWidth: Thumbnail.size.width, alignment: .leading)
                    .font(.body.bold())
                Text(self.userName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(alignment: .leading)
            }
        }
        .scaleEffect(x: animate ? 1.1 : 1, y: animate ? 1.1 : 1)
        .animation(.easeIn(duration: 0.1), value: animate)
        .onHover(perform: { hover in
            animate = hover
        })
        .onTapGesture {
            var channel = Channel()
            pop_name(&channel, toCCString(str: self.userName as NSString))
            pop_login(&channel, toCCString(str: self.userLogin as NSString))
            get_video_token(&client.client, &vid.video, &channel)
            get_stream_url(&client.client, &channel, &vid.video, false)
            
            viewModel.urlString = String(cString:&vid.video.resolution_list[0].link.0)
            viewModel.vid_playing = true
        }
    }
}

struct GameView: View {
    @ObservedObject var category: GameCategory
    var game: Game
    
    var gridItemLayout = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    init(game: Game) {
        self.game = game
        category = GameCategory(game: &self.game)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 30) {
                ForEach(0..<Int(category.items), id: \.self) { i in
                    var stream = self.category.streams![i]
                    GameItem(
                        title: String(cString: &stream.title.0),
                        url: String(cString: &stream.thumbnail_url.0),
                        userName: String(cString: &stream.user_name.0),
                        userLogin: String(cString: &stream.user_login.0),
                        channel: &stream
                    )
                }
            }
        }.padding(EdgeInsets(top: 25, leading: 0, bottom: 0, trailing: 0))
    }
}
