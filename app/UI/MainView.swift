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
            }
        }
    }
}

struct DetailRouter: View {
    @ObservedObject var model: AppModel
    var body: some View {
        switch model.selection {
        case .day: DayPage(model: model, editor: model.editor).id(model.editor.day)
        case .week: WeeklyReviewView(model: model)
        case .search: SearchView(model: model)
        }
    }
}

struct WhatsNewSheet: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            Text("What's new in 0.2").font(Theme.font(22, .semibold)).foregroundColor(Theme.textPrimary)
            VStack(alignment: .leading, spacing: Theme.s2) {
                ForEach(["Skip a day without breaking your streak.", "Gentle mode and notifications.",
                         "Menu bar item, search, weekly review.", "Choose your own sections and folder."], id: \.self) { s in
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
        .padding(Theme.s8).frame(width: 440).background(Theme.surface)
    }
    private func done() { model.defaults.set(true, forKey: "dailylog.whatsNew.0.2"); model.sheet = nil }
}
