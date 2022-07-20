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

struct ChatView: View {
    @ObservedObject var cWrapper: CWrapper
    
    init (channel: Channels) {
        self.cWrapper = CWrapper(channel: channel)
    }
    
    var body: some View {
        WebView(channel: self.cWrapper.channel.user_name)
    }
}
