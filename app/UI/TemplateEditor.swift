// TemplateEditor.swift - Settings > Page: the words-to-log rule, the new-day template (plain markdown) and the headings
// that "From yesterday" carries over. Also the template presets used by onboarding.
import SwiftUI

enum TemplatePreset: String, CaseIterable, Identifiable {
    case dailyReview, standup, blank
    var id: String { rawValue }
    var title: String {
        switch self { case .dailyReview: return "Daily review"; case .standup: return "Standup"; case .blank: return "Blank page" }
    }
    var detail: String {
        switch self {
        case .dailyReview: return "Five prompts for the end of the day."
        case .standup: return "What moved, what's next, what's stuck."
        case .blank: return "An empty page. Add headings as you go."
        }
    }
    var markdown: String {
        switch self {
        case .dailyReview: return Settings.defaultTemplate
        case .standup: return "## Yesterday\n\n## Today\n\n## Blockers"
        case .blank: return ""
        }
    }
    var carryOverHeadings: [String] {
        switch self {
        case .standup: return ["Today", "Blockers"]
        default: return Settings.defaultCarryOverHeadings
        }
    }
    /// Short preview lines for the picker cards.
    var preview: [String] {
        switch self {
        case .dailyReview: return ["What I did", "Finished", "Started", "Pending / blocked", "To do next"]
        case .standup: return ["Yesterday", "Today", "Blockers"]
        case .blank: return []
        }
    }
    var isDefault: Bool { self == .dailyReview }
}

struct PageSettings: View {
    @ObservedObject var model: AppModel
    var body: some View {
        Form {
            Section {
                WordsRuleRow(minWords: $model.settings.minWords)
                Text("Headings, empty list items and images don't count as words.")
                    .font(Theme.font(12)).foregroundColor(Theme.textSecondary)
            }
            Section("New day template") { TemplateEditor(model: model) }
            Section("Carried over from yesterday") { CarryHeadingsEditor(model: model) }
        }
        .formStyle(.grouped)
    }
}

/// "A day counts as logged after [ 20 ] words", 1...500.
struct WordsRuleRow: View {
    @Binding var minWords: Int
    var body: some View {
        HStack(spacing: Theme.s2) {
            Text("A day counts as logged after")
            Spacer()
            TextField("", value: $minWords, format: .number).textFieldStyle(.roundedBorder).multilineTextAlignment(.trailing)
                .frame(width: 56).accessibilityLabel("Words to log a day")
            Stepper("", value: $minWords, in: Settings.minWordsRange).labelsHidden()
            Text("words")
        }
    }
}

struct TemplateEditor: View {
    @ObservedObject var model: AppModel
    @StateObject private var text = Box("")
    @StateObject private var work = Box<DispatchWorkItem?>(nil)

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            HStack {
                Menu("Start from…") {
                    ForEach(TemplatePreset.allCases) { p in Button(p.title) { apply(p) } }
                }.fixedSize()
                Spacer()
                Button("Reset to default") { apply(.dailyReview) }
                    .disabled(model.settings.template == Settings.defaultTemplate && model.settings.carryOverHeadings == Settings.defaultCarryOverHeadings)
            }
            TextEditor(text: $text.value)
                .font(.system(size: 12, design: .monospaced)).foregroundColor(Theme.textPrimary)
                .scrollContentBackground(.hidden).padding(6).frame(height: 150)
                .background(Theme.rect(Theme.radiusMd).fill(Theme.surface))
                .overlay(Theme.rect(Theme.radiusMd).stroke(Theme.borderStrong, lineWidth: 1))
                .accessibilityLabel("New day template, markdown")
            Text("Pre-filled into a new day's page. Nothing is saved until you start writing. Use ## for headings, - [ ] for to-dos.")
                .font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { text.value = model.settings.template }
        .onChange(of: text.value) { v in
            work.value?.cancel()
            let w = DispatchWorkItem { if model.settings.template != v { model.settings.template = v } }
            work.value = w
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: w)
        }
    }

    private func apply(_ p: TemplatePreset) {
        work.value?.cancel()
        text.value = p.markdown
        model.settings.template = p.markdown
        model.settings.carryOverHeadings = p.carryOverHeadings
    }
}

struct CarryHeadingsEditor: View {
    struct Item: Identifiable, Equatable { let id = UUID(); var text: String }
    @ObservedObject var model: AppModel
    @StateObject private var items = Box<[Item]>([])

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            ForEach($items.value) { $item in
                HStack {
                    TextField("", text: $item.text, prompt: Text("Heading")).labelsHidden().textFieldStyle(.roundedBorder).multilineTextAlignment(.leading).accessibilityLabel("Heading to carry over")
                    Button { items.value.removeAll { $0.id == item.id } } label: { Image(systemName: "minus.circle") }
                        .buttonStyle(.plain).foregroundColor(Theme.textSecondary).help("Remove").accessibilityLabel("Remove \(item.text)")
                }
            }
            HStack {
                Button { items.value.append(Item(text: "")) } label: { Label("Add heading", systemImage: "plus") }
                Spacer()
            }
            Text("From yesterday offers the lines written under these headings (a heading's case and emoji don't matter).")
                .font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { items.value = model.settings.carryOverHeadings.map { Item(text: $0) } }
        .onChange(of: items.value) { v in
            let list = v.map { $0.text }
            if list != model.settings.carryOverHeadings { model.settings.carryOverHeadings = list }
        }
    }
}
