//
//  Followed.swift
//  apple-twitch
//
//  Created by Adam Solloway on 8/28/22.
//

import Foundation

func fromCString(str: UnsafePointer<CChar>) -> NSString {
    let s = NSString(utf8String: str)
    return s!
}

class GameSelection: ObservableObject {
    @Published var game: UnsafeMutablePointer<Game>?
    var i: Int?
    
    func set_selection(game: UnsafeMutablePointer<Game>, i: Int) {
        if self.game?.pointee == nil {
            self.game?.deallocate()
        }
        self.game = game
        self.i = i
    }
}

class StreamSelection: ObservableObject {
    @Published var channel: UnsafeMutablePointer<TwitchStream>?
    
    func set_selection(channel: UnsafeMutablePointer<TwitchStream>) {
        if self.channel?.pointee == nil {
            self.channel?.deallocate()
        }
        self.channel = channel
    }
}

class Chat: ObservableObject {
    @Published var channel: UnsafeMutablePointer<TwitchStream>?
    
    func set_channel(channel: UnsafeMutablePointer<TwitchStream>) {
        if self.channel?.pointee == nil {
            self.channel?.deallocate()
        }
        self.channel = channel
    }
}

class FollowedChannels: ObservableObject {
    var client = SwiftClient()
    var followed = UnsafeMutablePointer<TwitchStream>?.init(nilLiteral: ())
    @Published var count = 0
    
    init() {
        get_followed()
    }

    func get_followed() {
        followed?.deallocate()
        count = Int(get_followed_streams(&client.client, &followed, Int32(count)))
    }
}
