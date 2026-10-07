// MainView.swift - NavigationSplitView: sidebar + detail routing, sheets.
import SwiftUI

struct MainView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            DetailRouter(model: model)
                .background(Theme.bg.ignoresSafeArea())
        }
        .frame(minWidth: 860, minHeight: 600)
        .onAppear { model.openWindowAction = { openWindow(id: "main") } }
        .sheet(item: $model.sheet) { sheet in
            switch sheet {
            case .skip(let day): SkipSheet(model: model, day: day)
            case .onboarding: OnboardingView(model: model)
            case .whatsNew: WhatsNewSheet(model: model)
            case .restore(let day): RestoreVersionSheet(model: model, day: day)
            }
        }
    }
}

struct DetailRouter: View {
    @ObservedObject var model: AppModel
    var body: some View {
        switch model.selection {
        case .day: DayPage(model: model, editor: model.editor)
        case .week: WeeklyReviewView(model: model)
        case .search: SearchView(model: model)
        }
    }
}

struct WhatsNewSheet: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            Text("What's new in 0.3").font(Theme.font(22, .semibold)).foregroundColor(Theme.textPrimary)
            VStack(alignment: .leading, spacing: Theme.s2) {
                ForEach(["One page per day: headings, lists, to-dos and images.", "It saves as you write. There is no Save button.",
                         "Your five prompts are now a template you can edit in Settings.",
                         "Earlier versions of each day are kept, so nothing is lost."], id: \.self) { s in
                    HStack(alignment: .firstTextBaseline, spacing: Theme.s2) {
                        Image(systemName: "checkmark").font(Theme.font(11, .bold)).foregroundColor(Theme.accent).accessibilityHidden(true)
                        Text(s).font(Theme.font(13)).foregroundColor(Theme.textPrimary)
                    }
                }
            }
            HStack {
                Spacer()
                Button("Take a look at Settings") { done(); NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Done") { done() }.buttonStyle(PrimaryButtonStyle()).keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.s8).frame(width: 460).background(Theme.surface)
    }
    private func done() { model.defaults.set(true, forKey: AppModel.whatsNewKey); model.sheet = nil }
}
