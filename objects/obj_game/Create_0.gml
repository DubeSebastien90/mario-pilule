randomise()

//deux plateaux cote a cote, centres dans la room
var _boardW = MAP_LENGTH*TILE_SIZE
var _gap = 64
var _x0 = (room_width - (_boardW*2 + _gap)) / 2
var _y0 = (room_height - MAP_HEIGHT*TILE_SIZE) / 2

games = [
	new DrMarioGame(_x0, _y0,
		{ left: vk_left, right: vk_right, down: vk_down, rotate: vk_up }),

	new DrMarioGame(_x0 + _boardW + _gap, _y0,
		{ left: ord("A"), right: ord("D"), down: ord("S"), rotate: ord("W") })
]

//chaque partie connait l'autre : la fin de l'une termine l'autre
games[0].opponent = games[1]
games[1].opponent = games[0]
