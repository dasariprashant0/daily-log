// AssetStore.swift - pasted/dropped images, stored in <storage>/assets/ and referenced from markdown by a path
// RELATIVE to the storage folder:  ![](assets/2026-10-06-1a2b3c4d.png)
//
// API: AssetStore(dir:)               `dir` = the storage folder (same one LogStore uses)
//   save(data:ext:day:) throws -> String       relative path "assets/<day>-<8hex>.<ext>". The 8 hex are the start of the
//                                              SHA-256 of the data, so saving identical bytes twice for a day returns the same
//                                              path and writes one file. Allowed ext (case-insensitive, leading "." ok):
//                                              png jpg jpeg gif webp. Max 20 MB, no empty data. Atomic write.
//                                              Errors (LogError): unsupportedAsset, assetTooLarge, emptyAsset, badDay,
//                                              folderMissing, folderNotWritable, badPath (assets/ links outside the folder), io.
//   resolve(_ relativePath) -> URL?             the real file for a markdown image path, or nil. nil when: empty, absolute,
//                                              contains "..", extension not allowed, file missing/not a regular file, or the
//                                              real path (symlinks resolved) is outside the storage folder or not an image ext.
//   resolve(assetURL:) -> URL?                  same for a dlasset://local/<relative path> URL (uses the decoded URL path)
//   AssetStore.fileExtension(mime:name:) -> String?   "image/png" -> "png", "image/jpeg" -> "jpg", gif, webp; falls back to the
//                                              file name's extension; nil when neither is an allowed image type (for uploadImage)
// Security: symlinks that lead out of the storage folder are refused, including a symlinked assets/ directory.
import Foundation
import CryptoKit

struct AssetStore {
    static let allowedExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "webp"]
    static let maxBytes = 20 * 1024 * 1024
    static let folderName = "assets"

    let dir: URL
    init(dir: URL) { self.dir = dir }

    /// Canonical absolute path with every symlink resolved; nil if the path does not exist.
    static func realPath(_ url: URL) -> String? {
        guard let p = realpath(url.path, nil) else { return nil }
        defer { free(p) }
        return String(cString: p)
    }
    private static func extensionOf(_ name: String) -> String { (name as NSString).pathExtension.lowercased() }

    /// Allowed extension for an upload, from its MIME type (parameters ignored) or, failing that, its file name.
    static func fileExtension(mime: String?, name: String?) -> String? {
        let m = (mime ?? "").split(separator: ";").first.map { String($0).dlTrimmed.lowercased() } ?? ""
        switch m {
        case "image/png": return "png"
        case "image/jpeg", "image/jpg", "image/pjpeg": return "jpg"
        case "image/gif": return "gif"
        case "image/webp": return "webp"
        default: break
        }
        let e = extensionOf(name ?? "")
        return allowedExtensions.contains(e) ? e : nil
    }

    func save(data: Data, ext: String, day: String) throws -> String {
        guard DayKey.isWellFormed(day) else { throw LogError.badDay(day) }
        var e = ext.lowercased().dlTrimmed
        if e.hasPrefix(".") { e.removeFirst() }
        guard Self.allowedExtensions.contains(e) else { throw LogError.unsupportedAsset(ext) }
        guard !data.isEmpty else { throw LogError.emptyAsset }
        guard data.count <= Self.maxBytes else { throw LogError.assetTooLarge(data.count) }

        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { throw LogError.folderMissing(dir.path) }
        let assets = dir.appendingPathComponent(Self.folderName, isDirectory: true)
        if !fm.fileExists(atPath: assets.path) {
            guard fm.isWritableFile(atPath: dir.path) else { throw LogError.folderNotWritable(dir.path) }
            do { try fm.createDirectory(at: assets, withIntermediateDirectories: false) }
            catch { throw LogError.folderNotWritable(dir.path) }
        }
        guard let realRoot = Self.realPath(dir), let realAssets = Self.realPath(assets), realAssets.hasPrefix(realRoot + "/") else {
            throw LogError.badPath(Self.folderName)
        }
        guard fm.isWritableFile(atPath: realAssets) else { throw LogError.folderNotWritable(assets.path) }

        let hex = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        for n in [8, 12, 16, 24, 64] {
            let name = "\(day)-\(hex.prefix(n)).\(e)"
            let url = assets.appendingPathComponent(name)
            if fm.fileExists(atPath: url.path) {
                if (try? Data(contentsOf: url)) == data { return "\(Self.folderName)/\(name)" }
                continue   // different bytes with the same short hash: use a longer one
            }
            do { try data.write(to: url, options: .atomic) } catch { throw LogError.io(error.localizedDescription) }
            return "\(Self.folderName)/\(name)"
        }
        throw LogError.io("could not pick a unique asset name")
    }

    func resolve(_ relativePath: String) -> URL? {
        guard !relativePath.isEmpty, !relativePath.hasPrefix("/"), !relativePath.contains("\0") else { return nil }
        var comps = [String]()
        for c in relativePath.split(separator: "/", omittingEmptySubsequences: true) {
            if c == "." { continue }
            if c == ".." { return nil }
            comps.append(String(c))
        }
        guard let last = comps.last, Self.allowedExtensions.contains(Self.extensionOf(last)) else { return nil }
        var url = dir
        for c in comps { url.appendPathComponent(c) }
        guard let realRoot = Self.realPath(dir), let real = Self.realPath(url), real.hasPrefix(realRoot + "/"),
              Self.allowedExtensions.contains(Self.extensionOf(real)) else { return nil }
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: real, isDirectory: &isDir), !isDir.boolValue else { return nil }
        return URL(fileURLWithPath: real)
    }

    func resolve(assetURL: URL) -> URL? {
        guard assetURL.scheme == "dlasset" else { return nil }
        return resolve(String(assetURL.path.drop(while: { $0 == "/" })))
    }
}
