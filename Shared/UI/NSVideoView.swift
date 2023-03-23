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
            let client = SwiftClient()
            get_user_by_login(&client.client, &user, &stream.user_login.0)
            DispatchQueue.main.async { [self] in
                url = CString(str: &user.profile_image_url.0)
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
        playerView.player?.preventsDisplaySleepDuringVideoPlayback = true
        playerView.showsFullScreenToggleButton = true
        self.playerView = playerView
        playerView.player?.play()
        return playerView
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
        nsView.player?.replaceCurrentItem(with: AVPlayerItem(url: vidModel.url!))
    }
}

struct StreamTitleView: View {
    @ObservedObject var img: ProfImage
    @State var stream: StreamItem
    @EnvironmentObject var vidModel: VideoViewModel
    
    var body: some View {
        HStack {
            img.image
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .frame(width: 85, height: 85)
            VStack(alignment: .leading) {
                Text(CString(str: &stream.stream.user_name.0))
                    .font(.largeTitle)
                    .font(.system(size: 38))
                Text(CString(str: &stream.stream.title.0))
                Text("Playing ") +
                Text(CString(str: &stream.stream.game_name.0)) +
                Text(" for ") +
                Text("\(stream.stream.viewer_count)") +
                Text(" viewers")
            }        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                .background(.black.opacity(0.7)).cornerRadius(15)
        }
        Spacer()
    }
}

struct ResolutionItem: View {
    @State var res: Resolution
    @State var isHover = false
    @EnvironmentObject var vidModel: VideoViewModel
    @Binding var toolbarLock: Bool
    
    var body: some View {
        resText(resolution: &res)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isHover ? .gray.opacity(0.1) : .clear)
                    .frame(width: 120, height: 30)
            )
            .onHover(perform: { hover in
                isHover = hover
            })
            .onTapGesture {
                vidModel.url = URL(string: CString(str: &res.link.0))
            }
    }
    
    func resText(resolution: inout Resolution) -> some View {
        return Text(String(Substring(cString: &resolution.name.0)))
    }
}

struct Toolbar: View {
    @EnvironmentObject var vidModel: VideoViewModel
    @State var showPopup = false
    @Binding var toolbarLock: Bool
    @State var curResolution = ""
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: togglePopup, label: {
                    Image(systemName: "gearshape")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25, height: 25)
                })
                .buttonStyle(.plain)
                .popover(isPresented: $showPopup, attachmentAnchor: .point(.top), arrowEdge: .top) {
                    VStack {
                        ResolutionItem(res: vidModel.vid.resolution_list.0, toolbarLock: $toolbarLock)
                            .padding(EdgeInsets(top: 15, leading: 20, bottom: 5, trailing: 20))
                            .frame(maxWidth: .infinity)
                        ResolutionItem(res: vidModel.vid.resolution_list.1, toolbarLock: $toolbarLock)
                            .padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                        ResolutionItem(res: vidModel.vid.resolution_list.2, toolbarLock: $toolbarLock)
                            .padding(EdgeInsets(top: 0, leading: 5, bottom: 5, trailing: 5))
                        ResolutionItem(res: vidModel.vid.resolution_list.3, toolbarLock: $toolbarLock)
                            .padding(EdgeInsets(top: 0, leading: 5, bottom: 15, trailing: 5))
                    }.onAppear(perform: {
                        toolbarLock = true
                    })
                    .onDisappear(perform: {
                        toolbarLock = false
                    })
                }.onHover(perform: {_ in
                    toolbarLock = true
                })
            }
            Spacer()
                .frame(height: 15)
        }
    }
    
    func togglePopup() {
        self.showPopup = true
    }
}

struct OverlayView: View {
    @ObservedObject var img: ProfImage
    @State var stream: StreamItem
    @Binding var toolbarLock: Bool
    var body: some View {
        VStack {
            HStack {
                StreamTitleView(img: img, stream: stream)
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                Toolbar(toolbarLock: $toolbarLock)
            }
        }
    }
}

struct PlayerView: View {
    @StateObject var helper = Helper(hide: true, toolbarLock: false)
    @EnvironmentObject var streamSelection: StreamSelection
    @EnvironmentObject var vidModel: VideoViewModel
    @State var firstLoad = true
    @ObservedObject var img: ProfImage
    @State var hideControlTimer: Timer?
    @State var refreshTimer = Timer.publish(every: 45, on: .main, in: .common).autoconnect()
    @ObservedObject var stream: StreamItem
    @State var monitor: Any?
    @EnvironmentObject var hideChat: HideChat
    
    var body: some View {
        ZStack {
            NSVideoView(stream: stream)
            if (!helper.hide) {
                VStack {
                    Spacer().frame(height: 10)
                    HStack {
                        Spacer().frame(width: 10)
                        OverlayView(img: img, stream: stream, toolbarLock: $helper.toolbarLock)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .toolbar {
            ToolbarItem(content: {
                let hideText = hideChat.hide ? "Show" : "Hide"
                Button("\(hideText) chat") {hideChat.hide.toggle()}
            })
        }
        .onAppear(perform: {
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
            let client = SwiftClient()
            get_stream_by_user_login(&client.client, &self.stream.stream, &self.stream.stream.user_login.0)
        }
    }
    
    func handle(event: NSEvent) -> NSEvent {
        if (helper.isOverContent) {
            helper.hide = false
            createTimer()
            firstLoad = false
        } else {
            if (!firstLoad && !helper.toolbarLock) {
                helper.hide = true
            }
        }
        return event
    }
    
    private func createTimer() {
        hideControlTimer?.invalidate()
        helper.hide = false
        hideControlTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(3), repeats: false) { _ in
            if (!helper.toolbarLock) {
                helper.hide = true
            }
        }
    }
}

class Helper: ObservableObject {
    @Published var hide: Bool
    @Published var toolbarLock: Bool
    var isOverContent = false
    
    init(hide: Bool, toolbarLock: Bool) {
        self.hide = hide
        self.toolbarLock = toolbarLock
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
