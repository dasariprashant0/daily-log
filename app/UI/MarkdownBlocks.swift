// MarkdownBlocks.swift - a small read-only markdown renderer for the weekly review (and the snapshot stand-in for the
// editor). Blocks: headings, bullets/numbers/tasks, quotes, code, images, paragraphs. Inline: bold, italic, code, links.
// Links are limited to http/https/mailto; images come only from AssetStore (inside the log folder).
import SwiftUI
import ImageIO

enum MDBlock: Equatable {
    case heading(level: Int, text: String)
    case bullet(text: String, checked: Bool?, indent: Int)
    case numbered(text: String, number: String, indent: Int)
    case quote(String)
    case code(String)
    case image(path: String, alt: String)
    case paragraph(String)
}

enum MDParse {
    private static let imageLine = try! NSRegularExpression(pattern: "^!\\[([^\\]]*)\\]\\(([^)\\s]+)(?:\\s+\"[^\"]*\")?\\)$")

    static func blocks(_ body: String) -> [MDBlock] {
        var out = [MDBlock](), para = [String](), code = [String](), inCode = false
        func flushPara() { if !para.isEmpty { out.append(.paragraph(para.joined(separator: "\n"))); para = [] } }
        for l in MarkdownBody.scan(body) {
            switch l.kind {
            case .fence:
                flushPara()
                if inCode { out.append(.code(code.joined(separator: "\n"))); code = []; inCode = false } else { inCode = true }
            case .code: code.append(l.text)
            case .blank: flushPara()
            case .heading(let level, let title): flushPara(); out.append(.heading(level: level, text: title))
            case .text:
                let raw = l.text
                let t = raw.trimmingCharacters(in: .whitespaces)
                let indent = min(3, (raw.prefix(while: { $0 == " " }).count) / 2)
                if let m = imageLine.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)), m.numberOfRanges == 3,
                   let a = Range(m.range(at: 1), in: t), let p = Range(m.range(at: 2), in: t) {
                    flushPara(); out.append(.image(path: String(t[p]), alt: String(t[a]))); continue
                }
                if t.hasPrefix(">") {
                    flushPara(); out.append(.quote(String(t.drop(while: { $0 == ">" || $0 == " " })))); continue
                }
                if let item = listItem(t) {
                    flushPara()
                    if let n = item.number { out.append(.numbered(text: item.text, number: n, indent: indent)) }
                    else { out.append(.bullet(text: item.text, checked: item.checked, indent: indent)) }
                    continue
                }
                para.append(t)
            }
        }
        if inCode { out.append(.code(code.joined(separator: "\n"))) }
        flushPara()
        return out
    }

    /// "- item", "* item", "+ item", "1. item", "1) item", with an optional "[ ]" / "[x]" task box.
    private static func listItem(_ t: String) -> (text: String, checked: Bool?, number: String?)? {
        var s = Substring(t), number: String?
        if let f = s.first, "-*+".contains(f), s.count == 1 || s.dropFirst().first == " " {
            s = s.dropFirst()
        } else {
            let digits = s.prefix(while: { ("0"..."9").contains($0) })
            guard !digits.isEmpty, digits.count <= 9, let d = s.dropFirst(digits.count).first, d == "." || d == ")",
                  s.dropFirst(digits.count + 1).first == " " || s.count == digits.count + 1 else { return nil }
            number = String(digits); s = s.dropFirst(digits.count + 1)
        }
        s = s.drop(while: { $0 == " " })
        var checked: Bool?
        if s.hasPrefix("["), s.count >= 3 {
            let mark = s[s.index(after: s.startIndex)], close = s[s.index(s.startIndex, offsetBy: 2)]
            if close == "]", mark == " " || mark == "x" || mark == "X", s.dropFirst(3).first == " " || s.count == 3 {
                checked = mark != " "; s = s.dropFirst(3).drop(while: { $0 == " " })
            }
        }
        return (String(s), checked, number)
    }
}

// MARK: inline text
enum MDInline {
    static func attributed(_ s: String) -> AttributedString {
        let opts = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard var a = try? AttributedString(markdown: s, options: opts) else { return AttributedString(s) }
        for run in a.runs {
            if let link = run.link, !["http", "https", "mailto"].contains(link.scheme?.lowercased() ?? "") {
                a[run.range].link = nil                      // never a file: or custom-scheme link
            }
        }
        return a
    }
    static func text(_ s: String) -> Text { Text(attributed(s)) }
}

// MARK: view
extension MDBlock {
    /// Rough height in text lines (for "Show more" cut-offs; never used for layout).
    var estimatedLines: Double {
        func wrap(_ s: String) -> Double { s.components(separatedBy: "\n").reduce(0) { $0 + max(1, ceil(Double($1.count) / 95)) } }
        switch self {
        case .heading: return 1.6
        case .bullet(let t, _, _), .numbered(let t, _, _), .quote(let t), .paragraph(let t): return wrap(t)
        case .code(let t): return Double(t.components(separatedBy: "\n").count)
        case .image: return 7
        }
    }
}

struct MarkdownBlocksView: View {
    let blocks: [MDBlock]
    let store: AssetStore
    var size: CGFloat = 14
    /// Review cards: headings become small labels so they stay below the day title.
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: size * 0.45) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, b in block(b) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func block(_ b: MDBlock) -> some View {
        switch b {
        case .heading(let level, let text):
            let sizes: [CGFloat] = [size * 1.5, size * 1.3, size * 1.12, size, size * 0.9, size * 0.9]
            if compact {
                MDInline.text(text).font(.system(size: level == 1 ? size : size - 2, weight: .semibold))
                    .foregroundColor(level == 1 ? Theme.textPrimary : Theme.textSecondary)
                    .padding(.top, size * 0.25).accessibilityAddTraits(.isHeader)
            } else {
                MDInline.text(text).font(.system(size: sizes[min(level, 6) - 1], weight: .semibold))
                    .foregroundColor(level >= 5 ? Theme.textSecondary : Theme.textPrimary)
                    .padding(.top, level <= 2 ? size * 0.5 : size * 0.3).accessibilityAddTraits(.isHeader)
            }
        case .bullet(let text, let checked, let indent):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let c = checked {
                    Image(systemName: c ? "checkmark.square.fill" : "square").font(.system(size: size * 0.9))
                        .foregroundColor(c ? Theme.accent : Theme.textSecondary).accessibilityHidden(true)
                } else { Text("•").foregroundColor(Theme.textSecondary) }
                MDInline.text(text).foregroundColor(c(checked) ? Theme.textSecondary : Theme.textPrimary)
            }
            .font(.system(size: size)).padding(.leading, CGFloat(indent) * 18)
            .accessibilityElement(children: .combine)
            .accessibilityValue(checked == nil ? "" : (checked == true ? "done" : "not done"))
        case .numbered(let text, let n, let indent):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(n).").foregroundColor(Theme.textSecondary).monospacedDigit()
                MDInline.text(text).foregroundColor(Theme.textPrimary)
            }.font(.system(size: size)).padding(.leading, CGFloat(indent) * 18)
        case .quote(let text):
            HStack(spacing: 10) {
                Rectangle().fill(Theme.borderStrong).frame(width: 2)
                MDInline.text(text).foregroundColor(Theme.textSecondary)
            }.font(.system(size: size)).fixedSize(horizontal: false, vertical: true)
        case .code(let text):
            Text(text).font(.system(size: size * 0.86, design: .monospaced)).foregroundColor(Theme.textPrimary)
                .padding(Theme.s2).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.rect(6).fill(Theme.sidebar))
        case .image(let path, let alt):
            AssetImageView(path: path, alt: alt, store: store)
        case .paragraph(let text):
            MDInline.text(text).font(.system(size: size)).foregroundColor(Theme.textPrimary).lineSpacing(size * 0.25)
        }
    }
    private func c(_ checked: Bool?) -> Bool { checked == true }
}

// MARK: images
/// Thumbnails are decoded with ImageIO at a small size (a pasted photo can be many megapixels) and cached.
enum Thumbs {
    private static let cache = NSCache<NSString, NSImage>()
    static func image(_ file: URL, maxPixel: Int = 720) -> NSImage? {
        let key = "\(file.path)#\(maxPixel)" as NSString
        if let c = cache.object(forKey: key) { return c }
        guard let src = CGImageSourceCreateWithURL(file as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceCreateThumbnailWithTransform: true,
                                     kCGImageSourceThumbnailMaxPixelSize: maxPixel]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else { return nil }
        let img = NSImage(cgImage: cg, size: NSSize(width: cg.width / 2, height: cg.height / 2))
        cache.setObject(img, forKey: key)
        return img
    }
}

struct AssetImageView: View {
    let path: String, alt: String
    let store: AssetStore
    var body: some View {
        if let file = store.resolve(path), let img = Thumbs.image(file) {
            Image(nsImage: img).resizable().scaledToFit()
                .frame(maxWidth: 360, maxHeight: 220, alignment: .leading)
                .clipShape(Theme.rect(6)).overlay(Theme.rect(6).stroke(Theme.border, lineWidth: 1))
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(alt.isEmpty ? "Image" : alt)
        } else {
            Text(alt.isEmpty ? "Image not found" : "Image not found: \(alt)").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                .padding(Theme.s2).background(Theme.rect(6).fill(Theme.hover))
        }
    }
}
