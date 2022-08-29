//
//  VideoPlayerView.swift
//  native_twitch
//
//  Created by Adam Solloway on 3/17/22.
//

import SwiftUI
import AVKit

class VideoViewModel : ObservableObject {
    @Published var vid_playing = false
    var vid = Video()
    @Published var urlString : String? {
        didSet {
            guard let urlString = urlString, let url = URL(string: urlString) else {
                return
            }
            player = AVPlayer(url: url)
            player.seek(to: .zero)
            player.preventsDisplaySleepDuringVideoPlayback = true
            player.play()
        }
    }
    var player = AVPlayer()
}

struct VideoPlaceholder: View {
    var body: some View {
        Text("Select a stream from the sidebar")
            .font(.largeTitle)
    }
}

struct PlayerView: View {
    var videoURL : String
    @State private var player : AVPlayer?
    
    var body: some View {
        VideoPlayer(player: player)
            .onAppear() {
                self.player = nil
                // Start the player going, otherwise controls don't appear
                guard let url = URL(string: videoURL) else {
                    return
                }
                let player = AVPlayer(url: url)
                self.player = player
                player.play()
            }
            .onDisappear() {
                // Stop the player when the view disappears
                player?.pause()
            }
            .frame(minWidth: 1000)
    }
}
