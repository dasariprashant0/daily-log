// SessionBar.swift - the thin bar above the normal day page while catching up: "Catching up 3 of 5 · Wed 7 Oct", End, previous,
// Skip day, "Next unlogged day" (⌘↩). The page below it is the ordinary editor: one writer, nothing special to save.
import SwiftUI

struct SessionBar: View {
    @ObservedObject var model: AppModel
    let session: CatchSession
    @Environment(\.accessibilityReduceMotion) private var reduce

    var body: some View {
        let total = max(1, session.days.count)
        let done = session.days.filter { model.states[$0] == .logged || model.states[$0] == .skipped }.count
        VStack(spacing: 0) {
            HStack(spacing: Theme.s3) {
                Button("End") { model.endSession() }
                    .buttonStyle(TextButtonStyle(color: Theme.textSecondary)).help("Back to the list")
                    .accessibilityLabel("End catching up")
                Text(session.note ?? "Catching up \(session.position) of \(total) · \(model.shortDate(session.current))")
                    .font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary).monospacedDigit().lineLimit(1)
                    .accessibilityHidden(true)
                Spacer(minLength: Theme.s2)
                Button { model.previousSessionDay() } label: {
                    Image(systemName: "chevron.left").font(Theme.font(12, .semibold)).frame(width: 28, height: 28).contentShape(Rectangle())
                }
                .buttonStyle(.plain).foregroundColor(session.position > 1 ? Theme.textSecondary : Theme.textTertiary)
                .disabled(session.position <= 1).help("Previous day in this run").accessibilityLabel("Previous day in this run")
                Button("Skip day") { model.requestSkip(day: session.current) }.buttonStyle(SecondaryButtonStyle())
                    .help("Skip \(model.shortDate(session.current))…")
                Button { model.nextUnloggedDay() } label: {
                    HStack(spacing: 6) {
                        Text("Next unlogged day")
                        Text("⌘↩").font(Theme.font(12)).opacity(0.8)
                    }
                }
                .buttonStyle(PrimaryButtonStyle()).help("Open the next unlogged day (⌘↩)")
                .accessibilityLabel("Next unlogged day")
                .background(Button("") { model.nextUnloggedDay() }.keyboardShortcut(.downArrow, modifiers: [.command, .option]).opacity(0).accessibilityHidden(true))
            }
            .padding(.horizontal, Theme.s4).frame(height: Theme.sessionBarH)
            ZStack(alignment: .leading) {
                Rectangle().fill(Theme.border)
                GeometryReader { geo in
                    Rectangle().fill(Theme.accent).frame(width: geo.size.width * CGFloat(done) / CGFloat(total))
                        .animation(Theme.animation(.easeOut(duration: 0.2), reduce: reduce), value: done)
                }
            }.frame(height: 3)
        }
        .background(Theme.sidebar)
        .clipShape(Theme.rect(Theme.radiusLg))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Catching up, \(session.position) of \(total)")
    }
}
