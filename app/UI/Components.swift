// Components.swift - banners, status chip, progress ring, heat cell shapes shared across screens.
import SwiftUI

enum BannerKind {
    case info, success, warning, error
    var fill: Color { switch self { case .info: return Theme.sidebar; case .success: return Theme.accentTint
        case .warning: return Theme.warningTint; case .error: return Theme.dangerTint } }
    var icon: String { switch self { case .info: return "info.circle"; case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle"; case .error: return "xmark.octagon" } }
    var tint: Color { switch self { case .info: return Theme.textSecondary; case .success: return Theme.accentText
        case .warning: return Theme.warning; case .error: return Theme.danger } }
}

struct Banner<Actions: View>: View {
    let kind: BannerKind
    let text: String
    var detail: String?
    var onDismiss: (() -> Void)?
    let actions: Actions

    init(_ kind: BannerKind, _ text: String, detail: String? = nil, onDismiss: (() -> Void)? = nil,
         @ViewBuilder actions: () -> Actions) {
        self.kind = kind; self.text = text; self.detail = detail; self.onDismiss = onDismiss; self.actions = actions()
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.s3) {
            Image(systemName: kind.icon).font(Theme.font(14)).foregroundColor(kind.tint).frame(width: 18).padding(.top, 1)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(text).font(Theme.font(13, detail == nil ? .regular : .semibold)).foregroundColor(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let d = detail {
                    Text(d).font(Theme.font(13)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: Theme.s2)
            HStack(spacing: Theme.s3) { actions }
            if let dismiss = onDismiss {
                Button(action: dismiss) {
                    Image(systemName: "xmark").font(Theme.font(11, .semibold)).foregroundColor(Theme.textTertiary).frame(width: 24, height: 24)
                }.buttonStyle(.plain).help("Dismiss").accessibilityLabel("Dismiss")
            }
        }
        .padding(.vertical, Theme.s3).padding(.horizontal, Theme.s4)
        .background(Theme.rect(Theme.radiusLg).fill(kind.fill))
        .overlay(Theme.rect(Theme.radiusLg).stroke(kind == .info ? Theme.border : Color.clear, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}
extension Banner where Actions == EmptyView {
    init(_ kind: BannerKind, _ text: String, detail: String? = nil, onDismiss: (() -> Void)? = nil) {
        self.init(kind, text, detail: detail, onDismiss: onDismiss) { EmptyView() }
    }
}

struct StatusChip: View {
    enum Kind { case none, draft, saved, unsaved, error }
    let kind: Kind
    let text: String
    var icon: String {
        switch kind { case .none: return "circle"; case .draft: return "pencil.circle"; case .saved: return "checkmark.circle.fill"
        case .unsaved: return "circle.lefthalf.filled"; case .error: return "exclamationmark.triangle" }
    }
    var color: Color {
        switch kind { case .saved: return Theme.accentText; case .error: return Theme.danger; default: return Theme.textSecondary }
    }
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(Theme.font(12)).foregroundColor(color).accessibilityHidden(true)
            Text(text).font(Theme.font(12, .medium)).foregroundColor(color).monospacedDigit()
        }
        .accessibilityElement(children: .ignore).accessibilityLabel(text)
    }
}

struct ProgressRing: View {
    let filled: Int, total: Int
    @Environment(\.accessibilityReduceMotion) private var reduce
    var body: some View {
        let frac = total == 0 ? 0 : Double(filled) / Double(total)
        ZStack {
            Circle().stroke(Theme.borderStrong, lineWidth: 3)
            Circle().trim(from: 0, to: CGFloat(frac)).stroke(Theme.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Theme.animation(.easeOut(duration: 0.24), reduce: reduce), value: filled)
            if filled >= total && total > 0 {
                Image(systemName: "checkmark").font(Theme.font(11, .bold)).foregroundColor(Theme.accent)
            } else {
                Text("\(filled)").font(Theme.font(11, .semibold)).foregroundColor(Theme.textPrimary).monospacedDigit()
            }
        }
        .frame(width: 28, height: 28)
        .accessibilityElement(children: .ignore).accessibilityLabel("Progress")
        .accessibilityValue("\(filled) of \(total) sections filled")
    }
}

/// Day-status glyph used by sidebar rows. Shapes differ per state (never colour alone).
struct StatusGlyph: View {
    let symbol: String
    let color: Color
    var body: some View {
        Image(systemName: symbol).font(Theme.font(14)).foregroundColor(color).frame(width: 16).accessibilityHidden(true)
    }
}

struct EmptyHint: View {
    let text: String
    var body: some View {
        Text(text).font(Theme.font(12)).foregroundColor(Theme.textTertiary).padding(Theme.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
