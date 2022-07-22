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
    var video: VideoViewModel
    @Binding var chan_indx: Int
    @State var isHover = false
    var client = SwiftClient()

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
        List(0..<store.count, id: \.self) { i in
            FollowBarItem(channel: store.followed[i])
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .onTapGesture {
                    chan_indx = i
                    video.vid = init_video_player()
                    get_video_token(&client.client, &video.vid, store.followed[i].channel)
                    get_stream_url(&client.client, store.followed[i].channel, &video.vid, false)
                    video.urlString = String(cString: &video.vid.resolution_list.0.link.0)
                    video.vid_playing = true
                }
        }
        .environment(\.defaultMinListRowHeight, 15)
    }
}
