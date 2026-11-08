# Checks

Requires Godot 4.6 and `gdlint` (from gdtoolkit):

```sh
uv tool install gdtoolkit==4.5.0
bash tests/run.sh
```

The runner imports the project, lints scripts, and runs the headless checks.
Set `GODOT=/path/to/godot` to use a different executable.

Run an individual check or lint only:

```sh
godot --headless --path . --script tests/gameplay_layout_test.gd
godot --headless --editor --path . --script tests/ui_editor_preview_test.gd
gdlint scripts tests
```

Coverage includes responsive screens and translations, board/slider input,
builder workflows, dialog actions, scoring, tutorial/credits scrolling,
shared themes/touch bounds, editor previews, and physical canvas scaling.
Runtime fixtures avoid writing player saves. Layout checks use logical sizes;
`canvas_scaling_test.gd` keeps the real project stretch settings enabled.

Application debug logs are off by default; use `SUM_ZERO_DEBUG=1 bash tests/run.sh`
to enable them. Warnings and errors remain visible. Invalid imports are normal
validation failures, not warnings.

Godot 4.6.3's `--editor --script` custom SceneTree shutdown reports engine resource
leaks even in an empty project; check the test's failure summary and exit code.
These checks do not replace visual review or phone testing for safe areas,
keyboards, artwork quality, and physical touch comfort.
