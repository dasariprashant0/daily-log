# Growth research: how open-source Mac apps and Claude Code tools earn stars and real users

Prepared 2026-10-06 for [dasariprashant0/daily-log](https://github.com/dasariprashant0/daily-log) (MIT, created 2026-10-06, 0 stars at time of writing per the GitHub API).

How to read this file

- Evidence tags: **[V]** = fetched and read from the primary source or an API on 2026-10-06. **[S]** = second-hand (third-party summary, forum thread, search snippet); verify before relying on it. **[U]** = unverified or thin; treat as a hypothesis to test.
- Every number has a named source. Where no number could be found, the text says so. No star counts were estimated or invented.
- "Planning targets" in section 5 are assumptions, not benchmarks.
- Scope: a free, MIT, local-first, native SwiftUI Mac app that writes plain markdown and may auto-draft from Claude Code sessions. This is research, not a product spec.

---

## 0. Summary

### 0.1 What the evidence says

1. **Stars are not users.** Homebrew installs in the last 365 days per star: Maccy 5.1, AltTab 3.9, Rectangle 3.8, Stats 3.4, Ice 2.0, CodexBar 1.2, Dayflow 0.2 [V, section 1.2]. Direct-download apps are mostly invisible to Homebrew analytics; their GitHub release downloads are a better proxy but include auto-updates.
2. **Three growth shapes.** (a) One sharp event within days of going public: Dayflow (Show HN 480 points, one day after the repo was created), Claude Code Usage Monitor (Show HN 245 points, repo created the same day), ccusage (launch blog post on the day the repo was created, plus a zero-install `npx` command). (b) A trigger moment: Ice (HN 670 points, two days after the Bartender-sale story) and claude-devtools (launched against Claude Code's change to summarise tool output [S]); both show decay once the trigger fades. (c) Slow compounding for 7-9 years at 6-16 average stars per day: Maccy, Rectangle, Stats, AltTab, helped by Homebrew, awesome lists and recurring recommendation threads (Stats got a 450-point HN thread in January 2025, almost six years after creation) [V].
3. **Two of the recent climbers had advantages a newcomer cannot copy.** CodexBar's author already had a large audience and ships roughly every 1.3 days; Dayflow is a Y Combinator Summer 2024 company [V/S]. A solo MIT app should plan for slow compounding plus one carefully prepared launch spike.
4. **In the Claude Code niche, what broke out is a number with money or limits attached** (usage, cost, quota): ccusage 18.9k stars, CodexBar 22.2k, codeburn 11.3k, Claude Code Usage Monitor 8.7k [V]. Session browsers mostly have double-digit stars (best hit in my search: 75); the exception, claude-devtools (4.0k), launched against a platform change [S]. I found one standup/journal-from-transcripts repo, with 0 stars. That is either white space or absent demand; the soft launch has to find out which [U].
5. **Install friction decides.** Every comparable offers a one-line install (brew cask or npx). All the Homebrew-cask apps pass Gatekeeper today. The exception, boring.notch, has no Apple Developer account, asks users to strip the quarantine flag, and still has 11k stars, but it cannot be in the official cask [V].
6. **Notarisation is now a distribution requirement, not polish.** Homebrew announced on 2025-11-12 that casks failing Gatekeeper checks would be disabled in September 2026, and its cask data now shows 600 of 7,775 casks disabled for that reason (599 on 2026-09-01, one more on 2026-10-04). macOS 15 also removed the Control-click bypass [S]. Cost: US$99 per year [V].
7. **README pattern.** Seven of eight analysed READMEs show an image or logo within the first ~250 characters (CodexBar's first non-badge image is at ~1,000, after a badge row). The two apps handling the most sensitive data state privacy early (Dayflow at 5% of the README, CodexBar at 9%). FAQs are mostly permission and troubleshooting answers. Successors carry a "differences with X" section (Rectangle) [V].
8. **Channel rules tightened in 2026.** HN restricts Show HN for accounts without history and asks for human-written posts; r/macapps wants modmail approval and spaces dev posts 30 days apart [S]; awesome-claude-code accepts only issue-form submissions from projects at least 14 days old or with 100+ stars; awesome-macOS rejects LLM-wrapper apps; Hacktoberfest no longer rewards pull requests [V].
9. **Contributors arrive through a documented, narrow lane.** CodexBar (482 contributors in ten months) has a four-step provider-authoring guide and a labelling guide; Stats accepts unsolicited work only for translations; AltTab gives contributors and translators free Pro licences; ccusage had 22 `good first issue` issues, all closed [V].
10. **Maintainer fatigue is visible and public.** Ice has had no release since 2025-09-16 and 440 open issues; AltTab's author asked for a successor in 2021, found none, and added a paid Pro tier in 2026 [V].

### 0.2 What it means for Daily Log

- **Reorder the roadmap.** `docs/ROADMAP.md` ranks the Homebrew cask first and notarisation second. The official cask requires a Gatekeeper-passing build, so notarisation has to come first. Use a personal tap now; official cask needs notability (75 stars, or 225 if you submit it yourself) and a repo at least 30 days old (earliest 2026-11-05) [V].
- **Position on the job, not on the plumbing.** "Write up your day before you leave it, with a first draft from your Claude Code sessions" is a different job from usage monitors and session viewers, which are crowded. Put a "why not ccusage / CodexBar / Dayflow" answer in the README, because commenters in this niche ask exactly that [V, HN item 48477047].
- **Make the privacy statement exactly true.** The project promises no network by default. If auto-draft sends text to a model, say where it goes, make it opt-in, and show a preview. An update check will be scrutinised (a commenter on the Stats HN thread called out its update check as phoning home) [S].
- **One big launch, not a blitz.** A single prepared Show HN (from an account with history), staggered communities, then directories and lists once eligible.
- **Build a contributor lane around "sources" or "importers"**, modelled on CodexBar's provider guide, within the project's no-dependency, no-network rules.
- **Measure without telemetry**: stars and forks, release downloads, GitHub Traffic (14-day window), issues filed by strangers, and a manual ten-person retention check.

---

## 1. Case studies

### 1.1 How the data was gathered, and what could not be measured

- GitHub REST API (stars, forks, created_at, contributors via the Link header), 2026-10-06. Homebrew install counts from the public formulae API (opt-out analytics, so a lower bound for brew users only). Release downloads from shields.io totals over GitHub release assets (these include Sparkle and Homebrew downloads, so they overstate unique users). Release cadence from each repo's `releases.atom` (gap across the last 10 releases). npm counts from the npm API. HN items and README files fetched directly.
- **First 100 and first 1,000 stars: not retrievable.** GitHub's stargazers endpoint now answers 401 "Requires authentication" even without timestamps (tested 2026-10-06), and boring.notch's README carries a comment saying its star-history chart broke because GitHub restricted the stargazer API [V]. Public event archives I tried (ClickHouse GitHub events, OSS Insight) had visible gaps (totals far below the real star count), so I discarded them. I did not use anyone's credentials. Appendix A has a command you can run with your own `gh` login.
- What stands in for it: the repo's created_at date, the dated launch events I could find, and the earliest dated star counts quoted by third parties.
- Survivorship bias: all ten repos are winners. No base rate for "what share of Show HN or Reddit launches get stars" was found.
- created_at is not launch day (Ice was public ten months before its moment; Dayflow's repo date is one day before its Show HN).

### 1.2 Growth and usage numbers

Table A1: growth (GitHub API, 2026-10-06). Contributors include anonymous commits.

| Repo | Kind | Created | Stars | Avg stars/day since creation | Forks | Contributors |
|---|---|---|---|---|---|---|
| [p0deje/Maccy](https://github.com/p0deje/Maccy) | clipboard manager | 2018-01-31 | 21,819 | 6.9 | 1,188 | 89 |
| [rxhanson/Rectangle](https://github.com/rxhanson/Rectangle) | window manager | 2019-06-21 | 30,040 | 11.3 | 1,009 | 190 |
| [exelban/stats](https://github.com/exelban/stats) | system monitor | 2019-05-29 | 42,332 | 15.8 | 1,557 | 194 |
| [lwouis/alt-tab-macos](https://github.com/lwouis/alt-tab-macos) | window switcher | 2019-08-14 | 16,368 | 6.3 | 888 | 51 |
| [jordanbaird/Ice](https://github.com/jordanbaird/Ice) | menu bar manager | 2023-08-04 | 29,754 | 25.7 | 976 | 12 |
| [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch) | notch utility | 2024-08-02 | 10,956 | 13.8 | 1,087 | 63 |
| [JerryZLiu/Dayflow](https://github.com/JerryZLiu/Dayflow) | work journal (from screen) | 2025-09-23 | 7,234 | 19.1 | 441 | 8 |
| [ccusage/ccusage](https://github.com/ccusage/ccusage) | usage/cost CLI | 2025-05-29 | 18,894 | 38.2 | 862 | 82 |
| [matt1398/claude-devtools](https://github.com/matt1398/claude-devtools) | session-log inspector | 2026-02-07 | 3,960 | 16.4 | 305 | not fetched |
| [steipete/CodexBar](https://github.com/steipete/CodexBar) | menu bar usage meter | 2025-11-16 | 22,219 | 68.6 | 2,055 | 482 |

Avg stars/day is a mean over the whole life and hides spikes (computed here from created_at to 2026-10-06).

Table A2: real-use proxies and cadence.

| Repo | Homebrew cask installs, 365d (30d) | Installs per star (365d) | GitHub release downloads (cumulative) | Avg gap, last 10 releases |
|---|---|---|---|---|
| Maccy | 110,782 (4,638) | 5.1 | 2.7M | ~69 days |
| Rectangle | 114,466 (5,276) | 3.8 | 20M (includes auto-updates) | ~21 days |
| Stats | 142,933 (6,077) | 3.4 | 12M | ~6 days |
| AltTab | 64,326 (1,650) | 3.9 | 1.5M (README banner claims 7.4M downloads, self-reported) | ~9 days |
| Ice | 58,677 (2,291) | 2.0 | 653k | ~39 days; last release 2025-09-16 |
| boring.notch | not in homebrew/cask (own tap) | n/a | 2.3M | ~35 days (rolling "nightly" tag) |
| Dayflow | 1,108 (34) | 0.2 | 145k | ~5 days |
| ccusage | n/a (npm: 197,130 last week, 556,660 last 30 days; includes CI and cache re-downloads) | n/a | n/a | ~9 days (v20.0.26 on 2026-09-27) |
| claude-devtools | 4,380 (98); last 90 days 664, so the recent pace is falling | 1.1 | 130k | ~7 days across the last 10 releases, but the newest release is dated 2026-05-13 |
| CodexBar | 27,324 (2,317) | 1.2 | 2.3M | ~1.3 days (0.72.0 on 2026-10-04) |

Sources: [Homebrew cask API](https://formulae.brew.sh/api/cask/maccy.json) (same pattern per cask), [shields.io download totals](https://img.shields.io/github/downloads/p0deje/Maccy/total), [npm API](https://api.npmjs.org/downloads/point/last-week/ccusage), each repo's `releases.atom`. All [V]. Thaw, the community project that replaced Ice for many people, shows 27,614 cask installs per year and about 11.8k stars [V/S].

Supporting evidence, not a full case: Claude Code Usage Monitor ([Maciek-roboblog/Claude-Code-Usage-Monitor](https://github.com/Maciek-roboblog/Claude-Code-Usage-Monitor), 8,731 stars, created 2025-06-19, Show HN 245 points) [V].

### 1.3 Launch, positioning and install, per repo

| Repo | Positioning (paraphrased from README) | Install paths | Earliest dated traction evidence found |
|---|---|---|---|
| Maccy | One-job clipboard manager; local storage; respects password managers | `brew install maccy`; GitHub releases; Gumroad; paid Mac App Store build as "support" ([maccy.app](https://maccy.app/)) | No launch thread found; HN comments recommend it. Slow compounding since 2018 |
| Rectangle | Window manager "based on Spectacle" (successor framing) | `brew install --cask rectangle`; download; links to older builds for older macOS | No launch thread found; Product Hunt page exists [S] |
| Stats | System monitor in your menu bar; two screenshots at the top | `brew install stats`; manual download | [HN thread](https://news.ycombinator.com/item?id=42881342): 450 points, 168 comments, 2025-01-30 |
| AltTab | README is now one banner pointing to the site (Pro tier) | brew cask; website | [HN, Pro announcement](https://news.ycombinator.com/item?id=48283349): 32 points, 18 comments (posted about four months before this research). No launch thread found |
| Ice | Menu bar manager; open Bartender alternative | `brew install --cask jordanbaird-ice`; download | [HN](https://news.ycombinator.com/item?id=40605532): 670 points, 189 comments, 2024-06-07, two days after the [Bartender sale story](https://news.ycombinator.com/item?id=40584606) (252 points) |
| boring.notch | Turns the notch into media controls, shelf and live activities; GIF and video demos | DMG plus a terminal command to clear quarantine; Homebrew via own tap | None found; channel unverified [U] |
| Dayflow | Private, automatic work journal for Mac; open source, local-first | DMG via site or releases; `brew install --cask dayflow` | [Show HN](https://news.ycombinator.com/item?id=45361268): 480 points, 130 comments, 2025-09-24 (repo created 2025-09-23) |
| ccusage | CLI that turns local Claude Code logs into usage and cost reports | `npx ccusage@latest` (zero install); npm | Launch blog post on 2025-05-29 (the repo's creation date). No Show HN of its own found; HN comments recommend it |
| claude-devtools | The debugging tool for Claude Code: read session transcripts, inspect tool calls and token use from local logs | `brew install --cask claude-devtools`; installers for macOS, Linux and Windows; Docker | No launch thread found; README opens with a platform-change trigger and links to an HN discussion of the backlash |
| CodexBar | Every AI coding limit in your menu bar | `brew install --cask codexbar` (official cask), own tap, Sparkle updates | An HN comment around January 2026 cites 1.7k stars; GitHub Trending for 5 days with best rank #8 on 2026-07-08 [S, star-history page] |

### 1.4 Per-repo notes

**Maccy (MIT, 2018).**
- README: logo, two badges (downloads, CI), one-paragraph pitch, contents list, then Features, Install, Usage, Advanced, FAQ, Translations, Motivation, License. Opens with a warning about fake sites impersonating the app (success attracts impostors) [V].
- Motivation is personal and short: wanted a simple clipboard manager after moving from Linux, and wanted to learn Swift [V].
- Model: free MIT build; paid Mac App Store build as support; FUNDING.yml; Discussions on; 89 contributors; 9 `good first issue` issues, all closed [V].
- Cadence is slow (about every two months), growth is Homebrew plus word of mouth.

**Rectangle (MIT with Spectacle attribution, 2019).**
- The hook is succession: the README says it is based on Spectacle and has a "Differences with Spectacle" section. Long README (about 18k characters), no badges, one image; sections for URL scheme, hidden preferences, JSON import/export, known issues, Contributing, Credits [V].
- Install is `brew install --cask rectangle` or download; Sparkle updates; a paid Rectangle Pro exists [S].
- 190 contributors; 2 `good first issue` issues; releases about every three weeks [V].

**Stats (MIT, 2019).**
- Two stacked screenshots, one-line pitch, Installation first (about 4% into the README), FAQs, Supported languages. The "Open source, but not open contribution" section says it is a one-maintainer project, unsolicited pull requests are generally not accepted, open an issue first, and translations are the standing exception [V].
- Releases about every six days; 194 contributors. HN thread of 450 points compared it to iStat Menus [V/S].

**AltTab (GPL-3.0, 2019).**
- README is now a single banner linking to the website. A Pro tier ($9.99 one-time) was announced by April 2026 while the source stays GPL-3.0; contributors, translators and donors get free Pro licences [S, HN thread and announcement page].
- The author opened [an issue asking for a successor](https://github.com/lwouis/alt-tab-macos/issues/1179) on 2021-10-19; nobody took it, and a pinned comment dated 2026-04-05 points to the Pro model [V].

**Ice (GPL-3.0, 2023).**
- A solid project ten months old when the incumbent broke trust. The Bartender sale story hit HN on 2024-06-05; Ice's own thread followed on 2024-06-07 [V]. Comment themes: relief at an open alternative, trust and ownership, feature gaps (notch handling) [S].
- README: icon and title, banner, 11 badges, Install, a Features/Roadmap checklist (done and not done), a short "why only macOS 14+" answer, an image gallery, sponsors [V].
- Today: last release 2025-09-16, last push 2025-09-20, 440 open issues, 12 contributors. A community project, Thaw (about 11.8k stars, 27.6k cask installs per year), is described on HN as the maintained option [V/S]. A spike without maintainer capacity decays.

**boring.notch (GPL-3.0, 2024).**
- Visual novelty: banner, video and GIF demos (14 media items), a roadmap checklist, Discord, Ko-fi, acknowledgements [V].
- Un-notarised by choice or cost: the README says there is no Apple Developer account yet and tells users to clear the quarantine flag in Terminal. Homebrew only via its own tap [V]. 2.3M downloads and 11k stars show that un-notarised apps can grow, but every user pays a friction toll and the official cask is closed.
- Growth channel unverified [U].

**Dayflow (MIT, YC Summer 2024 company).**
- The closest product neighbour: SwiftUI, local-first, MIT, a daily work journal, but automatic from screen recordings and a model, where Daily Log is a deliberate write-up [V].
- Show HN submitted by the founder; the first comment stressed local processing, MIT and an optional bring-your-own key. Reception: praise for privacy, concern about battery, a quality gap between local and cloud models, surveillance worries, macOS-only [S].
- README leads with the pitch and features (timeline, standup, weekly review, chat), then an explicit Privacy section saying where data lives and which AI options send data off the machine, then Install (DMG button and brew cask), Requirements, Build, Contributing (open an issue first for larger changes) [V].
- 8 contributors, release about every five days, 145k downloads, but only 1,108 cask installs per year: most users come through the DMG on its website [V].

**ccusage (2025).**
- Origin blog post (Zenn, 2025-05-29): why it exists, the single command `npx ccusage@latest`, JSON output, a disclosure that most of the code was written by Claude Code, a request to share results with a hashtag on X and Bluesky, a Sponsors link [S, [post](https://ryoppippi.com/blog/2025-05-29-zenn-6c9a8fe6629cd6-ja/)].
- Spread through HN comments pointing at it (for example 2025-07-02), derivative tools that wrapped or credited it (Claude Code Usage Monitor, VibeTime, Tokenusage, CodexBar's credits line), a third-party DEV article and a Raycast extension [V/S].
- README (in `apps/ccusage`): logo, npm and security badges, "Major Sponsors", Quick Start, Supported Sources, Installation, Usage, Features, Documentation; separate docs site. GitHub's primary language is now Rust. 82 contributors; 22 `good first issue` issues, all closed; issue templates include a "contribution" form [V].

**claude-devtools (MIT, 2026): a session viewer that broke out.**
- The README opens with a trigger rather than a feature: since Claude Code v2.1.20 the CLI replaced detailed output with short summaries, and the README links to a blog post and an HN thread about the backlash. The hero frames the pain (the agent works blind) and the promise (see everything it did) [V for the README text; S for the underlying claim].
- It pre-empts the obvious objection with a "Not a Wrapper" section (it only reads logs already on your machine), and ships a website, Discussions, a Security section, installers for macOS, Linux and Windows, Docker, and a Homebrew cask [V].
- Numbers: 3,960 stars in about 241 days (16.4 per day), 130k downloads, 4,380 cask installs per year. But cask installs ran at about 283 per month in days 31-90 and 98 in the last 30 days, and the newest release is dated 2026-05-13: a trigger-driven spike that is fading [V, computed].

**Supporting evidence: Claude Code Usage Monitor (2025).**
- Show HN on its creation day: 245 points, 8,731 stars today. Commenters said it was a thin wrapper over ccusage; the author of ccusage replied in the thread [S]. Lesson: Show HN works in a hot niche, and "is it more than a wrapper" is the differentiation test.

**CodexBar (MIT, 2025).**
- The author founded PSPDFKit, created OpenClaw and joined OpenAI in February 2026 per Wikipedia, so he brought an audience [S]. That is not replicable.
- README: tagline plus one-liner, 12 badges (release, macOS 14+, Homebrew, AUR, Linux), Why, Install (cask and tap), Providers list, screenshot, Features, a Privacy note saying it does not crawl the disk but reads a small set of known locations, a section explaining why each macOS permission is requested, a docs index, build instructions, related projects, links to other people's Windows ports and a Linux desktop integration, and a credit line saying it was inspired by ccusage [V].
- Contributor engine: a provider authoring guide that reduces a new provider to one folder, one descriptor with fetch strategies, one implementation, then tests and docs, plus an issue-labelling guide and an AGENTS.md. 482 contributors, 10 `good first issue` issues all closed; no root CONTRIBUTING.md and no issue templates [V].
- Distribution: official homebrew/cask entry, own tap, Sparkle. Release gap about 1.3 days; release announcements on X [S].

### 1.5 Patterns across the cases (inference, labelled as such)

- **The README is the landing page, and most also have a site** (maccy.app, rectangleapp.com, alt-tab.app, mac-stats.com, icemenubar.app, theboring.name, dayflow.so, ccusage.com, codex.bar) [V].
- **One-line install**: brew cask or `npx`, plus direct download.
- **A named incumbent or a known pain**: Spectacle to Rectangle, iStat Menus to Stats, Bartender to Ice, quota and cost anxiety to ccusage and CodexBar, hidden tool output to claude-devtools. Daily Log's comparator is a habit (notes, Day One, Obsidian daily notes), which is harder to name; the forced five-question write-up is the hook to test [U].
- **Trigger moments matter, and they fade**: Ice (the Bartender sale) and claude-devtools (Claude Code's output change) spiked on an outside event; Ice has not released since 2025-09-16 and claude-devtools' cask installs are falling. Daily Log has no such trigger, so plan for compounding plus one prepared launch.
- **Fast climbers release often** (CodexBar ~1.3 days, Dayflow ~5, Stats ~6, ccusage ~9) and announce each release; slow compounders release every one to two months. Causality is unproven, but visible activity is part of how people judge a tool.
- **Trust is written down**: privacy sections (Dayflow, CodexBar), a permissions explainer (CodexBar), an impersonation warning (Maccy).
- **Ecosystem adjacency helps**: CodexBar credits ccusage; ccusage has a Raycast extension; third-party tools wrap both.
- **Sustainability shows up late**: Maccy's paid App Store build, AltTab Pro, Rectangle Pro, Dayflow's pricing page, Ko-fi and Sponsors. None was needed for first traction.
- **What did not show up**: paid promotion; Product Hunt as a visible driver; awesome-list inclusion as a driver (the awesome-claude-code maintainer advises getting users first and keeping a backup plan, section 3).

### 1.6 The Claude Code neighbourhood (GitHub search, 2026-10-06) [V]

| Group | Examples (stars) | Read |
|---|---|---|
| Usage, cost, limits | ccusage 18.9k; CodexBar 22.2k; codeburn 11.3k; Claude Code Usage Monitor 8.7k; quotio 4.9k; Claude-Usage-Tracker 3.6k; vibeproxy 3.4k; ClaudeBar 1.5k | Proven demand; also crowded with near-identical Swift menu bar apps at 400-5k stars |
| Devtools and HUDs | claude-devtools 4.0k; claude-hud 28.3k | Inspecting sessions can work when framed as devtools and tied to a pain or platform change |
| Session viewers and browsers | best hits: 75, 43, 41, 12 | Low traction |
| Transcripts to daily markdown | cc-bridge, 0 stars | Possible white space or no demand [U] |
| Config, prompt and skill packs | single-file CLAUDE.md repo 217k; others above 100k | Star counts here say little about app adoption; do not benchmark against them |

Search coverage was a handful of queries, not exhaustive. Crowding shows up in HN too: a comment under a Show HN (about July 2026) asked what the benefit was over CodexBar, and the author answered that simplicity was the point [V, item 48477047].

### 1.7 What this means for "first 100 / first 1,000 stars"

- No timeline could be measured, so none is claimed. The structural facts that matter: 75 stars is the Homebrew bar if someone else submits your cask, 225 if you do; awesome-claude-code accepts anything with 100+ stars regardless of age; r/macapps' "Trust path" is reportedly tied to star count and age (wording ambiguous) [V/S]. Treat 100 and 225 as functional milestones, not vanity.
- For the fast climbers, the first stars came from one dated event within a day or two of the repo going public. For the slow ones there is no event on record.

---

## 2. README anatomy that converts

"Converts" has no controlled evidence here. Several blog posts quote precise lifts from demo GIFs and hero images (for example +35% star conversion); none cites reproducible data, so they are not used. What follows is descriptive: what the winners' READMEs do, then a recommended shape.

### 2.1 What eight winners' READMEs actually do [V, computed from raw README files]

| Repo | Length (chars) | First non-badge image or logo at char | "Install" heading at char (share of README) | First privacy or local mention (share) | Badges | Notable sections |
|---|---|---|---|---|---|---|
| Maccy | 8,176 | 233 | 2,018 (25%) | 6,019 (74%) | 2 | FAQ, Translations, Motivation |
| Ice | 4,319 | 25 | 1,575 (36%) | none | 11 | Roadmap checklist, why macOS 14+, Gallery |
| Rectangle | 18,347 | 81 | 455 (2%) | 14,088 (77%) | 0 | Differences with Spectacle, Known issues, Contributing |
| Stats | 11,528 | 79 | 484 (4%) | 2,695 (23%) | 0 | FAQs, not open contribution, Supported languages |
| Dayflow | 6,147 | 23 | 4,892 (80%) | 302 (5%) | 1 | Feature sections, Why people use it, Privacy, Requirements |
| boring.notch | 9,075 | 61 | 2,585 (28%) | 4,047 (45%) | 2 | Roadmap, Contributing, Discord, Ko-fi |
| ccusage | 13,668 | 25 | 5,744 (42%) | 6,083 (45%) | 4 | Major Sponsors, Quick Start, Supported Sources, Docs |
| CodexBar | 26,341 | ~1,018 | 2,433 (9%) | 2,290 (9%) | 12 | Why, Privacy note, macOS permissions, Docs, Related, Ports |

AltTab (283 characters, one banner) is omitted. Takeaways:
- An image or logo appears within the first 250 characters in 7 of 8. The first image is often a logo or banner; product screenshots follow within a screen.
- Older utilities put Install in the first 5% (Rectangle, Stats); newer pitch-led READMEs put features and privacy first (Dayflow).
- The two apps that handle the most sensitive data (Dayflow: screen content; CodexBar: tokens and cookies) put a privacy statement in the first 10%; ccusage, which reads local logs, first mentions local processing at 45%.
- Badge counts vary from 0 to 12 and do not track star counts (Rectangle and Stats have none).
- FAQs are practical: permission grants (Maccy's accessibility prompt), hotkey conflicts, menu bar ordering (Stats), why only a recent macOS (Ice).

### 2.2 Recommended skeleton for Daily Log

```markdown
<p align="center"><img src="docs/images/icon.png" width="96" alt="Daily Log"></p>

# Daily Log

Write up your day before you leave it. Daily Log asks five questions at your
reminder time, can draft the answers from your Claude Code sessions, and saves
plain markdown files you own. No account. No telemetry. macOS 13+. MIT.

[release] [license] [macOS 13+] [CI]            <- 3-5 informational badges, no vanity counters

![Reminder, five prompts, draft from a Claude Code session, saved markdown](docs/images/demo.gif)

## Install
brew install --cask dasariprashant0/tap/daily-log
Or download the notarised .dmg from Releases (SHA-256 in every release).
Requires macOS 13 or later.

## What it does            <- 4-6 bullets, each a visible behaviour, not a feature name
## Privacy: what it reads, writes and sends     <- table, see 2.3
## How it compares         <- short table, see 2.3
## FAQ                      <- permissions, where files live, uninstall, Claude log retention, Obsidian
## Roadmap and what it will not do   <- top 3 bets + the "will not do" list
## Contributing            <- link to CONTRIBUTING, good first issues, "add a source"
## License
```

Rationale for each block:
- **Hero line**: say who it is for and what it does in one sentence, then the three trust facts. Alternatives to A/B test in the soft launch: "End-of-day notes that start themselves" or "Five questions at 4:55pm. A markdown file you own."
- **Demo GIF**: 15 seconds, looping, showing the loop that is unique: reminder, draft appears, you edit, file saved. Never show real project names (use sample-data mode, 2.4).
- **One-line install** directly under it, then the notarised download.
- **Badges**: release, licence, macOS version, CI. Skip a downloads badge until the number helps you, and skip a star-history chart (see the boring.notch note in section 1.1).
- **Privacy table** (see Dayflow and CodexBar for the pattern): rows "Reads", "Writes", "Sends", "Stores credentials", each with the exact path or "nothing". Facts only, verified against the code before publishing.
- **Roadmap**: ROADMAP.md already has a strong "Will not do" list (no accounts, no telemetry, no team dashboards, no cloud sync). Surface it in the README; it doubles as a trust statement and as contributor guidance.
- **Disclose AI assistance** in one line if the code was written with an agent. ccusage disclosed it and still reached 18.9k stars; hiding it is the larger risk (section 6).

### 2.3 Two blocks worth drafting now

Privacy table (template; replace with what the code actually does):

| | Daily Log |
|---|---|
| Reads | Your own log folder (`~/daily-log`); if you enable Claude Code drafting, session files under `~/.claude/projects` (read-only) |
| Writes | Markdown files in your log folder; app settings in UserDefaults |
| Sends over the network | Nothing by default. [If an update check or a model call exists: say exactly what, when, and how to turn it off] |
| Accounts / telemetry | None |

Comparison table (fill after checking each product on publish day; only verified cells are filled here):

| | Daily Log | Dayflow | ccusage / CodexBar | ActivityWatch |
|---|---|---|---|---|
| Job | You write the day up, with a draft | Auto timeline from screen recordings | Token, cost and limit meters for coding agents | Automatic time tracking |
| Input | Your words; optional Claude Code session text | Screen content analysed by a model | Local agent logs and provider usage | Window and activity watchers |
| Data format | Plain markdown files | App database under Application Support | Reports (CLI) / menu bar meter | Local database |
| Licence | MIT | MIT | MIT-licensed menu bar app (CodexBar); ccusage verify | MPL-2.0 [V, API] |
| Platform | macOS 13+ | macOS | macOS (CodexBar), cross-platform CLI (ccusage) | Cross-platform |

Dayflow, ccusage and CodexBar rows rest on their READMEs [V]; verify every cell again before shipping.

FAQ topics that real READMEs answer: Where are my files? Does it phone home? Why does it need access to X (permissions)? How do I stop the login item? Does it work with Obsidian? What if Claude Code deletes old sessions (Claude Code keeps transcripts for 30 days by default [S])? Why macOS 13+? Which sources are supported?

### 2.4 Demo assets and sample-data mode

- **README GIF**: at most 10 MB (GitHub attachment limit for images and GIFs); aim for 15 seconds, about 900 px wide, looping. **Walkthrough video**: 60-90 seconds for HN, Reddit and X; GitHub accepts mp4, mov and webm but only 10 MB per video on free plans (100 MB on paid), so host longer cuts on YouTube [V, [GitHub docs](https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files)].
- **Screenshots**: light and dark, 3-6 images.
- **Social preview image**: 1280 x 640 px recommended (minimum 640 x 320), PNG or JPG or GIF under 1 MB [V, [GitHub docs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview)]. Put the app window, the one-line pitch, "macOS 13+ / MIT". Check it renders when the repo link is pasted into a chat or social composer.
- **Sample-data mode** (requested, and justified by the evidence): a launch flag or an onboarding choice that loads a fabricated week of logs and a fabricated Claude Code session fixture into a separate demo folder, never the real log folder. It lets you record without leaking real project names, lets reviewers try the headline feature without exposing their own sessions, and gives contributors fixtures for tests.
- **Per-capture checklist**: no real names, repos, window titles or usernames; same window size every take; record at 2x and downscale.

### 2.5 Gap analysis against the current README

The current README (about 1.3 KB) has a good first sentence but: no image or GIF; build instructions come before any install path; sharing instructions tell recipients to right-click Open or strip quarantine (a friction signal, section 3.3); no privacy table despite the strongest privacy story in the category; no FAQ, comparison, roadmap summary or contributing pointer; and nine doc links dominate the footer. Docs are heavy (UX_SPEC about 64 KB, DESIGN_SYSTEM about 37 KB) while the landing page is light; the winners invert that.

---

## 3. Distribution channels

### 3.1 Summary

| Channel | Verdict | Gate or prerequisite | When (see section 5) |
|---|---|---|---|
| Show HN | High: the dated spikes for Dayflow, Ice and Claude Code Usage Monitor | Notarised build; an HN account with normal history; 60-90 s video; human-written post; you online for hours | Day 15 |
| r/macapps | High-medium (Mac audience) | Modmail approval; account karma; one dev post per 30 days [S] | Day 17 |
| r/ClaudeAI, r/ClaudeCode | Medium; rules unverified | Modmail and flair; Claude-specific angle | Day 22 |
| r/opensource, r/SideProject, r/SwiftUI | Low-medium | Per-sub rules [S] | Opportunistic |
| DEV / Hashnode post | Medium; long tail and credibility | A real technical post, AI use disclosed | Day 18 |
| X and Bluesky | Medium for the Claude Code audience; evidence thin | A short native video clip | Day 16 |
| Newsletters | Low-medium | Console.dev, Changelog News, iOS Dev Weekly | Day 25 |
| Awesome lists | Low for traffic, cheap and durable | Per-list eligibility (below) | Day 24 |
| Directories | Low, durable | MacUpdate, AlternativeTo, MacMenuBar | Day 24 |
| Product Hunt | Low, optional | Personal account; you online all day | Skip unless time allows |
| Homebrew personal tap | Required install story | A release URL and checksum | Day 9 |
| Homebrew official cask | After the 30-day mark | Notarised; 75 or 225 stars; repo at least 30 days old | Day 31+ |
| Claude Code plugin marketplace | Optional | Own marketplace repo (no review) | Day 23 |

### 3.2 Channel details, rules and etiquette

**Show HN** [V unless marked]
- Rules ([Show HN](https://news.ycombinator.com/showhn.html), [guidelines](https://news.ycombinator.com/newsguidelines.html)): it must be something people can try, with no sign-up barrier; plain updates like "Foo 1.3.1" generally do not qualify; do not ask friends to upvote or comment; do not solicit votes or submissions; do not use HN mainly for promotion; do not put generated text in posts (write it yourself); do not automate posting; do not delete and repost.
- New accounts: since spring 2026 (the related Ask HN thread is dated March 2026), accounts without much HN history see [a notice](https://news.ycombinator.com/showlim) that Show HNs are temporarily restricted because of a massive influx. dang linked it as the reason for a dip in Show HN volume ([thread](https://news.ycombinator.com/item?id=47864393)); related threads are "Is Show HN dead? No, but it's drowning" (Feb 2026) and "Ask HN: Please restrict new accounts from posting" (Mar 2026). Practical consequence: use an account that has taken part in HN normally for weeks, and check the notice before launch day.
- How: title "Show HN: Daily Log - [what it does in plain words]". Link the repo or a page where the thing can be tried. Post a first comment within minutes that you wrote by hand: why you built it, how it works, limits, privacy facts, what feedback you want. Answer every comment, including hostile ones, calmly. File issues for real bugs in public. Do not send the HN link to friends; showing them the app is fine, steering votes is not.
- Expectations: Dayflow 480 points (a YC company), Claude Code Usage Monitor 245, "macOS menu bar app to track Claude usage" 161 [V]. All are survivors. The niche is saturated with Show HNs (CC Usage Bar, VibeTime, Tokenusage, CodeBurn, others), so commenters will ask what yours does that CodexBar or ccusage does not.
- The Show HN flood is also a quality filter: an analysis of about 1,590 recent Show HN pages found 22% scored high for "AI design patterns" [S, [analysis](https://www.adriankrebs.ch/blog/design-slop/)]. Look distinctive and show real use.

**r/macapps** [S: [Thread Otter profile, July 2026](https://www.threadotter.com/subreddit-rules/macapps); a developer's launch checklist dated 2026-08-23 in [this issue](https://github.com/mactools-app/MacTools/issues/334)]
- Reddit pages could not be fetched from this environment, so these rules are second-hand. Read the live rules and send modmail first.
- Reported rules: moderator permission or a designated thread; one developer post per 30 days (once per app for trusted developers); roughly 10 subreddit karma to self-promote in comments; correct flair and the sub's post template; disclose that you are the author; official direct URLs only (no shorteners or affiliate links); do not ask for upvotes or stars; the monthly "App Pile" megathread is the fallback; a main-feed "Trust path" is reportedly keyed to repo stars and age (wording ambiguous). Title format reported: "AppName - short description", with an open-source marker. Cross-posted identical text gets removed.
- How: a Mac-user post with screenshots or a GIF, notarised build, free and open source, privacy facts, install line. First person ("I built"). Reply to every comment.

**r/ClaudeAI and r/ClaudeCode** [S/U]
- A third-party profile (August 2026) says promotion needs moderator permission or a designated thread and recommends a short modmail first; r/ClaudeCode has no profile, so its rules are unknown to this research. Read both sidebars and pinned posts, use the flair they require, and send modmail.
- Angle: the workflow ("my Claude Code sessions write my end-of-day update"), the draft preview, and exactly what text leaves the machine. Disclose that it is your project. Do not post the same text as r/macapps.

**Local-first and self-hosting communities** [S/U]
- r/selfhosted is server-oriented and has restricted low-effort, vibe-coded project posts and expects disclosure of AI use ([HN thread on the January 2026 change](https://news.ycombinator.com/item?id=46677446)); a desktop app is probably off-topic there, so ask the mods before posting. r/opensource: disclose, flair as promotional, follow Reddit's under-10% self-promotion guideline [S]. r/SideProject: reported title format and 200-800 word first-person posts with GIFs [S]. r/SwiftUI: moderator permission and automatic link removal for new accounts [S]. r/ObsidianMD and r/PKMS: rules not checked.
- Reddiquette's self-promotion guideline (commonly summarised as 9 to 1) could not be fetched here [U].
- There is no large central local-first forum in my results; the visible assets are small awesome-local-first lists (for example [alexanderop/awesome-local-first](https://github.com/alexanderop/awesome-local-first), 235 stars) [V].

**Product Hunt** [V: [launch guide](https://www.producthunt.com/launch), [help article](https://help.producthunt.com/en/articles/484935-can-i-ask-my-community-friends-family-to-upvote-a-product)]
- Launches start at 12:01 am Pacific; you may not ask for upvotes; makers should post their own product (no advantage to a third-party hunter); personal accounts only, not company accounts; relaunch when there is a significant new iteration. Third-party guides say coordinated votes are discounted [S].
- No evidence found that Product Hunt moved any of the ten case studies. Rectangle has a page there [S]. Treat as optional.

**X and Bluesky** [mostly U]
- Documented practice in this niche: ccusage's author asked users to share results with a hashtag on X and Bluesky [S]; CodexBar's author posts each release on X [S]. Bluesky has a large developer presence according to secondary sources, but I found no Mac-indie-specific evidence [U].
- How: one post at launch with the native 15-second clip, the repo link in the post or first reply, plain language, no tagging of strangers for reach, no automation. Reply to people who engage.

**DEV and Hashnode** [V/S]
- DEV's [#showdev tag](https://dev.to/t/showdev) is for projects, community-driven and not salesy. DEV has [AI disclosure tiers](https://dev.to/devteam/introducing-ai-disclosure-on-dev-tools-for-nuance-clarity-and-better-feeds-34mk) (hand-written, AI-assisted, fully autonomous), and its [AI-assisted article guidelines](https://dev.to/guidelines-for-ai-assisted-articles-on-dev) say AI-assisted articles should not promote any business, program or course, including your own [S]. So write the post yourself, make it teach something, tag it honestly.
- Post idea with real content: building a SwiftUI app with Command Line Tools only (no Xcode project, no macros, no dependencies), parsing Claude Code's JSONL logs safely, notarising without Xcode. Cross-post to Hashnode with a canonical link back to the original (standard practice; not re-verified).

**Newsletters** [V unless marked]
- [Console.dev](https://console.dev/selection-criteria): weekly devtools newsletter; submissions by email to hello@console.dev; looks for developer-first tools that are actively maintained and documented with no security or privacy concerns; covers beta and pre-1.0 releases; no sponsored reviews. Daily Log fits only through its developer-facing Claude Code angle.
- [Changelog News](https://changelog.com/news/submit): needs an account; self-submission is allowed if it is newsworthy to developers; no how-tos or commercial products.
- [iOS Dev Weekly](https://suggest.iosdevweekly.com/): has a link suggestion form; best used for the technical post, not the app. Swift Weekly Brief has closed [S].
- Hacker Newsletter and similar digests are derived from HN; there is nothing to submit.

**Awesome lists** [V: stars and rules read on 2026-10-06]

| List | Stars | Rules that matter | Fit |
|---|---|---|---|
| [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | 55,144 | Web issue form only, no pull requests; project at least 14 days since first commit with active development, or 100+ stars; one submission at a time; submission must be human-written; descriptions are descriptions, not pitches, one line, no emojis; a Claude Code focus is a guideline, not a hard rule. The maintainer advises getting users first and having a backup plan, because a listing does not bring users by itself | Submit only once the Claude Code drafting exists and is the point; earliest about 2026-10-20 |
| [jaywcjlove/awesome-mac](https://github.com/jaywcjlove/awesome-mac) | 115,508 | Pull request per [CONTRIBUTING](https://github.com/jaywcjlove/awesome-mac/blob/master/docs/CONTRIBUTING.md): search duplicates, one entry per PR, alphabetical within category, title case, keep the English and zh/ja/ko READMEs in sync; AI-assisted PRs allowed if they follow the same rules | Has a "Journaling" category with four entries (Day One, Journey, Life Note, linked); good fit |
| [serhii-londar/open-source-mac-os-apps](https://github.com/serhii-londar/open-source-mac-os-apps) | 50,659 | Edit `applications.json`, not the README; one PR per suggestion; short description ending with a period; ineligible without recent commits or a clear English README; removed if no licence | Good fit; needs a licence and recent commits |
| [jaywcjlove/awesome-swift-macos-apps](https://github.com/jaywcjlove/awesome-swift-macos-apps) | 1,720 | Pull requests welcome; the maintainer says he will feature added apps on his X account | Native Swift; categories include Notes, Markdown, Menubar |
| [iCHAIT/awesome-macOS](https://github.com/iCHAIT/awesome-macOS) | 19,294 | Pull requests need community endorsement ("needs endorsement" label); no Electron apps; no apps whose main purpose is interfacing with LLMs, chatbots or agents; no tracking query strings | Lead with the markdown journal, not the AI draft, or skip |
| [SKaplanOfficial/Mac-Menubar-Megalist](https://github.com/SKaplanOfficial/Mac-Menubar-Megalist) | 127 | Menu bar app list | Small reach; only if there is a menu bar mode |
| awesome-local-first lists (several, for example [alexanderop](https://github.com/alexanderop/awesome-local-first)) | 235 | Pull requests; per-repo rules not read | Low reach, low effort |

I found no list literally named "awesome-macos-menubar"; the closest are the Megalist above and [menubar-apps.github.io](https://menubar-apps.github.io/) [S].

**Directories**
- [MacUpdate](https://www.macupdate.com/help/submit-app) [V]: submission form asks for name (no version numbers), download URL (pkg, dmg or zip, or App Store link), product page, price (blank if free), short and full descriptions without promotional language, version changes and system requirements. The page I could read did not state a notarisation requirement.
- AlternativeTo [S]: free listing; the account must be about seven days old with a verified email; submissions are moderated within days; pricing tags include open source; once listed you can propose it as an alternative to existing apps (for example Day One). Create the account in week 1.
- MacMenuBar ([macmenubar.app](https://macmenubar.app/)) has a Submit button; OpenAlternative ([openalternative.co](https://openalternative.co/submit)) has a submit page; rules for both were not readable [U].

**Homebrew** [V: [Package Acceptance Policy](https://docs.brew.sh/Package-Acceptance-Policy), [Acceptable Casks](https://docs.brew.sh/Acceptable-Casks), [Adding Software](https://docs.brew.sh/Adding-Software-to-Homebrew), [Tap guide](https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap)]

| Official cask requirement | Detail |
|---|---|
| Gatekeeper | Apps must pass Homebrew's Gatekeeper checks and must not require Gatekeeper or SIP to be disabled or bypassed |
| Public presence | Software with a public presence independent of Homebrew and a homepage that explains the project |
| Maintenance | Actively maintained upstream |
| Notability | 30+ forks, 30+ watchers or 75+ stars; if the repository owner submits it: 90+ forks, 90+ watchers or 225+ stars |
| Age | A repository under 30 days old is normally not eligible |
| Not a discovery service | Homebrew's repos are not editorial or recommendation services |
| Process | `brew create --cask URL`, then `brew audit --new --cask` and `brew style --fix --cask`; search earlier PRs first |

- Today: use a personal tap. Name the repo `homebrew-tap` under your account (`brew tap-new` scaffolds it); users then run `brew install --cask dasariprashant0/tap/daily-log`. CodexBar publishes both an official cask and its own tap; boring.notch uses its own tap only [V].
- Earliest official-cask date for this repo: 2026-11-05. Reaching 225 stars in 30 days is not something to count on; a user submitting it needs 75.
- Homebrew 5.0 (2025-11-12) deprecated casks without codesigning, said it would disable failing casks in September 2026, and deprecated `--no-quarantine` ([release post](https://brew.sh/2025/11/12/homebrew-5.0.0/)). As of 2026-10-06 the cask data shows 600 of 7,775 casks disabled with reason `fails_gatekeeper_check` (599 dated 2026-09-01, one dated 2026-10-04; FreeTube is an example) [V, [cask API](https://formulae.brew.sh/api/cask.json)]. The enforcement is real.

**Claude Code plugin marketplace** [V: [Claude Code docs](https://code.claude.com/docs/en/plugins/publish)]
- Your own marketplace is a `.claude-plugin/marketplace.json` in a git repo, with no submission form; users add it with `claude plugin marketplace add owner/repo`. Anthropic's directory needs a paid claude.ai plan and a developer-portal submission; the official marketplace takes no submissions through that portal.
- Worth it only if a plugin or hook materially improves the Daily Log flow (for example triggering a draft at session end). The app can read the local logs without it.

### 3.3 Apple notarisation: cost, need, perception

- **Cost**: US$99 per membership year; fee waivers are offered to eligible nonprofits, accredited educational institutions and government entities [V, [Apple enrol page](https://developer.apple.com/programs/enroll/)]. A free Apple developer account does not include Developer ID signing and notarisation [V, [compare memberships](https://developer.apple.com/support/compare-memberships/)]. The notary service uses `notarytool` (the old `altool` path ended in 2023) [V, [Developer ID page](https://developer.apple.com/developer-id/)]; check `xcrun --find notarytool` on the build machine.
- **Lead time**: Apple states 24-48 hours for individuals, but developers report waits of two to seven weeks or more in 2026 [S, [forum thread](https://developer.apple.com/forums/thread/822540), [another](https://developer.apple.com/forums/thread/817247)]. Enrol on Day 1 and treat the date as unknown.
- **What users see without it**: macOS blocks first launch and the user must go to System Settings, Privacy & Security, choose Open Anyway and confirm [V, [Apple Support](https://support.apple.com/en-us/102445)]. macOS 15 removed the Control-click shortcut ([MacRumors, 2024-08-06](https://www.macrumors.com/2024/08/06/macos-sequoia-gatekeeper-security-change/), [Michael Tsai](https://mjtsai.com/blog/2024/07/05/sequoia-removes-gatekeeper-contextual-menu-override/)); the bypass takes several dialogs and an admin password ([Eclectic Light](https://eclecticlight.co/2024/10/01/living-without-notarization/)). An ad-hoc-signed, quarantined app can also show a misleading "is damaged" message ([HN discussion](https://news.ycombinator.com/item?id=44520949)) [S]. The current README tells users to strip quarantine by hand, which is exactly the friction these sources describe.
- **How it is perceived** (judgement, labelled): technical users accept it, and boring.notch grew without it, but it is the first thing every user meets, Homebrew's main cask now excludes such apps, and Daily Log reads private working logs, so the trust bar is higher than for a window switcher. HN threads on the topic split between "$99 is a tax on open source" and "notarisation is cheap security" [S]. Recommendation: pay before any large launch; keep a build-from-source path and published checksums either way.

---

## 4. Contributor funnel

### 4.1 What the comparables do [V]

| Repo | CONTRIBUTING.md | Issue templates | Discussions | `good first issue` issues ever | Special lane |
|---|---|---|---|---|---|
| Maccy | no (README covers it) | yes (forms) | on | 9 (all closed) | Translations section |
| Ice | no (has code of conduct) | yes (forms) | on | 0 | Sponsors |
| Rectangle | yes | yes | on | 2 (closed) | Contributing section |
| Stats | no | yes (bug) | off | 0 | Translations only; open an issue first |
| AltTab | no | yes (3) | off | 0 | Free Pro for contributors, translators, donors |
| Dayflow | no | yes (bug) | on | 0 | Open an issue first for larger changes |
| boring.notch | yes | yes (forms) | off | 0 | Discord |
| ccusage | yes | yes, including a "contribution" form | on | 22 (all closed) | Docs site |
| CodexBar | no (dedicated docs instead) | none found | off | 10 (all closed) | Provider guide, labelling guide, AGENTS.md |

Counts of `good first issue` come from a GitHub search on 2026-10-06; `help wanted` is heavily used by Stats (63+ closed in the sample returned). Discussions are not required for growth (CodexBar has 482 contributors without them).

### 4.2 Recommended setup for Daily Log

- **Already in place** (per the repo): CONTRIBUTING with hard constraints, code of conduct, security policy, issue forms (bug, feature, config), PR template, CI and release workflows, a 188-test logic layer. This is more than most winners had.
- **Add**:
  - Labels: type (bug, enhancement, docs, question), area, `source: <name>` for importers, `good first issue`, `help wanted`, `needs repro`, `translation`. Borrow CodexBar's rule of 3-5 labels per issue.
  - A `.github/release.yml` so GitHub auto-groups release notes by label ([docs](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes)).
  - An issue-form entry for "request a source or importer" and, if Discussions stay off, a `config.yml` contact link that routes questions to a labelled issue type.
  - A "first PR in 15 minutes" section in CONTRIBUTING: build, run tests, change one string.
- **Seed 8-10 issues before launch**, each with acceptance criteria and a pointer to files: sample-data fixtures; a git-log source; a Codex CLI source with fixtures; an Obsidian daily-note filename option; a VoiceOver label audit; dark-mode screenshots; Homebrew tap docs; a "Claude Code format changed" regression fixture. `good first issue` is what GitHub uses to surface approachable work ([docs](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/encouraging-helpful-contributions-to-your-project-with-labels)). The GitHub community profile checklist (README, code of conduct, licence, CONTRIBUTING, issue templates, security policy) is a quick audit ([docs](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories)).
- **Release notes style**: lead with user impact; 3-6 bullets; link issues and PRs; thank contributors by handle; include the SHA-256; one "Known issues" line. Keep CHANGELOG in the existing Keep a Changelog format. Small frequent releases made the fast climbers look alive, but cadence must stay sustainable for one person.
- **Recognition that costs nothing**: credit in release notes and a contributors section; AltTab's free-licence model does not apply to a free app.
- **Be explicit about what will not be merged** (network calls, telemetry, new dependencies). The existing "Will not do" list and CONTRIBUTING constraints already do this; Stats shows that a clear "open an issue first" rule is a legitimate stance for a small project.

### 4.3 An integration architecture that invites contributions (design sketch only; no code was changed)

Pattern to copy: CodexBar's provider guide describes four steps (one folder, one descriptor with fetch strategies, one implementation, tests and docs), keeps shared host capabilities small and explicit, and keeps each provider's identity data siloed [V, [provider.md](https://raw.githubusercontent.com/steipete/CodexBar/main/docs/provider.md)].

For Daily Log, a "source" (importer) turns local activity into suggested lines for a day's log:

- **Shape**: a protocol with an identifier, a display name, an availability check that touches only local paths, and a function from a day interval to a list of normalised activity items (start, end, project, title, detail). The Claude Code source reads `~/.claude/projects/<project>/<session>.jsonl` (the documented local transcript location [S]); others could cover git history, Codex CLI, Aider, shell history.
- **Rules**: read-only; local only; text out; no network; no dependencies; each source in its own folder (for example `app/Core/Sources/<id>/`), with fixtures in `tests/fixtures/<id>/` and one doc page "add a source in 30 minutes". These match the project's constraints in CONTRIBUTING.
- **Compile-time registry, not dynamic plugins**: loading third-party code at runtime conflicts with hardened runtime, notarisation and the trust story. CodexBar's provider IDs are compile-time for the same reasons [V].
- **A catalogue** (`docs/SOURCES.md`): source, status (shipped, wanted, in progress), owner, fixture link. It is both documentation and a backlog that `good first issue` labels point into.
- **Contract tests**: every source must have a fixture, deterministic output, graceful failure on unknown fields (Claude Code's transcript format is not a stable public API [U]), and a redaction hook so drafts never include secrets.
- Optional, to evaluate later: a language-neutral drop folder where any script can write normalised items as JSON, so people can contribute sources without Swift.

### 4.4 Maintainer sustainability

- Ice: a news-driven spike, then 12 contributors, no release since 2025-09-16 and 440 open issues; a community project filled the gap [V/S]. AltTab: a successor was sought for five years without a taker, then a paid tier [V/S]. Stats: one maintainer who limits contributions on purpose [V].
- For Daily Log: state a support policy in the README (one maintainer; response times are best effort), keep scope narrow, and write down a handover or maintenance-mode plan before the first spike. Do not promise a roadmap; ROADMAP.md already calls its items bets, not promises.

---

## 5. 30-day launch plan

Dates assume Day 1 is Tuesday 2026-10-06; shift them together if you start later.

### 5.0 Prepare beforehand (before or during Week 1)

1. **Apple Developer Program** enrolment (Day 1) and the Developer ID certificate.
2. **Sample-data mode** (section 2.4) and fixtures.
3. **Demo assets**: 15-second looping GIF, 60-90 second walkthrough, 3-6 screenshots (light and dark), 1280 x 640 social preview.
4. **README rewrite** (section 2.2), repo About text, topics (macos, swiftui, menu-bar, markdown, journal, local-first, claude-code), website field.
5. **Claims ledger**: every README claim mapped to a file, a test or a command that proves it (especially privacy).
6. **Release hygiene**: notarised, stapled build; SHA-256; tagged release; Homebrew tap repo and cask.
7. **Repo plumbing**: labels, 8-10 seed issues, release.yml, `docs/SOURCES.md`, `docs/ADD_A_SOURCE.md`.
8. **Accounts and permissions**: HN account with history (check the Show HN notice); Reddit account in good standing and modmail drafts; AlternativeTo account (needs to age about a week).
9. **Launch copy written by hand**: Show HN title and first comment; one post per community with a different angle; a short social post; a DEV outline. Do not generate the HN text.
10. **Q&A crib** for: privacy; why not ccusage, CodexBar or Dayflow; AI-assisted development disclosure; relationship to Anthropic (none; use "works with Claude Code" language); update mechanism; supported macOS.
11. **Metrics baseline** (below) and a clean-machine test (new macOS user or VM).

### 5.1 Launch gates (all must pass before Day 15)

- G1 Notarised and stapled build opens on a clean Mac with no override (a pre-notarisation preview is acceptable for small, friendly communities only).
- G2 Five outside testers installed from the README alone and logged within five minutes.
- G3 Every README claim has proof in the ledger; the privacy table matches the code.
- G4 Sample-data mode and demo assets exist and leak nothing.
- G5 At least 8 labelled issues, templates and CONTRIBUTING are live.
- G6 You can be online for the first 4-6 hours after posting and responsive for 72 hours.
- G7 HN and Reddit prerequisites are in hand.

### 5.2 Day by day

| Day | Date | Action | Done when |
|---|---|---|---|
| 1 | Tue 10-06 | Enrol in Apple Developer Program (US$99). Create the `homebrew-tap` repo. Create the AlternativeTo account. Check HN account status. Save baseline metrics | Enrolment submitted; tap exists; baseline saved |
| 2 | Wed 10-07 | Write the claims ledger and one-sentence positioning; pick the hero line; draft the privacy table; check the code for any network use, entitlements and update checks | Every claim has proof |
| 3 | Thu 10-08 | Build sample-data mode with a fabricated week and a fabricated Claude Code session fixture in a separate demo folder | Fresh launch shows a full week with no personal data |
| 4 | Fri 10-09 | Record assets: README loop, walkthrough, screenshots | Files reviewed for leaks (window titles, usernames, project names) |
| 5 | Sat 10-10 | Social preview image; About text; topics; README v1 per 2.2 | README renders well in light and dark on GitHub |
| 6 | Sun 10-11 | Repo plumbing: labels, issue config, release.yml, SOURCES.md, ADD_A_SOURCE.md, 8-10 seed issues | `good first issue` filter shows at least 6 issues with acceptance criteria |
| 7 | Mon 10-12 | Clean-machine test: install, Gatekeeper path, first log, uninstall; time it; fix the top three friction points; tag a pre-release | A stranger-equivalent path works end to end |
| 8 | Tue 10-13 | If enrolment is approved: Developer ID sign with hardened runtime, notarise, staple, verify on a clean Mac; publish v0.3.0 with SHA-256. If not: contact Apple Developer Support with the enrolment ID and keep Gate G1 closed | App opens with no Gatekeeper override |
| 9 | Wed 10-14 | Publish the tap cask; test `brew install --cask dasariprashant0/tap/daily-log` on a clean machine; update the README install block; remove the manual quarantine advice | Install works from the README alone |
| 10 | Thu 10-15 | Soft launch to 5-10 people who match the audience (Claude Code users who write standups, markdown journallers). Ask for first impressions, no stars. Send modmail to r/macapps and the Claude subreddits asking what format they allow | Feedback collected; mod replies pending |
| 11 | Fri 10-16 | Triage feedback; fix; ship v0.3.1 with hand-written notes; add real questions to the FAQ | Top friction removed |
| 12 | Sat 10-17 | Write all launch copy by hand; check each claim against the ledger | Copy reviewed for over-claims |
| 13 | Sun 10-18 | Q&A crib; line up availability for 72 hours; check that your HN account is not under the Show HN restriction | Crib done; account OK |
| 14 | Mon 10-19 | Gate review (5.1). Go or hold | Decision recorded |
| 15 | Tue 10-20 | **Show HN.** Post, add the first comment within minutes, stay in the thread. No vote requests anywhere | Every comment answered |
| 16 | Wed 10-21 | Fixes and a patch release if needed. One post on X and Bluesky with the 60-second clip. Record GitHub Traffic referrers | Referrer data saved |
| 17 | Thu 10-22 | r/macapps post (or the megathread if modmail did not approve). Mac-user angle | Post live; replies answered |
| 18 | Fri 10-23 | DEV post (#showdev, honest AI-use tag) that teaches something technical; cross-post to Hashnode with a canonical link | Post live |
| 19-20 | Sat-Sun 10-24 / 10-25 | No new promotion. Triage, label, thank, merge small fixes; update FAQ | Inbox at zero |
| 21 | Mon 10-26 | Retro 1: stars, referrers, stranger-filed issues, themes in comments | Next-wave choices made from data |
| 22 | Tue 10-27 | r/ClaudeAI or r/ClaudeCode post per mod guidance; show the draft preview and exactly what leaves the machine | Post live |
| 23 | Wed 10-28 | Only if useful: package a Claude Code plugin in your own marketplace repo; document it | Plugin installs from a clean setup |
| 24 | Thu 10-29 | Submissions, one each, in fit order: awesome-mac (Journaling), open-source-mac-os-apps, awesome-swift-macos-apps, awesome-claude-code (only if Claude-specific; eligible about 10-20), MacUpdate, AlternativeTo, MacMenuBar | Submissions filed |
| 25 | Fri 10-30 | Newsletters: Changelog News (angle: what launch week taught you), Console.dev (only with the developer-facing Claude Code angle), iOS Dev Weekly (the technical post only) | Submissions filed |
| 26 | Sat 10-31 | Contributor day: welcome first-timers, add 3 source-request issues from feedback, check CI | Five or more open `good first issue` |
| 27 | Sun 11-01 | Buffer and rest | |
| 28 | Mon 11-02 | Decide on Product Hunt: skip unless you can be online all day | Decision recorded |
| 29 | Tue 11-03 | Release v0.4.0 with a feature that came from launch feedback; credit contributors; a short update post (not a second Show HN) | Release out |
| 30 | Wed 11-04 | Retro 2 against targets. Check official-cask readiness for Day 31 (2026-11-05): notarised, 75 or 225 stars, repo 30 days old, `brew audit --new --cask` | Plan for the next 30 days |

### 5.3 Metrics without telemetry, and planning targets

- **Public signals**: stars, forks, watchers; release asset downloads (includes updates, so an upper bound); GitHub Traffic (views, clones, referrers, popular content; kept for only 14 days, visible to people with push access, so snapshot weekly) [V, [docs](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-traffic-to-a-repository)]; issues and PRs from strangers; the cask's install count once it is in the official cask (a personal tap has no public count [U]).
- **Manual retention**: ask the soft-launch group at Day 14 and Day 30 whether they still use it. This respects the no-telemetry rule.
- **Planning targets (assumptions, not benchmarks)**: by Day 30, 100-300 stars, at least 3 issues filed by people you do not know, at least 1 external PR, at least 10 people who confirm they still use it. Treat more than about 1,000 stars as the result of a hook or luck. If the soft-launch group stops using it within a week, fix the product before the public launch.

### 5.4 Contingencies

- **Apple enrolment is slow**: launch to small, friendly communities with a clearly labelled pre-notarisation build and a checksum; hold HN and the Homebrew cask until notarised.
- **Show HN does not take off**: do not repost or delete and repost; keep the other channels on schedule; read the comments for the real objection.
- **A bug in the first hour**: fix publicly and quickly; a visible fix is a good signal.
- **A "why not X" pile-on**: answer with the comparison table and the specific job difference; do not disparage others.
- **A privacy challenge**: link the claims ledger and the code, and correct anything that was imprecise.

---

## 6. Pitfalls

| Pitfall | Evidence | What to do instead |
|---|---|---|
| Asking for upvotes or stars | HN forbids soliciting votes, comments or submissions [V]. Product Hunt forbids asking directly [V]. A developer's r/macapps launch checklist includes not asking for upvotes or GitHub stars [S] | Ask for feedback and bug reports |
| LLM-written posts or comments on HN | HN guidelines ask for human-written text [V]. DEV requires AI disclosure and says AI-assisted articles should not promote your own product [V/S] | Write launch text yourself; tag AI use honestly |
| Launching from a thin account | HN's Show HN restriction for accounts without history [V]; r/macapps karma and 30-day rules [S]; AlternativeTo account age [S] | Build real participation weeks ahead; one real account, real name |
| Astroturfing or buying stars | A study of GitHub Archive data found millions of suspected fake stars (4.5 million in the first version of the paper, six million in its current title), with campaigns surging in 2024, mostly promoting scams and malware, and a detector that finds them at scale [V/S, [arXiv 2412.13459](https://arxiv.org/pdf/2412.13459), [coverage](https://www.bleepingcomputer.com/news/security/over-31-million-fake-stars-on-github-projects-used-to-boost-rankings/)] | No sockpuppets, no star services, no vote groups. Disclose that you are the author everywhere |
| Cross-posting identical text | r/macapps removes cross-posted identical content [S] | One post per community with a different angle |
| Over-claiming privacy | Dayflow and CodexBar state precisely what leaves the machine and why permissions are needed [V]; Stats was criticised for an update check [S] | The privacy table, an opt-in update check, and "nothing leaves your Mac" only if it is literally true |
| Hiding AI assistance | HN and Reddit are hostile to undisclosed vibe-coded projects ([r/selfhosted change](https://news.ycombinator.com/item?id=46677446), Show HN flood). ccusage disclosed that most code was written by Claude Code and still thrived [S] | Disclose in the README; show tests and real use |
| Over-claiming the product | "First", "only", "best", user counts you cannot measure | Claims ledger; compare only on verified facts |
| Over-promising the roadmap | Roadmap items are bets, as ROADMAP.md says | Say "we are looking at this" and mean it |
| Implying affiliation with Anthropic | Not researched in detail [U] | Use "works with Claude Code"; do not use logos; state it is unofficial |
| Un-notarised launch to a technical crowd | Section 3.3; 600 casks disabled [V] | Gate G1 |
| Impersonation after you grow | Maccy's README warns about fake sites [V] | Canonical download links, SHA-256, one official site |
| Bus factor | Ice stalled; AltTab sought a successor for years [V] | Support policy; handover plan |
| Chasing stars over use | Installs per star vary from 0.2 to 5.1 [V]; the biggest Claude Code repos are config packs [V] | Track use signals; do not benchmark against them |
| Believing README conversion statistics | Unsourced blog claims [U] | Test your own hero line in the soft launch |
| Depending on an undocumented transcript format | Claude Code keeps transcripts locally for 30 days by default [S]; format not a stable API [U] | Fixtures, graceful failure, regression tests |
| Planning around Hacktoberfest | Pull requests no longer earn rewards in 2026 [V, [hacktoberfest.com](https://hacktoberfest.com/)] | Use your own good-first-issue lane |
| Generic name, weak search | 21 Swift repos named daily-log, top one with 2 stars, so GitHub collisions are mild; web search for "daily log" is generic [V/U] | Put a distinctive descriptor in the repo title and About text |

---

## 7. Open questions and what this research could not verify

- First 100 and first 1,000 star dates for every case study (GitHub stargazer timestamps need authentication; archives had gaps).
- Any base rate for Show HN, Reddit or Product Hunt outcomes. All case studies are survivors.
- Reddit rules are second-hand (the fetch tool could not read Reddit); r/ClaudeCode rules were not found; r/macapps "Trust path" wording is ambiguous.
- AlternativeTo and MacUpdate review times and whether either expects notarisation.
- Whether X, Bluesky or Product Hunt moved any of these projects; only practice was found (hashtag requests, release posts).
- Demand for a standup or journal drafted from Claude Code sessions (one zero-star repo and no visible signal either way).
- Notarisation status of each case study is inferred from the official cask entry (enabled as of 2026-10-06), not from inspecting binaries.
- A later founder post by Dayflow ("500k hours of beta use") appeared only as a search snippet and is not used for dating.
- Anthropic's brand rules for third-party tools were not researched.

---

## Appendix A: reproduce and refresh the numbers

```bash
# Homebrew install counts (official casks only)
curl -s https://formulae.brew.sh/api/cask/maccy.json | jq '.analytics.install'

# Date of the Nth star (needs `gh auth login`; list is oldest-first, check on a small repo first)
nth_star() { local repo=$1 n=$2 per=100
  local page=$(( (n + per - 1) / per )) idx=$(( (n - 1) % per ))
  gh api -H "Accept: application/vnd.github.star+json" \
    "repos/$repo/stargazers?per_page=$per&page=$page" --jq ".[$idx].starred_at"; }
nth_star p0deje/Maccy 100
nth_star p0deje/Maccy 1000

# Total release downloads
gh api "repos/OWNER/REPO/releases?per_page=100" --jq '[.[].assets[].download_count] | add'

# Weekly Traffic snapshot (14-day window; push access required)
gh api repos/dasariprashant0/daily-log/traffic/views
gh api repos/dasariprashant0/daily-log/traffic/popular/referrers

# Good-first-issue counts
gh search issues --repo OWNER/REPO --label "good first issue" --limit 100 --json number,state
```

## Appendix B: sources by topic

Case-study data and pages
- GitHub API and READMEs for: p0deje/Maccy, rxhanson/Rectangle, exelban/stats, lwouis/alt-tab-macos, jordanbaird/Ice, TheBoredTeam/boring.notch, JerryZLiu/Dayflow, ccusage/ccusage, matt1398/claude-devtools, Maciek-roboblog/Claude-Code-Usage-Monitor, steipete/CodexBar, thaw-app/Thaw.
- Homebrew cask API: https://formulae.brew.sh/api/cask.json and per-cask JSON; npm API: https://api.npmjs.org/downloads/point/last-month/ccusage
- HN: Dayflow https://news.ycombinator.com/item?id=45361268; Ice https://news.ycombinator.com/item?id=40605532; Bartender sale https://news.ycombinator.com/item?id=40584606; Stats https://news.ycombinator.com/item?id=42881342; AltTab Pro https://news.ycombinator.com/item?id=48283349; Claude Code Usage Monitor https://news.ycombinator.com/item?id=44317012; macOS menu bar app to track Claude usage https://news.ycombinator.com/item?id=46544524; CodexBar comparison https://news.ycombinator.com/item?id=48477047; ccusage mention https://news.ycombinator.com/item?id=44439059
- AltTab maintainer issue: https://github.com/lwouis/alt-tab-macos/issues/1179
- ccusage origin post: https://ryoppippi.com/blog/2025-05-29-zenn-6c9a8fe6629cd6-ja/
- Maccy site: https://maccy.app/ ; Dayflow at YC: https://www.ycombinator.com/companies/dayflow ; Peter Steinberger: https://en.wikipedia.org/wiki/Peter_Steinberger_(programmer) ; star-history page for CodexBar: https://www.star-history.com/steipete/codexbar/
- CodexBar provider guide: https://raw.githubusercontent.com/steipete/CodexBar/main/docs/provider.md ; labelling guide: https://raw.githubusercontent.com/steipete/CodexBar/main/docs/ISSUE_LABELING.md

Channels and rules
- HN: https://news.ycombinator.com/showhn.html ; https://news.ycombinator.com/newsguidelines.html ; https://news.ycombinator.com/showlim ; https://news.ycombinator.com/item?id=47864393 ; Show HN analysis https://www.adriankrebs.ch/blog/design-slop/
- Reddit (second-hand): https://www.threadotter.com/subreddit-rules/macapps ; https://github.com/mactools-app/MacTools/issues/334 ; https://www.threadotter.com/subreddit-rules/ClaudeAI ; https://www.threadotter.com/subreddit-rules/selfhosted ; https://www.threadotter.com/subreddit-rules/opensource ; https://www.threadotter.com/subreddit-rules/SwiftUI ; https://www.threadotter.com/subreddit-rules/SideProject ; https://news.ycombinator.com/item?id=46677446
- Product Hunt: https://www.producthunt.com/launch ; https://help.producthunt.com/en/articles/484935-can-i-ask-my-community-friends-family-to-upvote-a-product
- DEV: https://dev.to/t/showdev ; https://dev.to/devteam/introducing-ai-disclosure-on-dev-tools-for-nuance-clarity-and-better-feeds-34mk ; https://dev.to/guidelines-for-ai-assisted-articles-on-dev
- Newsletters: https://console.dev/selection-criteria ; https://changelog.com/news/submit ; https://suggest.iosdevweekly.com/
- Awesome lists: https://github.com/hesreallyhim/awesome-claude-code (CONTRIBUTING.md) ; https://github.com/jaywcjlove/awesome-mac (docs/CONTRIBUTING.md) ; https://github.com/serhii-londar/open-source-mac-os-apps (CONTRIBUTING.md) ; https://github.com/iCHAIT/awesome-macOS (.github/contributing.md) ; https://github.com/jaywcjlove/awesome-swift-macos-apps ; https://github.com/SKaplanOfficial/Mac-Menubar-Megalist ; https://github.com/alexanderop/awesome-local-first
- Directories: https://www.macupdate.com/help/submit-app ; https://macmenubar.app/ ; https://openalternative.co/submit ; AlternativeTo submission summary https://buttondown.com/where-to-post/archive/submitting-on-alternativetonet/
- Claude Code plugins: https://code.claude.com/docs/en/plugins/publish ; data and retention: https://code.claude.com/docs/en/data-usage

Homebrew and Apple
- https://docs.brew.sh/Package-Acceptance-Policy ; https://docs.brew.sh/Acceptable-Casks ; https://docs.brew.sh/Adding-Software-to-Homebrew ; https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap ; https://brew.sh/2025/11/12/homebrew-5.0.0/ ; https://github.com/orgs/Homebrew/discussions/6334
- https://developer.apple.com/programs/enroll/ ; https://developer.apple.com/support/compare-memberships/ ; https://developer.apple.com/developer-id/ ; https://support.apple.com/en-us/102445 ; https://www.macrumors.com/2024/08/06/macos-sequoia-gatekeeper-security-change/ ; https://mjtsai.com/blog/2024/07/05/sequoia-removes-gatekeeper-contextual-menu-override/ ; https://eclecticlight.co/2024/10/01/living-without-notarization/ ; https://developer.apple.com/forums/thread/822540 ; https://developer.apple.com/forums/thread/817247

GitHub features and integrity
- https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/attaching-files ; https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview ; https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes ; https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-traffic-to-a-repository ; https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/encouraging-helpful-contributions-to-your-project-with-labels ; https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/about-community-profiles-for-public-repositories
- Fake stars: https://arxiv.org/pdf/2412.13459 ; https://www.bleepingcomputer.com/news/security/over-31-million-fake-stars-on-github-projects-used-to-boost-rankings/
- Hacktoberfest: https://hacktoberfest.com/
