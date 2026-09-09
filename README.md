# Malatang

Malatang is a 2D cooperative restaurant action game built with Godot 4.7.2 and GDScript.

The visual direction is a fixed diagonal-down 2D view inspired by *Feed the Cups*. Maps remain horizontal and vertical, and `Camera2D` does not rotate. The sense of depth will come from sprites that show both top and front surfaces, not from 3D models, camera transforms, skew, or an isometric diamond grid.

Players move freely rather than on a grid. The long-term target is 1–4 players with both local and online play, but multiplayer is not implemented in the current foundation.

All player-visible text must use localization data. This rebuild does not reuse code from the previous desktop idle-game prototype.
