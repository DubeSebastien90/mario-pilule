TILE_SIZE = 32

MAP_HEIGHT = 16
MAP_LENGTH = 8

EMPTY_TILE = 0
BLUE_PILL = 1


board = clearBoard()

TICK_COOLDOWN = 60
tickCooldown = TICK_COOLDOWN

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
	board[playingPillA.i][playingPillA.j] = playingPillA.color 
	board[playingPillB.i][playingPillB.j] = playingPillB.color 
}

function updateBoard(){
	var _newBoard = clearBoard()
	for(var i = 0; i < MAP_HEIGHT; i++){
		for(var j = 0; j < MAP_LENGTH; j++){
			if i == playingPillA.i && j == playingPillA.j{
				_newBoard[i][j] = playingPillA.color
			}
			if i == playingPillB.i && j == playingPillB.j{
				_newBoard[i][j] = playingPillB.color
			}
		}
	}
	board = _newBoard
}

function movePlayingPill(_i, _j){
	playingPillA.i += _i
	playingPillA.j += _j
	playingPillB.i += _i
	playingPillB.j += _j
}