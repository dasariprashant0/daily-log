// SettingsPaneShortcuts.swift - Settings > Shortcuts: a read-only list of every keyboard shortcut. Each one is also a menu item.
// The list follows the keyboard map in docs/v1/UX_FLOWS.md 5.1 (M1 rows); keep it in step with AppCommands.swift.
import SwiftUI

struct ShortcutsSettings: View {
    struct ShortcutGroup: Identifiable {
        let title: String
        let items: [(name: String, keys: String)]
        var id: String { title }
    }

    static let groups: [ShortcutGroup] = [
        ShortcutGroup(title: "Go", items: [
            ("Today", "⌘1"), ("Catch Up", "⌘2"), ("Review", "⌘3"),
            ("Previous Day", "⌘["), ("Next Day", "⌘]"), ("Go to Date…", "⇧⌘T"),
        ]),
        ShortcutGroup(title: "Page", items: [
            ("Focus the Page", "⌘E"), ("Save Now", "⌘S"), ("Carry Over from Yesterday", "⇧⌘Y"),
            ("Skip Day…", "⇧⌘K"), ("Remind Me Later", "⇧⌘L"),
        ]),
        ShortcutGroup(title: "Search and copy", items: [
            ("Search Logs", "⌘F"), ("Next Search Result", "⌘G"), ("Previous Search Result", "⇧⌘G"),
            ("Copy Week as Markdown", "⇧⌘C"), ("Open Log Folder in Finder", "⇧⌘O"),
        ]),
        ShortcutGroup(title: "Settings", items: [
            ("Open Settings", "⌘,"), ("Switch pane", "← →"),
        ]),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            HStack(alignment: .top, spacing: Theme.s5) {
                VStack(alignment: .leading, spacing: Theme.s4) { card(ShortcutsSettings.groups[0]); card(ShortcutsSettings.groups[1]) }
                VStack(alignment: .leading, spacing: Theme.s4) { card(ShortcutsSettings.groups[2]); card(ShortcutsSettings.groups[3]) }
            }
            SettingsHelp("Every shortcut here is also a menu item, with the shortcut shown beside it.")
            Spacer(minLength: 0)
        }
        .padding(Theme.s5)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func card(_ g: ShortcutGroup) -> some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            Text(g.title).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary)
                .padding(.leading, Theme.s1).accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(Array(g.items.enumerated()), id: \.offset) { i, item in
                    if i > 0 { Divider().padding(.horizontal, Theme.s3) }
                    HStack(spacing: Theme.s3) {
                        Text(item.name).font(Theme.font(13)).foregroundColor(Theme.textPrimary)
                        Spacer(minLength: Theme.s3)
                        Text(item.keys).font(.system(size: 13, design: .rounded)).foregroundColor(Theme.textSecondary)
                            .accessibilityLabel(spokenShortcut(item.keys))
                    }
                    .padding(.vertical, 7).padding(.horizontal, Theme.s3)
                    .accessibilityElement(children: .combine)
                }
            }
            .background(Theme.rect(Theme.radiusLg).fill(Color.primary.opacity(0.05)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
