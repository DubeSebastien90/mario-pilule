randomise()

//menu de depart : aucune partie tant qu'un mode n'est pas choisi
menuActive = true
games = []

//photo a reconstituer, a droite des plateaux
photo = noone
PHOTO_ZOOM = 1.3			//taille de la photo par rapport a un plateau

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

//cree le panneau photo, mis a l'echelle pour tenir dans l'emplacement
//sans qu'aucun cote ne depasse, et centre dedans
function setupPhoto(_slotX, _slotY, _slotW, _slotH, _cols, _rows){
	var _sw = sprite_get_width(spr_photo)
	var _sh = sprite_get_height(spr_photo)

	//le plus petit des deux rapports : aucun cote ne depasse, proportions gardees
	var _scale = min(_slotW / _sw, _slotH / _sh)
	var _w = _sw * _scale
	var _h = _sh * _scale

	photo = new PhotoBoard(_slotX + (_slotW - _w)/2, _slotY + (_slotH - _h)/2, _w, _h, _cols, _rows)
}

//cree les parties du mode choisi et quitte le menu
function startGame(_mode){
	var _boardW = MAP_LENGTH*TILE_SIZE
	var _boardH = MAP_HEIGHT*TILE_SIZE
	var _gap = 64
	var _y0 = (room_height - _boardH) / 2

	//la photo occupe son propre emplacement, plus grand qu'un plateau
	var _photoW = _boardW * PHOTO_ZOOM
	var _photoH = _boardH * PHOTO_ZOOM
	var _photoY = (room_height - _photoH) / 2

	var _arrows = { left: vk_left, right: vk_right, down: vk_down, rotate: vk_up }
	var _wasd = { left: ord("A"), right: ord("D"), down: ord("S"), rotate: ord("W") }

	photo = noone

	if _mode == MODE_SOLO {
		//deux colonnes : plateau puis photo, 12 morceaux pour 12 virus
		var _x0 = (room_width - (_boardW + _gap + _photoW)) / 2
		games = [ new DrMarioGame(_x0, _y0, _arrows) ]

		setupPhoto(_x0 + _boardW + _gap, _photoY, _photoW, _photoH, 2, 6)
		games[0].photo = photo
		games[0].pieceIds = photo.shuffledIds()
	} else {
		//trois colonnes : deux plateaux, puis la photo plus large
		var _x0 = (room_width - (_boardW*2 + _gap*2 + _photoW)) / 2
		games = [
			new DrMarioGame(_x0, _y0, _wasd),
			new DrMarioGame(_x0 + _boardW + _gap, _y0, _arrows)
		]

		//chaque partie connait l'autre : la fin de l'une termine l'autre
		games[0].opponent = games[1]
		games[1].opponent = games[0]

		//mode test : le plateau WASD ne descend jamais, il ne peut donc pas perdre
		if _mode == MODE_DUO_TEST games[0].autoFall = false

		//une seule photo pour les deux : 24 morceaux, 12 chacun, tires au hasard
		setupPhoto(_x0 + (_boardW + _gap)*2, _photoY, _photoW, _photoH, 4, 6)
		games[0].photo = photo
		games[1].photo = photo

		//la liste melangee est coupee en deux : les deux moities sont donc disjointes
		var _ids = photo.shuffledIds()
		var _idsA = []
		var _idsB = []
		for(var n = 0; n < NB_INITIAL_VIRUS; n++){
			array_push(_idsA, _ids[n])
			array_push(_idsB, _ids[NB_INITIAL_VIRUS + n])
		}
		games[0].pieceIds = _idsA
		games[1].pieceIds = _idsB
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

//true si toutes les parties attendent encore le depart
function gamesWaiting(){
	if array_length(games) == 0 return false;
	for(var g = 0; g < array_length(games); g++){
		if games[g].state != STATE_READY return false;
	}
	return true
}

//lance toutes les parties d'un coup, quand chacun s'est declare pret
function startWhenAllReady(){
	if !gamesWaiting() exit;

	for(var g = 0; g < array_length(games); g++){
		if !games[g].ready exit;
	}
	for(var g = 0; g < array_length(games); g++){
		games[g].startPlaying()
	}
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
