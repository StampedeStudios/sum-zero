class_name PlayMode extends Resource

## Title show on selection menu
@export var title: String
## Icon show on selection menu
@export var icon: Texture2D
## Tutorial show before start play
@export var tutorial: TutorialData
## Level that allows unlocking (-1 to ignore)
@export var unlock_level_id: int = -1
