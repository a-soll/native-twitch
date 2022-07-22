//
//  ContentView.swift
//  native_twitch
//
//  Created by Adam Solloway on 3/7/22.
//

import SwiftUI
import AVKit

struct ContentView: View {
    private var store: FollowedChannels
    @StateObject var viewModel = VideoViewModel()
    @State var chan_ind = 0
    @State var gameSelection = false
    
    init() {
        self.store = FollowedChannels()
    }
    var body: some View {
        NavigationView {
            FollowBarView(store: store, video: viewModel, chan_indx: $chan_ind)
                .frame(minWidth: 250, maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 0, leading: -5, bottom: 0, trailing: 0))
            if viewModel.vid_playing {
                HStack(spacing:0) {
                    VideoPlayer(player: viewModel.player)
                    ChatView(channel: store.followed[chan_ind]).frame(minWidth: 350, maxWidth: 350)
                }
            }
            else {
                LandingPageView(gameSelection: $gameSelection, vid_playing: $viewModel.vid_playing)
                    .frame(minWidth: 1100, minHeight: 750)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                })
                .padding(EdgeInsets(top: 15, leading: -20, bottom: 0, trailing: -20))
                .frame(width: 50, height: 50)
                Button(action: toggleVidPlaying, label: {
                    Text("Browse")
                        .font(.title.bold())
                        .foregroundColor(.white)
                })
                .buttonStyle(PlainButtonStyle())
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }
        }
        .environmentObject(viewModel)
    }
    
    private func toggleVidPlaying() {
        viewModel.vid_playing = false
        gameSelection = false
        viewModel.player.pause()
    }
    
    private func toggleSidebar() {
#if os(iOS)
#else
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
#endif
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
