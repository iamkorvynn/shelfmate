# ShelfMate — Day 5 daily app (build with Antigravity)

Build a complete, real Flutter app called **ShelfMate**: a personal lending tracker.
It answers one question: "what did I lend, to whom, and when is it coming back?"

## What it does

- **Items**: add anything you lend — books, notes, chargers, lab gear, anything. Each item has a name, a category (Books, Notes, Chargers, Lab gear, Other), an optional note, and a photo-free simple entry.
- **Lend it out**: pick a borrower (a friend), the date lent, and an expected return date. Status becomes Out.
- **Return it**: mark returned with the return date. Status becomes Returned and it moves to history.
- **Overdue**: any Out item past its expected return date shows as Overdue automatically.
- **Borrowers**: a friends list (name, optional phone). Tap a friend to see everything they currently have and everything they ever borrowed.
- **Return reminders**: local notifications — due tomorrow, due today, and overdue. Configurable reminder time in Settings.
- **Dashboard**: out now, due soon, overdue, total lent ever, and the next item due back.
- **History**: every returned item with lent date, return date, and how long it was out.
- **Stats**: most-borrowed item, most frequent borrower, longest outstanding loan, on-time return rate, loans per category.
- **Settings**: default loan period in days, reminder time, 12h/24h clock, export data (CSV), backup/restore (JSON), clear all data.

## Screens

Dashboard, Items (Out / Returned tabs), Borrowers, Stats, Settings. Bottom navigation. Material 3, clean and simple.

## Data

- Local SQLite only (sqflite). The app starts EMPTY — no demo data, no sample items, no sample friends.
- No accounts, no cloud, no analytics. Everything stays on the device.

## Quality gates (all must pass before you finish)

1. `flutter analyze` — zero issues.
2. `flutter test` — 400+ tests, all passing. Test the models, the database layer, the overdue/due-soon logic, and the widgets.
3. `flutter build apk --release` — must succeed and produce `build/app/outputs/flutter-apk/app-release.apk`. The APK must declare `android.permission.INTERNET` (verify with aapt2).
4. **200 commits, all dated 2026-11-24**, by author "Numaan Bin Husain <numaanbinhusain@gmail.com>". Use GIT_AUTHOR_DATE / GIT_COMMITTER_DATE env vars (already set for this run). Small, real commits — one feature or fix per commit, not one giant commit.
5. The public GitHub repo `iamkorvynn/shelfmate` ALREADY EXISTS (remote `origin` is set and the scaffold commit is pushed) — do NOT create it, just push main to it. Verify it is PUBLIC with `gh repo view`.

## Build environment (already set for this run)

- Flutter SDK at `~/workspace/flutter-sdk/flutter/bin/flutter`, JDK 17 at `~/workspace/android-sdk/jdk17`.
- `JAVA_TOOL_OPTIONS=-Djava.net.preferIPv4Stack=true` (Java loopback hangs on this VM without it).
- `GRADLE_USER_HOME=~/workspace/overnight-8-apps/.gradle-home`, `TMPDIR=<workdir>/.tmp`, `CI=true`.
- For the release build you MUST set `JAVA_HOME=~/workspace/android-sdk/jdk17` and put its `bin` on PATH, or Gradle fails with "JAVA_HOME is not set".
- Gradle heap is 1.5G and the daemon is off (`org.gradle.daemon=false` in android/gradle.properties). Release builds take a while on this VM — be patient, do not kill them.

## Bugs fixed on earlier apps — do NOT repeat them

- Never put a Form inside a ListView (validation breaks). Use SingleChildScrollView + Column for every form screen.
- flutter_local_notifications needs desugaring enabled in android/app/build.gradle.kts, or the release build fails.
- In widget tests, always `await tester.pumpAndSettle()` after taps that trigger navigation or dialogs.

## Finish by reporting

Exact commit count, test count, analyze result, APK size in bytes, package name, repo URL, and the release APK path. Do not claim a gate passed unless you ran the command and saw it pass.
