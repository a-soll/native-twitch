//
//  nonsense.swift
//  native_twitch
//
//  Created by Adam Solloway on 3/8/22.
//

import Foundation

func toCString(str: NSString) -> UnsafeMutablePointer<CChar> {
    let str_p0 = UnsafeMutablePointer<CChar>(mutating: str.utf8String)
    return str_p0!
}

func charPointerToString(_ pointer: UnsafePointer<Int8>) -> String
{
    return String(cString: UnsafeRawPointer(pointer).assumingMemoryBound(to: CChar.self))
}

func fromCString(str: UnsafePointer<CChar>) -> NSString {
    let s = NSString(utf8String: str)
    return s!
}

// non-mutable
func toCCString(str: NSString) -> UnsafePointer<CChar> {
    let str_p0 = UnsafePointer<CChar>(str.utf8String)
    return str_p0!
}

class Channels: Identifiable, Hashable {
    let id = UUID()
    var chan: UnsafeMutablePointer<Channel>
    var user_id: String
    var user_name: String
    var game_id: String
    var game_name: String
    var vid: SwiftVideo
    
    init(chan: UnsafeMutablePointer<Channel>, user_id: String, user_name: String, game_id: String, game_name: String, vid: SwiftVideo) {
        self.chan = chan
        self.user_id = user_id
        self.user_name = user_name
        self.game_id = game_id
        self.game_name = game_name
        self.vid = vid
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Channels, rhs: Channels) -> Bool {
        return lhs.id == rhs.id
    }
}

class SwiftClient {
    var client: Client
    var accessToken = UserDefaults.standard.string(forKey: "AccessToken")
    var userLogin = UserDefaults.standard.string(forKey: "UserLogin")
    var userId = UserDefaults.standard.string(forKey: "UserId")

    init() {
        self.client = Client_init(self.accessToken, userId, userLogin)
    }
    
    deinit {
        clear_headers(&client)
    }
}

class SwiftGame {
    var game: UnsafeMutablePointer<Game>
    
    init(game: UnsafeMutablePointer<Game>) {
        self.game = game
    }
}

final class FollowedChannels: ObservableObject {
    var client = SwiftClient()
    var count = 0
    var f: UnsafeMutablePointer<Channel>?
    @Published var channels: [Channels] = []
    
    init() {
        DispatchQueue.global(qos: .background).async {
            self.populate()
        }
    }
    
    func populate() {
        channels.removeAll()
        free(f)
        self.count = Int(get_followed_channels(&client.client, &f, Int32(Int(self.count))))
        for i in 0..<self.count {
            let vid = SwiftVideo()
            var c = f![Int(i)]
            let s = String(cString: &c.user_id.0)
            let user_name = String(cString: &c.user_name.0)
            let game_id = String(cString: &c.game_id.0)
            let gn = charPointerToString(&f![Int(i)].game_name.0)
            let op: Channels = Channels(chan: &f![Int(i)], user_id: s, user_name: user_name, game_id: game_id, game_name: gn as String, vid: vid)
            DispatchQueue.main.async {
                self.channels.append(op)
            }
        }
    }
    
    func getChannel(id: UUID) -> Int? {
        return self.channels.firstIndex(where: {$0.id == id})
    }
}
class SwiftVideo {
    var video: Video
    
    init() {
        video = init_video_player()
    }
}
