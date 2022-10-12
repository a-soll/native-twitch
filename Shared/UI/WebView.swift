import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    @AppStorage("ffzSettings") private var ffzSettings: String = ""
    var url: URL
    var webView: WKWebView
    var channel: String

    init(channel: String) {
        self.channel = channel
        url = URL(string: "https://www.twitch.tv/popout/\(self.channel)/chat")!
        webView = WKWebView()
        webView = loadWebViewWithCustomJavaScript()
    }
    
    func makeNSView(context: Context) -> WKWebView {
        let urlRequest = URLRequest(url: url)
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

        let scriptContent2 = """
        var settings = \(ffzSettings)
        for(var key in settings['values']) {
            localStorage.setItem('FFZ:setting:' + key, JSON.stringify(settings['values'][key]))
        }
"""
        let script2 = WKUserScript(source: scriptContent2, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        contentController.addUserScript(script2)
        configuration.userContentController = contentController
        return WKWebView(frame: .zero, configuration: configuration)
    }

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
