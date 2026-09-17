var boardXOffset = room_width/2 - (MAP_LENGTH/2)*TILE_SIZE
var boardYOffset = room_height/2 - (MAP_HEIGHT/2)*TILE_SIZE

//pendant le clignotement, les cases condamnées sont masquées une frame sur deux
var _blinking = (state == STATE_CLEARING) && marks != noone && ((stateTimer div 4) % 2 == 0)


//draw back
for(var i = 0; i < MAP_HEIGHT; i++){
	for(var j = 0; j < MAP_LENGTH; j++){
		draw_sprite(spr_square,0,boardXOffset + j*TILE_SIZE + TILE_SIZE/2,boardYOffset + i*TILE_SIZE + TILE_SIZE/2)
	}
}


//draw_board
for(var i = 0; i < MAP_HEIGHT; i++){
	for(var j = 0; j < MAP_LENGTH; j++){
		var _tile = board[i][j]
		if _tile == EMPTY_TILE continue;
		if _blinking && marks[i][j] continue;
		drawTile(_tile, links[i][j], boardXOffset + j*TILE_SIZE, boardYOffset + i*TILE_SIZE)
	}
}


//draw pilule en vol, par-dessus le plateau
if playingPillA != noone && playingPillB != noone{
	var _linkA = linkBetween(playingPillA.i, playingPillA.j, playingPillB.i, playingPillB.j)
	var _linkB = linkBetween(playingPillB.i, playingPillB.j, playingPillA.i, playingPillA.j)
	drawTile(playingPillA.color, _linkA, boardXOffset + playingPillA.j*TILE_SIZE, boardYOffset + playingPillA.i*TILE_SIZE)
	drawTile(playingPillB.color, _linkB, boardXOffset + playingPillB.j*TILE_SIZE, boardYOffset + playingPillB.i*TILE_SIZE)
}


//message de fin, au dessus du plateau
if state == STATE_WIN || state == STATE_LOSE{
	var _text = (state == STATE_WIN) ? "YOU WIN" : "YOU LOSE"
	draw_set_halign(fa_center)
	draw_set_valign(fa_bottom)
	draw_set_color(c_white)
	draw_text_transformed(boardXOffset + (MAP_LENGTH*TILE_SIZE)/2, boardYOffset - 8, _text, 2, 2, 0)
	draw_set_halign(fa_left)
	draw_set_valign(fa_top)
}
