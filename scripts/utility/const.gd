class_name GlobalConst

enum AreaEffect { ADD, SUBTRACT, CHANGE_SIGN, BLOCK }
enum AreaBehavior { BY_STEP, FULL }
enum GameState {
	MAIN_MENU,
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
	TUTORIAL_ZERO
}
enum LevelGroup { CUSTOM, MAIN }
enum GenerationElement { HOLE, BLOCK, SLIDER }

# Default sizes
const SCREEN_SIZE_X: int = 720
const SCREEN_SIZE_Y: int = 1280
const CELL_SIZE: int = 256
const SLIDER_SIZE: int = 128
const Y_MARGIN_PERCENTAGE: float = 0.05
const X_MARGIN_PERCENTAGE: float = 0.1
const TITLE_FONT_SIZE: int = 60
const SUBTITLE_FONT_SIZE: int = 50
const TEXT_FONT_SIZE: int = 48
const SMALL_TEXT_FONT_SIZE: int = 36
const SMALL_ICON_MAX_WIDTH: int = 32
const ICON_MAX_WIDTH: int = 64
const BTN_ICON_MAX_WIDTH: int = 128
const BTN_SEPARATION: int = 20

const MIN_LEVEL_SIZE: int = 2
const MAX_LEVEL_SIZE: int = 5

const MIN_CELL_VALUE: int = -4
const MAX_CELL_VALUE: int = 4

const HALF_BUILDER_SELECTION: int = 300

const MAX_STARS_GAIN: int = 3

const EXTRA_STARS_MSGS: Array[String] = ["EXTRA_STAR_MSG_1", "EXTRA_STAR_MSG_2", "EXTRA_STAR_MSG_3"]
const THREE_STARS_MSGS: Array[String] = ["THREE_STAR_MSG_1", "THREE_STAR_MSG_2", "THREE_STAR_MSG_3"]
const TWO_STARS_MSGS: Array[String] = ["TWO_STAR_MSG_1", "TWO_STAR_MSG_2", "TWO_STAR_MSG_3"]
const ONE_STARS_MSGS: Array[String] = ["ONE_STAR_MSG_1", "ONE_STAR_MSG_2", "ONE_STAR_MSG_3"]
const NO_STARS_MSGS: Array[String] = ["ZERO_STAR_MSG_1", "ZERO_STAR_MSG_2", "ZERO_STAR_MSG_3"]

const AVAILABLE_LANGS: Array[String] = ["en", "fr", "it", "es", "de"]
