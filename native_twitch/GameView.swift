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

class Streams {
    var viewerCount: String
    var userLogin: String
    var userName: String
    var channel: UnsafeMutablePointer<Channel>
    var title: String
    var thumbnailUrl: String
    
    init(viewerCount: String, userLogin: String, userName: String, channel: UnsafeMutablePointer<Channel>, title: String, thumbnailUrl: String) {
        self.viewerCount = viewerCount
        self.userLogin = userLogin
        self.userName = userName
        self.channel = channel
        self.title = title
        self.thumbnailUrl = thumbnailUrl
    }
}

class GameCategory: ObservableObject {
    @Published var streams: [Streams] = []
    var stream_list: UnsafeMutablePointer<Channel>?
    var iterator = SwiftStreamIterator()
    var items: Int32 = 0
    var client = SwiftClient()
    var game: UnsafeMutablePointer<Game>?
    
    init(game: UnsafeMutablePointer<Game>?) {
        self.game = game
        fetch()
    }
    
    func fetch() {
        let new = get_game_streams(&client.client, game, &stream_list, &iterator.iterator, items)
        var j = items
        for _ in 0..<new {
            let login = String(cString: &stream_list![Int(j)].user_login.0)
            let name = String(cString: &stream_list![Int(j)].user_name.0)
            let viewer_count = String(cString: &stream_list![Int(j)].viewer_count.0)
            let url = String(cString: &stream_list![Int(j)].thumbnail_url.0)
            let title = String(cString: &stream_list![Int(j)].title.0)
            let s = Streams(viewerCount: viewer_count, userLogin: login, userName: name, channel: &stream_list![Int(j)], title: title, thumbnailUrl: url)
            j += 1
            self.streams.append(s)
        }
        self.items += new
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
        image = KFImage(url).placeholder { Image(systemName: "square.fill").resizable().frame(width: 344, height: 194).foregroundColor(.gray) }
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
    var channel: SwiftChannel
    var viewerCount: String
    @State var animate = false
    
    init(title: String, url: String, userName: String, userLogin: String, channel: Channel, viewerCount: String) {
        var c = channel
        self.title = title
        self.url = URL(string: url)!
        self.userName = userName
        self.userLogin = userLogin
        self.channel = SwiftChannel(channel: &c)
        self.viewerCount = viewerCount
        Thumbnail = ThumbailImage(url: self.url)
    }
    
    var body: some View {
        VStack {
            ZStack {
                Thumbnail.image
                    .cornerRadius(12)
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
                Text(self.title)
                    .frame(maxWidth: Thumbnail.size.width, alignment: .leading)
                    .font(.body.bold())
                Text(self.userName)
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
            var channel = Channel()
            pop_name(&channel, self.userName)
            pop_login(&channel, self.userLogin)
            get_video_token(&client.client, &vid.video, &channel)
            get_stream_url(&client.client, &channel, &vid.video, false)
            viewModel.urlString = String(cString:&vid.video.resolution_list.0.link.0)
            viewModel.vid_playing = true
        }
    }
}

struct GameView: View {
    @ObservedObject var category: GameCategory
    var game: SwiftGame
    
    var gridItemLayout: [GridItem] = Array(repeating: .init(.adaptive(minimum: 300)), count: 3)

    init(game: UnsafeMutablePointer<Game>?) {
        self.game = SwiftGame(game: game)
        category = GameCategory(game: game)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: gridItemLayout, spacing: 30) {
                ForEach(0..<Int(category.items), id: \.self) { i in
                    let stream = self.category.streams[i]
                    GameItem(
                        title: stream.title,
                        url: stream.thumbnailUrl,
                        userName: stream.userName,
                        userLogin: stream.userLogin,
                        channel: stream.channel.pointee,
                        viewerCount: stream.viewerCount
                    )
                    .onAppear(perform: {
                        if i == category.items - 1 {
                            category.fetch()
                        }
                    })
                }
            }
        }
    }
}
