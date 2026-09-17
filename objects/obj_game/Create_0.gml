TILE_SIZE = 32

MAP_HEIGHT = 16
MAP_LENGTH = 8

EMPTY_TILE = 0
BLUE_PILL = 1


board = clearBoard()

TICK_COOLDOWN = 10
tickCooldown = TICK_COOLDOWN

NEW_PILL_COOLDOWN = 30
newPillCooldown = NEW_PILL_COOLDOWN

function Pill(_i, _j, _c) constructor {
    i = _i;
    j = _j;
	color = _c
}

playingPillA = noone
playingPillB = noone


spawnPill()

function clearBoard(){
	var _board = noone
	for(var i = 0; i < MAP_HEIGHT; i++){
		for(var j = 0; j < MAP_LENGTH; j++){
			_board[i][j] = EMPTY_TILE
		}
	}
	return _board
}

function spawnPill(){
	playingPillA = new Pill(0,(MAP_LENGTH/2)-1,BLUE_PILL)
	playingPillB = new Pill(0,MAP_LENGTH/2,BLUE_PILL)
	tickCooldown = TICK_COOLDOWN
}

function dropPillOnBoard(){
	board[playingPillA.i][playingPillA.j] = playingPillA.color
	board[playingPillB.i][playingPillB.j] = playingPillB.color
	playingPillA = noone
	playingPillB = noone
}

function movePlayingPill(_i, _j){
	if playingPillA != noone && playingPillB != noone{
		if playingPillA.i + _i >= MAP_HEIGHT || playingPillB.i + _i >= MAP_HEIGHT{
			dropPillOnBoard()
			exit
		}
		playingPillA.i += _i
		playingPillA.j += _j
		playingPillB.i += _i
		playingPillB.j += _j
	}
}