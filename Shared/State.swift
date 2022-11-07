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

class VideoViewModel: ObservableObject {
    @Published var vid_playing = false
    @Published var url: URL?
    @Published var player: NSVideoView?
    var vid = Video()
    var client = SwiftClient()
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

class StreamItem: ObservableObject {
    @Published var stream: UnsafeMutablePointer<TwitchStream>
    
    init(stream: UnsafeMutablePointer<TwitchStream>) {
        self.stream = stream
    }
}

class StreamSelection: ObservableObject {
    @Published var channel = UnsafeMutablePointer<TwitchStream>?.init(nilLiteral: ())

    func set_selection(channel: UnsafeMutablePointer<TwitchStream>) {
        if self.channel?.pointee == nil {
            self.channel?.deallocate()
        }
        self.channel = channel
    }
}

class SwiftStream: ObservableObject {
    @Published var stream: UnsafeMutablePointer<TwitchStream>?

    func set_selection(stream: UnsafeMutablePointer<TwitchStream>) {
        if self.stream?.pointee == nil {
            self.stream?.deallocate()
        }
        self.stream = stream
    }
}

class Chat: ObservableObject {
    @Published var channel = ""

    func set_channel(channel: UnsafeMutablePointer<TwitchStream>) {
        self.channel = String(cString: &channel.pointee.user_login.0)
    }
}

class FollowedChannels: ObservableObject {
    var followed = UnsafeMutablePointer<TwitchStream>?.init(nilLiteral: ())
    @Published var count:Int32 = 0

    init() {
        self.get_followed()
    }

    func get_followed() {
        followed?.deallocate()
        let client = SwiftClient()
        count = get_followed_streams(&client.client, &followed, 0)
    }
}
