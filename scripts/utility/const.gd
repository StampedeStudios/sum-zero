## Enums and common constants.
class_name Constants

## All existing game states.
## Transitions are handled by the game_manager and a signal can be emitted by nodes
## when another scene needs to be loaded. Each component that requires this feature
## can connect to the signal at ready-time and handles state changes according to themselves.
enum GameState {
	MAIN_MENU,
	OPTIONS_MENU,
	LEVEL_PICK,
	LEVEL_START,
	PLAY_LEVEL,
	LEVEL_END,
	BUILDER_IDLE,
	BUILDER_SELECTION,
	BUILDER_SAVE,
	BUILDER_TEST,
	BUILDER_RESIZE,
	LEVEL_INSPECT,
	LEVEL_IMPORT,
	CUSTOM_LEVEL_INSPECT,
	ARENA_MODE,
	ARENA_END,
	TUTORIAL_ZERO,
	MODE_SELECTION
}
enum LevelGroup { CUSTOM, MAIN }
enum GenerationElement { HOLE, BLOCK, SLIDER }

const MIN_LEVEL_SIZE: int = 2
const MAX_LEVEL_SIZE: int = 5
const MIN_CELL_VALUE: int = -4
const MAX_CELL_VALUE: int = 4
const MAX_STARS_GAIN: int = 3

## Currently available languages are listed here and are used to fill language selection menu.
const AVAILABLE_LANGS: Array[String] = ["en", "fr", "it", "es", "de", "pl"]


class Sliders:
	enum Effect { ADD, SUBTRACT, CHANGE_SIGN, BLOCK }
	enum Behavior { BY_STEP, FULL }


# Native board artwork dimensions, independent of UI theme metrics.
class Sizes:
	const CELL_SIZE: int = 256
	const SLIDER_SIZE: int = 128
