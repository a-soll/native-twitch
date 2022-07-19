//
//  FollowBarItem.swift
//  native_twitch
//
//  Created by Adam Solloway on 7/4/22.
//

import SwiftUI
import Kingfisher

class ProfileImage: ObservableObject {
    var id = UUID()
    var client = SwiftClient()
    var channel: Channels
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var url: String = ""
    
    init(channel: Channels) {
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "circle.fill").resizable().frame(width: 75, height: 75) }
        self.channel = channel
        if !self.fetched {
            get_url()
        }
    }

    func get_url() {
        DispatchQueue.global(qos: .background).async { [self] in
            get_profile_url(&client.client, &channel.chan.pointee)
            get_channel_stream(&client.client, &channel.chan.pointee)
            DispatchQueue.main.async { [self] in
                url = String(cString: &channel.chan.pointee.profile_image_url.0)
                image = KFImage(URL(string: url))
                fetched = true
            }
        }
    }
}

struct FollowBarItem: View {
    @ObservedObject var img: ProfileImage
    var channel: Channels
    var url = String("")
    @State private var isHover = false
    @State var loaded = false
    
    init(channel: Channels) {
        self.channel = channel
        self.img = ProfileImage(channel: channel)
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
                Text(channel.user_name)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(channel.game_name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(alignment: .leading)
//                    .help(Text(channel.game_name))
            }
            HStack {
                Image(systemName: "circle.fill").foregroundColor(.red)
                    .padding(-5)
                Text(String(cString: &channel.chan.pointee.viewer_count.0))
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
            }.frame(alignment: .leading)
        }
        .help(Text("\(String(cString: &channel.chan.pointee.title.0))\n\(String(channel.user_name))\n\(String(channel.game_name))"))
        .frame(minHeight: 45)
        .background(isHover ? .gray.opacity(0.1) : .clear).clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover(perform: { hover in
            print(String(cString: &channel.chan.pointee.title.0))
            isHover = hover
        })
    }
}
