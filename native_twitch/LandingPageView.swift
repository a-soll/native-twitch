//
//  LandingPageView.swift
//  native_twitch
//
//  Created by Adam Solloway on 7/16/22.
//

import SwiftUI
import Kingfisher

class GameImage: ObservableObject {
    var id = UUID()
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var url: String = ""
    
    init(url: URL) {
        image = KFImage(url).placeholder { Image(systemName: "square.fill").resizable().frame(width: 188, height: 251) }
    }
}

struct LandingPageView: View {
    @State var animate = false
    @Binding var gameSelection: Bool
    @Binding var vid_playing: Bool
    //    @State var selectedGame: UnsafeMutablePointer<Game>?
    @State var selectedGame: Game?
    
    var body: some View {
        VStack {
            if !gameSelection {
                CategoryView(gameSelection: $gameSelection, selectedGame: $selectedGame)
            } else {
                GameView(game: selectedGame!)
            }
        }.frame(alignment:.leading)
    }
    
    func toggleSelection() {
        if gameSelection == true {
            gameSelection = false
        } else {
            gameSelection = true
        }
    }
}
