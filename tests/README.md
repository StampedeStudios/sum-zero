# UI layout checks

Import the project once, then run the main-menu checks:

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/main_menu_layout_test.gd
godot --headless --path . --script tests/gameplay_layout_test.gd
godot --headless --path . --script tests/arena_layout_test.gd
godot --headless --path . --script tests/editor_arena_unlock_test.gd
godot --headless --path . --script tests/builder_playtest_layout_test.gd
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
