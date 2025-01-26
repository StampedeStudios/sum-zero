class_name GlobalConst

enum AreaEffect { ADD, SUBTRACT, CHANGE_SIGN, BLOCK }
enum AreaBehavior { BY_STEP, FULL }
enum GameState {
	MAIN_MENU,
	OPTION_MENU,
	LEVEL_PICK,
	LEVEL_START,
	LEVEL_END,
	BUILDER_IDLE,
	BUILDER_SELECTION,
	BUILDER_SAVE,
	BUILDER_TEST,
	BUILDER_RESIZE,
	LEVEL_INSPECT,
	LEVEL_IMPORT,
	CUSTOM_LEVEL_INSPECT
}
enum LevelGroup { CUSTOM, MAIN }
enum GenerationElement { HOLE, BLOCK, SLIDER }

# Default sizes
const SCREEN_SIZE_X = 720
const SCREEN_SIZE_Y = 1280
const CELL_SIZE: float = 256
const SLIDER_SIZE: float = 128
const Y_MARGIN_PERCENTAGE: float = 0.05
const X_MARGIN_PERCENTAGE: float = 0.1
const TITLE_FONT_SIZE: int = 60
const SUBTITLE_FONT_SIZE: int = 50
const TEXT_FONT_SIZE: int = 40
const ICON_MAX_WIDTH: int = 64
const BTN_ICON_MAX_WIDTH: int = 128
const BTN_SEPARATION: int = 20

const MIN_LEVEL_SIZE: int = 2
const MAX_LEVEL_SIZE: int = 5

const MIN_CELL_VALUE: int = -4
const MAX_CELL_VALUE: int = 4

const HALF_BUILDER_SELECTION: int = 300

const MAX_STARS_GAIN: int = 3

const THREE_STARS_MSGS: Array[String] = [
	"Star-studded victory!", "Flawless finish!", "You nailed it!"
]
const TWO_STARS_MSGS: Array[String] = [
	"Shining bright!", "Almost perfect!", "So close, yet so bright!"
]
const ONE_STARS_MSGS: Array[String] = ["Barely made it!", "Star power on fumes!", "A win is a win!"]
const NO_STARS_MSGS: Array[String] = [
	"At least you finished!", "A win... kinda.", "Room for improvement!"
]
