// Onboarding.swift - first-run sheet, 3 steps. Everything is pre-filled; the login item is opt-in (unticked).
//   1 Welcome + the page template   2 Reminder + words to log a day   3 Folder + login item
import SwiftUI
import AppKit

final class OnboardingState: ObservableObject {
    enum FolderChoice: Hashable { case local, icloud, custom }
    @Published var step = 1
    @Published var template = TemplatePreset.dailyReview
    @Published var minutes: Int
    @Published var days: Set<Int>
    @Published var mode: ReminderMode
    @Published var minWords: Int
    @Published var choice = FolderChoice.local
    @Published var customURL: URL?
    @Published var login = false
    init(_ s: Settings) { minutes = s.reminderMinutes; days = s.weekdays; mode = s.mode; minWords = s.minWords }
    static var iCloudFolder: URL? {
        let base = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        return FileManager.default.fileExists(atPath: base.path) ? base.appendingPathComponent("Gloamlog") : nil
    }
}

struct OnboardingView: View {
    @ObservedObject var model: AppModel
    @StateObject private var st: OnboardingState
    @Environment(\.accessibilityReduceMotion) private var reduce

    init(model: AppModel, startStep: Int = 1) {
        self.model = model
        _st = StateObject(wrappedValue: { let s = OnboardingState(Settings()); s.step = startStep; return s }())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { i in Capsule().fill(i <= st.step ? Theme.accent : Theme.border).frame(width: 28, height: 4) }
                }.accessibilityElement(children: .ignore).accessibilityLabel("Step \(st.step) of 3")
                Spacer()
                if st.step == 1 { Button("Skip setup") { finish(useDefaults: true) }.buttonStyle(TextButtonStyle(color: Theme.textSecondary)) }
            }
            Group {
                switch st.step {
                case 1: welcome
                case 2: reminder
                default: folder
                }
            }.padding(.top, Theme.s6).frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: Theme.s4)
            HStack {
                if st.step > 1 { Button("Back") { go(st.step - 1) }.buttonStyle(TextButtonStyle(color: Theme.textSecondary)) }
                Spacer()
                Button(st.step == 3 ? "Start writing" : "Continue") { next() }.buttonStyle(PrimaryButtonStyle()).keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.s10).frame(width: 600, height: 520).background(Theme.surface)
        .interactiveDismissDisabled()
        .onAppear { let s = model.settings; st.minutes = s.reminderMinutes; st.days = s.weekdays; st.mode = s.mode; st.minWords = s.minWords }
    }

    private func go(_ n: Int) { withAnimation(Theme.animation(.easeInOut(duration: 0.2), reduce: reduce)) { st.step = n } }
    private func next() {
        if st.step == 2 { Notifier.shared.requestAuthorization { _ in Notifier.shared.refreshState { s in model.notifState = s } } }
        if st.step < 3 { go(st.step + 1) } else { finish(useDefaults: false) }
    }

    private func headline(_ t: String) -> some View {
        Text(t).font(Theme.font(28, .semibold)).tracking(-0.4).foregroundColor(Theme.textPrimary).accessibilityAddTraits(.isHeader)
    }
    private func note(_ t: String) -> some View {
        Text(t).font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
    }

    // MARK: 1 welcome + template
    private var welcome: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            headline("Write up your day, every day.")
            Text("Each day gets one page. Write freely, with headings, lists, to-dos and images, or start from a few prompts.")
                .font(Theme.font(15)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            Text("Start your page with").font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary).padding(.top, Theme.s2)
            HStack(alignment: .top, spacing: Theme.s3) {
                ForEach(TemplatePreset.allCases) { p in templateCard(p) }
            }
            note("Your pages are plain markdown files you own. Nothing leaves your Mac. You can change the template any time in Settings.")
        }
    }

    private func templateCard(_ p: TemplatePreset) -> some View {
        let on = st.template == p
        return Button { st.template = p } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: on ? "largecircle.fill.circle" : "circle").foregroundColor(on ? Theme.accent : Theme.textSecondary)
                    Text(p.title).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary)
                }
                Text(p.detail).font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 2)
                if p.preview.isEmpty {
                    Text("(empty)").font(.system(size: 11, design: .monospaced)).foregroundColor(Theme.textTertiary)
                } else {
                    VStack(alignment: .leading, spacing: 1) {
                        ForEach(p.preview.prefix(5), id: \.self) { l in
                            Text("## \(l)").font(.system(size: 11, design: .monospaced)).foregroundColor(Theme.textSecondary).lineLimit(1)
                        }
                    }
                }
            }
            .padding(Theme.s3).frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
            .background(Theme.rect(Theme.radiusLg).fill(on ? Theme.accentTint : Theme.surface))
            .overlay(Theme.rect(Theme.radiusLg).stroke(on ? Theme.accent : Theme.borderStrong, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain).accessibilityLabel("\(p.title). \(p.detail)").accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: 2 reminder
    private var reminder: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            headline("When should we ask?")
            HStack(spacing: Theme.s4) {
                DatePicker("Time", selection: Binding(
                    get: { model.cal.date(bySettingHour: st.minutes / 60, minute: st.minutes % 60, second: 0, of: model.now) ?? model.now },
                    set: { d in let c = model.cal.dateComponents([.hour, .minute], from: d); st.minutes = (c.hour ?? 16) * 60 + (c.minute ?? 55) }),
                           displayedComponents: .hourAndMinute).fixedSize()
                WeekdayToggles(days: Binding(get: { st.days }, set: { st.days = $0 }), cal: model.cal)
            }
            Text("How firm?").font(Theme.font(15, .semibold)).foregroundColor(Theme.textPrimary).padding(.top, Theme.s2)
            HStack(spacing: Theme.s3) {
                modeCard(.strict, "Strict", "Comes to the front until you save or skip the day.")
                modeCard(.gentle, "Gentle", "One notification. You decide when.")
            }
            WordsRuleRow(minWords: $st.minWords).padding(.top, Theme.s2)
            note("A day counts once the page has this many words. You can always skip a day or snooze. Change all of this later in Settings.")
        }
    }

    private func modeCard(_ m: ReminderMode, _ title: String, _ body: String) -> some View {
        let on = st.mode == m
        return Button { st.mode = m } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: on ? "largecircle.fill.circle" : "circle").foregroundColor(on ? Theme.accent : Theme.textSecondary)
                    Text(title).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary)
                }
                Text(body).font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
            .padding(Theme.s3).frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
            .background(Theme.rect(Theme.radiusLg).fill(on ? Theme.accentTint : Theme.surface))
            .overlay(Theme.rect(Theme.radiusLg).stroke(on ? Theme.accent : Theme.borderStrong, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain).accessibilityLabel("\(title). \(body)").accessibilityAddTraits(on ? .isSelected : [])
    }

    // MARK: 3 folder
    private var folder: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            headline("Where should logs live?")
            VStack(alignment: .leading, spacing: Theme.s2) {
                Picker("", selection: $st.choice) {
                    Text("On this Mac: ~/Gloamlog").tag(OnboardingState.FolderChoice.local)
                    if OnboardingState.iCloudFolder != nil { Text("iCloud Drive: Gloamlog").tag(OnboardingState.FolderChoice.icloud) }
                    Text(st.customURL.map { "Another folder: " + ($0.path as NSString).abbreviatingWithTildeInPath } ?? "Another folder…").tag(OnboardingState.FolderChoice.custom)
                }.pickerStyle(.radioGroup).labelsHidden()
                .onChange(of: st.choice) { c in if c == .custom { chooseCustom() } }
                if st.choice == .custom { Button("Choose…") { chooseCustom() }.buttonStyle(SecondaryButtonStyle()) }
            }
            note("Pick iCloud Drive or Dropbox to keep logs on every Mac. Images you add live next to your pages in an assets folder.")
            Toggle("Open Gloamlog at login", isOn: $st.login).toggleStyle(.checkbox)
            note("So the reminder can fire after a restart. You can change this in Settings.")
        }
    }

    private func chooseCustom() {
        let p = NSOpenPanel(); p.canChooseDirectories = true; p.canChooseFiles = false; p.canCreateDirectories = true; p.prompt = "Choose"
        if p.runModal() == .OK, let u = p.url { st.customURL = u } else if st.customURL == nil { st.choice = .local }
    }

    private func finish(useDefaults: Bool) {
        var s = model.settings
        if !useDefaults {
            s.reminderMinutes = st.minutes; s.weekdays = st.days.isEmpty ? [2, 3, 4, 5, 6] : st.days; s.mode = st.mode
            s.minWords = st.minWords
            s.template = st.template.markdown; s.carryOverHeadings = st.template.carryOverHeadings
            switch st.choice {
            case .local: s.storageFolder = Settings.defaultFolder
            case .icloud: s.storageFolder = OnboardingState.iCloudFolder ?? Settings.defaultFolder
            case .custom: s.storageFolder = st.customURL ?? Settings.defaultFolder
            }
        } else {
            s.template = st.template.markdown; s.carryOverHeadings = st.template.carryOverHeadings
        }
        s.onboarded = true
        if s.storageFolder != model.settings.storageFolder { model.store = AppModel.makeStore(dir: s.storageFolder, backupDir: model.backupDir) }
        model.settings = s
        try? model.store.ensureFolder()
        if !useDefaults && st.login { model.setLogin(true) }
        if useDefaults { Notifier.shared.requestAuthorization { _ in Notifier.shared.refreshState { s in model.notifState = s } } }
        model.defaults.set(true, forKey: AppModel.whatsNewKey)
        model.planner = model.planner.suppressed(until: model.clock().addingTimeInterval(ReminderPlanner.graceAfterLaunch))
        model.reload()
        model.sheet = nil
        model.openDay(model.today, focus: true, force: true)     // a fresh page with the chosen template, cursor in it
    }
}
