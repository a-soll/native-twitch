//
//  LandingPage.swift
//  native_twitch
//
//  Created by Adam Solloway on 7/17/22.
//

import Foundation

class SwiftGameIterator {
    var iterator = init_paginator()
}

class LandingPage: ObservableObject {
    @Published var games: UnsafeMutablePointer<Game>?
    var iterator = SwiftGameIterator()
    var items: Int32 = 0
    var client = SwiftClient()
    
    init() {
        items = get_top_games(&client.client, &games, &iterator.iterator, Int32(items))
    }

    deinit {
        free(games)
    }
    
    func fetch() {
        items += get_top_games(&client.client, &games, &iterator.iterator, Int32(items))
    }
}
