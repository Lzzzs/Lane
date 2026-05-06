# Lane — Design Spec

**Date:** 2026-05-06
**Status:** Draft, pending user review
**Author:** brainstormed with Claude (Opus 4.7)

---

## 1. Overview

**Lane** is a local-first, native macOS app for tracking parallel work-in-progress over time. It is designed for solo practitioners (initially developers) who manage many concurrent threads — product requirements, technical-infrastructure projects, learning, ops — and need to see the whole field at once without losing the daily focus.

The app's core metaphor is the **swim lane**: each parallel track of work occupies a horizontal lane on a shared time axis, and the user reads off "what's where" at a glance.

### Problems being solved

The user currently manages parallel work in Logseq. Three pains drove this project:

1. **Text-only is unreadable when parallelism is high.** Multiple in-flight requirements collapse into a wall of bullet points; nothing is glanceable.
2. **No timeline view.** No way to see at a glance where each requirement stands today and what should be touched. The user has to summarize the day's actionables manually each morning.
3. **Different work types mix together.** Product requirements and technical infrastructure get tangled in the same notes; mental separation has no visual support.

### Non-goals (v1)

- Team collaboration / multi-user
- Sync across devices
- Network/cloud features of any kind
- Reading or interoperating with any other tool's data (including Logseq)
- iOS / iPad / Windows / Linux versions
- AI features (summarization, suggestion, etc.)

### Future-friendliness

The user plans to potentially distribute Lane to others later. The data model and concepts are kept generic where possible (groups, not "requirements vs tech-infra"; editable templates, not hardcoded stages) so the v1 doesn't paint into a corner. But no v2 features are implemented in v1.

---

## 2. Brand & Visual System

### Name

**Lane** — singular. From "swim lane," the product's central UI metaphor. Single syllable, pronounceable in CN/EN, domain-friendly, ownable.

### Logo

The mark is two parallel horizontal lines, each with a short filled segment placed at a different x-position. It encodes: timeline + parallel tracks + asynchronous progress + calm. Pure black on warm white.

**No wordmark.** The mark stands alone. The name "Lane" appears in product chrome as plain text in General Sans Medium.

```
─────▮▮▮▮─────────
────────▮▮▮▮──────
```

Concrete file: `docs/superpowers/specs/lane-logo-concepts.svg` (variant A).

### App icon

macOS rounded-square, light variant: warm-white base (`#FAFAF7`) with the same mark in black. The choice keeps the icon visually consistent with the app's content background — a coherent "the icon is a snapshot of the canvas" feel.

Required sizes: 16, 32, 64, 128, 256, 512, 1024 px (icns bundle).

### Aesthetic direction

Editorial / Swiss-minimal / warm-paper. Heavy whitespace; tiny ALL-CAPS micro-labels in muted gray; one warm peach gradient wash at the top edge of the main canvas as the only signature flourish; no shadows, no large color fills, no rounded-corner skeuomorphism.

### Type

| Role | Family | Notes |
|---|---|---|
| Primary UI (Latin) | **General Sans** | Bundled with app (free for commercial use) |
| Primary UI (CJK) | **Source Han Sans** | Bundled (Noto Sans SC) |
| Mono (dates, numbers, IDs) | **JetBrains Mono** | Bundled |

CJK and Latin glyphs are mixed via font cascade (`CTFontDescriptor` + `kCTFontCascadeListAttribute`), not by per-character font switching.

User can override all three families in Settings → General → Typography. Bundled fonts always appear first; system fonts second.

### Color tokens

```
--bg-base       #FAFAF7   warm white background
--bg-wash       linear-gradient(180deg, #F5E8DD 0%, transparent 220px)
--bg-card       #FFFFFF
--border-hair   #E8E6E1   1px细
--border-rule   #DEDAD2   分隔线略深

--ink           #1A1A18   primary text
--ink-muted     #8A8682   secondary text
--ink-faint     #B5B0AA   tertiary, disabled, strikethrough

--tag-bg        #F0EEE8
--tag-ink       #5C5852

--accent-now    #000000   today line + due dot
--accent-warn   #B8542E   overdue (used sparingly)
```

**Group colors** (lane identity) — appear only as a 3px left rule on each lane and a small dot on cards. Never as full lane fills.

Default palette (calm, warm-leaning):

```
墨绿       #7A8C7A    (default for "Requirements")
暖灰棕     #8A7A6A    (default for "Tech Infra")
+ 6 more  curated set users pick from when creating new groups
```

Users cannot enter free hex values for group colors — only pick from the curated palette. This is a deliberate constraint to prevent palette drift that would damage the editorial coherence.

### Spacing rhythm

8-multiple system. Card padding 16/20/24, card spacing 12, section spacing 32, top bar height 56.

### Restraint rules (hard)

- No drop shadows
- No gradients except the single top wash
- No large color fills
- Icons: 1.5px stroke in `--ink-muted`, no color
- No "blue progress bar" — progress shown as character-density (`▓▓▓░░░`) or a 1px line at proportional length

---

## 3. Architecture

### App shape

- Standard macOS app (Dock icon, regular window, **not** menubar app)
- Single window, single primary view, no tab bar in main UI
- Settings open in a separate standard preferences window
- ⌘N for new requirement, ⌘, for settings, ⌘Z for undo

### Layered architecture

```
┌─────────────────────────────────────────────┐
│  Views (SwiftUI)                            │
│  - SplitView (Timeline 2/3 | Today 1/3)     │
│  - DetailInspector (overlay)                │
│  - SettingsScene                            │
└──────────────────────┬──────────────────────┘
                       │ @Observable
┌──────────────────────▼──────────────────────┐
│  Stores (in-memory observable state)        │
│  - AppStore (groups/requirements/today)     │
│  - TimelineStore (zoom, viewport, filter)   │
│  - SettingsStore (templates, prefs)         │
└──────────────────────┬──────────────────────┘
                       │ async calls
┌──────────────────────▼──────────────────────┐
│  Repository (Swift, protocols + SQL)        │
└──────────────────────┬──────────────────────┘
                       │
┌──────────────────────▼──────────────────────┐
│  Persistence (GRDB.swift)                   │
│  SQLite + WAL + migrations                  │
└─────────────────────────────────────────────┘
```

### Key technical decisions

| Decision | Rationale |
|---|---|
| **GRDB.swift** over Core Data / SwiftData | SQLite file is transparent — user can open with any SQLite tool. Core Data files are opaque, hurts data ownership. GRDB is mature, well-documented, fast. |
| **Repository protocol abstraction** | Stores can be unit-tested with in-memory implementation, no disk required. |
| **No network layer** | v1 is fully offline. |
| **Optimistic UI updates** | All edits update Stores synchronously, write to disk asynchronously. UI never waits on the database. |
| **Database location** | `~/Library/Application Support/Lane/store.db`, user-relocatable in Settings. |

### Performance budget (hard targets)

- Cold start ≤ 500 ms
- Time-granularity switch ≤ 100 ms
- Any write reflected in UI ≤ 16 ms
- Idle memory ≤ 80 MB with 50 requirements + 200 todos

---

## 4. Data Model

### Tables (SQLite, 9 total)

```sql
-- groups (swim lanes)
group
├ id            TEXT PRIMARY KEY    -- UUID
├ name          TEXT NOT NULL
├ color         TEXT NOT NULL       -- #hex from curated palette
├ icon          TEXT NOT NULL       -- single char from curated set: ●◆▲■★
├ sort_order    INTEGER NOT NULL
└ created_at    DATETIME NOT NULL

-- stage templates (global, reusable)
stage_template
├ id            TEXT PK
├ name          TEXT NOT NULL
├ is_default    BOOLEAN NOT NULL    -- exactly one row has true
└ created_at    DATETIME NOT NULL

stage_template_item
├ id            TEXT PK
├ template_id   TEXT NOT NULL FK -> stage_template ON DELETE CASCADE
├ name          TEXT NOT NULL
└ sort_order    INTEGER NOT NULL

-- the work itself
requirement
├ id            TEXT PK
├ group_id      TEXT NOT NULL FK -> group ON DELETE RESTRICT
├ title         TEXT NOT NULL
├ description   TEXT NOT NULL DEFAULT ''   -- markdown
├ template_id   TEXT FK -> stage_template ON DELETE RESTRICT  -- nullable if fully custom
├ status        TEXT NOT NULL DEFAULT 'active'  -- 'active' | 'archived'
├ sort_order    INTEGER NOT NULL          -- within group
├ created_at    DATETIME NOT NULL
├ updated_at    DATETIME NOT NULL
└ deleted_at    DATETIME                  -- soft delete; NULL = not deleted

-- stages owned by a requirement (cloned from template at creation)
stage_instance
├ id            TEXT PK
├ requirement_id TEXT NOT NULL FK -> requirement ON DELETE CASCADE
├ name          TEXT NOT NULL
├ sort_order    INTEGER NOT NULL
├ start_date    DATE                      -- NULL = unscheduled
├ end_date      DATE                      -- NULL = unscheduled
└ status        TEXT NOT NULL DEFAULT 'pending'  -- 'pending'|'active'|'done'|'skipped'

-- todos under stages
todo
├ id            TEXT PK
├ stage_instance_id TEXT NOT NULL FK -> stage_instance ON DELETE CASCADE
├ title         TEXT NOT NULL
├ done          BOOLEAN NOT NULL DEFAULT FALSE
├ done_at       DATETIME                  -- when marked done; for "completed today" view
├ sort_order    INTEGER NOT NULL
└ created_at    DATETIME NOT NULL

external_link
├ id            TEXT PK
├ requirement_id TEXT NOT NULL FK -> requirement ON DELETE CASCADE
├ label         TEXT NOT NULL
├ url           TEXT NOT NULL
└ sort_order    INTEGER NOT NULL

-- daily pinning (auto-expires)
today_pin
├ requirement_id TEXT NOT NULL FK -> requirement ON DELETE CASCADE
├ pinned_date    DATE NOT NULL
└ PRIMARY KEY (requirement_id, pinned_date)

-- key-value store for prefs and daily notes
setting
├ key   TEXT PRIMARY KEY
└ value TEXT NOT NULL                     -- JSON
```

### Key invariants and decisions

1. **Templates and instances decoupled.** Editing a `stage_template` never modifies any existing `stage_instance`. Creation copies template items to instances; the link via `requirement.template_id` is informational (lets the UI show "based on X template" and allows `template_id` to be set to NULL if the user fully customizes).

2. **Unscheduled = NULL dates.** A `stage_instance` with both dates NULL renders as a placeholder on the timeline and is excluded from the today view.

3. **`today_pin` auto-expires by composite primary key.** The user pins for a specific date. Old pins are not actively garbage-collected; a nightly background sweep on app launch deletes pins older than 30 days.

4. **Soft delete via `requirement.deleted_at`.** Deleted requirements stay in the database for 30 days (Settings → Data → Trash to restore). After 30 days a launch-time sweep hard-deletes them along with all FK-cascaded children.

5. **Group deletion is restricted.** If any non-deleted, non-archived requirement references the group, deletion is blocked with a UI prompt to reassign or archive first.

6. **Template deletion is restricted.** If any non-deleted requirement references the template, deletion is blocked. (Even though instances are decoupled, the back-reference matters for UI clarity.)

7. **Schema versioning.** Every database has a `schema_version` row in `setting`. Migrations run at startup; failure backs up the existing db as `store.db.backup-{version}` and aborts startup with a clear error.

---

## 5. Main Layout

```
┌────────────────────────────────────────────────────────────────────────────┐
│  ─ ─ ▮ ─ ─    [日 周 月]  [今天]   🔍 搜索    [需求][技建][+]      ⚙ +  │ ← top bar
├──────────────────────────────────────────────────────┬─────────────────────┤
│                                                       │  TODAY              │
│   5/4   5/5   5/6 ▼  5/7   5/8   5/9   5/10          │  MAY 6, 2026 · WED  │
│                     │                                 │                     │
│ REQUIREMENTS                                          │  IN PROGRESS    3   │
│ ▍ 登录改造        [评审━][设计▓▓▓░│┃[开发┄┄]        │  ┌───────────────┐  │
│ ▍ 支付接入                  ┃[设计━━━━━]            │  │ ●  REQ-074    │  │
│ ▍ 通知中心        [评审┄]                            │  │ 登录改造      │  │
│                              ┃                        │  │ 设计 · 3/5    │  │
│ TECH INFRA                   ┃                        │  └───────────────┘  │
│ ▍ 监控告警                  │┃[POC━━][实施┄┄]       │  ...                │
│ ▍ 日志归档        [调研━]   ┃                        │                     │
│                          today line                   │  PINNED TODAY  1   │
│                                                       │  ...                │
│                                                       │                     │
│                                                       │  ▾ COMPLETED   1   │
└──────────────────────────────────────────────────────┴─────────────────────┘
       ← timeline (2/3 of width)        drag    today panel (1/3)
```

### Top bar

- App mark (logo variant A) at far left
- Time granularity selector: `[日 周 月]`, default 周
- "Today" jump button (highlighted when scrolled away from current date)
- Search field (full-text over titles, descriptions, todos)
- Group filter pills — one per group, click to toggle visibility, `+` opens new-group dialog
- Settings gear, `+` new requirement

### Split

- Left 2/3: timeline canvas
- Right 1/3: today panel
- Draggable divider; window narrower than 900pt auto-collapses today panel into a side button
- Window narrower than 720pt falls back to a list view (timeline rendering disabled, user prompted to widen window)

### Detail inspector

Triggered by clicking any requirement. **Slides in from the right edge as an overlay** above the today panel. Today panel dims but remains visible. Width: 40% of window (clamped 480–720pt). Closed by ✕ / ESC / clicking empty space / clicking the same requirement again.

Rationale for overlay vs replace: today panel is the daily anchor; viewing a requirement should not destroy that context.

### Empty states

| Condition | Display |
|---|---|
| No requirements at all | Centered prompt on left: "Create your first requirement"; right: "Nothing scheduled today." |
| All groups filtered off | Left center: "All lanes hidden. Toggle a pill in the top bar." |
| Today has nothing in progress | Today panel: "Nothing actively scheduled today. Drag a stage onto today, or right-click → Pin to today." |

---

## 6. Timeline View

### Time granularity

| Level | Column width | Default visible range | Use case |
|---|---|---|---|
| Day | 200 pt | 5 days (today ±2) | scheduling specific work for the day |
| Week | 64 pt | 14 days | **default** — weekly rhythm |
| Month | 18 pt | 60 days | release-level planning |

When the user switches level, the today column stays in the visual center; left/right animates open/closed.

### Stage segment rendering

Each `stage_instance` renders as a horizontal bar following the editorial system:

```
done:        ─────       1px solid black, no fill, label struck through, gray
active:      ▓▓▓░░░      progress = (today - start) / (end - start), quantized to 0/25/50/75/100
pending:     ┄┄┄┄┄       1px dashed outline, white fill
unscheduled: ╭┄占位┄╮    placed after the last scheduled stage; very faint dashed, ink-faint label
```

- Quantized progress to integer fractions (avoid sub-pixel jitter on every tick)
- Label truncates with ellipsis if segment too narrow
- Segment narrower than 24pt: no label, only the bar; tooltip shows everything

### Today line

- 1px black vertical line spanning the timeline canvas
- 6px filled circle at top with ALL CAPS `TODAY` label
- "Today" button in top bar highlights when this line scrolls out of viewport; click → smooth scroll back

### Lane layout

```
▍REQUIREMENTS                                  3
│
│  Requirement A    [评审━][设计▓▓░][开发┄┄]
│  Requirement B                [设计▓▓▓▓░░░░]
│  Requirement C    [评审┄]
│  + Add requirement              ← gray ghost row, hover-only
│
▍TECH INFRA                                    2
```

- Lane header: ALL CAPS 11pt + count badge
- 3px group-color rule down the left edge
- Track row height: 36pt
- One requirement per row; never multi-line within a row
- Click lane header to collapse (count remains visible)

### Drag interactions (v1, intentionally minimal)

✅ Drag stage segment left/right → adjust both `start_date` and `end_date` together (preserves duration)
✅ Drag segment ends (handles) → adjust `start_date` or `end_date` individually
✅ Double-click segment → open detail inspector at that stage
✅ Single-click segment → tooltip with stage / dates / todo progress
✅ Right-click segment → menu: mark done / mark skipped / set unscheduled / delete
✅ Drag requirement-row handle → reorder within lane, or drop into another lane (changes `group_id`)

### v1 explicitly does not

- ❌ Stage-to-stage dependency arrows (Gantt-style)
- ❌ Cascading date changes (moving one stage doesn't shift later stages)
- ❌ Multi-select / batch operations

---

## 7. Today Panel

### Three sections

1. **IN PROGRESS** — auto-populated. Includes any requirement that has a `stage_instance` where `start_date ≤ today ≤ end_date` AND `status IN ('active', 'pending')`. Sorted by group, then by `requirement.sort_order`.

2. **PINNED FOR TODAY** — manual. From `today_pin WHERE pinned_date = today`. If a requirement appears in IN PROGRESS, it's excluded from this section (no duplicates).

3. **COMPLETED TODAY** — collapsed by default. Aggregates any `todo.done_at` or `stage_instance` transitioned to `done` on today's date. Items show `✓ {title} · {requirement} · {time}`.

### Card

```
┌─────────────────────────────────┐
│ ●  REQUIREMENTS    REQ-074      │ group dot + ALL CAPS group name + ID
│                                 │
│ 登录改造                         │ 14pt title
│                                 │
│ 设计  ·  3/5 todo               │ current stage + progress
│                                 │
│ ▓▓▓▓▓▓▓▓▓░░░░░ 60%              │ 1px line, length proportional to progress
│                                 │
│ VIEW DETAILS  →                 │ click anywhere on card opens detail
└─────────────────────────────────┘
```

### Card interactions

- Click card → open detail inspector
- Hover the todo line → inline checklist expands; click checkboxes without leaving panel
- Drag card → reorder (only meaningful in PINNED)
- Right-click → context menu (unpin / mark done / jump to timeline)

### Daily quick note

A single-line input at the bottom of the today panel, no border, placeholder `Quick note for today...`. Stored as `setting.daily_note_<YYYY-MM-DD>`. Cleared each new day. Pure private scratch — does not appear in timeline or anywhere else.

---

## 8. Detail Inspector & New Requirement Flow

### Detail inspector

Right-side overlay with title, description, stages with todos, links, timestamps. All editing is **inline** — click any text field to enter edit mode, Enter or blur to save. No save button. Optimistic updates write to memory immediately and to disk asynchronously.

```
✕                              REQ-074  ⋯
●  REQUIREMENTS

登录改造重构                              ← inline-editable title

────────────────────────────────────────
DESCRIPTION
{markdown content, click to edit}

────────────────────────────────────────
STAGES               TEMPLATE: 标准开发流程 ▾

✓ 评审      05/02 → 05/04         ▓▓▓▓▓
    ✓ 与产品对齐边界
    ✓ 兼容性确认

▶ 设计      05/05 → 05/09         ▓▓▓░░    ← active stage, expanded by default
    ✓ ER 图
    ✓ 接口文档
    □ Mock 数据
    □ 异常路径
    + 添加 todo

○ 开发      ──未排期──                       ← click to set dates
○ 联调      ──未排期──
○ 测试      ──未排期──
○ 上线      ──未排期──

────────────────────────────────────────
LINKS
→ PRD                  cooper.didi.../...
→ Figma 设计稿         figma.com/...
+ 添加链接

────────────────────────────────────────
CREATED  2026-04-28        UPDATED  TODAY
```

### Stage status icons

```
✓  done
▶  active
○  pending (unscheduled)
–  skipped
```

### Template switch

The `TEMPLATE: ▾` selector switches the requirement's template. A confirmation appears: **"Switching templates will reset stages that haven't started. Completed stages and their dates are preserved."** Concretely: stages where `status ∈ ('done', 'active')` are kept verbatim; pending/skipped stages are deleted and replaced with copies from the new template.

### More menu (⋯)

Archive · Duplicate as new · Delete (with second confirmation showing impact: "deletes 6 stages, 12 todos, 3 links")

### New requirement flow

`⌘N` or top-bar `+` → standard macOS sheet:

```
NEW REQUIREMENT

Title___________________________

GROUP
[ ● 需求 ] [ ◆ 技建 ]  + 新建分组

TEMPLATE
[ 标准开发流程 ▾ ]

STARTING STAGE
[ 评审 ▾ ]   start: [today]    duration: [3 days]

[ Cancel ]    [ Create ⏎ ]
```

- Only Title is required
- Default group = first group; default template = the one with `is_default = true`
- Default starting stage = first stage of template; default start = today; default duration = 3 days
- All other stages are created as `unscheduled`

---

## 9. Settings

Four tabs: General · Stages · Groups · Data. Standard macOS preferences window.

### General

- Default time granularity (Day / Week / Month)
- Week start (Monday / Sunday)
- Database file location (display + Reveal in Finder + Move...)
- Open window on launch ✓
- Theme (Light only in v1; Dark deferred to v2 — editorial style does not invert cleanly)
- **Typography**:
  - English font (default General Sans; bundled options + system fonts)
  - Chinese font (default Source Han Sans / PingFang SC fallback; bundled + system)
  - Mono font (default JetBrains Mono)
  - Base size (13 / 14 / 15 / 16 pt)
  - Live preview pane

### Stages (template editor)

Each template is a named, ordered list of stage names. Drag-handles to reorder, ✕ to remove a stage, `+ Add stage` at the end. Templates have a `⋯` menu for rename / set as default / duplicate / delete. Footer note reminds user that editing a template does not affect existing requirements.

### Groups

List of groups with editable name, color (curated palette only — no free hex input), icon (chosen from `● ◆ ▲ ■ ★ ▶`), and reorder handle. Deletion blocked if non-empty (with reassign / archive prompt).

### Data

```
DATABASE
   /Users/.../Library/.../store.db
   2.4 MB · 23 requirements · 156 todos
   [ Reveal in Finder ]   [ Move... ]

EXPORT
   [ Export as JSON  ↓ ]    single file, full schema dump with schema_version
   [ Export as Markdown ↓ ] one .md per requirement, for archival

IMPORT
   [ Import from JSON ↑ ]
   ⚠ Imports merge with existing data; conflicts skipped by ID.

TRASH (30-day retention)
   {list of soft-deleted requirements with restore / hard-delete buttons}

DANGER ZONE
   [ Reset all data... ]    red border, two-step confirmation
```

JSON export schema is the flat dump of the SQLite database with `schema_version`, designed to be the format Lane will eventually migrate from when shared with other users.

---

## 10. Edge Cases & Error Handling

### Dates

| Case | Behavior |
|---|---|
| `start > end` | Save blocked, red inline message |
| Stage dates out of order with neighbors | **Allowed** — real work is non-linear |
| Today > `end_date` and `status = 'active'` | Show ⚠ marker (`--accent-warn`), do not auto-transition status |
| DST / timezone | All dates are local-date only (no timestamp), so no conversion needed |
| Drag past ±5 years from today | Clamp |

### Data integrity

| Case | Behavior |
|---|---|
| Delete group with requirements | Blocked, prompt to reassign |
| Delete template with requirements | Blocked |
| Delete stage in template | Existing requirements unaffected (decoupled) |
| Delete requirement | Two-step confirm with impact summary; soft-delete; restorable for 30 days |
| Delete todo | No confirm; ⌘Z undoable |

### Database

| Case | Behavior |
|---|---|
| `store.db` corrupt | Startup detects, dialog with two options: open path in Finder, or initialize fresh DB (corrupt file moved to `.corrupted`) |
| Database locked by external | WAL allows concurrent read; on write conflict show transient toast, retry 3× |
| Disk full | In-memory state preserved; persistent red banner until space freed; auto-retry |
| Migration failure | Backup as `store.db.backup-{version}` before any migration; rollback on failure |

### Input

| Case | Behavior |
|---|---|
| Empty title on create | Blocked |
| Empty title on edit | Render as "Untitled" placeholder, do not persist empty |
| Long description | Unlimited storage; render truncated at 5000 chars with expand control |
| Invalid URL | Stored verbatim; on click, fail gracefully if not http(s)/file:// |
| Duplicate group/template name | Allowed (IDs are unique); soft warning prompt |

### Visual

| Case | Behavior |
|---|---|
| 50+ requirements in one lane | Lane header collapsed by default; >30 rows uses virtual scrolling |
| Stage segment width <24pt | No label; tooltip suffices |
| Window <720pt wide | Falls back to list view; prompts user to widen |
| Retina | All 1px lines computed as `0.5 / displayScale` |

---

## 11. Testing Strategy

### Unit (≈60% of tests)

- Repository layer fully covered, in-memory SQLite implementation
- CRUD on every entity
- Date validation
- Cascade rules (group → block, template → block, requirement → cascade children)
- Today-view query: given a date, returns the correct in-progress set
- `today_pin` expiration sweep
- Migration: simulate upgrade from older schema versions
- Import/export round-trip: `export → import` produces identical dataset

### Integration (≈30%)

- Stores ↔ Repository wiring
- Cross-store consistency: changing a group's color updates timeline render data
- Undo stack: 50-step minimum, all entity edits undoable

### Snapshot / UI (≈10%)

- Timeline at all 3 granularities
- Detail inspector in 3 states: empty stages, all done, all unscheduled
- Today panel: empty, partial, all sections populated

### Manual checklist (in CI's release-gate phase)

- Cold start ≤ 500 ms
- Idle memory ≤ 80 MB with seed data of 50 requirements + 200 todos
- Drag at 60 fps
- Bundled fonts load before first paint (no FOUT)
- Migration drill on real device

---

## 12. Out-of-scope but acknowledged (v2+)

These are intentionally not in v1 but the design accommodates them:

- **Cross-platform**: data model is filesystem + SQLite, transferable. UI layer would need rewrite (SwiftUI → other) but data layer is portable.
- **Stage dependencies / cascading dates**: stage instances already have `sort_order`; dependency edges would be a separate join table.
- **Recurring tasks / habits**: would be a new entity type, separate lane.
- **Sync**: SQLite + WAL is amenable to file-level sync (iCloud Drive); CRDT-style sync would require deeper schema changes.
- **Pure kanban users (no stages)**: a requirement with a single stage is effectively a kanban card; the v1 model already supports it.
- **AI features**: explicitly excluded.

---

## 13. Open questions for review

The following decisions were locked during brainstorming but should be confirmed during implementation:

- ✅ Logo variant A (mark only, no wordmark)
- ✅ App icon: light variant
- ✅ Curated group color palette (no free hex)
- ✅ v1 light mode only
- ✅ Soft-delete with 30-day trash retention
- ✅ Daily quick note in today panel
- ✅ Markdown export

---

## Appendix A: File layout (target)

```
Lane.app/
├ Contents/
│   ├ MacOS/Lane
│   ├ Info.plist
│   ├ Resources/
│   │   ├ AppIcon.icns
│   │   ├ Fonts/
│   │   │   ├ GeneralSans-Regular.otf
│   │   │   ├ GeneralSans-Medium.otf
│   │   │   ├ GeneralSans-Semibold.otf
│   │   │   ├ SourceHanSansSC-Regular.otf
│   │   │   ├ SourceHanSansSC-Medium.otf
│   │   │   └ JetBrainsMono-Regular.otf

~/Library/Application Support/Lane/
├ store.db
├ store.db-wal
├ store.db-shm
└ backups/
    └ store.db.backup-{schema_version}
```

## Appendix B: Bundle metadata

- Bundle ID: `app.lane.mac` (placeholder; revisit at distribution)
- Min macOS: 14.0 (Sonoma) — needed for `@Observable`, modern SwiftUI primitives
- Sandbox: enabled, with read/write access to user-selected database location only
- Hardened runtime + notarization: yes, for distribution outside Mac App Store
