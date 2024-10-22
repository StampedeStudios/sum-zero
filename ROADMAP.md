# Roadmap
This document represent a sharable roadmap that contains all main activities and goals of the game.

## Activities

- [x] Android Build;
- [x] Clear with design choise from where a specific slider come when watching a tile;
- [x] Handle sliders with outline instead of a tint, to improve readability;
- [x] Remove highlight effect on slider since on mobile has no functionality;
- [x] Make sliders grabbable only by the moving side;
- [x] Make UI and grid variable as screen size;
- [x] Remove how-to-play section from in-game mode, and remove timer;
- [x] Add number of moves left (The number of left moves when the level is finished indicates the number of stars that the player gets);
- [x] Main mechanics:
	- Add 1 (+);
	- Remove 1 (-);
	- Change tile sign (/);
	- Obstacles: tiles that stops sliders but are never meant to be altered as the value is already 0;
	- Quick sliders: sliders that cannot be manually resized to a specific length but are always fully extended or not;
	- Movable obstacles as sliders: sliders that make tiles blocked while setting their value to 0;
- [x] Persistent data saving;
- [x] Skip level;
- [x] Main menu;
- [x] Sandbox with sharable custom levels;
	- [x] Level resizing;
	- [x] Tile setup;
	- [x] Basic slider setup;
	- [x] Quick slider setup;
	- [x] On the fly play mode;
	- [x] Level data persistence;
	- [x] Level reset;
	- [x] Player levels saving;
	- [ ] QRCode generation for local share;
- [x] UI elements
	- Texture blocked tile;
	- Resize icon;
	- Level menu;
- [x] Level select menu;
	- Deletion;
	- Load in editor;
- [ ] Tutorial;
- [-] SFX;
- [-] Graphic effects;

## Level design
Having four main mechanics, following the truth table to estimate the number of levels for each mechanic combiation considering that there are more seconday mechanics that can help to break the monotony. 

Secondary mechanics are:

- Quick slider: some slider can be block the player to set a specific length as they are always fully extended. This mechanic creates a fun experience when combined with block sliders;
- Blocked/absent tiles: some tiles can be missing to complicate farther more the level design and, with it, the solution;
- Levels can have size from 2x2 up to 5x5: this can be used to complicate and differentiate even more levels that make use of the same set of main mechanics.

| INDEX |  ADD  | REMOVE | INVERT | BLOCK | # Levels |
|-------|-------|--------|--------|-------|----------|
|  01   | false | false  | false  | true  |     1    |
|  02   | false | false  | true   | false |     -    |
|  03   | false | false  | true   | true  |     -    |
|  04   | false | true   | false  | false |     3    |
|  05   | false | true   | false  | true  |     2    |
|  06   | false | true   | true   | false |     2    |
|  07   | false | true   | true   | true  |     3    |
|  08   | true  | false  | false  | false |     1    |
|  09   | true  | false  | false  | true  |     1    |
|  10   | true  | false  | true   | false |     1    |
|  11   | true  | false  | true   | true  |     3    |
|  12   | true  | true   | false  | false |     2    |
|  13   | true  | true   | false  | true  |     2    |
|  14   | true  | true   | true   | false |     3    |
|  15   | true  | true   | true   | true  |     5    |
| TOTAL | ----- | ------ | ------ | ----- |     29   |

