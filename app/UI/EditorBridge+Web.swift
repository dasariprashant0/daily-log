// EditorBridge+Web.swift - WKNavigationDelegate / WKUIDelegate for the editor web view: nothing navigates but the first
// load; links open in the default browser (http/https/mailto only); "Choose image" is a native open panel.
import WebKit
import AppKit
import UniformTypeIdentifiers

// MARK: navigation: nothing but the first load; links go to the default browser
extension EditorBridge: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if allowInitialLoad, action.targetFrame?.isMainFrame == true { allowInitialLoad = false; decisionHandler(.allow); return }
        if action.navigationType == .linkActivated, let u = action.request.url { Self.openExternal(u.absoluteString) }
        decisionHandler(.cancel)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { allowInitialLoad = false }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        allowInitialLoad = false
        delegate?.editorLoadFailed("The editor couldn't load. \(error.localizedDescription)")
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        allowInitialLoad = false
        delegate?.editorLoadFailed("The editor couldn't load. \(error.localizedDescription)")
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { processTerminated() }
}

extension EditorBridge: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let u = action.request.url { Self.openExternal(u.absoluteString) }
        return nil
    }

    /// "Choose image": a native open panel limited to the four allowed image types.
    func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.png, .jpeg, .gif, .webP]
        panel.prompt = "Choose"
        if let w = webView.window { panel.beginSheetModal(for: w) { completionHandler($0 == .OK ? panel.urls : nil) } }
        else { completionHandler(panel.runModal() == .OK ? panel.urls : nil) }
    }
}
