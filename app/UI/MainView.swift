// MainView.swift - NavigationSplitView: sidebar + detail routing, the unified toolbar (previous day, Today, next day, Go to
// date), sheets.
import SwiftUI

struct MainView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    private var onDay: Bool { if case .day = model.selection { return true }; return false }

    var body: some View {
        NavigationSplitView {
            SidebarView(model: model)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
        } detail: {
            DetailRouter(model: model)
                .background(Theme.bg.ignoresSafeArea())
                .toolbar {
                    ToolbarItemGroup(placement: .navigation) {
                        if onDay {
                            Button { model.step(-1) } label: { Image(systemName: "chevron.left") }
                                .help("Previous day (⌘[)").accessibilityLabel("Previous day").disabled(!model.canStep(-1))
                            Button("Today") { model.openToday() }
                                .help("Go to today (⌘T)").accessibilityLabel("Today").disabled(model.selection == .day(model.today))
                            Button { model.step(1) } label: { Image(systemName: "chevron.right") }
                                .help("Next day (⌘])").accessibilityLabel("Next day").disabled(!model.canStep(1))
                        }
                        GoToDateButton(model: model)
                    }
                }
        }
        .frame(minWidth: 860, minHeight: 600)
        .background(WindowChrome())
        .background(Button("") { model.openToday() }.keyboardShortcut("1").opacity(0).accessibilityHidden(true))   // ⌘1: Today, as in the sidebar
        .onAppear { model.openWindowAction = { openWindow(id: "main") } }
        .sheet(item: $model.sheet) { sheet in
            switch sheet {
            case .skip(let day): SkipSheet(model: model, day: day)
            case .skipMany(let days): SkipSheet(model: model, day: days.first ?? model.today, days: days)
            case .onboarding: OnboardingView(model: model)
            case .whatsNew: WhatsNewSheet(model: model)
            case .restore(let day): RestoreVersionSheet(model: model, day: day)
            }
        }
    }
}

/// Hides the window title next to the toolbar (the page shows its own date). The title string stays "Gloamlog", which is
/// how the app finds its window. Same effect as `.windowToolbarStyle(.unified(showsTitle: false))` on the scene.
struct WindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { let v = NSView(); DispatchQueue.main.async { v.window?.titleVisibility = .hidden }; return v }
    func updateNSView(_ v: NSView, context: Context) { DispatchQueue.main.async { v.window?.titleVisibility = .hidden } }
}

struct DetailRouter: View {
    @ObservedObject var model: AppModel
    var body: some View {
        switch model.selection {
        case .day: DayPage(model: model, editor: model.editor)
        case .catchUp: CatchUpView(model: model)
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
                Button("Take a look at Settings") { done(); model.openSettings() }
                    .buttonStyle(SecondaryButtonStyle())
                Button("Done") { done() }.buttonStyle(PrimaryButtonStyle()).keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.s8).frame(width: 460).background(Theme.surface)
    }
    private func done() { model.defaults.set(true, forKey: AppModel.whatsNewKey); model.sheet = nil }
}
