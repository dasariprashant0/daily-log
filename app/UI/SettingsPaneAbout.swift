// SettingsPaneAbout.swift - Settings > About: version, what Gloamlog does and does not do, licence, "Run setup again".
import SwiftUI
import AppKit

struct AboutSettings: View {
    @ObservedObject var model: AppModel

    private var version: String {
        let info = Bundle.main.infoDictionary
        guard let short = info?["CFBundleShortVersionString"] as? String else { return "Development build" }
        let build = info?["CFBundleVersion"] as? String
        return (build == nil || build == short) ? "Version \(short)" : "Version \(short) (\(build ?? ""))"
    }
    private var licencesURL: URL? { Bundle.main.url(forResource: "THIRD_PARTY_LICENSES", withExtension: "md") }

    var body: some View {
        VStack(spacing: Theme.s2) {
            Spacer(minLength: Theme.s4)
            Image(nsImage: NSApplication.shared.applicationIconImage).resizable().frame(width: 72, height: 72).accessibilityHidden(true)
            Text("Gloamlog").font(Theme.font(22, .semibold)).foregroundColor(Theme.textPrimary).accessibilityAddTraits(.isHeader)
            Text(version).font(Theme.font(13)).foregroundColor(Theme.textSecondary)
            VStack(spacing: Theme.s1) {
                Text("A calm end-of-day log. One plain markdown file per day, on your Mac.")
                Text("No network requests, no account, no telemetry.")
            }
            .font(Theme.font(13)).foregroundColor(Theme.textPrimary).multilineTextAlignment(.center).padding(.top, Theme.s2)
            HStack(spacing: Theme.s3) {
                Button("Run setup again…") { model.runSetupAgain() }
                    .help("Walk through the setup steps again. Your pages and settings stay as they are until you change something.")
                Button("Third-party licences") { if let u = licencesURL { NSWorkspace.shared.open(u) } }
                    .disabled(licencesURL == nil).help(licencesURL == nil ? "Not included in this build" : "Open the licences of the bundled editor")
            }.padding(.top, Theme.s4)
            Text("Released under the MIT licence.").font(Theme.font(12)).foregroundColor(Theme.textSecondary).padding(.top, Theme.s3)
            Spacer(minLength: Theme.s4)
        }
        .padding(.horizontal, Theme.s8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
