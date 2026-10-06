// Onboarding.swift - first-run sheet, 3 steps. Everything is pre-filled; the login item is opt-in (unticked).
import SwiftUI
import AppKit

final class OnboardingState: ObservableObject {
    enum FolderChoice: Hashable { case local, icloud, custom }
    @Published var step = 1
    @Published var minutes: Int
    @Published var days: Set<Int>
    @Published var mode: ReminderMode
    @Published var choice = FolderChoice.local
    @Published var customURL: URL?
    @Published var login = false
    init(_ s: Settings) { minutes = s.reminderMinutes; days = s.weekdays; mode = s.mode }
    static var iCloudFolder: URL? {
        let base = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
        return FileManager.default.fileExists(atPath: base.path) ? base.appendingPathComponent("DailyLog") : nil
    }
}

struct OnboardingView: View {
    @ObservedObject var model: AppModel
    @StateObject private var st = OnboardingState(Settings())
    @Environment(\.accessibilityReduceMotion) private var reduce

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
            }.padding(.top, Theme.s8).frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: Theme.s4)
            HStack {
                if st.step > 1 { Button("Back") { go(st.step - 1) }.buttonStyle(TextButtonStyle(color: Theme.textSecondary)) }
                Spacer()
                Button(st.step == 3 ? "Start logging" : "Continue") { next() }.buttonStyle(PrimaryButtonStyle()).keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.s10).frame(width: 560, height: 480).background(Theme.surface)
        .interactiveDismissDisabled()
        .onAppear { st.minutes = model.settings.reminderMinutes; st.days = model.settings.weekdays; st.mode = model.settings.mode }
    }

    private func go(_ n: Int) { withAnimation(Theme.animation(.easeInOut(duration: 0.2), reduce: reduce)) { st.step = n } }
    private func next() {
        if st.step == 2 { Notifier.shared.requestAuthorization { _ in Notifier.shared.refreshState { s in model.notifState = s } } }
        if st.step < 3 { go(st.step + 1) } else { finish(useDefaults: false) }
    }

    private func headline(_ t: String) -> some View {
        Text(t).font(Theme.font(28, .semibold)).tracking(-0.4).foregroundColor(Theme.textPrimary).accessibilityAddTraits(.isHeader)
    }
    private func bullet(_ t: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.s2) {
            Image(systemName: "checkmark").font(Theme.font(11, .bold)).foregroundColor(Theme.accent).accessibilityHidden(true)
            Text(t).font(Theme.font(14)).foregroundColor(Theme.textPrimary)
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            headline("Write up your day, every day.")
            Text("At a time you choose, Daily Log asks five short questions: what you did, what's done, what you started, what's stuck, and what's next.")
                .font(Theme.font(15)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: Theme.s2) {
                bullet("Your logs are plain markdown files you own.")
                bullet("Nothing leaves your Mac. No account, no tracking.")
            }
        }
    }

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
            Text("You can always skip a day or snooze. Change this later in Settings.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
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
            .padding(Theme.s3).frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
            .background(Theme.rect(Theme.radiusLg).fill(on ? Theme.accentTint : Theme.surface))
            .overlay(Theme.rect(Theme.radiusLg).stroke(on ? Theme.accent : Theme.borderStrong, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain).accessibilityLabel("\(title). \(body)").accessibilityAddTraits(on ? .isSelected : [])
    }

    private var folder: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            headline("Where should logs live?")
            VStack(alignment: .leading, spacing: Theme.s2) {
                Picker("", selection: $st.choice) {
                    Text("On this Mac: ~/daily-log").tag(OnboardingState.FolderChoice.local)
                    if OnboardingState.iCloudFolder != nil { Text("iCloud Drive: DailyLog").tag(OnboardingState.FolderChoice.icloud) }
                    Text(st.customURL.map { "Another folder: " + ($0.path as NSString).abbreviatingWithTildeInPath } ?? "Another folder…").tag(OnboardingState.FolderChoice.custom)
                }.pickerStyle(.radioGroup).labelsHidden()
                .onChange(of: st.choice) { c in if c == .custom { chooseCustom() } }
                if st.choice == .custom { Button("Choose…") { chooseCustom() }.buttonStyle(SecondaryButtonStyle()) }
            }
            Text("Pick iCloud Drive or Dropbox to keep logs on every Mac.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
            Toggle("Open Daily Log at login", isOn: $st.login).toggleStyle(.checkbox)
            Text("So the reminder can fire after a restart. You can change this in Settings.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
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
            switch st.choice {
            case .local: s.storageFolder = Settings.defaultFolder
            case .icloud: s.storageFolder = OnboardingState.iCloudFolder ?? Settings.defaultFolder
            case .custom: s.storageFolder = st.customURL ?? Settings.defaultFolder
            }
        }
        s.onboarded = true
        if s.storageFolder != model.settings.storageFolder { model.store = LogStore(dir: s.storageFolder, sections: s.sections) }
        model.settings = s
        try? model.store.ensureFolder()
        if !useDefaults && st.login { model.setLogin(true) }
        if useDefaults { Notifier.shared.requestAuthorization { _ in Notifier.shared.refreshState { s in model.notifState = s } } }
        model.planner = model.planner.suppressed(until: model.clock().addingTimeInterval(ReminderPlanner.graceAfterLaunch))
        model.reload()
        model.editor = DayEditor(day: model.today, model: model)
        model.sheet = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { model.focusFirstEmpty() }
    }
}
