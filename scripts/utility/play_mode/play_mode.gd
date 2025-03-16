class_name PlayMode extends Resource

enum UnlockMode { NONE, LEVEL, STAR }

## Title show on selection menu
@export var title: String
## Icon show on selection menu
@export var icon: Texture2D
## Tutorial show before start play
@export var tutorial: TutorialData
## Unlock mode type
@export var unlock_mode: UnlockMode
## Counter referred to unlock mode
@export var unlock_count: int
