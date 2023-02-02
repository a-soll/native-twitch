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
    var streams = UnsafeMutablePointer<TwitchStream>?.init(nilLiteral: ())
    @Published var items = 0
    var game: UnsafeMutablePointer<Game>?
    var client = SwiftClient()
    var iterator = paginator_init()

    init(game: UnsafeMutablePointer<Game>) {
        self.game = game
        self.fetch()
    }

    deinit {
        streams?.deallocate()
    }

    func fetch() {
        let new = Int(get_game_streams(&client.client, &streams, game, &iterator, Int32(items)))
        self.items += Int(new)
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
    @Published var gameList = GameList()
    var client = SwiftClient()
    var index = 0
    init() {
        GameList_init(&gameList, nil)
        self.fetch()
    }
    func fetch() {
        get_top_games(&client.client, &gameList)
    }

    deinit {
        GameList_deinit(&gameList)
    }
}
