//
//  FollowBarView.swift
//  native_twitch
//
//  Created by Adam Solloway on 3/13/22.
//

import Kingfisher
import SwiftUI
import AVFoundation

struct FollowBarView: View {
    @ObservedObject var store: FollowedChannels
    @Binding var url: String?
    @Binding var vid_playing: Bool
    @Binding var chan_indx: Int
    @State var isHover = false
    var client = SwiftClient()
    @State var c = 0
    
    var body: some View {
        HStack(alignment: .center) {
            Text("Following")
                .font(.headline)
                .offset(x: 90)
            Spacer()
            Button(action: store.populate, label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 25, height: 25)
            })
            .buttonStyle(BorderlessButtonStyle())
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
        }.frame(alignment: .leading)
        List(store.channels) { channel in
            FollowBarItem(channel: channel)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .onTapGesture {
                    chan_indx = store.getChannel(id: channel.id)!
                    get_video_token(&client.client, &store.channels[chan_indx].vid.video, &store.channels[chan_indx].chan.pointee)
                    get_stream_url(&client.client, &store.channels[chan_indx].chan.pointee, &store.channels[chan_indx].vid.video, false)
                    url = String(cString: &channel.vid.video.resolution_list[0].link.0)
                    vid_playing = true
                }
        }
        .environment(\.defaultMinListRowHeight, 15)
    }
}
