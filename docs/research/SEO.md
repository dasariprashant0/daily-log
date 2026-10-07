# SEO and discoverability plan

- Product: native macOS work-journal app (working title "Daily Log"), MIT, local-first
- Repo: github.com/dasariprashant0/daily-log
- Research date: 2026-10-06. Every count, star total and availability result below is a snapshot from that day.
- Status: research only. Nothing in the repo or on any external service was changed.

Contents: [0 Read first](#0-read-this-first) · [1 Landscape](#1-the-landscape) · [2 Keywords](#2-keyword-research) · [3 Naming](#3-naming) · [4 GitHub SEO](#4-github-seo) · [5 Landing page](#5-landing-page-github-pages) · [6 Off-site and timeline](#6-off-site-backlinks-and-realistic-timeline) · [7 Measurement](#7-measurement) · [8 Checklist](#8-checklist-ordered-by-impact-and-effort) · [9 Accuracy notes](#9-accuracy-and-risk-notes) · [10 Sources](#10-sources) · [Appendix](#appendix-autocomplete-evidence-2026-10-06)

---

## 0. Read this first

### Data limits (be sceptical of anything that looks too precise)

- **No search-volume data.** The Semrush MCP could not be loaded in this run (tool search was disabled), so it was skipped as instructed. No Ahrefs or Keyword Planner either. "Competition" below is my judgement from who ranks today and how large they are, not a keyword-difficulty score. Autocomplete proves a phrase is typed, not how often.
- Autocomplete came from Google's unofficial suggest endpoint, fetched through a summarising proxy from an unknown location. Five result sets looked machine-written rather than real suggestions and were discarded: "generate standup from github", "performance review self assessment generator", "journal app for developers", "work journal for performance review", "automatic standup".
- Availability checks are same-day registry and API lookups. Names get registered daily. Re-run before buying (commands in 3.3).
- Not checked: trademark registers (USPTO, EUIPO, WIPO), Mac App Store name search, social handles, Product Hunt.
- Anything labelled "estimate" is my judgement, not data.

### The seven decisions that matter most

1. **Rename first.** "Daily Log" is a generic phrase owned by construction and field-logging products. It cannot be a brand (section 3.1).
2. **Name: Gloamlog (recommended), Quillwell and Dusklog (backups).** Gloamlog was free on GitHub (user and repo), npm, PyPI, .dev, .app, .com and Homebrew (cask and formula) on 2026-10-06 and had no software namesake. Vesperlog, Cairnlog, Tidelog and Owlight looked good but collide with live products in this exact niche.
3. **Compete in two small ponds, not the big one.** "Automatic work journal" belongs to Dayflow (7.2k stars, screen capture) and Meridian (405). Open ground: "Claude Code + journal / work log / daily summary" (GitHub best-match top 10 for "claude code work log" held repos with 4 to 96 stars) and a native Mac app that *makes you write*, which none of the projects I found do.
4. **Do not publish "writes itself from your Claude sessions" until it ships.** PRD v0.2 lists AI summaries as a non-goal and ROADMAP ranks an opt-in AI summary 6th. Also decide how drafting works: parsing local transcripts is local; calling a model usually is not, and "no network" claims must match (section 9).
5. **Notarise before launching.** Homebrew's main cask repo disables apps that fail Gatekeeper from September 2026, and macOS 15 removed the right-click-Open bypass your README recommends.
6. **Use a custom domain for the landing page**, not `github.io/daily-log`: a project-site robots.txt is ignored by crawlers, and renaming the repo breaks the project-site URL.
7. **Realistic outcome:** GitHub search position within days; Google long-tail in 2 to 4 months; head terms ("work journal app", "brag document") not in year one. First stars come from launch channels, not search.

### If you only have two hours

Pick the name (1), rename the repo, set the About description and 20 topics (4.3, 4.4), rewrite the README top fold with one screenshot, upload the 1280x640 social preview, cut a release with named assets. That is checklist items 1 to 6 in section 8 and captures most of the cheap upside.

---

## 1. The landscape

Stars are from 2026-10-06. These are the projects a searcher will see next to yours.

| Project | Stars | What it does | Why it matters |
|---|---|---|---|
| [Dayflow](https://github.com/JerryZLiu/Dayflow) (JerryZLiu) | 7.2k | Screen-capture "automatic work journal"; macOS 14+; MIT; official Homebrew cask `dayflow`; own site dayflow.so; created 2025-09-23 | Owns "automatic work journal" on GitHub. Its README (timeline, daily standup, weekly review, privacy, install) is the structure to beat. |
| [Work-Review](https://github.com/wm94i/Work-Review) (wm94i) | 1.8k | Automatic app and website time tracking; MIT; topic `work-log` | Top of the `work-log` topic |
| [Agent Sessions](https://github.com/jazzyalex/agent-sessions) (jazzyalex) | 891 | macOS app to browse, search and resume sessions of 16+ coding agents incl. Claude Code; MIT; GitHub Pages site; own Homebrew tap | Nearest "native Mac app that reads Claude sessions", but a viewer, not a journal |
| [Meridian](https://github.com/Meridiona/meridian) (Meridiona) | 405 | Screen-activity work journal, Jira worklog drafts; macOS and Windows; MIT; topic `worklog` | Second owner of "automatic work journal" |
| [engineering-notebook](https://github.com/prime-radiant-inc/engineering-notebook) | 342 | Bun CLI: ingests Claude Code and Codex transcripts, LLM daily summaries, web UI; Apache-2.0; created 2026-02-24 | Closest functional match to "auto-draft from Claude sessions" (CLI and web, not a native app) |
| [brag-doc](https://github.com/deeheber/brag-doc) (deeheber) | 15 | Two Claude Code skills: log wins daily, generate promotion and review drafts; MIT | Owns topic `brag-doc` |
| [Pulse](https://github.com/muhammademanaftab/pulse) | 9 | "A memory layer for your Claude Code work", writes daily notes; Python; MIT | Same idea, tiny |
| [DevLog](https://github.com/moose-lab/DevLog) (moose-lab) | 4 | Searchable AI coding-agent work journal CLI and dashboard; no licence | Same idea, tiny |
| [daily-journal](https://github.com/pylenius/daily-journal) (pylenius) | 0 | Claude Code plugin plus SwiftUI iPhone/iPad app, MIT, created 2026-09-04 | Newest direct overlap, and a near-namesake of "Daily Log" |
| Vesper ([vesperlog.com](https://vesperlog.com)) | n/a | Private-beta web SaaS: daily work journal that builds performance-review evidence | Why "Vesperlog" was rejected |
| [git-standup](https://github.com/kamranahmedse/git-standup) | 7.9k | CLI listing your commits from the last working day | Owns "git standup" |

**What none of them do:** make you write. Dayflow and Meridian record the screen; engineering-notebook, Pulse and DevLog summarise transcripts for you; brag-doc logs wins through a skill. A native Mac app with an enforced end-of-day write-up that can pre-fill from Claude Code sessions is an uncontested combination in these searches. Use that as the copy angle, but only once it is true (section 9).

---

## 2. Keyword research

### 2.1 How to read the tables

Evidence codes: **AC** = seen in Google autocomplete on 2026-10-06. **SERP** = I inspected the results page. **GH** = I inspected GitHub search, topic pages or the API. **UV** = unverified hypothesis (not observed).

Competition is relative to a brand-new repo and a one-page site: **Low / Medium / High / Very high**. "Repo" and "Site" say whether the GitHub repo page (in Google and in GitHub search) or the landing page can realistically win a top-10 slot: **Yes** (plausible within 3 to 6 months), **Maybe**, **No**.

Total queries listed: 38. Autocomplete suggestions behind them are in the appendix.

### 2.2 Queries by intent

#### A. Category searches ("which app should I use?"), commercial investigation

| # | Query | Evidence | Competition | Who ranks / what I saw | Repo | Site |
|---|---|---|---|---|---|---|
| 1 | work journal app | AC | High | Day One, Diarly, Apple Journal, Zapier roundups, App Store "Work Diary" | Maybe (GitHub search) | No |
| 2 | work log app mac | SERP (AC adds "time log app mac") | High, wrong intent | App Store "Work Log" time trackers, Clockify, TrackingTime. Intent is time tracking. | No | No |
| 3 | work diary app | AC | High | App Store "Work Diary", Day One | No | No |
| 4 | daily work log | AC | High, template intent | Excel and Word templates | No | No |
| 5 | software engineer work log | AC | Medium | The Pragmatic Engineer "A Work Log Template for Software Engineers" (high authority) | Yes (README section) | Maybe |
| 6 | mac journal app | AC | High | Apple Journal, Day One, Diarly, MacRumors threads | No | No |
| 7 | markdown journal app mac (also "best markdown journal macos", "open source markdown journal macos") | AC | Medium | Roundups (David Mytton, MacMD Viewer posts) | Yes | Yes |
| 8 | open source journal app (also "best open source journal app", "...for mac") | AC | Medium | Listicles: LinuxLinks, medevel, mactools.pro, unstore.io, memexlab.ai. Getting into these lists is the lever. | Yes | Yes |
| 9 | day one open source alternative (head term: "day one alternative") | AC | Medium (long form), High (head) | AlternativeTo, Reddit threads | Yes (README "Compared with") | Yes |
| 10 | jrnl alternative | AC | Medium | Not inspected | Maybe | Maybe |

#### B. Claude Code-specific (tool-seeking). Lowest competition, highest relevance

| # | Query | Evidence | Competition | Who ranks / what I saw | Repo | Site |
|---|---|---|---|---|---|---|
| 11 | claude code journal (also "journal tool", "journal skill", "claude code diary") | AC, GH | Low to Medium | engineering-notebook (342), claude_code_journaling (149), dev-journal, claude-code-session-journal, mostly small repos | Yes | Yes |
| 12 | claude code daily summary | SERP (AC only offers limit, usage, routine) | Low | A GitHub gist ("Today in Claude Code"), prajwalram8/ClaudeDailyDigest, mcpmarket skills, an X post | Yes | Yes |
| 13 | claude code work log (or "worklog") | GH, SERP | Low | GitHub best-match top 10 (211 results) holds repos with 4, 4, 5, 9, 12, 27, 34, 41, 53 and 96 stars | Yes | Yes |
| 14 | claude code standup | AC ("claude code stand up skill") | Low | Skills | Maybe | Maybe |
| 15 | claude code session history | AC, SERP | Medium to High | dev.to "I Tested 4 Tools for Browsing Claude Code Session History", jhlee0409 viewer, Medium, HN, mcpmarket | Maybe | Maybe (you are not a viewer; do not promise one) |
| 16 | claude code sessions directory | AC | Low | Not inspected | n/a | Guide page (Phase 2) |
| 17 | claude code history disappeared (also "session disappeared", "history gone") | AC | Medium | anthropics/claude-code issues (#95203, #62041, #18881), blog posts | n/a | Guide or blog post (strong hook, see 2.5) |
| 18 | claude code export conversation to markdown | AC | Medium | ccexport (GitHub), dev.to, kentgigger.com, the built-in `/export` | Maybe | Guide |
| 19 | claude code time tracking | SERP | Low to Medium | Small repos: claude-code-timelog, claude-worktime, claude-session-tracker | Maybe (off-core) | No |
| 20 | summarize claude code sessions | UV | Unknown, probably Low | Not inspected | Maybe | Maybe (test in Search Console) |
| 21 | claude desktop history | AC | Medium, ambiguous | Intent mixes version history and chat export | No | No (see section 9 caveat) |
| 22 | claude code history viewer | AC, SERP | High | Product Hunt, jhlee0409 (with its own github.io page), yanicklandry, a VS Code extension, usemagictools | No | No. Mention in README compare only. |
| 23 | claude code usage tracker | AC | High, wrong intent | claude-usage (2.3k stars), tokens and cost trackers | No | No |

#### C. Use-case searches (standups, brag docs, reviews)

| # | Query | Evidence | Competition | Who ranks / what I saw | Repo | Site |
|---|---|---|---|---|---|---|
| 24 | daily standup generator | AC (thin), SERP | Medium | Ona, dev.to, Taskade, fifthdraft.ai, t0ggles, mcpmarket. GitHub results top out at 10 stars. | Maybe | No (you are not a generator) |
| 25 | git standup | AC, GH | High | git-standup, 7.9k stars | No | No |
| 26 | brag document tool (or "app") | SERP | Medium | clementino-labs/bragdoc, bovem/brag (23 stars), a Notion template, bragbook.io, getbragdoc.com, bragdoc.ai. Top GitHub repo for "brag document" has 46 stars. | Yes (GitHub) | Maybe |
| 27 | brag document / template / example | AC | Very high | Julia Evans, ClickUp, Notion, dev.to | No | No |
| 28 | brag document software engineer | AC | High | Guides and templates | No | No |
| 29 | track accomplishments at work | AC | Medium to High | HR and career blogs | No | Content later |
| 30 | end of day report template | AC | High, off-intent | Ops and retail templates | No | No |
| 31 | standup notes template | AC | High | Templates | No | No |
| 32 | work journal template | AC | High | Word, Excel, Notion, Docs, OneNote templates | No | No |

#### D. Auto and AI journal

| # | Query | Evidence | Competition | Who ranks / what I saw | Repo | Site |
|---|---|---|---|---|---|---|
| 33 | ai work journal (also "ai work diary", "ai work log") | AC | Medium (polluted by "journalist" results) | Mixed | Yes | Yes |
| 34 | automatic work journal | GH (Dayflow tagline) | Very high on GitHub | Dayflow 7.2k, Meridian 405 | No for the head term. Win "from Claude sessions" instead. | No |
| 35 | automated work log | AC | High, intent is Jira or time logging | Jira worklog tools | No | No |

#### E. Brand and comparison (exist only after launch)

| # | Query | Evidence | Competition | Notes | Repo | Site |
|---|---|---|---|---|---|---|
| 36 | `<name>`, `<name> app`, `<name> mac`, `<name> github` | n/a | None if the name is unique | Rank #1 within weeks if the token is unique. Quick win and a reason to fix the name. | Yes | Yes |
| 37 | dayflow alternative, `<name>` vs dayflow | UV (AlternativeTo has a Dayflow page listing 12 alternatives) | Low | Comparison section plus an AlternativeTo listing | Yes | Yes |
| 38 | daily log app | AC, SERP | Very high, wrong intent | "daily log app for construction", Sitemate, Google Play "Day Log", a Jotform template. This is the reason to rename. | No | No |

### 2.3 What to target first (ownership map, designed before Search Console data exists)

| Cluster | Owner page | Notes |
|---|---|---|
| Brand and "`<name>` + app/mac/github" | Landing page `/` (repo is the second result) | Two listings on the SERP is good, not cannibalisation, because they are different hosts. |
| claude code journal, daily summary, work log, standup (rows 11 to 14) | Repo README and landing page | The repo wins GitHub search and Google's GitHub results; the landing page wins the "Mac app" framing. |
| open source journal, markdown journal, day one alternative (rows 7 to 9) | Landing page, via listicle inclusion and AlternativeTo | README carries a matching "Compared with" section. |
| brag document tool, standup (rows 24, 26) | Repo, GitHub search only | Use topics, not landing-page copy. |
| claude code sessions directory, history disappeared, export (rows 16 to 18) | Future guides on your domain (Phase 2), one guide per cluster | The home page does not target these, so guides and home never compete. |

### 2.4 Avoid (do not write copy for these)

Rows 2 to 4, 6, 21 to 23, 25, 27 to 32, 34, 35, 38. Reasons: wrong intent (time tracking, templates, token cost), a dominant incumbent, or a head term that Ahrefs-type data says new pages almost never win (section 6.3).

### 2.5 Content angle discovered during research

Claude Code deletes local session transcripts older than 30 days by default (`cleanupPeriodDays`, minimum 1, default 30; per Anthropic's docs, confirm on the page). Sessions started in Claude Desktop are kept longer unless `desktopSessionCleanupPeriodDays` is set. Several GitHub issues and blog posts describe users losing history, and "claude code history disappeared" is in autocomplete. A daily log that preserves what you did *before* the cleanup is a concrete, verifiable benefit and a natural article (6.2). Verify the current default and wording before publishing.

---

## 3. Naming

### 3.1 Is "Daily Log" searchable? No.

- Autocomplete for "daily log app": "daily log app for construction", "...free", "...for iphone", "...android", "...windows", "daily appointment log", "daily journal app", "daily tracker app".
- SERP: Google Play "Day Log", a Jotform "Daily Log App Template", Sitemate's "Daily Log App: Best construction and field work daily logs", App Store "Work Log - Time sheet", AlternativeTo "Day Log Journal".
- GitHub: topic `daily-log` has 42 repos (top has 8 stars); repos named `daily-log` or `dailylog` already exist (joemasilotti/daily-log, SamanQasempour/daily-log, madCode/dailylog); `pylenius/daily-journal` sits in your exact niche.
- Verdict: unwinnable as a brand and confusing as a product name. Keep "daily log" as a descriptor in prose ("a daily log app for Mac") and as the GitHub topic `daily-log`, where #1 is reachable.

### 3.2 Constraints applied to every candidate

- **No "Claude" or "Anthropic" in the name, logo, domain, repo or Homebrew token.** Anthropic's Claude Code legal page: you can accurately say in plain text that a product runs Claude Code, but you "can't use the Claude Code or Anthropic names or logos as part of your own product, feature, or company name, in your own logo, or in a way that suggests Anthropic built, endorses, or is partnered with your product." Other uses need written permission (trademark guidelines; contact address given there is marketing@anthropic.com). Plain-text "works with Claude Code" is the safe pattern. Add "Not affiliated with Anthropic" in the README and footer. Avoid the Claude starburst and orange palette in the icon.
- **Stay out of the "Day-" family** (Dayflow is the 7.2k-star leader). Dayrite, Daydraft, Dayscribe and Daylit invite mix-ups.
- **No names built on words that give 100k noisy results** (Journal, Log alone, Vesper, Cairn, Quill alone).
- **One token, 6 to 9 letters, no hyphen, spellable when heard.**
- `.dev` and `.app` are on the browser HSTS preload list (HTTPS-only), which suits Pages. Google treats any TLD that is not a country code as a generic TLD with no geographic signal; I found no sign of a ranking difference versus .com.

### 3.3 What I checked (and how to re-run it)

Checked per name: GitHub user or org (`github.com/<name>`), GitHub repo-name search, `<name>.dev` and `<name>.app` via the Google Registry RDAP, `<name>.com` via Verisign RDAP, Homebrew cask and formula API, web search for namesakes (software, apps, companies), and for the finalists npm, PyPI and what is hosted on any taken domain.

Re-run (404 = free; 200 = taken):

```sh
n=gloamlog
curl -s -o /dev/null -w "github user/org %{http_code}\n"  https://github.com/$n
curl -s -o /dev/null -w "github repo     %{http_code}\n"  https://github.com/$n/$n
curl -s -o /dev/null -w ".dev            %{http_code}\n"  https://pubapi.registry.google/rdap/domain/$n.dev
curl -s -o /dev/null -w ".app            %{http_code}\n"  https://pubapi.registry.google/rdap/domain/$n.app
curl -s -o /dev/null -w ".com            %{http_code}\n"  https://rdap.verisign.com/com/v1/domain/$n.com
curl -s -o /dev/null -w "brew cask       %{http_code}\n"  https://formulae.brew.sh/api/cask/$n.json
curl -s -o /dev/null -w "brew formula    %{http_code}\n"  https://formulae.brew.sh/api/formula/$n.json
curl -s -o /dev/null -w "npm             %{http_code}\n"  https://registry.npmjs.org/$n
curl -s -o /dev/null -w "pypi            %{http_code}\n"  https://pypi.org/pypi/$n/json
```

Registry lookups are rate-limited (I hit HTTP 429 once); space them out. "Free" in RDAP means unregistered at that moment, not "available to buy at a normal price".

### 3.4 The eight candidates

| # | Name | GitHub user/org | .dev | .app | .com | brew cask / formula | Namesakes found | Say it, spell it | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Gloamlog** | free | free | free | free | free / free (npm, PyPI also free) | None exact. Neighbours: "Gloam" HDR/night-mode tool for Windows (getgloam.org), a sunset-tracking app, a sunrise/sunset data-viz repo, a Korean app "Gloam" on Google Play. GitHub repo-name search: 0 results. | "GLOHM-log". Gloam = twilight (Merriam-Webster). Risk: heard as "gloom". | **Recommended** |
| 2 | **Quillwell** | taken (dormant, 0 repos) | free | free | taken (2017) | free / not checked (npm free) | None exact. "Quill" noise (Quill.js and dozens of repos). | "KWIL-well", easy to spell | **Backup 1** |
| 3 | **Dusklog** | free | free | free | taken: dusklog.com is an invite-only private social-sharing site behind a login (registered 2026-03-20) | free / not checked | dusklog.com (live product, different category, tiny); repo `dusklog-join` for its invite page; "Dusk Log", a 2004 EP by mum | Easiest to say and spell | **Backup 2, with a known collision** |
| 4 | Dayrite | free | free | taken: placeholder page showing only "Dayrite" (registered 2026-02-15) | taken (2005) | free / not checked | No product found | "day-rite" puns on rite/right/write; spelling ambiguity ("Dayright"); sits in Dayflow's "Day-" family | Honourable mention |
| 5 | Evenlog | free | free | free | taken (2013) | free / not checked | 3 tiny repos that are typos of "eventlog" | "even log"; Google may "correct" it to "event log"; weak meaning | Weak |
| 6 | Lamplog | free | free | free | taken (2021, parked) | free / not checked | None exact | "lamp log" reads as LAMP stack (Linux, Apache, MySQL, PHP) | Weak |
| 7 | Tallylog | free | free | free | taken (registered 2026-06-07) | free / not checked | None exact. "Tally" accounting and form-builder brands add noise. | Easy | Weak |
| 8 | Duskpad | free | free | taken (2026-01-23) | taken (same day, so one owner) | free / not checked | No software. "Dusk pad" gaming mouse pads dominate results. | Easy | Weak |

### 3.5 Screened out (so you do not repeat the work)

| Name | Why it failed |
|---|---|
| Vesperlog | vesperlog.com is "Vesper - Close your day. Build your case.", a private-beta work-journal SaaS for performance-review evidence (same category). Also echoes the defunct Vesper notes app. |
| Cairn, Cairnlog | GitHub org `cairnlog` ships an MIT Claude Code plugin ("external memory and decision management") tied to a cairnlog service. |
| Tidelog | Same-category repos: enhen3/Tidelog (AI-guided plan, review and insights for Markdown daily notes), shipvane/tidelog, chemany/TideLog (scheduling). |
| Owlight | owlight.io is a live feedback widget that integrates with Claude Code. |
| Wraplog | wraplog.com gift app, a SourceForge logging library, npm and Go packages. |
| Dailogue, Daylogue | Existing GitHub orgs and repos (Dailogue/browserhand; daylogue.io; an Android "Daylogue" journal app). Typo magnets for "dialogue". |
| Daydraft | GitHub handle created September 2026 (empty) and .app registered June 2026: someone is circling it. |
| Dayscribe, Daylit, Diurna, Inklog, Emberlog, Pagelog, Evenfall, Evensong, Stela, Quipu, Vespera, Hibi, Kiroku, Penlog, Gloaming, Chronolog, Lastlight, Nightcap, Sitrep, Writ, Leaflog, Daywell, Notewell | A taken .dev or .app, or an already-occupied GitHub handle (several of them dormant). Diurna also has an archived macOS Hacker News reader of that name. |

### 3.6 Recommendation

**Gloamlog**, with Quillwell and Dusklog as backups.

Why Gloamlog:

1. It is the only candidate that is clean on every axis I could check: GitHub user and repo, npm, PyPI, .dev, .app, .com, Homebrew cask and formula.
2. A unique token means the brand query ("gloamlog") should return your repo and your landing page at the top within weeks. That is the cheapest SEO win available.
3. It carries the category ("log") and the moment ("gloam" = twilight, the end-of-day nag at 4:55pm).
4. It contains no Anthropic or Apple marks and stays out of the "Day-" family.
5. Tagline fit: "Gloamlog - your work log that writes itself from your Claude sessions". For now, the truthful version is "Gloamlog - the work journal for Mac that makes you write up your day".

Risks to test, not assume: an unusual word may be misheard as "gloom". Say it aloud to five people, ask them to type it back, and check what they search for. The tone is moody; the icon and copy can be warm (a lamp, soft twilight).

Why Quillwell as Backup 1: no exact namesake found, .dev, .app and cask free. Costs: the GitHub handle `quillwell` is held by a dormant account and .com is taken.

Why Dusklog as Backup 2: the best-feeling name, free handles on three axes, but a live namesake (dusklog.com, invite-only social sharing) and a taken .com. Only choose it if you accept that overlap, or contact the owner first.

### 3.7 Before you commit (30 minutes)

- Re-run the 3.3 checks the same day you buy.
- Search USPTO, EUIPO and WIPO Global Brand Database for "GLOAMLOG" and "GLOAM" (software classes 9 and 42). I did not.
- Register `.dev` and `.app` (and `.com` if still free); point the extras at the canonical one with a redirect.
- Create the GitHub org (if you want one) and the Homebrew tap repo `<org>/homebrew-tap`, which reserves the install path `brew install --cask <org>/tap/<name>`.
- Rename the repo, app bundle name, bundle identifier prefix and README **before** enabling Pages or submitting to any directory (4.2).

---

## 4. GitHub SEO

### 4.1 How discovery works (verified facts)

- GitHub's default repository search matches **name, description and topics**; README text is searched only with `in:readme` ([docs](https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories)). The "best match" formula is not documented ([docs](https://docs.github.com/en/search-github/getting-started-with-searching-on-github/sorting-search-results)).
- In practice, relevance matters more than stars: for "claude code work log", the best-match order was 96, 41, 53, 4, 34, 4, 12, 27, 5, 9 stars. A 4-star repo ranks 4th, above a 34-star repo, and seven of the top ten have under 40 stars (checked via the API, 2026-10-06).
- **Token-exact:** "work journal mac" returned 3 unrelated repos; "work journal macos" returned 19, including Dayflow. Put both "Mac" and "macOS" in the description.
- Google titles repo pages as `GitHub - owner/repo: <description> · GitHub`. Your description is the visible title text. Because the prefix eats about 35 characters, only the first 25 to 40 characters of the description reliably show (estimate; Google truncates by pixel width and may rewrite titles). Front-load "Mac work journal".
- Limits: description 350 characters ([GitHub Desktop issue showing the error](https://github.com/desktop/desktop/issues/19465)); topics at most 20, each at most 50 characters, lowercase letters, numbers and hyphens ([docs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics)); social preview at least 640x320, 1280x640 recommended, under 1 MB, PNG/JPG/GIF, set in Settings only ([docs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview)).
- Traffic insights keep **14 days** only ([docs](https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-traffic-to-a-repository)). Snapshot weekly (section 7).
- Renaming a repo redirects issues, wikis, stars, followers and git operations, **except GitHub Pages project-site URLs** ([docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository)).

### 4.2 Repository name

- Use the brand as the repo name (`gloamlog`). Do not stuff keywords into the name: the brand token is what earns the #1 brand result, and keywords belong in the description, topics and README.
- Rename now, while the repo has about zero stars. Do it before Pages is enabled and before any directory or awesome-list submission, because the Pages project-site URL does not redirect.
- Keep the org or user, repo name, app name, cask token and domain identical.

### 4.3 Description (350 characters maximum)

Counts are hand-tallied; GitHub rejects anything over 350.

**Use now (describes what ships; 231 characters):**

```
Mac work journal that makes you write up your day. Open-source macOS menu bar app (SwiftUI, MIT): end-of-day reminder, streaks, searchable logs, weekly review for standups. Local-first, plain Markdown files, no cloud, no telemetry.
```

**Use after Claude drafting ships (about 249 characters):**

```
Mac work journal that writes itself from your Claude Code sessions. Open-source macOS app (SwiftUI, MIT): end-of-day reminder, auto-drafted daily log, standup and weekly review, brag doc. Local-first, plain Markdown files, no accounts, no telemetry.
```

Notes: it deliberately drops "no cloud" in the second version in case the draft step calls a model (section 9). Describe only features that exist when you edit the field. Set the **Website** field to the landing page and tick **Releases**.

### 4.4 Topics (the 20)

Counts are public repos using the topic on 2026-10-06.

| # | Topic | Repos | Top repo | Role |
|---|---|---|---|---|
| 1 | work-journal | 28 | Dayflow 7.2k; #3 has 12 stars | Niche, #2 reachable |
| 2 | work-log | 42 | Work-Review 1.8k; #2 has 48 | Niche |
| 3 | worklog | 154 | Meridian 405; #2 has 46 | Niche |
| 4 | developer-journal | 24 | kaydet 48 | Niche, #1 reachable |
| 5 | engineering-journal | 10 | 6 stars | Niche, #1 reachable |
| 6 | daily-log | 42 | 8 stars | Niche, #1 reachable, covers the old name |
| 7 | daily-standup | 36 | planning-poker tool 498 | Use-case |
| 8 | standup | 190 | git-standup 7.9k | Use-case, broader |
| 9 | brag-document | 20 | reflect 36 | Niche |
| 10 | performance-review | 51 | brag-doc 15 | Use-case |
| 11 | weekly-review | 27 | 4 stars | Matches the weekly review feature |
| 12 | journaling | 875 | Pile 3.1k | Category, mid-size |
| 13 | ai-journal | 27 | memex 766 | Niche. Add only when AI drafting exists. |
| 14 | macos-app | 3,844 | awesome-mac 116k | Platform and type |
| 15 | menu-bar-app | 1,544 | capcap 954 | UI type |
| 16 | macos | very large (not measured) | n/a | Platform filter |
| 17 | swiftui | 29,702 | awesome-mac 116k | Stack filter |
| 18 | local-first | 24,612 | open-design 99.7k | Philosophy filter |
| 19 | claude-code | 84,507 | 274k stars | Audience filter. No ranking value at this size, but it is the audience tag. Add only when the Claude feature ships. |
| 20 | claude-desktop | 2,492 | happy 24k | Audience filter. Only if you really read Claude Desktop Code-tab sessions. |

Pattern: 11 niche or use-case topics (most have a top repo under 50 stars, so a top-3 slot is realistic; `standup` is the exception), 6 mid or large topics for GitHub's topic-filter searches, 3 audience and platform tags. Until the Claude feature ships, swap #13, #19, #20 for `daily-journal` (36 repos, top 100 stars), `status-report` (12 repos, top 10 stars) and `markdown`. `standup-generator` has zero repos on GitHub (unclaimed); tag it only if the product really generates standup text. Do not use `claude-code-plugin` (8,510 repos) unless you ship a plugin.

### 4.5 README structure and keyword placement

The current README opens with "A small Mac app that makes you write up your day..." and has no screenshot, badges, site link, FAQ or comparison, and its install note ("right-click then Open") no longer works on macOS 15 (section 9). Proposed outline:

```
# Gloamlog
**Your work log that writes itself from your Claude sessions.**     <- only once true; until then:
**The Mac work journal that makes you write up your day.**

[Release] [License: MIT] [macOS 13+] [CI]        [Download] [Website] [Docs]

![<alt text, see 4.6>](docs/images/gloamlog-macos-work-journal-main-window.png)

Gloamlog is an open-source work journal for Mac (macOS 13+). <2 sentences, <60 words,
naming: work journal, Mac or macOS, Markdown, local-first, and (when true) Claude Code.>

## What it does          (6 to 8 one-line features: end-of-day reminder, five required
                          sections, streak and heatmap, search, weekly review for standups)
## How it works          (3 steps)
## Install               (DMG from Releases; Homebrew tap; build from source;
                          macOS 15+ note: System Settings > Privacy & Security > Open Anyway,
                          until notarised)
## Privacy and your data (Markdown at ~/daily-log/YYYY-MM-DD.md; telemetry: none)
## FAQ                   (5 to 6 questions copied from section 5.5)
## Compared with         (factual table: Dayflow, Meridian, Day One, jrnl, git-standup,
                          engineering-notebook; fill with facts you have verified on the day)
## Roadmap, Contributing, License
Not affiliated with Anthropic. "Claude" and "Claude Code" are trademarks of Anthropic.
```

Rules: one H1 only; the first paragraph becomes the search snippet, so write it for a stranger, not for yourself; use each key phrase naturally once or twice ("work journal", "work log", "Mac", "macOS", "Markdown", "standup"); no keyword lists; keep the existing "Docs" and "Scripts (no app)" sections below the fold. Do not paste the README into the landing page; write the page for benefits, the README for install and development.

### 4.6 Image alt text and filenames

Rules from Google's image guidance: descriptive, useful, in context, no keyword stuffing; descriptive short filenames. Keep alt text to roughly 100 to 125 characters, never start with "image of", leave decorative images with `alt=""`.

| File | Alt text |
|---|---|
| `gloamlog-macos-work-journal-main-window.png` | `Gloamlog main window on macOS with today's work log in five sections: done, finished, started, pending and next` |
| `gloamlog-menu-bar-status-streak.png` | `Gloamlog menu bar item showing today's log status and current streak` |
| `gloamlog-activity-heatmap.png` | `12-week heatmap of logged, skipped and missed workdays` |
| `gloamlog-weekly-review-standup.png` | `Weekly review screen combining the week's logs into Markdown to paste into a standup` |
| `gloamlog-claude-session-draft.png` (after it ships) | `Draft log generated from Claude Code sessions, open for editing before saving` |
| `gloamlog-social-preview-1280x640.png` | GitHub has no alt field for this. Use `og:image:alt` on the site. |

### 4.7 Release naming and assets

- **Tag:** `v0.3.0` (SemVer; also what a Homebrew `version` expects).
- **Title:** `Gloamlog 0.3.0 - Draft your day from Claude Code sessions` (version, then the one headline feature in plain words; avoid "Release 0.3.0" alone).
- **Notes, in this order:** one-sentence summary with the key phrases; **Download** (links to the asset names below); What's new; Fixes; Requirements (macOS 13+, Apple silicon or Intel, whichever you build for); Known issues.
- **Assets:** `Gloamlog-0.3.0.dmg` (or `.zip`) and `Gloamlog-0.3.0.dmg.sha256`. Versioned names; link to `/releases/latest` from docs rather than a hard-coded file.
- Mark betas as pre-release; do not delete releases; keep `CHANGELOG.md` in sync (it exists).
- Cadence: a small release every 2 to 4 weeks keeps "recently updated" and trust signals alive (estimate).

### 4.8 Social preview image spec

| Property | Value |
|---|---|
| Size | 1280 x 640 px (2:1). GitHub minimum is 640 x 320. |
| Format and weight | PNG, sRGB, under 1 MB (GitHub limit). Aim for under 300 KB. |
| Where to set | Repo Settings > Social preview. It cannot be committed to the repo. |
| Layout (recommendation) | Left two-thirds: name at 96 px or larger, tagline at 44 px or larger over at most 2 lines, a chip row "macOS 13+ / MIT / local-first". Right third: crop of the real main window. |
| Safe area | Keep all text inside the central 1120 x 480 px; platforms crop and pad differently. |
| Text | At most 8 words in the headline. Contrast at least 4.5:1. No tiny UI text. |
| Check | Paste the repo URL into Slack, Discord and X to see the unfurl before launch. |
| Site image | Reuse the artwork as `og-1200x630.png` (1.91:1, under 300 KB) for the landing page. |

### 4.9 Other GitHub surfaces

- Enable **Discussions** and seed three Q&A posts that mirror the FAQ; they are public, indexable pages (assumption, not tested). Keep Wiki off (it dilutes).
- Pin the repo on your profile and link the landing page from your profile README.
- Keep Issues templates (the PRD says they exist), `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`; label a few `good first issue`.
- A single optional line in the README ("If this saves you time, a star helps others find it") is normal. Do not buy or trade stars.

---

## 5. Landing page (GitHub Pages)

### 5.1 Hosting and domain

- Pages project sites live at `https://<owner>.github.io/<repo>` ([docs](https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages)). They can rank: the Claude Code History Viewer project page on github.io appears in search results, and Agent Sessions also uses a `github.io/<repo>` page. A custom domain is for **control**, not rankability:
  1. robots.txt must sit at the host root, and applies per host ([Google](https://developers.google.com/search/docs/crawling-indexing/robots/create-robots-txt)). `owner.github.io/daily-log/robots.txt` is ignored ([GitHub community thread](https://github.com/orgs/community/discussions/64865)); only a root-level file in a separate `owner.github.io` repo would count.
  2. Renaming the repo breaks the project-site URL with no redirect (4.1).
  3. Brand equity would accrue to github.io, not to you.
- Buy `<name>.dev` (or `.app`). Both are HTTPS-only (HSTS preload) and Pages supports HTTPS. Pick **one canonical host** (apex `https://gloamlog.dev/` in the examples) and let the other redirect; GitHub creates the apex/www redirect when both are configured. GitHub recommends a `www` subdomain for stability and takeover safety, and verifying the domain in your account settings ([docs](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/about-custom-domains-and-github-pages)).
- DNS for an apex domain ([docs](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)): `A` records to `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`; optional `AAAA` to `2606:50c0:8000::153`, `2606:50c0:8001::153`, `2606:50c0:8002::153`, `2606:50c0:8003::153`; `CNAME www` to `<owner>.github.io`. "Enforce HTTPS" can take up to 24 hours to become available.
- Limits and terms ([docs](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)): 1 GB site, soft 100 GB/month bandwidth, soft 10 builds/hour; not for running a commercial SaaS or store. A free open-source app page is fine.
- Publish from a dedicated branch or a `site/` folder with a workflow, not `/docs` (already used by project docs). Add an empty `.nojekyll` so no Jekyll build runs.

### 5.2 File layout (single static page)

```
index.html                 the whole page, inline CSS
404.html
robots.txt
sitemap.xml
CNAME                      one line with the domain (branch publishing only)
.nojekyll
assets/og-1200x630.png     under 300 KB
assets/screenshot-main-1280.webp  + .png fallback, width/height attributes set
favicon.svg, favicon.ico, apple-touch-icon.png (180x180)
```

### 5.3 Head tags (working name; swap the copy to the "now" variant until the feature ships)

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">

<title>Gloamlog - Mac work journal from your Claude Code sessions</title>
<meta name="description" content="Gloamlog is an open-source Mac app that makes you write up your day, then drafts the log from your Claude Code sessions. Local-first Markdown. Free, MIT.">
<link rel="canonical" href="https://gloamlog.dev/">
<meta name="robots" content="index, follow, max-image-preview:large">
<meta name="color-scheme" content="light dark">
<meta name="theme-color" content="#f6f3ee" media="(prefers-color-scheme: light)">
<meta name="theme-color" content="#14161f" media="(prefers-color-scheme: dark)">

<link rel="icon" href="/favicon.ico" sizes="32x32">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">

<meta property="og:type" content="website">
<meta property="og:site_name" content="Gloamlog">
<meta property="og:title" content="Gloamlog - your work log that writes itself from your Claude sessions">
<meta property="og:description" content="Open-source Mac app. Write up your day in minutes; Gloamlog drafts it from your Claude Code sessions. Local-first Markdown, MIT.">
<meta property="og:url" content="https://gloamlog.dev/">
<meta property="og:image" content="https://gloamlog.dev/assets/og-1200x630.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="Gloamlog on macOS: the daily work log window next to the menu bar item showing today's streak.">

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="Gloamlog - your work log that writes itself">
<meta name="twitter:description" content="Open-source Mac work journal drafted from your Claude Code sessions. Local-first, MIT.">
<meta name="twitter:image" content="https://gloamlog.dev/assets/og-1200x630.png">
<meta name="twitter:image:alt" content="Gloamlog on macOS: the daily work log window next to the menu bar item showing today's streak.">
</head>
```

Length checks: title 58 characters; description 153 characters. Google may rewrite either; it says titles should be descriptive and concise with no stuffing, and that it primarily builds snippets from page content ([title links](https://developers.google.com/search/docs/appearance/title-link), [snippets](https://developers.google.com/search/docs/appearance/snippet)). "Now" variant title: `Gloamlog - Work journal app for Mac, local-first` (48 characters).

### 5.4 JSON-LD (what it will and will not do)

Be honest about the payoff:

- **SoftwareApplication rich results need `offers.price` plus either `aggregateRating` or `review`** ([Google](https://developers.google.com/search/docs/appearance/structured-data/software-app)). A new free app has no genuine ratings, so no rich result is expected. Never invent ratings or reviews. The markup is still useful for entity clarity.
- **FAQ rich results are gone.** Google restricted them in 2023 to well-known government and health sites, and its FAQPage page now says the rich result "is no longer shown in Google Search results" (documentation change dated May 2026). Keep FAQPage markup only if the same questions and answers are visible on the page; expect zero rich-result benefit. The visible FAQ is the real asset: it matches long-tail question queries.

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "Gloamlog",
  "url": "https://gloamlog.dev/",
  "description": "Open-source work journal for macOS that makes you write up your day and drafts the log from your Claude Code sessions. Local-first, plain Markdown files.",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "macOS 13 or later",
  "softwareVersion": "0.3.0",
  "license": "https://opensource.org/license/mit",
  "isAccessibleForFree": true,
  "offers": { "@type": "Offer", "price": "0", "priceCurrency": "USD" },
  "downloadUrl": "https://github.com/dasariprashant0/gloamlog/releases/latest",
  "sameAs": ["https://github.com/dasariprashant0/gloamlog"],
  "screenshot": "https://gloamlog.dev/assets/screenshot-main-1280.png",
  "author": { "@type": "Person", "name": "Prashant Dasari", "url": "https://github.com/dasariprashant0" }
}
</script>

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "Does Gloamlog read my Claude Code sessions?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes, on your Mac. Claude Code stores each session as a JSONL transcript under ~/.claude/projects/. Gloamlog reads those files to draft the day's log, which you edit before saving." }
    },
    {
      "@type": "Question",
      "name": "How long does Claude Code keep session history?",
      "acceptedAnswer": { "@type": "Answer", "text": "By default Claude Code deletes local transcripts older than 30 days (the cleanupPeriodDays setting). A daily log keeps a permanent summary of what you did." }
    },
    {
      "@type": "Question",
      "name": "Is Gloamlog free and open source?",
      "acceptedAnswer": { "@type": "Answer", "text": "Yes. It is MIT licensed and your logs are plain Markdown files in a folder you choose." }
    }
  ]
}
</script>
```

Publish the Claude-specific answers only after the feature ships and only after re-checking Anthropic's docs.

### 5.5 Page outline and visible FAQ

```
header   logo, nav: How it works / FAQ / GitHub
H1       Gloamlog - your work log that writes itself from your Claude sessions
         (now: "The Mac work journal that makes you write up your day")
p        one sentence of value; two buttons: Download for macOS (Releases/latest), View on GitHub
img      main window screenshot, width/height set, alt text from 4.6
H2       How it works        3 steps: reminder, draft, edit and save
H2       What you get        6 plain-language bullets
H2       Private by default  where files live; telemetry: none
H2       How it compares     factual table (Dayflow, Meridian, Day One, jrnl, git-standup)
H2       Install             DMG, Homebrew tap, build from source; macOS 13+; Gatekeeper note
H2       FAQ                 each question an H3, answers of 2 to 4 sentences
H2       Open source         MIT, contributing, roadmap
footer   GitHub, Releases, Changelog, License; "Not affiliated with Anthropic..."
```

FAQ questions (match real queries, answer in the first sentence): What is Gloamlog? Does it read my Claude Code sessions, and where are they stored? How long does Claude Code keep session history? Can I use it for standups, weekly updates and a brag doc? Is it free and open source? Does it send my data anywhere? Which macOS versions? How is it different from Dayflow or a time tracker? Is it affiliated with Anthropic?

### 5.6 robots.txt, sitemap.xml, canonical

`robots.txt` (at the host root, which a custom domain gives you):

```
User-agent: *
Allow: /

Sitemap: https://gloamlog.dev/sitemap.xml
```

`sitemap.xml` (one URL; a sitemap affects only its parent directory and below, so keep it at the root; file limits are 50 MB or 50,000 URLs; Google uses `lastmod` only if it is consistently accurate and ignores `priority` and `changefreq`; [Google](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://gloamlog.dev/</loc>
    <lastmod>2026-10-06</lastmod>
  </url>
</urlset>
```

Canonical: absolute URL, self-referencing, HTTPS, the single chosen host ([Google](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)). It is a hint, so also keep the redirects consistent. Update `lastmod` only when the page materially changes.

### 5.7 Performance (non-negotiable thresholds)

Core Web Vitals "good", at the 75th percentile: **LCP 2.5 s or less, INP 200 ms or less, CLS 0.1 or less** ([web.dev](https://web.dev/articles/vitals)). A single static page should beat these easily. Budget (my targets):

- HTML plus inline CSS under 30 KB compressed; total page weight under 300 KB; zero third-party requests; no web fonts (system font stack) or one font under 30 KB with `font-display: swap`.
- Hero image WebP or AVIF under 150 KB with PNG fallback, `width` and `height` set (prevents layout shift), `fetchpriority="high"`; other images `loading="lazy"` and `decoding="async"`.
- No GIF: use short muted looping `<video playsinline>` with a poster, or stills. Respect `prefers-reduced-motion`.
- No analytics script. It fits the app's no-telemetry promise; Search Console and GitHub traffic are enough.
- Test with PageSpeed Insights after deploy. Field (CrUX) data will not exist until there is traffic; rely on lab scores at first.

### 5.8 Accessibility (WCAG 2.2 AA as the bar)

`lang="en"`; landmarks (`header`, `main`, `nav`, `footer`); exactly one H1 and headings in order; text contrast 4.5:1 or better; visible keyboard focus; a skip-to-content link; interactive targets at least 24 x 24 CSS px; links with descriptive text (never "click here"); alt text per 4.6; `prefers-color-scheme` dark mode; reduced-motion respected; no information carried by colour alone (the app's own menu-bar states already use distinct symbols).

### 5.9 Search Console and Bing

1. Add a **Domain** property in Google Search Console (DNS TXT at the registrar).
2. Submit `sitemap.xml`. Run URL Inspection on `/` and request indexing.
3. Import the site into Bing Webmaster Tools from Search Console.
4. Check the Pages report in week 2; "Discovered, currently not indexed" is common for new sites and fixed by internal and external links, not by resubmitting.
5. At weeks 4 and 8, export Performance by **page plus query** and re-check ownership (5.10).

### 5.10 Internal links and cannibalisation check (before Search Console data exists)

URL inventory and ownership (the pre-GSC method: list every URL that touches the topic, assign one owner per query cluster, deconflict titles and H1s):

| URL | Role | Owns | Title and H1 rule |
|---|---|---|---|
| `https://gloamlog.dev/` | Landing page | Brand; "Mac work journal"; Claude Code journal and daily summary framing | Title starts with the brand. One H1, benefit-led. |
| `github.com/dasariprashant0/gloamlog` | Repo | GitHub-intent: open source, source, issues; GitHub search | Description front-loads "Mac work journal" (needed for GitHub search). Different host, so no authority split. |
| `.../releases` | Downloads | "`<name>` download", versions | Title pattern `<Name> x.y.z - headline` |
| `.../discussions` | Q&A | Long-tail how-to | Titles are real questions |
| `docs/*.md` | Reference | Nothing (supporting) | Do not repeat the README H1 or its key phrases as titles |
| Future `gloamlog.dev/guides/...` | Guides | One query cluster each (rows 16 to 18) | Home page never targets these |
| `owner.github.io/daily-log/` | Old project-site URL | Nothing | Do not publish it; rename first |

Same-domain cannibalisation cannot occur at launch (one page). It appears when guides are added: give each guide one cluster, link it from the home page with a descriptive anchor, and never reuse a guide's primary phrase in the home title or H1.

Link map:

```
Directories, dev.to, Reddit, HN, Homebrew cask "homepage"
        |
        v
  gloamlog.dev (/)  <------ release notes, README badge, GitHub About "Website"
   |  Download CTA  \  View source / Star
   v                 v
GitHub Releases    GitHub repo (README)
 (latest)           |  docs/*.md  ->  back to README and the site (footer line)
```

Rules: brand name plus descriptor as anchor text ("Gloamlog, a work journal for Mac"); every page links to the other two above the fold; one canonical home URL used everywhere (About field, cask `homepage`, awesome-list entries that accept a site link, social bios); list pages that require a GitHub link get the repo URL.

---

## 6. Off-site: backlinks and realistic timeline

### 6.1 Where links and mentions come from

| Channel | What to do | Rules and gates (verified unless noted) | Effort | Value |
|---|---|---|---|---|
| open-source-mac-os-apps (50.7k stars) | PR to `applications.json`, not the README | One PR per app; fields `short_description, categories, repo_url, title, icon_url, screenshots, official_site, languages`; description ends with a full stop; needs recent commits and an English README ([contributing](https://raw.githubusercontent.com/serhii-londar/open-source-mac-os-apps/master/CONTRIBUTING.md)) | S | High (long-lived, indexed list) |
| awesome-mac (116k stars) | PR adding one line | Title-case `[Name](link)`, alphabetical in the right category, one PR per app, check duplicates ([contributing](https://github.com/jaywcjlove/awesome-mac/blob/master/docs/CONTRIBUTING.md)). I could not confirm the icon syntax or a journaling category: read the README's Contents at PR time. | S | High |
| awesome-claude-code (55.1k stars) | Issue form only; PRs are rejected and abuse can get you restricted | Eligible if at least 14 days since first commit with continued commits, or at least 100 stars; one resource per submission; functional description, no sales language or emojis; no signup or payment barrier ([contributing](https://raw.githubusercontent.com/hesreallyhim/awesome-claude-code/main/CONTRIBUTING.md)) | S | High for the Claude audience |
| AlternativeTo | "Suggest new application" after signing up; tag as alternative to Day One and Dayflow | Needs a verified account and a full form. Third-party guides say review can take weeks to months and a paid fast-review exists (not verified on AlternativeTo's own pages). Dayflow's page lists 12 alternatives, so the slot exists. | S | Medium (long-tail "alternative" queries) |
| OpenAlternative | [Submit form](https://openalternative.co/submit) | Open source, actively maintained, English, framed as an alternative to a proprietary product (use Day One); needs a public GitHub repo (third-party summary) | S | Medium |
| Homebrew | Personal tap now; official cask later | Official repos need 30 forks, 30 watchers or 75 stars (225 stars, 90 forks or 90 watchers if you submit it yourself), repo older than 30 days, and the app must pass Gatekeeper ([policy](https://docs.brew.sh/Package-Acceptance-Policy), [casks](https://docs.brew.sh/Acceptable-Casks)). Homebrew 5.0.0: "We will disable all Homebrew/homebrew-cask casks that fail Gatekeeper checks in September 2026" ([release](https://brew.sh/2025/11/12/homebrew-5.0.0/)). Dayflow is in the official cask; Agent Sessions uses a tap. | S (tap) | Medium (install path, `homepage` link) |
| Show HN | One post, link the repo or release | Must be something people can try; landing pages do not qualify; do not ask anyone to upvote; be present to answer ([rules](https://news.ycombinator.com/showhn.html)) | S | High variance; one shot, so do it when notarised and polished |
| Reddit: r/macapps | Developer post | Per a third-party rules summary (verify the sidebar): developer posts limited to one per developer per 30 days, flair and disclosure required, moderator permission or a megathread ([summary](https://www.threadotter.com/subreddit-rules/macapps)) | S | Medium |
| Reddit: r/ClaudeAI, r/ClaudeCode | Showcase post | A secondary source says r/ClaudeAI uses "Built with Claude" flair and r/ClaudeCode runs a weekly showcase. Unverified; read the sidebars. Disclose you are the author. | S | Medium |
| dev.to, Hashnode, Medium | Articles (6.2) | Set the canonical URL to your own site so the copy does not split the original | M | Medium, compounding |
| Listicles that rank today | Short email to the author after launch | LinuxLinks "Best Free and Open Source Alternatives to Apple Journal", medevel "17 Best Open-source ... Journaling", mactools.pro, unstore.io, David Mytton's Mac notes list, memexlab.ai. Expect a low reply rate (estimate: 1 in 10). | M | Medium |
| Product Hunt | Optional | Dayflow and Claude Code History Viewer both have pages. Skip until notarised and screenshots are good. | M | Low to Medium |
| Newsletters (for example Console.dev) | Submit | Unverified. Check each submission page. | S | Unknown |
| AI answer engines | Keep README and FAQ factual; monitor | Unproven. Ask ChatGPT, Claude and Perplexity your target queries monthly and note whether you are cited. `llms.txt` is optional and unproven. | S | Unknown |

Hygiene: no paid links, link exchanges, fake reviews or bought stars, no mass directory submissions. They violate search and GitHub guidelines and do not rank.

### 6.2 Content that earns links (write four, in this order)

1. "Claude Code deletes your session history after 30 days. Here is how I turned mine into a daily work log." Targets rows 11 to 13 and 17. Strongest hook.
2. "Where Claude Code stores your sessions (`~/.claude/projects`) and what is inside the JSONL." Targets row 16. Evergreen reference; re-verify against the docs before publishing.
3. "Why a work journal that makes you write beats automatic capture (and where it does not)." Targets rows 5, 7 and 34 and positions you against Dayflow honestly.
4. "Building a SwiftUI menu bar app with only the Command Line Tools." The PRD records that constraint (no Xcode, no Swift macros). A developer-audience story that links to the repo.

Publish on your domain first, then cross-post with the canonical URL pointing home.

### 6.3 Ranking timeline expectations

Hard evidence: Ahrefs (2025, about 1.3 million random US keywords) found only **1.74%** of newly published pages reach the top 10 within a year, the average #1 page is **5 years old**, and **72.9%** of top-10 pages are over 3 years old ([study](https://ahrefs.com/blog/how-long-does-it-take-to-rank/)). That sample is dominated by competitive keywords, so niche long-tail (rows 11 to 14) should do better, but the direction is clear. An older Google line, reported by The SEM Post, says SEO takes 4 months to a year; I could not find it on Google's current page, so treat it as secondary.

My estimates (low confidence, wide error bars):

| Window | What can realistically happen |
|---|---|
| Days 0 to 7 | Repo is searchable on GitHub within hours (not measured here). Google may index the repo page in days to a few weeks. Landing page discovered via sitemap and URL Inspection. |
| Weeks 2 to 8 | Brand query returns your repo and site at #1 to #3. GitHub search top 10 for 3 to 5 niche phrases if description and topics match (evidence: 4 to 27 star repos hold top-10 slots today). First Search Console impressions for long-tail. |
| Months 2 to 4 | Landing page on page 1 for the brand and a few long-tail phrases (rows 11 to 14, 33), page 2 or 3 for others. Organic visits in the low single or double digits per week. |
| Months 4 to 8 | With 100+ stars, 5 to 10 referring domains and 2 or 3 guides, positions 3 to 10 for several Claude-specific queries. Tens, possibly low hundreds, of weekly visits. |
| 12+ months | "work journal app", "brag document", "work log app mac" stay out of reach. A slow gain on "open source journal app" and "day one open source alternative" if listicles link to you. |

Stars (estimate from benchmarks): Dayflow reached 7.2k in about 12.5 months and is the ceiling case; Agent Sessions 891, Meridian 405 and engineering-notebook 342 are strong niche results; most of the roughly 15 closest Claude-journal repos I examined have under 50. A well-executed niche launch could plausibly reach 50 to 300 stars in three months. Search follows launch; it does not replace it.

---

## 7. Measurement

Track weekly in a private sheet (not in the repo):

| Query | Engine | Position | URL | Date |
|---|---|---|---|---|
| `<name>` | Google, GitHub | | | |
| work journal macos | GitHub | | | |
| claude code work log | GitHub | | | |
| claude code journal | GitHub, Google | | | |
| claude code daily summary | Google | | | |
| claude code session history | Google, GitHub | | | |
| brag document tool | GitHub | | | |
| open source journal app mac | Google | | | |
| markdown journal app mac | Google | | | |
| day one open source alternative | Google | | | |
| daily standup generator | GitHub, Google | | | |
| work log app mac | Google (watch only) | | | |

Use a logged-out browser and note your location; results vary.

- **GitHub traffic:** snapshot views, clones, referrers and popular content weekly via the repository traffic API, because the UI keeps only 14 days.
- **Google Search Console:** impressions and clicks by page and query; branded versus non-branded; Pages (indexing) report. Bing Webmaster Tools alongside.
- **Leading indicators:** impressions rise before clicks; stars per week after each launch event; referrers.
- **Decision rules:**
  - Zero impressions after 8 weeks: check URL Inspection, canonical, robots, and the Pages report before changing copy.
  - Repo missing from the top 10 of GitHub search for a target phrase after description and topic changes: compare tokens against the current top 10 (the "mac" versus "macOS" lesson).
  - Fewer than 25 stars after launch week: the gap is distribution or demo quality, not SEO.
  - After week 4 and 8: export page and query from Search Console and confirm the 5.10 ownership map; fix any query where two of your own URLs split impressions.

---

## 8. Checklist, ordered by impact and effort

Impact: H, M, L. Effort: S (under 2 hours), M (a day), L (several days). Ordered so that blockers come first, then the best impact-to-effort ratio.

### P0: decisions that block everything

| # | Task | Impact | Effort | Notes |
|---|---|---|---|---|
| 1 | Choose the name; re-run checks; trademark search | H | S | 3.6, 3.7 |
| 2 | Buy `.dev` and `.app` (and `.com`); create the GitHub org if wanted | H | S | Same day as #1 |
| 3 | Rename the repo and app; keep the cask token, bundle name and domain identical | H | S | Before Pages and any directory submission |
| 4 | Decide the signing path: Apple Developer ID and notarisation (the widely quoted price is 99 USD a year; confirm with Apple) | H | M | Unlocks installs, the official cask and Homebrew policy. The ROADMAP already ranks it 2nd; move it up. |
| 5 | Decide exactly how Claude drafting works and what you may claim today | H | S | Section 9 |

### P1: first day (highest ratio)

| # | Task | Impact | Effort | Notes |
|---|---|---|---|---|
| 6 | GitHub About: description (4.3), Website, 20 topics (4.4), Releases on | H | S | |
| 7 | README top fold: H1 and tagline, screenshot with alt text, install, FAQ, comparison; replace the "right-click then Open" advice with Open Anyway for macOS 15+ until notarised | H | S to M | 4.5 |
| 8 | Upload the 1280 x 640 social preview | M | S | 4.8 |
| 9 | Cut a release with versioned assets, checksum, keyword-bearing notes | H | S | 4.7 |
| 10 | Add the "not affiliated with Anthropic" line | M | S | 3.2 |
| 11 | Enable Discussions; seed three Q&As | L | S | 4.9 |

### P2: first week

| # | Task | Impact | Effort | Notes |
|---|---|---|---|---|
| 12 | Landing page on the custom domain with HTTPS | H | M | Section 5 |
| 13 | Search Console (Domain property), sitemap, URL Inspection; Bing import | M | S | 5.9 |
| 14 | Personal Homebrew tap and cask | M | S | `brew install --cask <org>/tap/<name>` |
| 15 | Screenshots (4) and a short muted demo video, with alt text | H | M | The main conversion lever on both README and site |
| 16 | open-source-mac-os-apps PR | M | S | 6.1 |
| 17 | AlternativeTo and OpenAlternative submissions | M | S | Queues are slow, so start early |
| 18 | awesome-mac PR (after reading its categories) | M | S | |

### P3: launch window (weeks 2 to 4, only when installable in under two minutes and notarised)

| # | Task | Impact | Effort | Notes |
|---|---|---|---|---|
| 19 | awesome-claude-code issue form (gate: 14 days of commits or 100 stars) | M | S | |
| 20 | Show HN, linking the repo | H (variance) | S | One shot |
| 21 | Reddit posts by each sub's rules, disclosed | M | S | Stagger; do not cross-post identical text on the same day |
| 22 | Article 1 (30-day cleanup hook), cross-posted with a canonical URL | M | M | 6.2 |
| 23 | Listicle outreach (5 emails) | L to M | M | |

### P4: ongoing

| # | Task | Impact | Effort | Notes |
|---|---|---|---|---|
| 24 | Guides 2 and 3 on your domain; article 4 | M | M | One query cluster per guide |
| 25 | Release every 2 to 4 weeks with proper notes | M | S each | |
| 26 | Weekly measurement and traffic snapshot | M | S | Section 7 |
| 27 | Submit the official Homebrew cask once you pass the star gate and notarise | M | S | 6.1 |
| 28 | Week 4 and 8 cannibalisation check from Search Console (page plus query) | M | S | 5.10 |
| 29 | Monthly AI-answer check | L | S | |

### Do not

Buy stars or links; stuff topics or descriptions; claim features that are not shipped; imply Anthropic affiliation; paste README text into the landing page; submit to dozens of generic directories; add analytics scripts to a site that sells a no-telemetry app.

---

## 9. Accuracy and risk notes

1. **Shipped versus planned.** PRD v0.2 lists "AI summaries" as a non-goal (F19) and the ROADMAP ranks an opt-in AI weekly summary 6th. "Auto-drafts from your Claude Code sessions" is a new direction. SEO copy that overclaims drives bounces and bad reviews and can be treated as misleading. Use the "now" copy until it ships.
2. **Local-first versus drafting.** Reading transcripts under `~/.claude/projects` is local. Turning them into prose needs a model. If that goes over the network (your own API key, or shelling out to the Claude CLI), then "no network" and "nothing leaves your Mac" are false for that feature; the ROADMAP's own principle is opt-in, explicit, off by default with a preview of what leaves the Mac. Decide this before writing privacy copy, the description and the FAQ.
3. **"Claude desktop sessions."** Anthropic's docs describe transcripts kept for sessions started in Claude Desktop or Cowork, which implies Claude Code sessions run from the desktop app are local. A third-party analysis says ordinary Claude Desktop chats live on Anthropic's servers with almost nothing local. Claim only what you can read from disk, and verify it yourself.
4. **Gatekeeper and install friction.** macOS 15 Sequoia removed the Control-click override; users must go to System Settings > Privacy & Security and choose Open Anyway ([iDownloadBlog](https://www.idownloadblog.com/2024/08/07/apple-macos-sequoia-gatekeeper-change-install-unsigned-apps-mac/)). Your README's "right-click then Open" instruction therefore fails on current macOS. Notarisation fixes this and the Homebrew gate.
5. **Trademark and naming.** Nothing here is legal advice. The registers were not searched. Keep "Claude" out of the name, logo, domain, repo and cask token.
6. **Competitor facts** (stars, licences, features) are from 2026-10-06 GitHub pages and APIs read through a summarising fetch tool; re-check any number you quote publicly.
7. **Part of the evidence is secondary:** the r/macapps rules, AlternativeTo's queue length and price, the r/ClaudeAI flair, the "4 months to a year" line, and the claim that Claude Desktop chats are server-side. Each is marked above.
8. **This file is public if committed.** It contains the screened-out names and competitor notes. Decide whether you want that in the repo.
9. **Autocomplete caveats:** unofficial endpoint, unknown locale, no volumes, and some outputs discarded as synthetic (section 0).

---

## 10. Sources

GitHub and Google documentation

- GitHub topics: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/classifying-your-repository-with-topics
- GitHub social preview: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview
- GitHub repository search: https://docs.github.com/en/search-github/searching-on-github/searching-for-repositories
- GitHub sorting search results: https://docs.github.com/en/search-github/getting-started-with-searching-on-github/sorting-search-results
- 350-character description limit (error text): https://github.com/desktop/desktop/issues/19465
- Renaming a repository: https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository
- Repository traffic: https://docs.github.com/en/repositories/viewing-activity-and-data-for-your-repository/viewing-traffic-to-a-repository
- GitHub Pages overview: https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages
- Pages custom domains: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/about-custom-domains-and-github-pages and https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site
- Pages limits: https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits
- robots.txt on github.io (community thread): https://github.com/orgs/community/discussions/64865
- Google robots.txt: https://developers.google.com/search/docs/crawling-indexing/robots/create-robots-txt
- Google sitemaps: https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap
- Google canonicals: https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls
- Google software app structured data: https://developers.google.com/search/docs/appearance/structured-data/software-app
- Google FAQPage structured data: https://developers.google.com/search/docs/appearance/structured-data/faqpage
- Google title links: https://developers.google.com/search/docs/appearance/title-link
- Google snippets: https://developers.google.com/search/docs/appearance/snippet
- Google image best practices: https://developers.google.com/search/docs/appearance/google-images
- Google on gTLDs: https://developers.google.com/search/docs/specialty/international/managing-multi-regional-sites
- Core Web Vitals: https://web.dev/articles/vitals

Homebrew, Apple, Anthropic

- Homebrew package acceptance policy: https://docs.brew.sh/Package-Acceptance-Policy
- Homebrew acceptable casks: https://docs.brew.sh/Acceptable-Casks
- Homebrew cask cookbook: https://docs.brew.sh/Cask-Cookbook
- Homebrew 5.0.0 release notes: https://brew.sh/2025/11/12/homebrew-5.0.0/
- macOS Sequoia Gatekeeper change: https://www.idownloadblog.com/2024/08/07/apple-macos-sequoia-gatekeeper-change-install-unsigned-apps-mac/ and https://developer.apple.com/news/?id=saqachfa
- .dev and .app HSTS preload: https://www.registry.google/domains/dev/ and https://kb.porkbun.com/article/96-hsts-preload-and-google-registry
- Claude Code legal and compliance (naming rule): https://code.claude.com/docs/en/legal-and-compliance
- Anthropic trademark guidelines: https://www.anthropic.com/legal/trademark-guidelines
- Claude Code .claude directory and cleanup settings: https://code.claude.com/docs/en/claude-directory and https://code.claude.com/docs/en/settings
- Session deletion reports: https://github.com/anthropics/claude-code/issues/95203, https://github.com/anthropics/claude-code/issues/62041, https://github.com/anthropics/claude-code/issues/18881

Timeline and channels

- Ahrefs, how long it takes to rank (2025): https://ahrefs.com/blog/how-long-does-it-take-to-rank/
- The SEM Post on Google's "4 months to a year" (secondary): http://www.thesempost.com/google-seos-need-4-months-year-seo-changes-ranks/
- Show HN rules: https://news.ycombinator.com/showhn.html
- open-source-mac-os-apps: https://github.com/serhii-londar/open-source-mac-os-apps
- awesome-mac contributing: https://github.com/jaywcjlove/awesome-mac/blob/master/docs/CONTRIBUTING.md
- awesome-claude-code: https://github.com/hesreallyhim/awesome-claude-code
- OpenAlternative submit: https://openalternative.co/submit
- AlternativeTo (Dayflow page): https://alternativeto.net/software/dayflow/ ; submission guide (secondary): https://buttondown.com/where-to-post/archive/submitting-on-alternativetonet/
- r/macapps rules summary (secondary): https://www.threadotter.com/subreddit-rules/macapps

Competitors and collisions

- Dayflow https://github.com/JerryZLiu/Dayflow · Meridian https://github.com/Meridiona/meridian · Agent Sessions https://github.com/jazzyalex/agent-sessions · engineering-notebook https://github.com/prime-radiant-inc/engineering-notebook · brag-doc https://github.com/deeheber/brag-doc · Pulse https://github.com/muhammademanaftab/pulse · DevLog https://github.com/moose-lab/DevLog · daily-journal https://github.com/pylenius/daily-journal · Work-Review https://github.com/wm94i/Work-Review · Vesper https://vesperlog.com · cairnlog https://github.com/cairnlog/claude-plugin
- Pragmatic Engineer work log template: https://blog.pragmaticengineer.com/work-log-template-for-software-engineers/

Data endpoints used (2026-10-06)

- Google suggest: `https://suggestqueries.google.com/complete/search?client=firefox&q=<query>` (unofficial)
- GitHub REST search and topic pages: `https://api.github.com/search/repositories?q=...`, `https://github.com/topics/<topic>`
- RDAP: `https://pubapi.registry.google/rdap/domain/<name>.dev|.app`, `https://rdap.verisign.com/com/v1/domain/<name>.com`
- Homebrew: `https://formulae.brew.sh/api/cask/<token>.json`, `https://formulae.brew.sh/api/formula/<name>.json`

---

## Appendix: autocomplete evidence (2026-10-06)

Seed, then what Google suggested (abridged). The five discarded sets are not listed.

- work log app mac: time log app mac; working hours app mac
- work journal app: ...free; work log app; work diary app; ...for windows, iphone, android
- daily log app: ...for construction; ...free; ...for iphone, android, windows; daily appointment log; daily journal app; daily tracker app
- daily work log: ...book; ...excel template; ...template; ...sheet
- work journal template: word; excel; pdf; notion; google docs; onenote
- software engineer work log: ...template; work journal software engineer
- brag document: template; template excel; example; software engineer; julia evans; template google docs; reddit
- brag document app: (itself only)
- claude code session: sessions; session history; session limit; session management; session list; session id; session sharing; session disappeared; session resume
- claude code history: history viewer; chat; command; disappeared; gone; vscode; viewer github; search
- claude code daily: daily limit; token limit; free limit; active users; token usage; routine; usage
- claude code summary: summary skill; view; prompt; command; context
- claude code journal: journal tool; journal skill; diary
- claude code standup: stand up skill
- claude code sessions list: list command; list to resume; sessions directory; previous session list
- claude code export conversation: to markdown; history; to file; save conversation
- claude code conversation viewer: chat viewer; history viewer; view conversation history
- claude code usage tracker: extension; github; vscode; plugin; mac; reddit; windows; terminal; chrome extension
- claude desktop history: chat history; version history; release history; update history
- ai work journal: ai work diary; ai work log
- mac journal app: desktop; reddit; review; download; export
- open source journal app: android; windows; reddit; diary app; best ...; free ...; open source daily journal app
- markdown journal app mac: free; best markdown journal macos; markdown journaling software; markdown diary mac; open source markdown journal macos
- day one alternative: reddit; journal alternative; app alternative; free alternative; best; open source alternative
- standup notes: template; daily standup notes; meeting notes template
- standup generator / daily standup generator: (itself only)
- git standup: github standup
- end of day report: template; sample; excel template; google sheets template; format; word template
- end of day journal: prompts; template; questions
- track accomplishments at work: template; examples
- automatic work log: automated work log; automated log work for jira; app to log work hours
- jrnl alternative: (itself only)
- journaling for software engineers: journals for software engineering; bullet journal for software engineers
