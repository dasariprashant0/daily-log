// PageView.swift - the day page: banners, header (date + streak chip), Yesterday card, section cards, save bar.
import SwiftUI

struct DayPage: View {
    @ObservedObject var model: AppModel
    @ObservedObject var editor: DayEditor
    @FocusState private var focus: String?

    var body: some View {
        VStack(spacing: 0) {
            if editor.isSkipped && !editor.writingAnyway {
                ScrollView { Column { PageHeader(model: model, editor: editor); SkippedBody(model: model, editor: editor) } }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        Column {
                            PageBanners(model: model, editor: editor)
                            PageHeader(model: model, editor: editor)
                            if editor.day == model.today { YesterdayCard(model: model) }
                            VStack(spacing: Theme.s4) {
                                ForEach(editor.sections) { s in
                                    SectionCard(title: s.displayTitle, hint: s.hint, required: s.required, muted: false,
                                                text: Binding(get: { editor.text(s.id) }, set: { editor.setText(s.id, $0) }),
                                                focusID: s.id, focus: $focus, onNothing: { editor.insertNothing(s.id) })
                                        .id(s.id)
                                }
                                ForEach(Array(editor.extras.enumerated()), id: \.offset) { i, x in
                                    SectionCard(title: displayTitle(of: x.title), hint: "", required: false, muted: true,
                                                text: Binding(get: { editor.extras.indices.contains(i) ? editor.extras[i].text : "" }, set: { editor.setExtra(i, $0) }),
                                                focusID: "extra-\(i)", focus: $focus, onNothing: nil)
                                }
                            }
                            .padding(.top, Theme.s8).padding(.bottom, Theme.s6)
                        }
                    }
                    .onChange(of: model.focusRequest) { r in
                        guard let r = r else { return }
                        focus = r.sectionID
                        withAnimation { proxy.scrollTo(r.sectionID, anchor: .center) }
                    }
                }
                SaveBar(model: model, editor: editor)
            }
        }
        .background(Theme.bg)
        .onAppear { if editor.day == model.today && editor.showsEditors && !model.editorStartedFocused { model.editorStartedFocused = true; DispatchQueue.main.async { model.focusFirstEmpty() } } }
        .background(Button("") { model.saveCurrent() }.keyboardShortcut(.return, modifiers: .command).opacity(0).accessibilityHidden(true))
    }
}

/// Centred 720 column with the standard page padding.
struct Column<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0, content: content)
            .frame(maxWidth: Theme.columnMax, alignment: .leading)
            .padding(.horizontal, Theme.s12).padding(.top, Theme.s10).padding(.bottom, Theme.s6)
            .frame(maxWidth: .infinity)
    }
}

struct PageBanners: View {
    @ObservedObject var model: AppModel
    @ObservedObject var editor: DayEditor
    var body: some View {
        VStack(spacing: Theme.s3) {
            if let p = model.folderProblem { FolderBanner(model: model, problem: p, editor: editor) }
            else if let e = editor.errorText {
                Banner(.error, "Couldn't save this log.", detail: "\(e). Your draft is kept. Try again or choose another folder.") {
                    Button("Try again") { editor.save() }.buttonStyle(TextButtonStyle())
                }
            }
            if editor.day == model.today && model.isDue && editor.showsEditors { NagBanner(model: model) }
            if editor.openedAsToday && editor.day != model.today && !model.rolloverDismissed {
                Banner(.info, "It's now \(DayKey.format(model.today, "EEEE, d MMMM", model.cal)). You're still writing \(DayKey.format(editor.day, "EEEE, d MMMM", model.cal)).",
                       onDismiss: { model.rolloverDismissed = true }) {
                    if !editor.dirty { Button("Start today's log") { model.openToday() }.buttonStyle(TextButtonStyle()) }
                }
            }
            if let r = editor.restoredFrom, editor.dirty {
                Banner(.info, "Draft restored from \(Fmt.time(r)).") {
                    Button("Discard draft") { editor.discardDraft() }.buttonStyle(TextButtonStyle())
                }
            }
            if editor.day != model.today && !editor.editBannerDismissed && editor.hasFile && editor.showsEditors {
                Banner(.info, "Editing \(model.longDate(editor.day).replacingOccurrences(of: " 20", with: ", 20"))",
                       onDismiss: { editor.editBannerDismissed = true })
            }
        }
        .padding(.bottom, model.folderProblem != nil || editor.errorText != nil || editor.restoredFrom != nil || (editor.day == model.today && model.isDue) ? Theme.s6 : 0)
    }
}

struct NagBanner: View {
    @ObservedObject var model: AppModel
    var body: some View {
        let strict = model.settings.mode == .strict
        Banner(.info, strict ? "It's \(Fmt.time(model.now)). Time to write up today." : "Today isn't logged yet.",
               detail: strict && model.planner.showSkipHint ? "Not today? Skip day." : nil) {
            Button(model.snoozeLabel) { model.snooze() }.buttonStyle(TextButtonStyle()).disabled(!model.canSnooze)
            Button("Skip day") { model.requestSkip() }.buttonStyle(TextButtonStyle())
        }
        .accessibilityLabel("Reminder")
    }
}

struct FolderBanner: View {
    @ObservedObject var model: AppModel
    let problem: FolderProblem
    @ObservedObject var editor: DayEditor
    var body: some View {
        switch problem {
        case .missing(let p):
            Banner(.warning, "Your log folder can't be found.",
                   detail: "\"\((p as NSString).abbreviatingWithTildeInPath)\" isn't there any more. It may have been moved or an external drive is disconnected.") {
                Button("Choose folder…") { model.chooseFolder() }.buttonStyle(TextButtonStyle())
                Button("Try again") { model.retryFolder() }.buttonStyle(TextButtonStyle())
                Button("Create it again") { model.recreateFolder() }.buttonStyle(TextButtonStyle())
            }
        case .notWritable(let p):
            Banner(.error, "Daily Log can't save to this folder.",
                   detail: "You may not have permission to write to \"\((p as NSString).lastPathComponent)\". Your text is safe as a draft on this Mac.") {
                Button("Choose folder…") { model.chooseFolder() }.buttonStyle(TextButtonStyle())
                Button("Try again") { model.retryFolder() }.buttonStyle(TextButtonStyle())
                Button("Copy my text") { editor.copyText() }.buttonStyle(TextButtonStyle())
            }
        }
    }
}

struct PageHeader: View {
    @ObservedObject var model: AppModel
    @ObservedObject var editor: DayEditor
    var body: some View {
        let isToday = editor.day == model.today
        let thisYear = String(model.today.prefix(4))
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(DayKey.format(editor.day, "EEEE, d MMMM", model.cal))
                    .font(Theme.font(32, .semibold)).tracking(-0.5).foregroundColor(Theme.textPrimary).lineLimit(1).minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: Theme.s4)
                if isToday && model.streak.current >= 2 {
                    Text("\(model.streak.current) day streak").font(Theme.font(12, .semibold)).foregroundColor(Theme.accentText).monospacedDigit()
                        .padding(.horizontal, 10).frame(height: 24).background(Capsule().fill(Theme.accentTint))
                        .help("Consecutive logged days. Skipped days do not break it.")
                }
            }
            HStack(alignment: .firstTextBaseline) {
                Text("Daily log" + (isToday || String(editor.day.prefix(4)) == thisYear ? "" : ", \(editor.day.prefix(4))"))
                    .font(Theme.font(13)).foregroundColor(Theme.textSecondary)
                if isToday && !model.isWorkday(editor.day) { Text("Not a workday").font(Theme.font(12)).foregroundColor(Theme.textSecondary) }
                Spacer()
                if editor.showsEditors { let c = editor.chip; StatusChip(kind: c.0, text: c.1) }
                else { StatusChip(kind: .none, text: "Skipped" + (editor.skipReason.isEmpty ? "" : " · \(editor.skipReason)")) }
            }.padding(.top, 4)
            Rectangle().fill(Theme.border).frame(height: 1).padding(.top, Theme.s6)
            if isToday && model.states[editor.day] == nil && !editor.dirty && editor.showsEditors {
                Text("Nothing logged yet. Take a few minutes to write up today, or come back at \(model.reminderLabel).")
                    .font(Theme.font(13)).foregroundColor(Theme.textSecondary).padding(.top, Theme.s4)
            }
        }
    }
}

struct SkippedBody: View {
    @ObservedObject var model: AppModel
    @ObservedObject var editor: DayEditor
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            Text("You skipped this day. It doesn't affect your streak.").font(Theme.font(15)).foregroundColor(Theme.textPrimary)
            HStack(spacing: Theme.s3) {
                Button("Write a log anyway") { editor.writingAnyway = true; model.focusFirstEmpty() }.buttonStyle(SecondaryButtonStyle())
                Button("Undo skip") { model.unskip(editor.day) }.buttonStyle(SecondaryButtonStyle())
            }
            if let e = editor.errorText { Text(e).font(Theme.font(13)).foregroundColor(Theme.danger) }
        }.padding(.top, Theme.s6)
    }
}

struct SaveBar: View {
    @ObservedObject var model: AppModel
    @ObservedObject var editor: DayEditor
    var body: some View {
        let progress = "\(editor.filled) of \(editor.total) filled"
        HStack(spacing: Theme.s3) {
            ProgressRing(filled: editor.filled, total: editor.total)
            VStack(alignment: .leading, spacing: 1) {
                Text(editor.filled == editor.total ? "All sections done" : progress).font(Theme.font(13)).foregroundColor(Theme.textSecondary).monospacedDigit()
                if let q = model.quietLine { Text(q).font(Theme.font(11)).foregroundColor(Theme.accentText) }
            }
            Spacer()
            if editor.day != model.today && editor.hasFile && editor.dirty {
                Button("Revert changes") { editor.revert() }.buttonStyle(TextButtonStyle(color: Theme.textSecondary))
            }
            if model.canSkipToday && editor.day == model.today {
                Button("Skip day…") { model.requestSkip() }.buttonStyle(TextButtonStyle(color: Theme.textSecondary))
            } else if editor.day != model.today && model.states[editor.day] != .logged && editor.showsEditors {
                Button("Skip day…") { model.requestSkip(day: editor.day) }.buttonStyle(TextButtonStyle(color: Theme.textSecondary))
            }
            Button("Open folder") { model.revealFolder() }.buttonStyle(TextButtonStyle(color: Theme.textSecondary))
            Button(editor.hasFile && editor.day != model.today || (editor.hasFile && editor.dirty) ? "Save changes" : "Save log") { editor.save() }
                .buttonStyle(PrimaryButtonStyle()).disabled(!editor.canSave)
                .help(editor.canSave ? "Save (⌘S)" : (editor.missing.isEmpty ? "Nothing to save" : "Still needed: " + editor.missing.map { $0.displayTitle }.joined(separator: ", ")))
                .accessibilityHint(editor.canSave ? "" : "\(progress). Fill all sections to save.")
        }
        .padding(.horizontal, Theme.s12).frame(height: Theme.saveBarHeight)
        .background(Theme.bg).overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .top)
    }
}
