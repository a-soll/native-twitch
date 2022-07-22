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

struct ChatView: View {
    var channel: SwiftChannel

    init (channel: SwiftChannel) {
        self.channel = channel
    }

    var body: some View {
        WebView(channel: String(cString: &self.channel.channel.pointee.user_name.0))
    }
}
