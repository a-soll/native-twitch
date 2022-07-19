import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    @AppStorage("ffzPath") private var fpath: String = ""
    var url: URL
    var webView: WKWebView
    var channel: String
    
    init(channel: String) {
        self.channel = channel
        url = URL(string: "https://www.twitch.tv/popout/\(channel)/chat")!
        webView = WKWebView()
        webView = loadWebViewWithCustomJavaScript()
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let urlRequest = URLRequest(url: url)
//        self.webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        self.webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView.load(urlRequest)
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
            let urlRequest = URLRequest(url: url)
            webView.load(urlRequest)
    }

    func loadWebViewWithCustomJavaScript() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        let js = getMyJavaScript()
        let script = WKUserScript(source: js, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(script)

        let settings = getJson()
        let scriptContent2 = """
        var settings = \(settings)
        for(var key in settings['values']) {
            localStorage.setItem('FFZ:setting:' + key, JSON.stringify(settings['values'][key]))
        }
"""
        let script2 = WKUserScript(source: scriptContent2, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(script2)
        configuration.userContentController = contentController
        return WKWebView(frame: .zero, configuration: configuration)
    }
    
    func getJson() -> String {
        do {
            let contentFromFile = try NSString(contentsOfFile: fpath, encoding: String.Encoding.utf8.rawValue)
            return contentFromFile as String
        } catch {
            return ""
        }
    }
//    func getJson() -> String {
////        return String(contentsOf: fileURL)
////        return ""
//        if let filepath = Bundle.main.path(forResource: self.fpath, ofType: "json") {
//            do {
//                print(filepath)
//                return try String(contentsOfFile: filepath)
//            } catch {
//                return ""
//            }
//        } else {
//            return ""
//        }
//    }

    func getMyJavaScript() -> String {
        if let filepath = Bundle.main.path(forResource: "ffz", ofType: "js") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return ""
            }
        } else {
            return ""
        }
    }
}
