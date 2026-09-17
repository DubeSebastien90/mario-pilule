var boardXOffset = room_width/2 - (MAP_LENGTH/2)*TILE_SIZE
var boardYOffset = room_height/2 - (MAP_HEIGHT/2)*TILE_SIZE


//draw back
for(var i = 0; i < MAP_HEIGHT; i++){
	for(var j = 0; j < MAP_LENGTH; j++){
		draw_sprite(spr_square,0,boardXOffset + j*TILE_SIZE,boardYOffset + i*TILE_SIZE)
	}
}


//draw_board
for(var i = 0; i < MAP_HEIGHT; i++){
	for(var j = 0; j < MAP_LENGTH; j++){
		var _tile = board[i][j]
		if _tile != 0{
			draw_sprite(spr_square,_tile,boardXOffset + j*TILE_SIZE,boardYOffset + i*TILE_SIZE)
		}
	}
}