randomise()

//menu de depart : aucune partie tant qu'un mode n'est pas choisi
menuActive = true
games = []

BUTTON_W = 280
BUTTON_H = 64
BUTTON_GAP = 24

//bouton de retour, en haut a gauche une fois la partie finie
BACK_X = 24
BACK_Y = 24
BACK_W = 240
BACK_H = 48

//les boutons du menu, empiles et centres
buttons = [
	{ text: "SOLO",		mode: MODE_SOLO },
	{ text: "DUO",		mode: MODE_DUO },
	{ text: "DUO TEST",	mode: MODE_DUO_TEST },
]

var _total = array_length(buttons)*BUTTON_H + (array_length(buttons)-1)*BUTTON_GAP
var _y = (room_height - _total)/2
for(var b = 0; b < array_length(buttons); b++){
	buttons[b].x = (room_width - BUTTON_W)/2
	buttons[b].y = _y + b*(BUTTON_H + BUTTON_GAP)
}

//cree les parties du mode choisi et quitte le menu
function startGame(_mode){
	var _boardW = MAP_LENGTH*TILE_SIZE
	var _gap = 64
	var _y0 = (room_height - MAP_HEIGHT*TILE_SIZE) / 2

	var _arrows = { left: vk_left, right: vk_right, down: vk_down, rotate: vk_up }
	var _wasd = { left: ord("A"), right: ord("D"), down: ord("S"), rotate: ord("W") }

	if _mode == MODE_SOLO {
		games = [ new DrMarioGame((room_width - _boardW)/2, _y0, _arrows) ]
	} else {
		var _x0 = (room_width - (_boardW*2 + _gap)) / 2
		games = [
			new DrMarioGame(_x0, _y0, _arrows),
			new DrMarioGame(_x0 + _boardW + _gap, _y0, _wasd)
		]

		//chaque partie connait l'autre : la fin de l'une termine l'autre
		games[0].opponent = games[1]
		games[1].opponent = games[0]

		//mode test : le 2e plateau ne descend jamais, il ne peut donc pas perdre
		if _mode == MODE_DUO_TEST games[1].autoFall = false
	}

	menuActive = false
}

//true si la souris est dans ce rectangle
function rectHovered(_x, _y, _w, _h){
	return point_in_rectangle(mouse_x, mouse_y, _x, _y, _x + _w, _y + _h)
}

//true si la souris est sur ce bouton du menu
function buttonHovered(_b){
	return rectHovered(_b.x, _b.y, BUTTON_W, BUTTON_H)
}

//true si toutes les parties en cours sont terminees
function gamesFinished(){
	for(var g = 0; g < array_length(games); g++){
		var _s = games[g].state
		if _s != STATE_WIN && _s != STATE_LOSE return false;
	}
	return true
}

//abandonne les parties et revient au menu
function backToMenu(){
	games = []
	menuActive = true
}
