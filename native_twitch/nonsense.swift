//
//  nonsense.swift
//  native_twitch
//
//  Created by Adam Solloway on 3/8/22.
//

import Foundation

func fromCString(str: UnsafePointer<CChar>) -> NSString {
    let s = NSString(utf8String: str)
    return s!
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

    deinit {
        free(self.game)
    }
}

class SwiftChannel {
    var channel: UnsafeMutablePointer<Channel>

    init(channel: UnsafeMutablePointer<Channel>) {
        self.channel = channel
    }

    deinit {
        free(self.channel)
    }
}

final class FollowedChannels: ObservableObject {
    var client = SwiftClient()
    var count = 0
    @Published var followed: [SwiftChannel] = []

    init() {
        DispatchQueue.global(qos: .background).async {
            self.populate()
        }
    }
    func populate() {
        var tmp: UnsafeMutablePointer<Channel>?
        self.count = Int(get_followed_channels(&client.client, &tmp, Int32(Int(self.count))))
        for i in 0..<self.count {
            let chan = SwiftChannel(channel: &tmp![i])
            DispatchQueue.main.async {
                self.followed.append(chan)
            }
        }
    }
    func clean() {
        for i in 0..<self.count {
//            free(self.followed[i].channel)
        }
        self.followed.removeAll()
        self.count = 0
    }
}

class SwiftVideo {
    var video: Video

    init() {
        video = init_video_player()
    }

    deinit {
//        free(self.video.resolution_list)
    }
}
