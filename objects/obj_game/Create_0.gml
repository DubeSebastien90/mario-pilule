TILE_SIZE = 32

MAP_HEIGHT = 16
MAP_LENGTH = 8

EMPTY_TILE = 0
BLUE_PILL = 1


board = clearBoard()

TICK_COOLDOWN = 60
tickCooldown = TICK_COOLDOWN


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
	board[0][MAP_LENGTH/2] = BLUE_PILL
	board[0][MAP_LENGTH/2 - 1] = BLUE_PILL
}

function simulate(){
	var _newBoard = clearBoard()
	for(var i = 0; i < MAP_HEIGHT; i++){
		for(var j = 0; j < MAP_LENGTH; j++){
			var _tile = board[i][j]
			if _tile = BLUE_PILL{
				_newBoard[i][j] = EMPTY_TILE
				_newBoard[i+1][j] = BLUE_PILL
			}
		}
	}
	board = _newBoard
}