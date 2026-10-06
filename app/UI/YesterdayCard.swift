// YesterdayCard.swift - continuity card on Today: last logged day's To do next / Pending, with carry-over.
import SwiftUI

struct YesterdayCard: View {
    @ObservedObject var model: AppModel

    var body: some View {
        if let c = model.carryCard {
            let heading = CarryOver.heading(for: c, today: model.today, calendar: model.cal)
            VStack(alignment: .leading, spacing: Theme.s3) {
                if model.carried && !model.carryExpanded {
                    HStack(spacing: Theme.s2) {
                        Image(systemName: "checkmark").font(Theme.font(11, .bold)).foregroundColor(Theme.accentText).accessibilityHidden(true)
                        Text("\(heading): carried over.").font(Theme.font(13)).foregroundColor(Theme.textSecondary)
                        Button("Show") { model.carryExpanded = true }.buttonStyle(TextButtonStyle())
                        if model.carryUndo != nil { Button("Undo") { model.undoCarry() }.buttonStyle(TextButtonStyle()) }
                        Spacer()
                    }
                } else {
                    HStack {
                        Text(heading).font(Theme.font(13, .semibold)).foregroundColor(Theme.textSecondary)
                        Text(c.sourceLabel).font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                        Spacer()
                        if model.carried {
                            Text("Carried ✓").font(Theme.font(13, .semibold)).foregroundColor(Theme.accentText)
                            if model.carryUndo != nil { Button("Undo") { model.undoCarry() }.buttonStyle(TextButtonStyle()) }
                        }
                    }
                    if !c.todo.isEmpty { Block(label: "To do next", text: c.todo) }
                    if !c.pending.isEmpty { Block(label: "Pending / blocked", text: c.pending) }
                    HStack(spacing: Theme.s3) {
                        Spacer()
                        carryControl
                        Button("Hide") { model.hideCarry() }.buttonStyle(TextButtonStyle(color: Theme.textSecondary))
                            .accessibilityLabel("Hide Yesterday card")
                    }
                }
            }
            .padding(Theme.s4).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.rect(Theme.radiusLg).fill(Theme.sidebar))
            .overlay(Theme.rect(Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
            .padding(.top, Theme.s6)
            .accessibilityElement(children: .contain).accessibilityLabel("Yesterday's plan")
        }
    }

    private var carryControl: some View {
        let target = model.sectionTitle(model.carryTargetID)
        return Menu {
            ForEach(model.settings.sections) { s in
                Button("Carry over to \(s.displayTitle)") { model.carryOver(into: s.id) }
            }
        } label: { Text("Carry over to \(target)").font(Theme.font(13, .semibold)) } primaryAction: { model.carryOver() }
        .menuStyle(.borderedButton).fixedSize()
        .accessibilityLabel("Carry over to \(target)")
    }

    private struct Block: View {
        let label: String, text: String
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).font(Theme.font(12, .semibold)).foregroundColor(Theme.textSecondary)
                ClampedText(text: text, lines: 6, font: Theme.font(14), color: Theme.textPrimary)
            }
        }
    }
}

/// Selectable text clamped to N lines with Show more / Show less (heuristic: long or many-line text offers it).
struct ClampedText: View {
    let text: String, lines: Int, font: Font, color: Color
    @StateObject private var open = Box(false)
    var body: some View {
        let long = text.components(separatedBy: "\n").count > lines || text.count > lines * 70
        VStack(alignment: .leading, spacing: 4) {
            Text(text).font(font).foregroundColor(color).lineSpacing(2)
                .lineLimit(open.value ? nil : lines).textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            if long { Button(open.value ? "Show less" : "Show more") { open.value.toggle() }.buttonStyle(TextButtonStyle()) }
        }
    }
}
