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

func CString(str: UnsafeMutablePointer<CChar>) -> String {
    return (NSString(cString: str, encoding: NSUTF8StringEncoding) ?? (NSString(cString: str, encoding: NSUnicodeStringEncoding)!)) as String
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
    @Published var stream: TwitchStream

    init(stream: TwitchStream) {
        self.stream = stream
    }
}

class StreamSelection: ObservableObject {
    @Published var stream = TwitchStream()

    func set_selection(stream: TwitchStream) {
        self.stream = stream
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
        self.channel = CString(str: &channel.pointee.user_login.0)
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
