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
    var channel: SwiftChannel
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var url: String = ""
    
    init(channel: SwiftChannel) {
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "circle.fill").resizable().frame(width: 75, height: 75) }
        self.channel = channel
        if !self.fetched {
            get_url()
        }
    }
    
    func get_url() {
        DispatchQueue.global(qos: .background).async { [self] in
            get_profile_url(&client.client, channel.channel)
            get_channel_stream(&client.client, channel.channel)
            DispatchQueue.main.async { [self] in
                url = String(cString: &channel.channel.pointee.profile_image_url.0)
                image = KFImage(URL(string: url))
                fetched = true
            }
        }
    }
}

struct FollowBarItem: View {
    @ObservedObject var img: ProfileImage
    var channel: SwiftChannel
    var url = String("")
    @State private var isHover = false
    @State var loaded = false

    init(channel: SwiftChannel) {
        self.channel = channel
        self.img = ProfileImage(channel: channel)
    }

    var body: some View {
        var channel = channel.channel.pointee
        HStack {
            img.image
                .resizable()
                .scaledToFit()
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 0))
            VStack(alignment: .leading) {
                Text(String(cString: &channel.user_name.0))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(String( cString: &channel.game_name.0))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(alignment: .leading)
            }
            HStack {
                Image(systemName: "circle.fill").foregroundColor(.red)
                    .padding(-5)
                Text(String(cString: &channel.viewer_count.0))
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 5))
            }.frame(alignment: .leading)
        }
        .help(Text("\(String(cString: &channel.title.0))\n\(String(cString: &channel.user_name.0))\n\(String(cString: &channel.game_name.0))"))
        .frame(minHeight: 45)
        .background(isHover ? .gray.opacity(0.1) : .clear).clipShape(RoundedRectangle(cornerRadius: 10))
        .onHover(perform: { hover in
            isHover = hover
        })
    }
}
