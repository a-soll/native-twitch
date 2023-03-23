//
//  ChatView.swift
//  apple-twitch
//
//  Created by Adam Solloway on 8/28/22.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chat: Chat
    @EnvironmentObject var hideChat: HideChat

    var body: some View {
        if (hideChat.hide == false) {
            WebView(channel: chat.channel)
        }
    }
}
