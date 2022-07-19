//
//  Chat.swift
//  native_twitch
//
//  Created by Adam Solloway on 5/23/22.
//

import Foundation
import Combine
import SwiftUI

extension Color {
    init(hex string: String) {
        var string: String = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.hasPrefix("#") {
            _ = string.removeFirst()
        }
        
        // Double the last value if incomplete hex
        if !string.count.isMultiple(of: 2), let last = string.last {
            string.append(last)
        }
        
        // Fix invalid values
        if string.count > 8 {
            string = String(string.prefix(8))
        }
        
        // Scanner creation
        let scanner = Scanner(string: string)
        
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        
        if string.count == 2 {
            let mask = 0xFF
            
            let g = Int(color) & mask
            
            let gray = Double(g) / 255.0
            
            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: 1)
            
        } else if string.count == 4 {
            let mask = 0x00FF
            
            let g = Int(color >> 8) & mask
            let a = Int(color) & mask
            
            let gray = Double(g) / 255.0
            let alpha = Double(a) / 255.0
            
            self.init(.sRGB, red: gray, green: gray, blue: gray, opacity: alpha)
            
        } else if string.count == 6 {
            let mask = 0x0000FF
            let r = Int(color >> 16) & mask
            let g = Int(color >> 8) & mask
            let b = Int(color) & mask
            
            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0
            
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
            
        } else if string.count == 8 {
            let mask = 0x000000FF
            let r = Int(color >> 24) & mask
            let g = Int(color >> 16) & mask
            let b = Int(color >> 8) & mask
            let a = Int(color) & mask
            
            let red = Double(r) / 255.0
            let green = Double(g) / 255.0
            let blue = Double(b) / 255.0
            let alpha = Double(a) / 255.0
            
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
            
        } else {
            self.init(.sRGB, red: 1, green: 1, blue: 1, opacity: 1)
        }
    }
}

class Holder : Hashable {
    
    var id = UUID()
    var dmsg: [MsgFragment]
    var count: Int
    var user: String
    var color: Color
    
    init(count: Int, dmsg: [MsgFragment], user: String, color: String) {
        self.count = count
        self.dmsg = dmsg
        self.user = user
        self.color = Color(hex: color)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Holder, rhs: Holder) -> Bool {
        return lhs.id == rhs.id
    }
}

class Loop: ObservableObject {
    @Published var data: [Holder] = []
    var run = false
    var irc = Irc()
    var chat = TwitchChat()
    var client = SwiftClient()
    var emote_map = hashmap_s()
    var channel: Channels

    func startLoop() {
        self.run = true
        while self.run {
            var dmsg = [MsgFragment](repeating: MsgFragment(), count: 250)
            parse_irc(&self.chat, &self.irc);
            var len = 0
            if self.irc.finished {
                let user = String(cString: &self.irc.message.user.0)
                let color = String(cString: &self.irc.header.color.0)
                withUnsafeMutablePointer(to: &self.emote_map, {
                    len = Int(build_message(&self.irc, &dmsg, $0))
                })
                DispatchQueue.main.async {
                    self.data.append(Holder(count: Int(len), dmsg: dmsg, user: user, color: color))
                }
            }
        }
    }
    
    func stopLoop(){
        self.run = false
    }
    
    init(channel: Channels) {
        self.channel = channel
        init_irc(&self.irc)
        chat_init(&self.chat)
        self.emote_map = init_emote_map(1024)
        get_global_emotes(&self.client.client, &emote_map)
        get_bttv_global(&self.client.client, &emote_map)
        let chan_id = self.channel.user_id
        let chan_name = String(cString: &self.channel.chan.pointee.user_login.0)
        get_bttv_channel_emotes(&self.client.client, chan_id, &self.emote_map)
        get_ffz_channel_emotes(&self.client.client, chan_id, &self.emote_map)
        get_channel_emotes(&self.client.client, chan_id, &self.emote_map)
        chat_send(&chat, toCString(str:"pass oauth:8ox86acj1t44umog3hncwn3e7s52xa\n"))
        chat_send(&chat, toCString(str:"nick swifcheese\n"))
        chat_send(&chat, toCString(str:":swifcheese!swifcheese@swifcheese.tmi.twitch.tv JOIN #\(chan_name)\r\n" as NSString));
//        chat_send(&chat, toCString(str:":swifcheese!swifcheese@swifcheese.tmi.twitch.tv JOIN #swifcheese\r\n" as NSString))
        chat_send(&chat, toCString(str:"CAP REQ :twitch.tv/tags\n"))
        
        DispatchQueue.global(qos: .background).async {
            self.startLoop()
        }
    }
}
