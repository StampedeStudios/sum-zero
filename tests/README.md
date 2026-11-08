# UI layout checks

Import the project once, then run the main-menu checks:

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/main_menu_layout_test.gd
godot --headless --path . --script tests/gameplay_layout_test.gd
godot --headless --path . --script tests/arena_layout_test.gd
godot --headless --path . --script tests/editor_arena_unlock_test.gd
godot --headless --path . --script tests/builder_playtest_layout_test.gd
godot --headless --path . --script tests/builder_editor_layout_test.gd
godot --headless --path . --script tests/level_menu_layout_test.gd
godot --headless --path . --script tests/level_inspect_layout_test.gd
godot --headless --path . --script tests/level_import_layout_test.gd
godot --headless --path . --script tests/mode_selection_layout_test.gd
```

The test checks six viewport sizes in all six supported languages, including
live resizing, translated button minimum sizes, centering, vertical overflow,
signal connections, and menu visibility when navigating away and back.
It does not replace visual or pointer/touch testing.

## Main-menu migration checkpoint

The menu now uses containers and `assets/resources/themes/main_menu.tres`,
without reading `GameManager` sizing values. Buttons retain their natural
content width (with a 280-unit minimum for the column), rather than stretching
across tablet displays. Longer labels wrap; short windows scroll vertically.

For this intermediate step, visual sizes target the existing 480×853 window.
Project-wide stretch settings and all other screens remain unchanged. Thus the
menu reflows on resize, but does not yet scale proportionally with resolution.
When switching the project to a 720×1280 logical canvas, retune this menu's
theme metrics and column minimum width for that canvas at the same checkpoint.

Before continuing, visually check the five menu actions, icon/text spacing,
hover/pressed states, and scrolling in a short embedded game window. Safe-area
insets and the global resolution-scaling switch remain later work.

## Campaign gameplay checkpoint

`GameUI` now allocates a `BoardHost` above its action bar. The host supplies the
board's available rectangle whenever containers resize or reposition it.
`LevelManager` fits the board and its edge-handle band uniformly into that
rectangle, with an 8-unit inset and a 120-unit cell-size cap. These are logical
480×853-era metrics to revisit at the global stretch checkpoint.

Builder testing uses the same host after its own migration (see below).
Slider dragging and hit distances no longer depend on cached screen-sized
cells; entry reveal distances are also board-local to tolerate resizing.
No sprites or puzzle rules were changed.

The gameplay test covers square/rectangular 2–5-cell boards, five window shapes,
skip visibility changes, action-bar separation, cell-size limits, all four
slider orientations, and tile changes/rewinding after a drag.

Visually test campaign levels (small and large), dragging from each edge,
automatic sliders, reset, completion, replay/next, and resizing during a level.
Also smoke-test an arena round and builder playtest since they share sliders.

## Arena checkpoint

Arena uses the same board host and gameplay button theme as campaign. A VBox
reserves room for the timer header, board, and actions; untimed modes hide the
header entirely. The loading indicator is anchored to the board-host center,
and the floating time bonus is anchored relative to the timer's center.
Successive time bonuses cancel the previous animation instead of accumulating
position offsets. Timer rules, scoring, and generation are unchanged.

The arena test covers 80 combinations of board dimensions, viewport shape,
timer visibility, and skip visibility. It also checks timer startup, skip-cost
visibility, repeated positive/negative bonuses, and loading display.

Visually check timed and untimed modes, loading between puzzles, time bonuses
and skip penalties, reset, end-of-round results, exit, and live resizing.
Sprites and global stretch settings remain unchanged.

### Testing locked arena modes

Open `packed_scene/user_interface/PlayModeSelection.tscn`, select the root node,
and enable **Unlock Arena Modes In Editor** in the Inspector. Save the scene and
run the project. Arena cards bypass progression locks without modifying saves.
The checkbox defaults to off and is ignored by export-template builds (including
debug exports); it checks `OS.has_feature("editor")`, not `Engine.is_editor_hint()`.
It also works when launching the project with the editor executable from a shell.

## Builder playtest checkpoint

`BuilderTest` uses the shared board host and gameplay icon-button theme, with
a move counter above the board and actions below it. It rebinds the host each
time playtest starts, including when reusing the same UI after editing a level.
It does not change the editing canvas, editor zoom/pan, or editing dialogs.

The test checks 20 board/window combinations, move counting, reset, returning
to the editor, repeated playtests with different grid dimensions, preserving
the source level, and freeing playtest scenes when leaving the builder.

Visually test small/large custom levels, resize during playtest, make moves,
reset, return to editing, change the grid dimensions, then playtest again.

## Builder editor checkpoint

The editor reserves a canvas between wrapping top/bottom toolbars. Its board
fit and temporary slider-selection pan are editor-owned, independent of the
old global level scale. The hidden editor keeps its canvas rectangle up to
date while selection overlays are open. Selection actions follow grid-local
targets and stay inside the viewport; their backdrop resizes with the window.
The dimension dialog fits and centers the board inside its live square preview.
The save dialog uses bounded dimensions and a local opening animation instead
of global UI scaling. Puzzle rules, save encoding, sprites, and global stretch
settings are unchanged.

The editor test covers 120 dimension/window/language combinations, cell edits,
all four slider edges, resetting temporary pan, live selection/preview resizing,
dimension changes, cancelling save at portrait/landscape sizes, and the real
playtest/return lifecycle. It never writes a custom level to disk.

Visually check drag-selecting one/many cells, value/block/remove actions,
slider effects/behaviors on all edges, growing/shrinking dimensions, generation,
reset, save/cancel, and editing again after playtest. Resize with selection,
dimension, and save overlays open, especially in a narrow or landscape window.

## Level-selection menu checkpoint

Campaign/custom level selection uses a header, clipped page host, and bottom
navigation. Each page centers its 3×3 grid inside the host, with bounded tile
sizes and a dedicated theme. Page width follows the host, not startup viewport
dimensions. Resizing cancels an unfinished transition/swipe and retains the
last settled page. Paging still reuses three pages and supports mouse swipes.
Returning from play/editor refreshes the page count; shrinking custom lists
clamps the selected page. Empty custom/import tiles clear stale disabled state.

The test covers 60 context/window/language combinations, next/previous and final
pages, resizing mid-animation/swipe, tile-state recycling, and custom counts
0/8/9/10/18 including the extra import page and shrinking the list. Fixtures
replace only in-memory save data and never call persistence methods.

Visually check campaign/custom grids, locks/stars, arrow and swipe navigation,
click suppression after swiping, opening a level and returning, import slots,
and launching/returning from the editor. Level-detail dialogs have their own
checkpoint below; import retains its existing layout.

## Level-detail dialog checkpoint

Campaign/custom inspectors now share one container-based scene, with custom
copy/delete controls enabled by the inherited scene. A bounded panel tracks
window size and uses a local opening animation independent of global UI scale.
The title wraps up to two lines (then ellipsizes), stars occupy a reserved row,
and actions use a flow container. Content can scroll on unusually short windows.
Dark text/icons, primary Play styling, gray unearned stars, and gold earned
stars are explicit in the dialog theme/materials. Star visibility resets on
every initialization, including incomplete levels. Unlock/edit rules, encoding,
clipboard and deletion signals are unchanged. Import has its own checkpoint below.

The inspector test covers 60 dialog/window/language combinations, long names,
ratings 0–4 and incomplete progress, campaign access rules, control signal
bindings, copy-code display, delete signaling without persistence, closing,
and resizing during the opening animation. It uses an in-memory save copy.

Visually check campaign locked/uncompleted/completed dialogs, custom names and
copy feedback, all star ratings, Play/Edit transitions and returning to the
menu, dismissing via the backdrop, and live resizing. Test actual deletion only
with a disposable custom level (the automated test never deletes saved data).

## Level-import dialog checkpoint

Import uses the shared bounded dialog panel and local opening animation, with
container-managed name/code fields, Paste and full-width Save. A scroll fallback
keeps content reachable on unusually short windows. Field and icon colors are
explicit; global stretch settings remain unchanged.

Save now decodes the visible code field, fixing typed codes previously ignored
in favor of a stale paste-only variable. Paste still takes the first clipboard
line and passes it through the existing code filter. Invalid-code feedback uses
a dialog-owned timer; editing cancels a pending clear so it cannot erase the
replacement code. Closing frees the timer with the dialog.

The test covers 30 window/language combinations, palette, opening/centering,
name/code filtering, valid-code decoding, Save enablement, invalid-code feedback,
editing during error feedback, signal connections, and closing during an error.
Two decoder warnings for deliberately invalid codes are expected. No successful
Save calls are made, so the test never writes player data.

Visually check typing and pasting a copied level code, entering a name, successful
import/return to the custom list, invalid code feedback, cancel and live resizing.
Phone virtual-keyboard behavior still needs on-device review. Game-mode selection
is the next layout checkpoint before considering global scaling.

## Game-mode selection checkpoint

Mode selection uses the shared bounded panel instead of legacy global scaling.
Cards follow the live scroll-host width with zero inter-card separation, so
scroll offsets match exact card boundaries. Navigation uses theme metrics;
overlay text has a dedicated theme and can scroll if necessary. Setup reuses
cards instead of appending duplicates, and all selection paths update Play and
arrow availability. Repeated navigation replaces its previous snap animation;
resizing cancels that animation and restores the selected card. Existing mode
resources and the saved editor-unlock checkbox are preserved.

The test covers 150 viewport/language/mode combinations, repeated setup, card
alignment, controls, lock explanations, editor bypass, rapid navigation, resize,
and scroll-end snapping. Existing editor-unlock tests separately protect the
campaign/export restrictions. Visually check each card/overlay, arrows/swiping,
Play, backdrop dismissal, and launching each mode.

## Remaining responsiveness audit (before global scaling)

These screens still use legacy sizing; this audit identifies risks rather than
claiming they have all been visually reproduced:

| Screen | Remaining dependency | Suggested checkpoint |
| --- | --- | --- |
| Tutorial | Runtime global font/margin overrides; image/text/button layout needs short-window checks | Tutorial checkpoint across tips/locales |
| Credits | Runtime global margins/fonts | Small credits checkpoint; verify scrolling/dismissal |

`animated_panel.gd` retains legacy global-scale methods, but result dialogs now
override them through the shared responsive panel.
The gameplay renderer retains a legacy no-host scale fallback; migrated gameplay
screens bind their host. These dependencies should be reviewed before removing
the old sizing helpers from `GameManager`. Fixed theme metrics are intentional
logical units, not physical pixel scaling; global canvas/stretch configuration,
phone safe areas, virtual keyboard behavior, and actual device readability/touch
targets remain a separate validation checkpoint. Decorative background effects
also need a visual resize check at that stage.

## Splash and Options checkpoint

Run `godot --headless --path . --script tests/splash_options_layout_test.gd`.

Splash now has a live logo host and a separate version-label region. Logo fitting
uses the animation frame dimensions and a themed maximum width, preserving the
two-part animation, audio, click-to-speed-up behavior, fade, and menu startup.
Options uses a fixed Back header above scrollable settings; wrapping labels and
the original toggle artwork replace viewport-derived fonts and icon dimensions.
Language popup typography and navigation/toggle metrics live in dedicated themes.
Existing save, audio, tutorial, language, Back, and Credits handlers are retained.

The test covers 36 viewport/locale combinations, including narrow portrait and
short landscape, live resize, logo bounds/centering, version clearance, setting
initialization, signal bindings, toggle artwork, language-popup fit, reaching
Credits by scrolling, splash skip/animation completion and main-menu startup.
Persistence handlers are disconnected only in the test before visual toggling;
no saves are written. Global stretch settings remain unchanged.

Visually review startup/skip, resizing during splash, all settings and language
choices, scrolling in landscape, Back, and Credits navigation. Results dialogs,
Tutorial, and Credits remain before global scaling/device validation.

## Level-menu editor reference

`LevelUI.tscn` and `LevelsPage.tscn` now share small `@tool` geometry scripts
with runtime: the page strip positions/sizes its three pages, and the centered
grid follows the available page size. Gameplay/controller scripts remain non-tool;
editor layout never accesses autoloads, player saves, audio, or level actions.
The page scene contains representative numbered/starred/locked buttons, replaced
by actual progression during runtime initialization. Open `LevelUI.tscn` in the
2D editor for a full menu reference, or `LevelsPage.tscn` for the grid alone.
Reopen the scene if Godot has not yet picked up the new tool scripts.

Run the editor-only check separately from runtime tests:
`godot --headless --editor --path . --script tests/level_menu_editor_preview_test.gd`.
It verifies actual editor-hint layout at three window sizes and sample content;
`level_menu_layout_test.gd` continues to cover real progression and paging.

## UI editor-preview pass

Open scenes normally in the 2D editor (reopen existing tabs after script imports).
All 21 UI screen/component scenes are covered by the editor-only smoke test:
`godot --headless --editor --path . --script tests/ui_editor_preview_test.gd`.
It checks 42 portrait/landscape cases without gameplay autoload instances.
Godot's headless editor/custom-main-loop shutdown still reports editor-owned RID
cleanup warnings; layout checks and normal runtime tests are separate.

| Scenes | Editor reference |
| --- | --- |
| MainMenu, LevelUI, LevelsPage | Existing container menu and sample level states |
| LevelInspect, CustomLevelInspect, LevelImport | Shared live bounded panel; existing stars, fields and actions |
| BuilderSave | Editor-aware local panel sizing |
| SplashScreen | Shared logo fitting; final animation frame, no startup/audio |
| Options | Original toggle textures present before runtime initialization |
| PlayModeSelection | Real panel, arrows, Play and empty card host; cards are created at runtime |
| PlayModeUI | Standalone card art |
| GameUI, ArenaUI, BuilderUI, BuilderTest | Real controls and empty BoardHost bounds; select BoardHost to locate the runtime board region |
| BuilderResize, BuilderSelection | Real overlay controls; selection buttons have centered, editable scene defaults |
| LevelEnd, ArenaEnd, TutorialUI, CreditsScreen | Existing serialized content retained; campaign hint fully revealed |

There are no mock boards, preview cards or `EditorReference` components. The
editor shows actual scene nodes with usable defaults. Content generated by game
logic remains absent; select its host Control to inspect its layout bounds.
The level grid retains its existing editable button defaults, populated with
actual progression at runtime. No separate preview content is generated.

Only geometry scripts and the panel base are `@tool`; controllers remain runtime
only. Preview scripts never access saves, play audio, launch levels, or animate
screen transitions. Results, Tutorial and Credits still await their separate
responsive-layout migration; editor visibility does not certify those layouts
for small windows. Global canvas scaling remains unchanged.

## Results-dialog responsiveness checkpoint

Run `godot --headless --path . --script tests/results_layout_test.gd`.

Campaign and arena results now use the shared editor-visible bounded panel with
a scrollable summary and separate always-visible action row. Theme typography,
navigation and primary buttons are independent of global theme mutations.
Campaign stars use expanding container slots with the middle star raised; award
animations scale within those slots, with pivots following live resize. Hint
shader materials are local per scene instance. Existing rating messages, replay,
Next/Exit signals, arena score resources and record persistence are preserved.

Arena record/stats slots reserve space to prevent score jumps during tallying.
The final animated 250-unit spacer is replaced by an action-row fade. Score
tweens are node-bound and cancellation releases suspended calculation when the
dialog is dismissed, without persisting an unfinished tally.

The test covers 72 dialog/viewport/locale combinations, all campaign ratings
including extra-star messaging, final-level Exit, awarded-star animation, live
resize, large scores/multipliers, record-badge layout, score calculation against
the original resources, action signals/connections and mid-tally dismissal.
An in-memory high-score fixture prevents disk writes. Editor checks also verify
both result panels are centered and sized without running gameplay controllers.

Visually review 0–3 stars, hint reveal, Replay and Next/final Exit; arena score
tally/fast-forward, record badge, Restart/Exit; portrait/landscape and resizing
during animation. Tutorial and Credits are the next remaining screen checkpoint.
