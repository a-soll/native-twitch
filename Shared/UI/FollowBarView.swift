//
//  FollowBarView.swift
//  apple-twitch
//
//  Created by Adam Solloway on 8/28/22.
//

import SwiftUI
import Kingfisher
import OSLog

class ProfileImage: ObservableObject {
    var id = UUID()
    var client = SwiftClient()
    var stream: TwitchStream
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var url: String = ""
    
    init(stream: TwitchStream) {
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "circle.fill")
                .resizable()
                .frame(width: 75, height: 75)
                .foregroundColor(.gray)
        }
        self.stream = stream
        get_url()
    }
    
    func get_url() {
        DispatchQueue.global(qos: .background).async { [self] in
            var user = User()
            get_user_by_login(&client.client, &user, &stream.user_login.0)
            DispatchQueue.main.async { [self] in
                url = CString(str: &user.profile_image_url.0)
                image = KFImage(URL(string: url))
                fetched = true
            }
        }
    }
}

struct FollowBarItem: View {
    @EnvironmentObject var followed: FollowedChannels
    @EnvironmentObject var selectedStream: StreamSelection
    @State private var isHover = false
    @ObservedObject var img: ProfileImage
    var stream: StreamItem
    var index: Int
    var userName: String
    var gameName: String
    
    init(index: Int, stream: inout TwitchStream) {
        self.index = index
        self.stream = StreamItem(stream: stream)
        self.img = ProfileImage(stream: stream)
        self.userName = CString(str: &stream.user_name.0)
        self.gameName = CString(str: &stream.game_name.0)
    }
    
    var body: some View {
        HStack {
            img.image
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
            VStack(alignment: .leading) {
                Text(userName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(gameName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(alignment: .leading)
            }
            HStack {
                Image(systemName: "circle.fill").foregroundColor(.red)
                    .padding(-5)
                self.abbreviate(index: index)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
            }.frame(alignment: .leading)
        }
        .help (
            Text(CString(str: &stream.stream.title.0))
        )
        .frame(minHeight: 45)
        .background(isHover ? .gray.opacity(0.1) : .clear).clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover(perform: { hover in
            isHover = hover
        })
    }
    
    func abbreviate(index: Int) -> Text {
        var count: Array<CChar> = Array(repeating: 32, count: 15)
        var s = String("\(self.followed.followed![index].viewer_count)")
        abbreviate_number(&s, &count)
        return Text(CString(str: &count))
    }
}

struct FollowBarView: View {
    var client = SwiftClient()
    @StateObject var followed = FollowedChannels()
    @EnvironmentObject var selectedStream: StreamSelection
    @EnvironmentObject var vidModel: VideoViewModel
    @EnvironmentObject var chat: Chat
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Text("Following")
                    .font(.headline)
                    .frame(alignment: .center)
                Button(action: followed.get_followed, label: {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 25, height: 25)
                })
                .buttonStyle(BorderlessButtonStyle())
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }
            List(0..<Int(followed.count), id: \.self) { i in
                FollowBarItem(index: i, stream: &followed.followed![i])
                    .onTapGesture {
                        vidModel.vid_playing = false
                        selectedStream.set_selection(stream: followed.followed![i])
                        init_video_player(&vidModel.vid)
                        get_stream_url(&client.client, &selectedStream.stream, &vidModel.vid, false, self.client.useAdblock)
                        vidModel.url = URL(string: CString(str: &vidModel.vid.resolution_list.0.link.0))
                        chat.set_channel(channel: &selectedStream.stream)
                        vidModel.vid_playing = true
                    }
            }
            .environmentObject(self.followed)
        }
    }
}
