//
//  LandingPage.swift
//  native_twitch
//
//  Created by Adam Solloway on 7/17/22.
//

import Foundation
import CoreMIDI

class LandingGame {
    var name: String
    var id: String
    var box_art_url: String
    var game: UnsafeMutablePointer<Game>

    init(name: String, id: String, box_art_url: String, game: UnsafeMutablePointer<Game>) {
        self.name = name
        self.id = id
        self.box_art_url = box_art_url
        self.game = game
    }
}

class SwiftGameIterator {
    var iterator = init_paginator()
}

class LandingPage: ObservableObject {
    var gameList: UnsafeMutablePointer<Game>?
    @Published var games: [LandingGame] = []
    var iterator = SwiftGameIterator()
    var items: Int32 = 0
    var client = SwiftClient()

    func fetch() {
        let new = get_top_games(&client.client, &gameList, &iterator.iterator, Int32(items))
        var j = items
        for _ in 0..<new {
            let n = String(cString: &gameList![Int(j)].name.0)
            let id = String(cString: &gameList![Int(j)].id.0)
            let url = String(cString: &gameList![Int(j)].box_art_url.0)
            let sg = LandingGame(name: n, id: id, box_art_url: url, game: &gameList![Int(j)])
            j += 1
            self.games.append(sg)
        }
        self.items += new
    }
}
