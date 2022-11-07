//
//  VideoPlayerView.swift
//  native_twitch
//
//  Created by Adam Solloway on 3/17/22.
//

import SwiftUI
import Kingfisher
import AVKit

class ProfImage: ObservableObject {
    var id = UUID()
    var client = SwiftClient()
    @Published var image: KFImage
    @State var fetched = false
    @State var stream: TwitchStream
    var url: String = ""
    
    init(channel: TwitchStream) {
        image = KFImage(URL(string: url)).placeholder { Image(systemName: "circle.fill").resizable().frame(width: 75, height: 75)
        }
        self.stream = channel
        get_url()
    }
    
    func get_url() {
        DispatchQueue.global(qos: .background).async { [self] in
            var user = User()
            get_user_by_login(&client.client, &user, &stream.user_login.0)
            DispatchQueue.main.async { [self] in
                url = String(cString: &user.profile_image_url.0)
                image = KFImage(URL(string: url))
                fetched = true
            }
        }
    }
}

struct NSVideoView: NSViewRepresentable {
    @EnvironmentObject var vidModel: VideoViewModel
    @State private var playerView: AVPlayerView?
    @State var stream: StreamItem
    
    func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.allowsPictureInPicturePlayback = true
        playerView.controlsStyle = .floating
        playerView.player = AVPlayer(url: vidModel.url!)
        self.playerView = playerView
        playerView.player?.play()
        return playerView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.player?.replaceCurrentItem(with: AVPlayerItem(url: vidModel.url!))
    }
}

struct PlayerView: View {
    var client = SwiftClient()
    @StateObject var helper = Helper(hide: true)
    @EnvironmentObject var streamSelection: StreamSelection
    @State var firstLoad = true
    @ObservedObject var img: ProfImage
    @State var hideControlTimer: Timer?
    @State var refreshTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    @ObservedObject var stream: StreamItem
    @State var monitor: Any?
    
    var body: some View {
        ZStack {
            NSVideoView(stream: stream)
            if (!helper.hide) {
                VStack {
                    Spacer().frame(height: 10)
                    HStack {
                        Spacer().frame(width: 10)
                        img.image
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(width: 85, height: 85)
                        VStack(alignment: .leading) {
                            Text(String(cString: &stream.stream.user_name.0))
                                .font(.largeTitle)
                                .font(.system(size: 38))
                            Text(String(cString: &stream.stream.title.0))
                            Text("Playing ") +
                            Text(String(cString: &stream.stream.game_name.0)) +
                            Text(" for ") +
                            Text("\(stream.stream.viewer_count)") +
                            Text(" viewers")
                        }
                        Spacer()
                    }
                    Spacer()
                }.frame(minWidth: 500, minHeight: 500)
            }
        }.onAppear(perform: {
            if (firstLoad) {
                helper.hide = false
            }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved], handler: handle)
            createTimer()
        })
        .whenHovered({_ in
            helper.isOverContent.toggle()
        })
        .onDisappear(perform: {
            hideControlTimer?.invalidate()
            hideControlTimer = nil
            NSEvent.removeMonitor(monitor as Any)
        })
        .onReceive(refreshTimer) { _ in
            get_stream_by_user_login(&client.client, &self.stream.stream, &self.stream.stream.user_login.0)
        }
    }
    
    func handle(event: NSEvent) -> NSEvent {
        if (helper.isOverContent) {
            helper.hide = false
            createTimer()
            firstLoad = false
        } else {
            if (!firstLoad) {
                helper.hide = true
            }
        }
        return event
    }
    
    private func createTimer() {
        hideControlTimer?.invalidate()
        helper.hide = false
        hideControlTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(3), repeats: false) { _ in
            helper.hide = true
        }
    }
}

class Helper: ObservableObject {
    @Published var hide: Bool
    var isOverContent = false
    
    init(hide: Bool) {
        self.hide = hide
    }
}

struct MouseInsideModifier: ViewModifier {
    let mouseIsInside: (Bool) -> Void
    
    init(_ mouseIsInside: @escaping (Bool) -> Void) {
        self.mouseIsInside = mouseIsInside
    }
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { proxy in
                Representable(mouseIsInside: mouseIsInside,
                              frame: proxy.frame(in: .global))
            }
        )
    }
    
    private struct Representable: NSViewRepresentable {
        let mouseIsInside: (Bool) -> Void
        let frame: NSRect
        
        func makeCoordinator() -> Coordinator {
            let coordinator = Coordinator()
            coordinator.mouseIsInside = mouseIsInside
            return coordinator
        }
        
        class Coordinator: NSResponder {
            var mouseIsInside: ((Bool) -> Void)?
            
            override func mouseEntered(with event: NSEvent) {
                mouseIsInside?(true)
            }
            
            override func mouseExited(with event: NSEvent) {
                mouseIsInside?(false)
            }
        }
        
        func makeNSView(context: Context) -> NSView {
            let view = NSView(frame: frame)
            
            let options: NSTrackingArea.Options = [
                .mouseEnteredAndExited,
                .inVisibleRect,
                .activeInKeyWindow
            ]
            
            let trackingArea = NSTrackingArea(rect: frame,
                                              options: options,
                                              owner: context.coordinator,
                                              userInfo: nil)
            
            view.addTrackingArea(trackingArea)
            
            return view
        }
        
        func updateNSView(_ nsView: NSView, context: Context) {}
        
        static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
            nsView.trackingAreas.forEach { nsView.removeTrackingArea($0) }
        }
    }
}

extension View {
    func whenHovered(_ mouseIsInside: @escaping (Bool) -> Void) -> some View {
        modifier(MouseInsideModifier(mouseIsInside))
    }
}
