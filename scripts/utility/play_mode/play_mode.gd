class_name PlayMode extends Resource

enum UnlockMode{ 
	NONE,	## No lock
	LEVEL,	## Unlock when you have completed all the levels up to
	STAR	## Unlock when you have reached the number of stars
	}

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
