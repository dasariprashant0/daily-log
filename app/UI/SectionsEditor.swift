// SectionsEditor.swift - add / rename / reorder / remove sections. Edits a local copy and commits only valid lists,
// so a half-typed empty name never resets anything.
import SwiftUI
import AppKit

final class SectionsDraft: ObservableObject {
    @Published var list: [SectionDef]
    @Published var error: String?
    init(_ l: [SectionDef]) { list = l }
}

struct SectionsEditor: View {
    @ObservedObject var model: AppModel
    @StateObject private var draft = SectionsDraft([])

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            List {
                ForEach($draft.list) { $s in
                    SectionRow(section: $s, onRemove: { remove(s) }, canRemove: draft.list.count > 1)
                }
                .onMove { from, to in draft.list.move(fromOffsets: from, toOffset: to); commit() }
            }
            .frame(minHeight: 230).listStyle(.inset(alternatesRowBackgrounds: false))
            HStack {
                Button { add() } label: { Label("Add section", systemImage: "plus") }.disabled(draft.list.count >= 10)
                Spacer()
                Button("Reset to default") { draft.list = DefaultSections.all; commit() }
            }
            if let e = draft.error { Text(e).font(Theme.font(12)).foregroundColor(Theme.danger) }
            Text("Every section is required when you save. 1 to 10 sections. Past logs keep the old name and still open fine.")
                .font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.s4)
        .onAppear { draft.list = model.settings.sections }
        .onChange(of: draft.list) { _ in commit() }
    }

    private func commit() {
        draft.error = SectionDef.validationError(draft.list)
        if draft.error == nil, draft.list != model.settings.sections { model.settings.sections = draft.list }
    }
    private func add() {
        var n = 1; while draft.list.contains(where: { $0.title.lowercased() == "new section \(n)" }) { n += 1 }
        draft.list.append(SectionDef(title: "New section \(n)"))
    }
    private func remove(_ s: SectionDef) {
        let a = NSAlert()
        a.messageText = "Remove \"\(s.displayTitle)\"?"
        a.informativeText = "New logs won't have this section. What you already wrote stays in your files and in past days."
        a.addButton(withTitle: "Remove section"); a.addButton(withTitle: "Keep section")
        if a.runModal() == .alertFirstButtonReturn { draft.list.removeAll { $0.id == s.id } }
    }
}

private struct SectionRow: View {
    @Binding var section: SectionDef
    let onRemove: () -> Void
    let canRemove: Bool
    @StateObject private var hintOpen = Box(false)
    var body: some View {
        HStack(spacing: Theme.s2) {
            Image(systemName: "line.3.horizontal").foregroundColor(Theme.textTertiary).accessibilityHidden(true)
            TextField("Section name", text: $section.title).textFieldStyle(.plain).font(Theme.font(13))
                .accessibilityLabel("Section name")
            Spacer()
            Button { hintOpen.value = true } label: { Image(systemName: "pencil") }
                .buttonStyle(.plain).help("Edit hint").accessibilityLabel("Edit hint for \(section.displayTitle)")
                .popover(isPresented: Binding(get: { hintOpen.value }, set: { hintOpen.value = $0 })) {
                    VStack(alignment: .leading, spacing: Theme.s2) {
                        Text("Hint").font(Theme.font(13, .semibold))
                        TextField("Shown while the section is empty", text: $section.hint).frame(width: 280)
                    }.padding(Theme.s4)
                }
            Button(action: onRemove) { Image(systemName: "trash") }
                .buttonStyle(.plain).disabled(!canRemove).help(canRemove ? "Remove section" : "Keep at least one section")
                .accessibilityLabel("Remove \(section.displayTitle)")
        }
        .padding(.vertical, 2)
    }
}
