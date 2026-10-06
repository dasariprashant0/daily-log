// ReminderPlanner.swift - pure decision function for the nag. The UI owns a 30-60 s timer (and wake/launch hooks),
// calls decide() each tick, performs the Action, and stores newState (persist `state` so snoozesUsed survives relaunch).
//
// API:
//   ReminderPlanner.decide(now:, calendar:, settings:, todayStatus:, state:, windowVisible:) -> (ReminderAction, PlannerState)
//   ReminderPlanner.snooze(state:, now:, settings:, calendar:) -> PlannerState?   nil = Strict has no snoozes left
//   ReminderPlanner.snoozesLeft(state:, settings:) -> Int?                        nil = unlimited (Gentle)
//   ReminderPlanner.isPending(now:, calendar:, settings:, todayStatus:) -> Bool   banner / menu-bar "due, unlogged" (ignores snooze)
//   PlannerState.atLaunch(previous:, now:, calendar:)   2-min grace after login/launch, keeps today's snooze count
//   PlannerState.suppressed(until:) / ReminderPlanner.graceAfterSettingsChange (60 s) / graceAfterUndoSkip (120 s)
//   PlannerState.showSkipHint        true once the 3rd re-open happened ("Not today? Skip day.")
// Actions:
//   .notify                       post one notification only (Gentle first fire, Gentle after snooze)
//   .bringToFront(notify:)        Strict: activate window + Dock bounce; notify=true on first fire, false after a snooze
//   .reopen                       Strict: orderFrontRegardless WITHOUT activating (window was closed >= 5 min)
//   .none
// todayStatus: pass .missed or .partial for "unlogged"; logged/skipped/off/future never nag.
// Nag window: reminder time <= now < 23:00 local, scheduled weekday only. App launched late or Mac woken after the
// reminder time fires on the next tick (after the grace). Day change resets the state.
import Foundation

enum ReminderAction: Equatable {
    case none
    case notify
    case bringToFront(notify: Bool)
    case reopen
}

struct PlannerState: Codable, Equatable {
    var day = ""
    var snoozesUsed = 0
    var snoozedUntil: Date?
    var firstFired = false
    var lastFire: Date?
    var reopenCount = 0
    var hiddenSince: Date?
    var graceUntil: Date?

    var showSkipHint: Bool { reopenCount >= ReminderPlanner.skipHintAfterReopens }

    func suppressed(until d: Date) -> PlannerState { var s = self; s.graceUntil = max(d, s.graceUntil ?? d); return s }

    static func atLaunch(previous: PlannerState?, now: Date, calendar: Calendar) -> PlannerState {
        let today = DayKey.string(now, calendar)
        var s = PlannerState(day: today)
        if let p = previous, p.day == today { s.snoozesUsed = p.snoozesUsed }
        s.graceUntil = now.addingTimeInterval(ReminderPlanner.graceAfterLaunch)
        return s
    }
}

enum ReminderPlanner {
    static let reopenInterval: TimeInterval = 5 * 60
    static let maxStrictSnoozes = 2
    static let cutoffMinutes = 23 * 60
    static let skipHintAfterReopens = 3
    static let graceAfterLaunch: TimeInterval = 120
    static let graceAfterUndoSkip: TimeInterval = 120
    static let graceAfterSettingsChange: TimeInterval = 60

    private static func minutes(_ now: Date, _ cal: Calendar) -> Int {
        let c = cal.dateComponents([.hour, .minute], from: now); return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }
    private static func needsLog(_ s: DayStatus) -> Bool { s == .missed || s == .partial }

    static func isPending(now: Date, calendar: Calendar, settings: Settings, todayStatus: DayStatus) -> Bool {
        guard needsLog(todayStatus), settings.weekdays.contains(calendar.component(.weekday, from: now)) else { return false }
        let m = minutes(now, calendar)
        return m >= settings.reminderMinutes
    }

    static func snoozesLeft(state: PlannerState, settings: Settings) -> Int? {
        settings.mode == .gentle ? nil : max(0, maxStrictSnoozes - state.snoozesUsed)
    }

    static func snooze(state: PlannerState, now: Date, settings: Settings, calendar: Calendar) -> PlannerState? {
        var s = state
        if s.day != DayKey.string(now, calendar) { s = PlannerState(day: DayKey.string(now, calendar), graceUntil: s.graceUntil) }
        if settings.mode == .strict {
            if s.snoozesUsed >= maxStrictSnoozes { return nil }
            s.snoozesUsed += 1
        }
        s.snoozedUntil = now.addingTimeInterval(TimeInterval(settings.snoozeMinutes * 60))
        s.hiddenSince = nil
        return s
    }

    static func decide(now: Date, calendar: Calendar, settings: Settings, todayStatus: DayStatus,
                       state: PlannerState, windowVisible: Bool) -> (ReminderAction, PlannerState) {
        var s = state
        let today = DayKey.string(now, calendar)
        if s.day != today { s = PlannerState(day: today, graceUntil: s.graceUntil) }

        guard needsLog(todayStatus), settings.weekdays.contains(calendar.component(.weekday, from: now)) else { return (.none, s) }
        let m = minutes(now, calendar)
        guard m >= settings.reminderMinutes, m < cutoffMinutes else { return (.none, s) }
        if let g = s.graceUntil, now < g { return (.none, s) }
        if let u = s.snoozedUntil, now < u { return (.none, s) }

        let strict = settings.mode == .strict
        // Snooze ended: fire again (Strict: window only, no second notification; Gentle: notification again).
        if s.snoozedUntil != nil {
            s.snoozedUntil = nil; s.firstFired = true; s.lastFire = now; s.hiddenSince = nil
            return (strict ? .bringToFront(notify: false) : .notify, s)
        }
        // First fire of the day (also covers app launched / Mac woken after the reminder time).
        if !s.firstFired {
            s.firstFired = true; s.lastFire = now; s.hiddenSince = nil
            return (strict ? .bringToFront(notify: true) : .notify, s)
        }
        guard strict else { return (.none, s) }

        // Strict re-open: window closed/minimised for >= 5 min, and >= 5 min since the last fire.
        if windowVisible { s.hiddenSince = nil; return (.none, s) }
        if s.hiddenSince == nil { s.hiddenSince = now; return (.none, s) }
        if now.timeIntervalSince(s.hiddenSince!) >= reopenInterval, now.timeIntervalSince(s.lastFire ?? .distantPast) >= reopenInterval {
            s.lastFire = now; s.hiddenSince = nil; s.reopenCount += 1
            return (.reopen, s)
        }
        return (.none, s)
    }
}
