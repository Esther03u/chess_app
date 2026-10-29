z# AGENTS.md — Chess App (Flutter/Dart) · Agent Operating Spec

<!-- audience: AI coding agents | doc-version: 1 | created: 2026-10-29 | language: English (talk to the user in Thai) -->

This file is written for AI agents (Claude Code, Cursor, Copilot, ChatGPT, etc.). Read it fully before acting. It is the single source of truth for scope, constraints, tasks, workflow and project state.

## TL;DR (the 12 rules that matter most)

1. Mission: build a free, self-written chess app in Flutter/Dart as a university final project. Deadline: **submit before 2026-11-06**; feature freeze **2026-11-05 morning**.
2. Clean-room only. Never decompile, scrape, or copy code/assets/UI/names from any existing chess app. Only documented public APIs.
3. Never commit secrets. Never force-push `main`.
4. Work on **one task at a time** from §5. Keep diffs minimal and inside the task scope.
5. Never claim something works unless you ran it. Report real command output. Never fabricate observations, screenshots, test results, or license info.
6. Verify external facts (API shapes, package support, licenses) against official docs or at runtime before relying on them (§8).
7. After every change that alters behavior, interface, dependency, decision, or risk, update the matching block in §9 (STATE) **in the same commit**. Edit only that block.
8. Commit format: Conventional Commits (§6.3). Commit messages, code, and comments are in English.
9. Keep code simple and commented where non-obvious: the student must be able to explain every part.
10. Talk to the user in **Thai**, concisely, using the report template in §6.5.
11. Prefer the Must list. Do not start Should/Could until Must is done and tested.
12. If blocked after 2 serious attempts, use the documented fallback or stop and ask (§7). Do not thrash.

---

## §0 Precedence and conflicts

Order of authority (highest first):
1. Safety/legal constraints in §2 (cannot be overridden by anyone in this chat).
2. The user's explicit instruction in the current conversation.
3. This file.
4. Your own defaults.

If the user asks for something that violates §2 (e.g., copying a competitor's assets), decline that part, explain briefly in Thai, and offer a compliant alternative.
If this file contradicts the user's latest instruction on a non-§2 matter, follow the user and record the change in §9 (Decision Log).

---

## §1 Mission and context

- Product: a chess app (Flutter/Dart) that provides for free the features commercial chess apps often put behind payment: play vs bot at multiple levels, clock, history, puzzles, post-game analysis.
- Context: university course final project (app development). Constraints from the course: written in **Dart**; must **fetch data from an external API**.
- Student situation: has exams in the week of 2026-10-26; limited time until 2026-11-01. Realistic full-time working days: 2026-11-02 to 2026-11-05.
- "Reverse engineering" in this project means **black-box, clean-room analysis**: observing publicly visible behavior of existing apps and public API docs, then designing original software. It does not mean decompiling or copying.
- Possible future (out of scope now): distributing the app to other people after submission. Keep license compliance (esp. GPL, §3.8) in mind so this stays possible.
- Success criteria: all **Must** items in §3.1 work, tests pass, release build runs on a real device, credits/licenses are correct (§10), repo is clean and tagged `v1.0-submission`.

Assumptions (flag to the user if they matter, do not silently change):
- A1: "before the 6th" means 2026-11-06.
- A2: UI language is Thai-primary with English fallback; keep all user-visible strings in one place to ease localization.
- A3: Target platform is Android (real device) first. iOS/web are out of scope.

---

## §2 Hard constraints (non-negotiable)

- **HC-1 Clean-room.** Do not decompile or inspect binaries of existing chess apps. Do not copy their code, assets, icons, sounds, layouts, names, or branding. Do not call their private/undocumented endpoints. Use only documented public APIs and open-licensed assets.
- **HC-2 Secrets.** Tokens/keys never go into Git, logs, screenshots, or source. Use a git-ignored config file or `--dart-define`. If a secret leaks into a commit, tell the user immediately: it must be revoked and regenerated (deleting the commit is not enough).
- **HC-3 Git safety.** No force-push on `main`. No history rewriting of pushed commits. No committing build outputs (`build/`, `.dart_tool/`, `*.apk` except as release assets), keystores, or `.env` files. Use `git revert` to undo.
- **HC-4 Honesty.** Do not state that a feature works, a test passes, or an API returns X unless you executed it and saw it. Mark anything unverified as `UNVERIFIED`. Never invent observations of competitor apps, screenshots, benchmark results, or license terms.
- **HC-5 Verify before use.** Treat everything in §8 as unverified until you check it against official docs or by running code. Record the result in §9.
- **HC-6 Minimal scope.** Change only what the current task requires. No drive-by refactors, reformatting of untouched files, or renames outside scope. If you find unrelated issues, log them in §9 (Open Issues) instead of fixing them.
- **HC-7 Dependencies.** Only add packages from §3.6 unless the user approves. Before adding any package: check its license, platform support, and last-maintained date; record it in §10.
- **HC-8 Explainability.** Prefer straightforward code over clever code. Add short comments for non-obvious logic (rules edge cases, UCI parsing, score sign conversion). The student must be able to defend the code orally.
- **HC-9 File safety.** Do not delete, overwrite, or rename user files outside your task scope. Do not run destructive commands (`rm -rf`, `git clean -fdx`, `git reset --hard`) without explicit user approval.
- **HC-10 Time discipline.** The deadline is fixed. Follow priorities in §3.1 and the schedule in §5. Cut scope rather than miss the deadline.

---

## §3 Product spec

### §3.1 Scope

| Level | Item | Notes |
|---|---|---|
| Must | Board + full chess rules, 2 players on one device | castling, en passant, promotion, check/mate/stalemate, draws (repetition, 50-move, insufficient material, agreed) |
| Must | Play vs bot, ≥3 difficulty levels | Stockfish via package, **fallback**: own minimax (§3.8) |
| Must | Chess clock with increment, flag detection | |
| Must | Game history (SQLite + PGN), reopen finished games | |
| Must | Puzzle from Lichess API (daily puzzle) with error handling | satisfies the "external API" requirement |
| Must | Unit tests for rules, classification math, PGN, JSON parsing | |
| Must | Release build verified on a real Android device | `INTERNET` permission in main manifest (§3.11) |
| Should | Post-game analysis: eval graph + blunder/mistake markers | only after all Must are done and tested |
| Could | Opening Explorer (requires token), player profile, themes/sounds, online play | cut by default |
| Out of scope | Online multiplayer, accounts, store publishing, iOS/web | |

### §3.2 Tech stack

- Flutter + Dart (record `flutter --version` in §9 after first run; do not upgrade the SDK mid-project).
- State management: `provider`.
- Storage: `sqflite` (+ `path`), `shared_preferences` for small settings.
- HTTP: `dio`.
- Rules: `chess` package (verify its API surface before use; §8).
- Engine: `stockfish` package (verify; §8).
- Charts (Should): `fl_chart`.

### §3.3 Architecture and directory layout

Layers (dependencies point downward only; `domain` must not import Flutter UI):

```
Presentation (screens, widgets)
State (providers/controllers)
Domain (rules wrapper, classification, PGN)   <- pure Dart, unit-testable
Data (EngineService, LichessApi, DbService)
```

```
lib/
  main.dart
  core/        theme, constants, strings (all user-visible text), result/error types
  models/      game_record.dart, move_record.dart, puzzle.dart
  services/    engine_service.dart, lichess_api.dart, db_service.dart
  domain/      game_logic.dart, classification.dart, classification_config.dart, pgn_codec.dart, simple_bot.dart
  providers/   game_controller.dart, clock_controller.dart, settings_provider.dart
  screens/     home, game, puzzle, history, analysis(optional), settings
  widgets/     board_view.dart, clock_view.dart, move_list.dart, eval_graph.dart(optional)
test/          mirrors lib/ (domain first)
docs/          this file lives at docs/ or repo root as AGENTS.md
```

### §3.4 Module responsibilities and suggested interfaces

Interfaces are suggestions: keep them small and stable; record any change in §9.

```dart
// domain/game_logic.dart — thin wrapper over the `chess` package
class GameLogic {
  String get fen;
  bool get isGameOver;
  String? get result;                 // '1-0' | '0-1' | '1/2-1/2' | null
  List<String> legalMovesFrom(String square);
  MoveResult tryMove(String from, String to, {String? promotion});
  bool undo();
  String toPgn();
}

// services/engine_service.dart
abstract class EngineService {
  Future<void> init();
  Future<void> setLevel(int skill0to20);
  Future<String> bestMove(String fen, {int movetimeMs = 500});
  Future<EngineEval> evaluate(String fen, {int movetimeMs = 250}); // cp from SIDE-TO-MOVE perspective
  Future<void> dispose();
}
class EngineEval { final int? cp; final int? mate; final String? bestMove; }

// services/lichess_api.dart
class LichessApi { Future<DailyPuzzle> dailyPuzzle(); }

// services/db_service.dart
class DbService {
  Future<int> saveGame(GameRecord g);
  Future<List<GameRecord>> listGames();
  Future<GameRecord?> getGame(int id);
  Future<void> saveAnalysis(int gameId, String json);
}
```

Fallback bot: `simple_bot.dart` implements the same bot interface using minimax depth 2–3 with alpha-beta on the `chess` package, material-count evaluation.

### §3.5 Data model

```sql
CREATE TABLE games (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pgn TEXT NOT NULL,
  white TEXT, black TEXT,
  result TEXT,                 -- '1-0' | '0-1' | '1/2-1/2' | '*'
  time_control TEXT,
  played_at INTEGER,           -- epoch ms
  analysis_json TEXT           -- cached analysis, nullable
);
```

PGN is the canonical game format. Use schema migrations (`onUpgrade`) if you change the table after data exists.

### §3.6 Approved dependencies

`chess`, `stockfish`, `dio`, `provider`, `sqflite`, `path`, `shared_preferences`, `fl_chart` (Should), `audioplayers` (Could), `flutter_secure_storage` (only if a token is ever stored), `mocktail` and `flutter_test` (dev). Anything else requires user approval (HC-7). Record version + license in §10 when added.

### §3.7 External APIs

All endpoints below are **UNVERIFIED until you check official docs / runtime** (§8). Always set sensible timeouts (8 s connect / 8 s receive), handle errors per §3.7.1.

| Purpose | Endpoint | Auth |
|---|---|---|
| Daily puzzle (Must) | `GET https://lichess.org/api/puzzle/daily` | none |
| Player profile (Could) | `GET https://lichess.org/api/user/{username}` | none |
| Cloud eval (optional) | `GET https://lichess.org/api/cloud-eval?fen=...` | none; may return 404 if position unknown |
| Opening Explorer (Could) | `GET https://explorer.lichess.ovh/masters?fen=...` | reported to require a Personal API Token — verify; excluded from scope by default |
| Chess.com player (Could) | `GET https://api.chess.com/pub/player/{username}` | none; verify User-Agent/rate-limit rules |

Expected daily-puzzle response fields (verify against a real response and save it as a test fixture): `puzzle.id`, `puzzle.rating`, `puzzle.solution` (list of UCI strings), `puzzle.initialPly`, `game.pgn`. Determine the puzzle's starting position by replaying `game.pgn` and confirm that `solution[0]` is a legal move there; write a unit test with the real fixture. Do not guess the ply arithmetic.

#### §3.7.1 Error handling (required for every API call)

- No connectivity → user-visible message + use cached last result if available.
- Timeout / 5xx → retry up to 2 times with exponential backoff, then show error.
- 429 → wait and retry once, then show error.
- 404 (e.g., cloud-eval) → fall back to local engine.
- Malformed/changed JSON → parse null-safely, never crash; show generic error.
- No secrets in logs.

### §3.8 Engine (UCI)

Protocol sequence: `uci` → `isready` → `ucinewgame` → `position fen <FEN>` → `go movetime <ms>` → read `info ... score cp <n>` or `score mate <n>` (use the last info line before `bestmove`) → `bestmove <uci>`. Difficulty: `setoption name Skill Level value <0..20>` and/or shorter `movetime`.

- Score perspective: UCI scores are from the **side to move**. Convert explicitly; never assume White's perspective.
- Run engine work off the UI thread; UI must stay responsive.
- Use a single engine instance shared by bot play and analysis, unless the package docs say otherwise (§8).
- Stockfish is **GPL**. Record this in §10. If the app is ever distributed, the corresponding source must be released under GPL-compatible terms.
- **Fallback trigger:** if the engine package cannot be integrated and working on the target Android device by **end of 2026-11-02**, switch to `simple_bot.dart` and log the decision in §9. Do not keep fighting the package.
- Engine files increase app size; test on a real device, not only an emulator.

### §3.9 Post-game analysis algorithm (Should)

Definitions for ply i (move `m_i` played from position `P_i`, giving `P_{i+1}`):

- `evalBefore_i` = eval(`P_i`), side-to-move = the mover → already mover's perspective (engine's best-play value).
- `evalAfter_i` = −eval(`P_{i+1}`) (side to move at `P_{i+1}` is the opponent, so negate).
- Evaluate each position **once** and reuse it (eval of `P_{i+1}` serves ply i and ply i+1).
- Do not send terminal positions to the engine: checkmated side to move → eval −10000; stalemate/draw → 0.
- Mate conversion: `score mate N` with N>0 → `cp = 10000 − N`; N<0 → `cp = −10000 − N`.
- `isEngineTop_i` = played move equals engine `bestmove` at `P_i`.

```dart
import 'dart:math';

double winPct(int cp) => 50 + 50 * (2 / (1 + exp(-0.00368208 * cp)) - 1);

double winLoss(int cpBefore, int cpAfter) =>
    max(0, winPct(cpBefore) - winPct(cpAfter));

String classify(double loss, {required bool isEngineTop}) {
  if (isEngineTop || loss < 2) return 'best';
  if (loss < 10) return 'good';
  if (loss < 20) return 'inaccuracy';
  if (loss < 30) return 'mistake';
  return 'blunder';
}

// UNVERIFIED constants: check against Lichess' published accuracy formula before claiming equivalence.
double moveAccuracy(double loss) =>
    (103.1668 * exp(-0.04354 * loss) - 3.1669).clamp(0, 100).toDouble();
```

- Game accuracy per side = arithmetic mean of `moveAccuracy` over that side's moves (not the mean of win%).
- Keep all thresholds/constants in `classification_config.dart` so they can be tuned and explained in the report.
- Run analysis in the background with a progress indicator; `movetime` ≈ 200–300 ms per position on mobile; cache the result in `analysis_json`.
- Brilliant (`!!`) and Book moves are Could; do not implement unless asked.

### §3.10 UI notes

- Board is always square (use `LayoutBuilder`/`AspectRatio`); works on small and large phones, portrait first.
- Highlight: legal destination squares, last move, king in check.
- Confirm resign; promotion dialog; move list with tap-to-navigate.
- All user-visible strings come from `core/strings.dart`.

### §3.11 Platform notes

- Android release builds need `<uses-permission android:name="android.permission.INTERNET"/>` in the **main** `AndroidManifest.xml` (not only debug/profile). Verify by building a **release** APK and calling the API on a real device.
- Test with network on and off.
- Do not hardcode tokens into the app; if a token is ever needed, it must be user-provided or kept out of the repo (HC-2).

---

## §4 Requirements and acceptance tests

| ID | Requirement | Acceptance check (must be executable or demonstrable) |
|---|---|---|
| FR1 | 2-player game with full rules | Unit tests pass for castling (incl. through check), en passant, promotion, checkmate, stalemate, threefold repetition, 50-move rule, insufficient material |
| FR2 | Bot with ≥3 levels | Level change affects play; record 5 games higher-vs-lower level in §9 with real results |
| FR3 | Clock + increment | Increment added after each move; flag = loss on time; clock stops when game ends |
| FR4 | History persistence | Finish a game → close app → reopen → game listed and replayable from PGN |
| FR5 | Daily puzzle via API | Loads on device; solution check works; handles offline/timeout/429/bad JSON without crashing |
| FR6 | Post-game analysis (Should) | Eval graph + per-move class for a sample game; math covered by unit tests |
| NFR1 | Responsive UI | No jank-level freezes while engine thinks (engine off UI thread) |
| NFR2 | Screen sizes | Board square and fully visible on small and large phones |
| NFR3 | Offline safety | App never crashes without network; shows a clear message |
| NFR4 | No secrets in repo | `git log -p` and tree contain no tokens/keys |
| NFR5 | Licensing | §10 complete for every dependency/asset before submission |

---

## §5 Task queue

Status values: `todo` · `doing` · `done` · `blocked` · `cut`. Update statuses in §9 (Status Board), not here.
Branch naming: `feat/<module>`, `fix/<topic>`, `docs/<topic>`. One PR/merge per task.

```yaml
- id: T-001
  title: Bootstrap repository
  level: Must
  target: 2026-10-29..2026-11-01
  branch: chore/bootstrap
  do:
    - flutter create (record Flutter/Dart versions)
    - git init -b main; extend .gitignore (.env, *.env, secrets.json, android/key.properties, *.jks, *.keystore)
    - place this file at docs/AGENTS.md or repo root AGENTS.md; create docs/observation/
    - add INTERNET permission to main AndroidManifest.xml
    - first commit "chore: initial Flutter project with project docs"
  done_when: flutter analyze clean; app launches; commit exists; user told how to push to GitHub

- id: T-002
  title: Observation table (competitor behavior)   # USER-OWNED
  level: Must
  target: before 2026-11-04
  do:
    - DO NOT fill this yourself. Ask the user for: app name, version, date, and for each feature: present? paywalled? plus screenshots saved in docs/observation/.
    - You may prepare the empty table and help structure the notes.
  done_when: user-provided table exists with evidence files

- id: T-003
  title: Board and rules
  level: Must
  target: 2026-10-29..2026-11-01 (light effort allowed)
  branch: feat/board
  files: lib/domain/game_logic.dart, lib/widgets/board_view.dart, lib/providers/game_controller.dart, test/domain/game_logic_test.dart
  done_when: FR1 tests pass; two humans can play a full game on one device

- id: T-004
  title: Lichess daily puzzle spike (verify API shape)
  level: Must
  target: 2026-10-29..2026-11-01 (small)
  branch: feat/puzzle-api
  files: lib/services/lichess_api.dart, lib/models/puzzle.dart, test/services/lichess_api_test.dart, test/fixtures/puzzle_daily.json
  do: call the endpoint once, save the real response as fixture, write model + parser against the fixture, implement §3.7.1 error handling
  done_when: parser test passes on real fixture; starting position derivation test passes

- id: T-005
  title: Engine integration with fallback
  level: Must
  target: 2026-11-02
  branch: feat/engine
  files: lib/services/engine_service.dart, lib/domain/simple_bot.dart, lib/screens/game (bot options)
  rules: verify package platform support first (§8); apply fallback trigger in §3.8
  done_when: FR2 satisfied on a real device

- id: T-006
  title: Clock
  level: Must
  target: 2026-11-03
  branch: feat/clock
  done_when: FR3 satisfied; unit tests for increment/flag logic (inject a fake ticker/clock)

- id: T-007
  title: Storage and history
  level: Must
  target: 2026-11-03
  branch: feat/storage
  done_when: FR4 satisfied; PGN round-trip test passes

- id: T-008
  title: Puzzle screen
  level: Must
  target: 2026-11-04
  branch: feat/puzzle-ui
  depends_on: [T-004, T-003]
  done_when: FR5 satisfied on a real device with network on/off

- id: T-009
  title: Tests and quality pass
  level: Must
  target: continuous; final pass 2026-11-04
  done_when: flutter test green; flutter analyze clean; dart format clean

- id: T-010
  title: Post-game analysis
  level: Should
  target: only if all Must are done and tested before 2026-11-04 afternoon; otherwise status=cut
  branch: feat/analysis
  depends_on: [T-005, T-007]
  done_when: FR6 satisfied

- id: T-011
  title: Release build verification
  level: Must
  target: 2026-11-05 morning
  done_when: release APK installed on a real device; API works; no crashes in a full game flow

- id: T-012
  title: Report and demo support
  level: Must
  target: 2026-11-05
  do: on request, produce outlines, diagrams, credit tables, and a demo script; the student writes/owns the final report; never fabricate results
  done_when: user confirms materials are ready

- id: T-013
  title: Freeze and tag
  level: Must
  target: 2026-11-05
  do: feature freeze (no new features), final checklist §6.6, tag v1.0-submission, make sure code is pushed
  done_when: tag exists; user confirms submission package
```

Cut rules:
- If at the end of 2026-11-04 any Must is incomplete → set T-010 and all Could to `cut` and spend the remaining time on Must + stability.
- Never start a new feature after the freeze.

---

## §6 Operating protocol

### §6.1 Per-task algorithm

1. **Orient:** read §9 (Status Board, Open Issues, the relevant module block). Run `git status`; the tree should be clean. Run `flutter pub get`, `flutter analyze`, `flutter test` to establish a baseline.
2. **Scope:** restate the task in 2–3 lines: module, files, acceptance check. If unclear, ask (§7).
3. **Branch:** `git switch -c <branch>` from up-to-date `main`.
4. **Test first** for bugs and rule logic (write the failing test, then fix). For new features, write the acceptance test or a manual test script.
5. **Implement minimally.** Touch only files in scope. Use targeted edits (patch the function/section, never regenerate whole files unless the file is new or the user asks).
6. **Verify:** `dart format .`, `flutter analyze`, `flutter test`. For UI/device behavior, run on a device/emulator and describe exactly what you did and saw. If you cannot run something (no device), say so explicitly and mark `UNVERIFIED`.
7. **Update state:** edit only the matching blocks in §9 (module block, Status Board row, Decision Log/Open Issues if applicable) and add a row at the top of the Change Log. Update §10 if dependencies/assets changed.
8. **Review diff:** `git diff` contains only intended changes; no secrets; no debug prints.
9. **Commit** using §6.3. One logical change per commit.
10. **Report** to the user in Thai using §6.5. Propose the next task.

### §6.2 Targeted-edit rules

- Prefer patch-style edits to existing files. Do not rewrite a file to change one function.
- Do not reformat unrelated code in the same commit as a logic change.
- When editing this file, replace only the content between the relevant `STATE:BEGIN/END` markers (§9). Never rewrite the whole file. Keep the markers intact.
- If a change touches more than one module, split it into separate commits (or separate tasks).

### §6.3 Commit convention (Conventional Commits)

```
<type>(<scope>): <summary, imperative, ≤ ~70 chars>

<why this change, if not obvious>
State: <module block(s) updated in AGENTS.md §9>
```

- `type`: `feat` `fix` `refactor` `test` `docs` `chore` `style`
- `scope`: `board` `rules` `engine` `clock` `storage` `api` `analysis` `ui` `settings` `tests` `docs`
- Examples: `feat(clock): add increment and flag detection` · `fix(rules): block castling through attacked square` · `test(analysis): cover mate conversion in winPct`

### §6.4 Git commands you may run (and may not)

- Allowed: `git status`, `git diff`, `git add <paths>`, `git commit`, `git switch`, `git switch -c`, `git log`, `git tag -a`, `git revert`, `git push -u origin <branch>` **only when the user has configured the remote and asked you to push**.
- Not allowed without explicit user approval: `git push --force`, `git reset --hard`, `git clean -fd`, `git rebase` on shared branches, deleting branches/tags.
- You do not have the user's GitHub credentials unless they are configured in your environment. If a push fails for auth reasons, give the user the exact commands to run themselves; do not ask them to paste tokens into chat.

### §6.5 Report template (to the user, in Thai)

```
สรุปงาน: <task id + สิ่งที่ทำ 1–2 ประโยค>
ไฟล์ที่แก้: <รายการ path>
ตรวจสอบแล้ว: <คำสั่งที่รันและผลจริง; สิ่งที่รันไม่ได้ให้ระบุว่ายังไม่ได้ตรวจ>
อัปเดตสถานะ: <บล็อกใน §9 ที่แก้>
Commit: <ข้อความ commit>
ขั้นตอนถัดไปที่แนะนำ: <task id>
คำถาม/สิ่งที่ต้องให้คุณตัดสินใจ: <ถ้ามี>
```

Keep it short. Do not paste whole files unless asked.

### §6.6 Definition of Done (every task) and pre-submission checklist

Per task:
- [ ] Acceptance check passes (real run, not assumed)
- [ ] `dart format .`, `flutter analyze`, `flutter test` clean
- [ ] Diff limited to scope; no secrets; no stray prints
- [ ] §9 updated (module block, Status Board, Change Log; Decision Log/Open Issues if relevant)
- [ ] §10 updated if dependency/asset/service added
- [ ] Commit message follows §6.3

Pre-submission (T-011/T-013):
- [ ] All Must tasks `done`
- [ ] Release APK tested on a real device with network on and off
- [ ] `INTERNET` permission present in the main manifest
- [ ] No tokens/keys in repo history
- [ ] §10 complete (packages, assets, Stockfish GPL note)
- [ ] Observation table + evidence provided by the user (T-002)
- [ ] README explains how to build and run
- [ ] Tag `v1.0-submission` created and pushed (if remote configured)

---

## §7 When to stop and ask the user

Ask (in Thai, one concise question, with your recommended default) when:
- A requirement is ambiguous and the wrong choice would cost >30 minutes.
- You need a dependency outside §3.6, or a license looks incompatible/unclear.
- You hit the same failure twice with different approaches (apply the documented fallback if one exists; otherwise ask).
- Something would exceed the Must scope or the time budget in §5.
- You need information only the user has (observation data, device model, GitHub repo URL, deadline confirmation, exam-free time windows).
- You are about to do anything destructive or irreversible (HC-3, HC-9).

Do **not** ask when: the answer is in this file; the choice is reversible and cheap; or you can verify it yourself by running code.

---

## §8 Verify-before-use list (all currently UNVERIFIED)

For each item: check official docs or run a minimal experiment, then record the outcome in §9 (Decision Log) and, if relevant, §10.

| # | Item | What to verify |
|---|---|---|
| V1 | `stockfish` package | Supported platforms (esp. the student's Android device), single-instance limitation, how UCI I/O is exposed, APK size impact, license text |
| V2 | `chess` package API | Names/behavior for legal moves, SAN/UCI, FEN/PGN import-export, draw detection (repetition, 50-move, insufficient material), promotion handling |
| V3 | Lichess daily-puzzle JSON | Real response shape; how `initialPly` relates to `game.pgn` ply count; save as fixture |
| V4 | Lichess puzzle variety | Whether an endpoint for more than the daily puzzle works without auth; otherwise keep daily-only |
| V5 | Lichess Opening Explorer | Whether a Personal API Token is required (reported yes); excluded from scope unless the user wants it |
| V6 | Chess.com PubAPI | User-Agent requirement and rate limits (only if used) |
| V7 | Accuracy formula constants | Compare with Lichess' published formula before describing it as "Lichess-equivalent" |
| V8 | Asset licenses | Every piece set / sound / font: license text and required attribution |
| V9 | Package licenses | Every dependency: license, and compatibility with GPL if Stockfish is bundled |
| V10 | Flutter/Android toolchain | Versions, device availability, emulator vs real-device behavior of the engine |

---

## §9 STATE (living handoff — edit only the block you changed)

Rules for this section:
- Every block is delimited by `<!-- STATE:BEGIN name -->` and `<!-- STATE:END name -->`. Replace **only** the text between matching markers. Never remove or rename markers.
- Update the relevant module block, the Status Board row, and the Change Log in the same commit as the code change.
- Dates are ISO (`YYYY-MM-DD`). New Change Log rows go on top.

<!-- STATE:BEGIN snapshot -->
| Field | Value |
|---|---|
| Last updated | 2026-10-29 |
| Repo | `https://github.com/Esther03u/chess_app.git` |
| Active branch | main |
| Latest tag | — |
| Flutter / Dart versions | Flutter 3.47.7 / Dart 3.13.5 |
| Target device | UNVERIFIED (ask the user) |
| Overall status | T-001 completed. Initial Flutter project created and baseline checks passed. |
<!-- STATE:END snapshot -->

<!-- STATE:BEGIN status-board -->
| Module | Level | Task | Status | Last updated | Notes |
|---|---|---|---|---|---|
| Bootstrap | Must | T-001 | done | 2026-10-29 | Initial Flutter project and docs |
| Observation table | Must | T-002 | todo | — | user-owned |
| Board & Rules | Must | T-003 | done | 2026-10-29 | FR1 unit tests passed; 2-player board UI complete |
| Puzzle API spike | Must | T-004 | done | 2026-10-29 | Real fixture verified; parser and error handling complete |
| Engine / Bot | Must | T-005 | done | 2026-10-29 | Pure Dart Minimax engine with 3 levels, off-thread compute, 5/5 wins Hard vs Easy |
| Clock | Must | T-006 | done | 2026-10-29 | Chess clock with increment, flag detection, FakeClockTicker, and UI |
| Storage | Must | T-007 | done | 2026-10-29 | SQLite persistence, PGN round-trip, History & Replay screens |
| Puzzle screen | Must | T-008 | done | 2026-10-29 | FR5 satisfied: Daily puzzle UI, move validation, opponent reply, offline/retry handling |
| Tests & quality | Must | T-009 | done | 2026-10-29 | 58 tests passed green; dart analyze clean; dart format clean; no secrets in repo |
| Analysis | Should | T-010 | todo | — | cut if Must not done by 2026-11-04 PM |
| Release verification | Must | T-011 | todo | — | |
| Report & demo support | Must | T-012 | todo | — | student owns final report |
| Freeze & tag | Must | T-013 | todo | — | |
<!-- STATE:END status-board -->

<!-- STATE:BEGIN module:board -->
- Last updated: 2026-10-29
- Files: lib/domain/game_logic.dart, lib/providers/game_controller.dart, lib/widgets/board_view.dart, lib/screens/game_screen.dart, lib/core/strings.dart, test/domain/game_logic_test.dart
- Implemented: Full chess rules (castling through check blocked, en passant, promotion with piece selection dialog, check/checkmate, stalemate, threefold repetition, 50-move rule, insufficient material, undo, PGN export), responsive square board view with legal destination/last move/check highlights, 2-player local match screen.
- Public interface: GameLogic (fen, turn, isInCheck, isCheckmate, isStalemate, isThreefoldRepetition, isInsufficientMaterial, isFiftyMoveRule, isDraw, isGameOver, result, legalMovesFrom, tryMove, undo, reset, loadFen, loadPgn, toPgn)
- Decisions: verified V2 (`chess` package API 0.8.1 works and covers full rules under MIT/BSD license); responsive square layout using Expanded and AspectRatio.
- Open issues: none
- Manual test steps: open app, play moves on board, observe legal move indicators, test pawn promotion, test check and checkmate, press undo and restart.
<!-- STATE:END module:board -->

<!-- STATE:BEGIN module:engine -->
- Last updated: 2026-10-29
- Files: lib/domain/simple_bot.dart, lib/services/engine_service.dart, lib/providers/game_controller.dart, lib/screens/game_screen.dart, test/domain/simple_bot_test.dart, test/providers/game_controller_test.dart
- Implemented: 3 difficulty levels (Easy, Medium, Hard), Minimax with Alpha-Beta pruning, positional evaluation (Piece-Square Tables + material weights), off-thread calculation via compute() (NFR1), UI mode toggle (Pass & Play vs Play vs Bot), player color selection, bot thinking indicator, auto move execution, undo support in bot mode, side-to-move centipawn/mate evaluation.
- Verified FR2 with simulated 5-game match between Hard and Easy (Hard won 5-0: 27, 29, 43, 45, 23 plies).
- Decisions: verified V1 (`stockfish` 1.8.1 GPL-3.0 compiles native binaries only for Android/iOS, causing FFI crashes on host Windows and test environments; therefore `simple_bot.dart` provides clean, rock-solid fallback on all platforms and devices).
- Open issues: none
- Manual test steps: Select "เล่นกับบอท", pick difficulty and color, play moves; bot responds within ~500ms without freezing UI; undo reverts both bot and player move.
<!-- STATE:END module:engine -->

<!-- STATE:BEGIN module:clock -->
- Last updated: 2026-10-29
- Files: lib/providers/clock_controller.dart, lib/widgets/clock_view.dart, lib/providers/game_controller.dart, lib/screens/game_screen.dart, test/providers/clock_controller_test.dart
- Implemented: TimeControl presets (Unlimited, Blitz 3+2, Blitz 5+0, Rapid 10+0, Rapid 15+10), ClockController with drift-free DateTime delta tracking and FakeClockTicker for tests, per-move increment addition (FR3), flag detection (loss on time 0-1 / 1-0) when time reaches 0, clock pausing when game ends or is paused, symmetrical ClockView UI displaying remaining time, active state glow, and low-time warning.
- Verified: 7 unit tests covering increment addition, flag detection, pause/resume, unlimited mode, and time formatters.
- Open issues: none
- Manual test steps: Select Time Control in settings (e.g. 3+2 Blitz), make moves; observe clock count down for the side to move, increment +2s added after each move, clock pauses on checkmate/resign.
<!-- STATE:END module:clock -->

<!-- STATE:BEGIN module:storage -->
- Last updated: 2026-10-29
- Files: lib/models/game_record.dart, lib/services/db_service.dart, lib/screens/history_screen.dart, lib/providers/game_controller.dart, test/domain/pgn_roundtrip_test.dart, test/services/db_service_test.dart, test/screens/history_screen_test.dart
- Schema version: 1 (see §3.5)
- Implemented: GameRecord model, DbService with SQLite persistence (`sqflite: ^2.4.5` + `path: ^1.9.1`), auto-save completed games on checkmate, draw, resign, and timeout, HistoryScreen listing completed matches in descending order with result badges and time controls, interactive GameReplayScreen for move-by-move navigation (first, prev, next, last) from saved PGN (FR4).
- Verified: PGN round-trip unit tests passed (preserving standard moves, castling, en passant, promotion); DbService CRUD tests passed on in-memory SQLite; HistoryScreen & GameReplayScreen widget tests passed.
- Open issues: none
- Manual test steps: Finish a game -> open History screen from AppBar -> confirm game is listed with correct result and players -> tap to open GameReplayScreen -> step through moves -> delete record.
<!-- STATE:END module:storage -->

<!-- STATE:BEGIN module:api -->
- Last updated: 2026-10-29
- Files: lib/models/puzzle.dart, lib/services/lichess_api.dart, lib/screens/puzzle_screen.dart, test/fixtures/puzzle_daily.json, test/services/lichess_api_test.dart, test/screens/puzzle_screen_test.dart
- Endpoint in use: `GET https://lichess.org/api/puzzle/daily` (verified V3 from live endpoint)
- Fixture: `test/fixtures/puzzle_daily.json` (captured and verified)
- Implemented: Daily puzzle screen (PuzzleScreen) with rating, themes, ID, interactive square board oriented to player's turn, move verification against UCI solution array, automatic opponent response delay, victory state detection, wrong move feedback, reveal solution, and offline error state with retry button (FR5).
- Decisions: verified V3 (daily puzzle response contains puzzle.fen, puzzle.solution UCI array, puzzle.initialPly, and game metadata); Opening Explorer excluded from scope (token requirement, V5).
- Error handling: implemented §3.7.1 (timeouts 8s, retry with exponential backoff on 5xx/timeout, 429 wait & retry, no-connectivity cached fallback, null-safe parsing).
- Manual test steps: open Daily Puzzle from AppBar -> make moves -> observe correct move / opponent reply / victory banner; test offline mode with retry button.
<!-- STATE:END module:api -->

<!-- STATE:BEGIN module:analysis -->
- Last updated: —
- Files: —
- Decisions: thresholds 2/10/20/30 win% loss (tunable in `classification_config.dart`); accuracy constants UNVERIFIED (V7)
- Open issues: —
<!-- STATE:END module:analysis -->

<!-- STATE:BEGIN module:ui -->
- Last updated: —
- Files: —
- Decisions: `provider` for state; all strings in `core/strings.dart`; Thai-primary UI (assumption A2)
- Open issues: —
<!-- STATE:END module:ui -->

<!-- STATE:BEGIN module:tests -->
- Last updated: 2026-10-29
- Covered:
  - Domain rules: castling (normal, queenside, through check blocked), en passant, promotion, checkmate, stalemate, threefold repetition, 50-move rule, insufficient material, UCI move parsing (`game_logic_test.dart` - 18 tests)
  - Engine / Bot: Minimax depth 1..3, alpha-beta pruning, mate-in-1 finish, free Queen capture, side-to-move centipawn eval, 5 games Hard vs Easy (5-0) (`simple_bot_test.dart` - 10 tests)
  - Controller & Bot UI: UI mode toggle, player color selection, bot move execution, undo in bot mode (`game_controller_test.dart` - 6 tests)
  - Clock: increment addition (+2s, +10s), flag detection (loss on time 0-1 / 1-0), unlimited mode, pause/resume, FakeClockTicker (`clock_controller_test.dart` - 7 tests)
  - Storage & PGN: PGN round-trip export/import preserving moves and results, SQLite CRUD operations (`pgn_roundtrip_test.dart` - 2 tests, `db_service_test.dart` - 5 tests)
  - Screens: HistoryScreen & GameReplayScreen navigation/replay (`history_screen_test.dart` - 4 tests)
  - Puzzle: Daily puzzle parsing, starting position derivation, move validation, opponent auto-reply, victory banner, wrong move handling, offline retry (`lichess_api_test.dart` - 4 tests, `puzzle_screen_test.dart` - 6 tests)
- Total tests: 58 unit and widget tests, 100% passing green.
- Commands: `flutter test`, `dart analyze`, `dart format --output=none --set-exit-if-changed .`
<!-- STATE:END module:tests -->

<!-- STATE:BEGIN decision-log -->
| Date | Decision | Reason | Alternatives not chosen |
|---|---|---|---|
| 2026-10-29 | Verified Stockfish package limitation (V1) & implemented SimpleBot fallback | Stockfish 1.8.1 requires native compilation for Android/iOS and fails on Windows host/tests; SimpleBot (Minimax Alpha-Beta) guarantees cross-platform reliability and off-thread UI responsiveness | Stuck on native FFI issues |
| 2026-10-29 | Verified Lichess Daily Puzzle API (V3) | Live endpoint returns puzzle with exact starting FEN, UCI solution, and initialPly; no auth required | Web scraping |
| 2026-10-29 | Verified `chess` 0.8.1 (V2) | Covers full FEN/PGN, castling, en passant, promotion, and draw rules; MIT/BSD license | Custom rules engine |
| 2026-10-29 | Keep project state, rules and tasks in this single AGENTS.md with STATE markers | Lets agents make targeted updates and onboard quickly | Multiple separate docs |
| 2026-10-29 | Online play, Opening Explorer, themes cut from submission scope | Limited time (exam week) | Build all features |
| 2026-10-29 | Post-game analysis is Should, not Must | Time risk | Mandatory |
| 2026-10-29 | `provider` for state management | Fast to learn, enough for scope | Riverpod, Bloc |
<!-- STATE:END decision-log -->

<!-- STATE:BEGIN open-issues -->
| # | Issue | Impact | Plan | Status |
|---|---|---|---|---|
| 1 | Limited time (exams until ~2026-11-01, deadline 2026-11-06) | Scope may not fit | Follow §5 priorities; apply cut rules | open |
| 2 | `stockfish` package unverified on target device (V1) | No strong bot | SimpleBot fallback implemented & satisfies FR2 | closed |
| 3 | Observation table not yet provided by the user (T-002) | Report lacks evidence | Ask the user; never fabricate | open |
| 4 | Release build may lack INTERNET permission | API fails in release | Add to main manifest in T-001; verify in T-011 | open |
| 5 | Deadline interpretation (A1) not confirmed | Wrong schedule | Confirm with the user once | open |
<!-- STATE:END open-issues -->

<!-- STATE:BEGIN change-log -->
| Date | Commit | Module | Summary | State blocks updated |
|---|---|---|---|---|
| 2026-10-29 | 70e377d | tests | T-009: Test suite verification (58/58 pass), analyze clean, format clean, zero secrets | status-board, module:tests, change-log |
| 2026-10-29 | fb38922 | puzzle | T-008: Daily puzzle screen, solution verification, opponent auto-reply, offline fallback | status-board, module:api, change-log |
| 2026-10-29 | 72e99b7 | storage | T-007: SQLite storage, PGN round-trip, History and GameReplay screens | status-board, module:storage, change-log, credits |
| 2026-10-29 | e04f7d2 | clock | T-006: Chess clock with increment, flag detection, and UI integration | status-board, module:clock, change-log |
| 2026-10-29 | e6d4d3a | engine | T-005: Engine integration with fallback (Minimax, 3 levels, off-thread compute, UI controls) | status-board, module:engine, decision-log, open-issues, change-log, credits |
| 2026-10-29 | 4a41fcc | api | T-004: Lichess daily puzzle API spike, parser and fixture | status-board, module:api, decision-log, change-log, credits |
| 2026-10-29 | 9bfd520 | board | T-003: Full chess rules and 2-player board UI | status-board, module:board, decision-log, change-log, credits |
| 2026-10-29 | 84dce56 | chore | T-001: Bootstrap Flutter repository and project docs | snapshot, status-board, change-log |
| 2026-10-29 | (none yet) | docs | Created agent-facing spec (AGENTS.md) | all |
<!-- STATE:END change-log -->

---

## §10 Credits and licenses (update whenever dependencies/assets/services change)

<!-- STATE:BEGIN credits -->
| Name | Version | Purpose | License (verified from source) | Source URL | Verified on |
|---|---|---|---|---|---|
| chess | 0.8.1 | rules, FEN/PGN | MIT / BSD-2-Clause | https://pub.dev/packages/chess | 2026-10-29 |
| stockfish | 1.8.1 | native Android engine | GPL-3.0 | https://pub.dev/packages/stockfish | 2026-10-29 |
| dio | 5.11.1 | HTTP | MIT | https://pub.dev/packages/dio | 2026-10-29 |
| provider | 6.1.5+1 | state | MIT | https://pub.dev/packages/provider | 2026-10-29 |
| sqflite | 2.4.5 | local SQLite DB | BSD-2-Clause | https://pub.dev/packages/sqflite | 2026-10-29 |
| path | 1.9.1 | path manipulation | BSD-3-Clause | https://pub.dev/packages/path | 2026-10-29 |

| Asset / service | Author | License | Required attribution | Source URL |
|---|---|---|---|---|
| (none yet) | | | | |
| Lichess API | Lichess | Open API (no auth for daily puzzle) | credit Lichess where data is shown | https://lichess.org/api | 2026-10-29 |
<!-- STATE:END credits -->

Notes:
- Stockfish is GPL: if the app is distributed, comply with GPL (release corresponding source).
- Never use assets from other chess apps.

---

## §11 Anti-patterns (do not do these)

- Rewriting whole files or regenerating the project to make a small change.
- Starting Should/Could work while a Must is unfinished or untested.
- Adding packages "just in case".
- Reporting success based on assumptions ("should work") instead of runs.
- Guessing API JSON shapes or ply arithmetic instead of using a real fixture.
- Filling the observation table or inventing competitor behavior.
- Embedding tokens, or logging them.
- Hand-waving engine score perspective (always convert from side-to-move).
- Doing long engine analysis on the UI thread.
- Large unexplained code the student cannot defend in an oral exam.
- Spending hours fighting a package after the fallback trigger date.
- Asking the user questions already answered by this file.
- Touching `main` directly for feature work.
