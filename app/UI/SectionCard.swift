// SectionCard.swift - one section: gutter check, label, auto-growing TextEditor, "Nothing to report".
import SwiftUI

/// Snapshot harness flips this to draw static text instead of the AppKit-backed TextEditor.
struct SnapshotModeKey: EnvironmentKey { static let defaultValue = false }
extension EnvironmentValues { var snapshotMode: Bool { get { self[SnapshotModeKey.self] } set { self[SnapshotModeKey.self] = newValue } } }

struct GutterMark: View {
    let filled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduce
    var body: some View {
        ZStack {
            Circle().stroke(Theme.borderStrong, lineWidth: 1.5).opacity(filled ? 0 : 1)
            Circle().fill(Theme.accent).scaleEffect(filled ? 1 : 0.6).opacity(filled ? 1 : 0)
            Image(systemName: "checkmark").font(Theme.font(10, .bold)).foregroundColor(Theme.onAccent).opacity(filled ? 1 : 0)
        }
        .frame(width: 20, height: 20)
        .animation(Theme.animation(.easeOut(duration: 0.16), reduce: reduce), value: filled)
        .accessibilityHidden(true)
    }
}

struct SectionCard: View {
    let title: String
    let hint: String
    let required: Bool
    let muted: Bool                 // retired section label
    @Binding var text: String
    var focusID: String
    var focus: FocusState<String?>.Binding
    var onNothing: (() -> Void)?

    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.snapshotMode) private var snapshot
    private var filled: Bool { !text.dlTrimmed.isEmpty }
    private var focused: Bool { focus.wrappedValue == focusID }

    var body: some View {
        HoverReader { hovering in
            VStack(alignment: .leading, spacing: Theme.s3) {
                HStack(spacing: Theme.s2) {
                    GutterMark(filled: filled)
                    Text(title).font(Theme.font(15, .semibold)).foregroundColor(Theme.textPrimary)
                    if muted { Text("Retired section").font(Theme.font(11)).foregroundColor(Theme.textSecondary) }
                    Spacer()
                    if !filled, let n = onNothing {
                        Button("Nothing to report") { n() }
                            .buttonStyle(TextButtonStyle(color: Theme.textSecondary))
                            .accessibilityLabel("Insert \"Nothing\" in \(title)")
                    }
                }
                editor
            }
            .padding(.horizontal, Theme.s4).padding(.top, Theme.s4).padding(.bottom, 14)
            .background(Theme.rect(Theme.radiusLg).fill(Theme.surface))
            .overlay(Theme.rect(Theme.radiusLg).stroke(focused ? Theme.accent : (hovering || contrast == .increased ? Theme.borderStrong : Theme.border),
                                                       lineWidth: focused ? 1.5 : 1))
            .background(Theme.rect(Theme.radiusLg + 2).stroke(focused ? Theme.accent.opacity(0.3) : Color.clear, lineWidth: 3).padding(-1.5))
        }
    }

    @ViewBuilder private var editor: some View {
        let font = Theme.font(15)
        if snapshot {
            Text(text.isEmpty ? hint : text).font(font).lineSpacing(4)
                .foregroundColor(text.isEmpty ? Theme.textSecondary : Theme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading).padding(.horizontal, 5)
        } else {
            ZStack(alignment: .topLeading) {
                // Hidden twin drives the height so the card grows with its text (max 360, then scrolls).
                Text(text + "\n").font(font).lineSpacing(4).opacity(0).padding(.horizontal, 5).frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
                TextEditor(text: $text)
                    .font(font).lineSpacing(4).foregroundColor(Theme.textPrimary)
                    .scrollContentBackground(.hidden).focused(focus, equals: focusID)
                    .accessibilityLabel(title).accessibilityHint(required ? "Required. Text area." : "Text area.")
                if text.isEmpty {
                    Text(hint).font(font).foregroundColor(Theme.textSecondary).padding(.leading, 5).allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 84, maxHeight: 360)
        }
    }
}
