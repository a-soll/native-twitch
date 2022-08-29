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
    var channel: UnsafeMutablePointer<Channel>
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var url: String = ""
    
    init(channel: UnsafeMutablePointer<Channel>?) {
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "circle.fill").resizable().frame(width: 75, height: 75) }
        self.channel = channel!
        if !self.fetched {
            get_url()
        }
    }
    
    func get_url() {
        DispatchQueue.global(qos: .background).async { [self] in
            get_profile_url(&client.client, channel)
            get_channel_stream(&client.client, channel)
            DispatchQueue.main.async { [self] in
                url = String(cString: &channel.pointee.profile_image_url.0)
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
    var index: Int
    
    init(index: Int, channel: UnsafeMutablePointer<Channel>) {
        self.index = index
        img = ProfileImage(channel: channel)
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
                Text(String(cString: &followed.followed![index].user_name.0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(String( cString: &followed.followed![index].game_name.0))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(alignment: .leading)
            }
            HStack {
                Image(systemName: "circle.fill").foregroundColor(.red)
                    .padding(-5)
                Text(String(cString: &followed.followed![index].viewer_count.0))
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
            }.frame(alignment: .leading)
        }
//        .help(Text("\(String(cString: &channel.title.0))\n\(String(cString: &channel.user_name.0))\n\(String(cString: &channel.game_name.0))"))
        .frame(minHeight: 45)
        .background(isHover ? .gray.opacity(0.1) : .clear).clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover(perform: { hover in
            isHover = hover
        })
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
            List(0..<followed.count, id: \.self) { i in
                FollowBarItem(index: i, channel: &followed.followed![i])
                    .onTapGesture {
                        selectedStream.set_selection(channel: &followed.followed![i])
                        vidModel.vid = init_video_player()
                        get_video_token(&client.client, &vidModel.vid, selectedStream.channel)
                        get_stream_url(&client.client, selectedStream.channel, &vidModel.vid, false)
                        vidModel.urlString = String(cString: &vidModel.vid.resolution_list.0.link.0)
                        chat.set_channel(channel: selectedStream.channel!)
                        vidModel.vid_playing = true
                    }
            }.environmentObject(self.followed)
        }
    }
}
