// RestoreVersionSheet.swift - the day's safety copies (LogStore.listBackups), newest first, with date, word count and a
// short preview. Restoring first backs the current page up (core rule), so a restore can itself be undone from this list.
import SwiftUI

final class RestoreForm: ObservableObject {
    struct Item: Identifiable {
        var id: String { info.url.lastPathComponent }
        let info: BackupInfo
        let preview: String
    }
    @Published var items: [Item] = []
    @Published var selected: String?
    @Published var error: String?
    @Published var busy = false

    func load(_ model: AppModel, day: String) {
        items = model.backups(for: day).map { info in
            let raw = (try? String(contentsOf: info.url, encoding: .utf8)) ?? ""
            let text = MarkdownBody.plainText(MarkdownFormat.parse(day: day, raw: raw).body)
            return Item(info: info, preview: String(text.prefix(120)))
        }
        selected = items.first?.id
    }
}

struct RestoreVersionSheet: View {
    @ObservedObject var model: AppModel
    let day: String
    @StateObject private var form = RestoreForm()

    private static let dayF: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEE d MMM"; return f
    }()
    /// "Mon 5 Oct, 4:30 pm" in the user's time zone (backup names are UTC stamps).
    private static func stamp(_ d: Date) -> String { "\(dayF.string(from: d)), \(Fmt.time(d))" }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            Text("Restore a previous version").font(Theme.font(22, .semibold)).foregroundColor(Theme.textPrimary).accessibilityAddTraits(.isHeader)
            Text("\(model.longDate(day)). Gloamlog keeps the last \(LogStore.maxBackupsPerDay) versions of each day. Restoring saves the current page as a version first, so you can undo it.")
                .font(Theme.font(13)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            if form.items.isEmpty {
                Text("No earlier versions yet. They appear after you change a page that was already saved.")
                    .font(Theme.font(13)).foregroundColor(Theme.textSecondary).padding(.vertical, Theme.s4)
                if let w = model.store.lastBackupWarning { Text(w).font(Theme.font(12)).foregroundColor(Theme.warning) }
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(form.items) { item in
                            let on = form.selected == item.id
                            Button { form.selected = item.id } label: {
                                HStack(alignment: .firstTextBaseline, spacing: Theme.s3) {
                                    Image(systemName: on ? "largecircle.fill.circle" : "circle").foregroundColor(on ? Theme.accent : Theme.textSecondary)
                                        .accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(Self.stamp(item.info.date)).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary)
                                            Text(Fmt.plural(item.info.words, "word")).font(Theme.font(12)).foregroundColor(Theme.textSecondary).monospacedDigit()
                                        }
                                        if !item.preview.isEmpty {
                                            Text(item.preview).font(Theme.font(12)).foregroundColor(Theme.textSecondary).lineLimit(2)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .background(Theme.rect().fill(on ? Theme.accentTint : Color.clear))
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(Self.stamp(item.info.date)), \(Fmt.plural(item.info.words, "word"))")
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                }.frame(height: min(CGFloat(form.items.count) * 56 + 4, 280))
            }
            if let e = form.error { Text(e).font(Theme.font(13)).foregroundColor(Theme.danger) }
            HStack {
                Spacer()
                Button("Cancel") { model.sheet = nil }.buttonStyle(SecondaryButtonStyle()).keyboardShortcut(.cancelAction)
                Button("Restore") { restore() }.buttonStyle(PrimaryButtonStyle()).keyboardShortcut(.defaultAction)
                    .disabled(form.selected == nil || form.busy)
            }
        }
        .padding(Theme.s8).frame(width: 520).background(Theme.surface)
        .onAppear { form.load(model, day: day) }
    }

    private func restore() {
        guard let id = form.selected, let item = form.items.first(where: { $0.id == id }) else { return }
        form.busy = true
        model.restore(item.info, day: day) { error in
            form.busy = false
            if let e = error { form.error = e } else { model.sheet = nil }
        }
    }
}
