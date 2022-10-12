//
//  ChatView.swift
//  apple-twitch
//
//  Created by Adam Solloway on 8/28/22.
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chat: Chat

    var body: some View {
        WebView(channel: chat.channel)
    }
}
