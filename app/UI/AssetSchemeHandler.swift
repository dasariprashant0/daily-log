// AssetSchemeHandler.swift - serves the day pages' images to the editor as dlasset://local/assets/<file>.
// Only what AssetStore.resolve(assetURL:) accepts is served (inside the storage folder, allowed image extension, a real
// file, symlinks resolved), with a MIME type derived from the extension. Everything else is a 404. No directory listing,
// no other file types, no network.
import WebKit

final class AssetSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "dlasset"
    static let host = "local"

    /// The CURRENT storage folder's asset store (changes when the user picks another folder).
    var assets: () -> AssetStore? = { nil }
    private var active = Set<ObjectIdentifier>()     // main thread only; a stopped task must never be messaged

    static func mimeType(forExtension ext: String) -> String? {
        switch ext.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return nil
        }
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let id = ObjectIdentifier(urlSchemeTask as AnyObject)
        active.insert(id)
        let url = urlSchemeTask.request.url
        let isGet = (urlSchemeTask.request.httpMethod ?? "GET").uppercased() == "GET"
        guard isGet, let url = url, url.scheme == Self.scheme, url.host?.lowercased() == Self.host,
              let store = assets(), let file = store.resolve(assetURL: url),
              let mime = Self.mimeType(forExtension: file.pathExtension) else {
            finish(urlSchemeTask, id, url: url ?? URL(string: "\(Self.scheme)://\(Self.host)/")!, status: 404, mime: "text/plain", data: Data())
            return
        }
        // Read off the main thread (images can be 20 MB); reply on it.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let data = try? Data(contentsOf: file, options: .mappedIfSafe)
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let d = data { self.finish(urlSchemeTask, id, url: url, status: 200, mime: mime, data: d) }
                else { self.finish(urlSchemeTask, id, url: url, status: 404, mime: "text/plain", data: Data()) }
            }
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        active.remove(ObjectIdentifier(urlSchemeTask as AnyObject))
    }

    private func finish(_ task: WKURLSchemeTask, _ id: ObjectIdentifier, url: URL, status: Int, mime: String, data: Data) {
        guard active.remove(id) != nil else { return }
        let headers = ["Content-Type": mime, "Content-Length": "\(data.count)", "Cache-Control": "no-store",
                       "X-Content-Type-Options": "nosniff"]
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers) else {
            task.didFailWithError(URLError(.badServerResponse)); return
        }
        task.didReceive(response)
        if !data.isEmpty { task.didReceive(data) }
        task.didFinish()
    }
}
