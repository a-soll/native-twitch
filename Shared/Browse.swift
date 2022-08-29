//
//  Browse.swift
//  apple-twitch
//
//  Created by Adam Solloway on 8/28/22.
//

import Foundation
import Kingfisher
import SwiftUI

class ThumbailImage: ObservableObject {
    var id = UUID()
    @Published var image: KFImage
    @Published var view_count = "0"
    @State var fetched = false
    var size = CGSize(width: 344.0, height: 194.0)
    var url: String = ""
    
    init(url: URL) {
        image = KFImage(url).placeholder { Image(systemName: "square.fill").resizable().frame(width: 344, height: 194).foregroundColor(.gray) }
    }
}

class GameStreams: ObservableObject {
    var streams = UnsafeMutablePointer<Channel>?.init(nilLiteral: ())
    @Published var items = 0
    var game: UnsafeMutablePointer<Game>?
    var client = SwiftClient()
    var iterator = init_paginator()
    
    init(game: UnsafeMutablePointer<Game>) {
        self.game = game
        self.fetch()
    }
    
    func fetch() {
        items += Int(get_game_streams(&client.client, game, &streams, &iterator, Int32(items)))
    }

    deinit {
        if streams?.pointee != nil {
            streams?.deallocate()
        }
    }
}

class GameImage: ObservableObject {
    var id = UUID()
    @Published var image: KFImage
    @Published var view_count = "0"
    var url: String = ""
    
    init(url: URL) {
        image = KFImage(url).placeholder { Image(systemName: "square.fill").resizable().frame(width: 188, height: 251) }
    }
}

class Browse: ObservableObject {
    var gameList = UnsafeMutablePointer<Game>?.init(nilLiteral: ())
    var iterator = init_paginator()
    @Published var items = 0
    var client = SwiftClient()
    var index = 0
    init() {
        self.fetch()
    }
    func fetch() {
        let new = get_top_games(&client.client, &gameList, &iterator, Int32(items))
        self.items += Int(new)
    }
    
    deinit {
        if gameList?.pointee != nil {
            self.gameList?.deallocate()
        }
    }
}
