//
//  ContentView.swift
//  Shared
//
//  Created by Adam Solloway on 8/28/22.
//

import SwiftUI
import AVKit

struct ContentView: View {
    @StateObject var vidModel = VideoViewModel()
    @State var pop = true
    @State var gameSelected = false
    @StateObject var selectedGame = GameSelection()
    @State private var searchPos: CGPoint = .zero
    @State private var searchSize: CGSize = .zero
    @StateObject var chat = Chat()
    @StateObject var selectedStream = StreamSelection()
    var hideChat = HideChat()

    var body: some View {
        NavigationView {
            FollowBarView()
                .frame(minWidth: 250, maxWidth: 550)
            if vidModel.vid_playing {
                HStack(spacing:0) {
                    PlayerView(img: ProfImage(channel: selectedStream.stream), stream: StreamItem(stream: selectedStream.stream))
                    ChatView().frame(minWidth: 350, maxWidth: 350)
                }.environmentObject(self.hideChat)
            }
            else {
                BrowseView(gameSelected: $gameSelected)
                    .frame(minWidth: 770)
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
                .padding(EdgeInsets(top: 0, leading: -20, bottom: 0, trailing: -20))
                .frame(width: 50, height: 50)

                Button(action: toggleVidPlaying, label: {
                    Text("Browse")
                        .font(.title.bold())
                        .fixedSize()
                })
                .buttonStyle(PlainButtonStyle())
                .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
            }// ToolbarItemGroup end
            ToolbarItem(content: {
                SearchMenu(gameSelected: $gameSelected)
            })
        }
        .environmentObject(self.selectedStream)
        .environmentObject(self.vidModel)
        .environmentObject(self.chat)
        .environmentObject(self.selectedGame)
    }// end body

    private func toggleVidPlaying() {
        self.gameSelected = false
        self.vidModel.vid_playing = false
    }

    private func toggleSidebar() {
#if os(iOS)
#else
        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
#endif

    }

}//end struct

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
