//
//  ChatView.swift
//  native_twitch
//
//  Created by Adam Solloway on 3/28/22.
//

import SwiftUI
import Foundation
import AVFoundation
import WebKit

class CWrapper: ObservableObject {
    @Published var channel: Channels
    
    init(channel: Channels) {
        self.channel = channel
    }
}

func usernameText(user: String, color: Color) -> Text {
    return Text("\(user):").fontWeight(.semibold).foregroundColor(color).font(.system(size: 16))
}

func tview(dmsg: [MsgFragment], len: Int, user: String, color: Color) -> Text {
    var t = Text("")
    let username = Text("\(user): ").fontWeight(.semibold).foregroundColor(color)
    t = t + username
    for i in 0..<len {
        var cur = dmsg[i]
        if (cur.is_emote) {
            let url = URL(string: String(cString: &cur.content.0))
            getImage(from: url!, completion: {(image, error) -> Void in
                t = t + Text(" \(Image(nsImage: image!))")
            })
        } else {
            t = t + Text(" \(String(cString: &cur.content.0))")
        }
    }
    return t
}

struct ChatView: View {
    @State private var indicator = false
    var channel: Channels
//    var client: SwiftClient
    //    @ObservedObject var loop: Loop
    var lightBack = Color(hex: "#242427")
    var darkBack = Color(hex: "#18181b")
    @ObservedObject var cWrapper: CWrapper
    //    @State var color_toggle = true
    
    init (channel: Channels) {
//        self.client = client
        self.channel = channel
        //        self.loop = Loop(client: self.client, channel: self.channel)
        self.cWrapper = CWrapper(channel: channel)
    }
    
    var body: some View {
        WebView(channel: self.cWrapper.channel.user_name)
        //        VStack(alignment: .leading) {
        //            ScrollView(showsIndicators: self.indicator) {
        //                ScrollViewReader { scrollView in
        //                    LazyVStack(alignment: .leading) {
        //                        ForEach(0..<loop.data.count, id: \.self) { i in
        //                            let curData = loop.data[i]
        //                            HStack {
        //                                tview(dmsg: curData.dmsg, len: curData.count, user: curData.user, color: curData.color).font(.system(size: 16))
        //                            }
        //                        }.onChange(of: loop.data.count) { _ in
        //                            if (!indicator) {
        //                                scrollView.scrollTo(self.loop.data.count - 1)
        //                            }
        //                        }
        //                    }.onHover { over in
        //                        indicator = over
        //                    }
        //                }
        //            }.onDisappear(perform: {
        //                self.loop.stopLoop()
        //            })
        //        }
    }
}

//struct ChatView_Previews: PreviewProvider {
//    let c: Channel = UnsafeMutablePointer<Channel>()
//    static var previews: some View {
//        ChatView(channel: Channels(chan: c, user_id: "swifcheese", user_name: "swifcheese", game_id: "hello", game_name: "PUBG", vid: SwiftVideo()))
//    }
//}
