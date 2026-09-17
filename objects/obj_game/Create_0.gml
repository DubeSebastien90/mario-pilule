randomise()

//menu de depart : aucune partie tant qu'un mode n'est pas choisi
menuActive = true
games = []

//photo affichee a droite des plateaux, en duo seulement
showPhoto = false
photoX = 0
photoY = 0
photoScale = 1

BUTTON_W = 280
BUTTON_H = 64
BUTTON_GAP = 24

//bouton de retour, au centre de l'ecran une fois la partie finie
BACK_W = 240
BACK_H = 48
BACK_X = (room_width - BACK_W)/2
BACK_Y = (room_height - BACK_H)/2

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

//met la photo a l'echelle pour tenir dans un emplacement large comme un plateau
//sans qu'aucun cote ne depasse, et la centre dedans
function setupPhoto(_slotX, _slotY, _slotW, _slotH){
	var _sw = sprite_get_width(spr_photo)
	var _sh = sprite_get_height(spr_photo)

	//le plus petit des deux rapports : aucun cote ne depasse, proportions gardees
	photoScale = min(_slotW / _sw, _slotH / _sh)

	//l'origine du sprite peut etre n'importe ou, on la compense
	photoX = _slotX + (_slotW - _sw*photoScale)/2 + sprite_get_xoffset(spr_photo)*photoScale
	photoY = _slotY + (_slotH - _sh*photoScale)/2 + sprite_get_yoffset(spr_photo)*photoScale

	showPhoto = true
}

//cree les parties du mode choisi et quitte le menu
function startGame(_mode){
	var _boardW = MAP_LENGTH*TILE_SIZE
	var _boardH = MAP_HEIGHT*TILE_SIZE
	var _gap = 64
	var _y0 = (room_height - _boardH) / 2

	var _arrows = { left: vk_left, right: vk_right, down: vk_down, rotate: vk_up }
	var _wasd = { left: ord("A"), right: ord("D"), down: ord("S"), rotate: ord("W") }

	showPhoto = false

	if _mode == MODE_SOLO {
		games = [ new DrMarioGame((room_width - _boardW)/2, _y0, _arrows) ]
	} else {
		//trois colonnes de meme largeur : plateau, plateau, photo
		var _x0 = (room_width - (_boardW*3 + _gap*2)) / 2
		games = [
			new DrMarioGame(_x0, _y0, _wasd),
			new DrMarioGame(_x0 + _boardW + _gap, _y0, _arrows)
		]

		//chaque partie connait l'autre : la fin de l'une termine l'autre
		games[0].opponent = games[1]
		games[1].opponent = games[0]

		//mode test : le plateau WASD ne descend jamais, il ne peut donc pas perdre
		if _mode == MODE_DUO_TEST games[0].autoFall = false

		setupPhoto(_x0 + (_boardW + _gap)*2, _y0, _boardW, _boardH)
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
