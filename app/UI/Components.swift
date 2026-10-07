// Components.swift - banners and small shared pieces.
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

/// Day-status glyph used by sidebar rows. Shapes differ per state (never colour alone).
struct StatusGlyph: View {
    let symbol: String
    let color: Color
    var body: some View {
        Image(systemName: symbol).font(Theme.font(14)).foregroundColor(color).frame(width: 16).accessibilityHidden(true)
    }
}

/// The one mark vocabulary (DESIGN_V4 principle 5), used by the calendar, the week tiles and the heat map: filled disc =
/// logged, half disc = started, hollow ring = not written, dash = skipped. Shape carries the meaning, hue only helps.
/// Nothing for days off and days to come. `onFill` redraws it for the selected day's accent fill.
struct DayMark: View {
    let status: DayStatus
    var size: CGFloat = Theme.calMark
    var onFill = false
    var showsMissed = true               // today never wears the amber ring
    var body: some View {
        ZStack {
            switch status {
            case .logged: Circle().fill(onFill ? Theme.onAccent : Theme.accent).frame(width: size, height: size)
            case .partial:
                Image(systemName: "circle.lefthalf.filled").font(.system(size: size + 1.5))
                    .foregroundColor(onFill ? Theme.onAccent : Theme.textSecondary)
            case .missed:
                if showsMissed { Circle().strokeBorder(onFill ? Theme.onAccent : Theme.warning, lineWidth: 1.25).frame(width: size, height: size) }
            case .skipped: Capsule().fill(onFill ? Theme.onAccent : Theme.textTertiary).frame(width: size + 1, height: 1.5)
            case .off, .future: EmptyView()
            }
        }
        .frame(width: size + 2, height: size + 2)
        .accessibilityHidden(true)
    }
}

struct EmptyHint: View {
    let text: String
    var body: some View {
        Text(text).font(Theme.font(12)).foregroundColor(Theme.textTertiary).padding(Theme.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
