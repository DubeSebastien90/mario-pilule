randomise()

//menu
flo_angle = 0
temps = 0

//menu de depart : aucune partie tant qu'un mode n'est pas choisi
menuActive = true
games = []

//codes secrets : trois fois 67 melange le plateau aux fleches, trois fois 69
//celui au WASD. les deux parties visees sont retenues au lancement de la partie
gameArrows = noone
gameWasd = noone
secretCodes = [
	{ keys: [6,7,6,7,6,7], who: "arrows", step: 0 },
	{ keys: [6,9,6,9,6,9], who: "wasd",   step: 0 },
]

//photo a reconstituer, a droite des plateaux
photo = noone
PHOTO_ZOOM = 1.3			//taille de la photo par rapport a un plateau

BUTTON_W = 280
BUTTON_H = 64
BUTTON_GAP = 24

//bouton de retour, centre sur le plateau de droite une fois la partie finie
//(le seul en solo, celui du milieu en duo). Recalcule dans startGame.
BACK_W = 240
BACK_H = 48
BACK_X = (room_width - BACK_W)/2
BACK_Y = (room_height - BACK_H)/2

//bouton pour quitter la partie a tout moment, pose au dessus de la photo,
//aligne sur son bord droit. Recalcule dans startGame.
QUIT_W = 140
QUIT_H = 40
QUIT_GAP = 12
QUIT_X = room_width - QUIT_W
QUIT_Y = 0

//les boutons du menu, empiles et centres
buttons = [
	{ text: "SOLO",		mode: MODE_SOLO },
	{ text: "DUO",		mode: MODE_DUO },
	//{ text: "DUO TEST",	mode: MODE_DUO_TEST },
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
	var _sw = sprite_get_width(spr_photo2)
	var _sh = sprite_get_height(spr_photo2)

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

	//aucun code n'est en cours au depart
	for(var c = 0; c < array_length(secretCodes); c++){
		secretCodes[c].step = 0
	}

	if _mode == MODE_SOLO {
		//deux colonnes : plateau puis photo, 12 morceaux pour 12 virus
		var _x0 = (room_width - (_boardW + _gap + _photoW)) / 2
		games = [ new DrMarioGame(_x0, _y0, _arrows) ]

		setupPhoto(_x0 + _boardW + _gap, _photoY, _photoW, _photoH, 2, 6)
		games[0].photo = photo
		games[0].pieceIds = photo.shuffledIds()

		//le seul joueur est aux fleches : le code WASD ne vise personne
		gameArrows = games[0]
		gameWasd = noone
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

		gameWasd = games[0]
		gameArrows = games[1]

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

	//le bouton de retour se centre sur le dernier plateau cree :
	//le seul en solo, celui du milieu en duo
	var _last = games[array_length(games)-1]
	BACK_X = _last.boardX + (_boardW - BACK_W)/2
	BACK_Y = _last.boardY + (_boardH - BACK_H)/2

	//le bouton quitter se pose juste au dessus du coin haut droit de la photo
	QUIT_X = photo.px + photo.pw - QUIT_W
	QUIT_Y = photo.py - QUIT_GAP - QUIT_H

	menuActive = false
}

//le chiffre tape cette frame, -1 si aucun. pave numerique compris
function digitPressed(){
	for(var d = 0; d <= 9; d++){
		if keyboard_check_pressed(ord(string(d))) return d;
		if keyboard_check_pressed(vk_numpad0 + d) return d;
	}
	return -1
}

//suit les codes secrets chiffre par chiffre, et melange le plateau vise
//quand l'un d'eux est tape en entier. un chiffre faux remet le code a zero,
//sauf s'il est lui-meme un debut de code
function checkSecretCodes(){
	var _digit = digitPressed()
	if _digit < 0 exit;

	for(var c = 0; c < array_length(secretCodes); c++){
		var _code = secretCodes[c]

		if _digit == _code.keys[_code.step] {
			_code.step += 1
			if _code.step < array_length(_code.keys) continue;

			_code.step = 0
			var _target = (_code.who == "wasd") ? gameWasd : gameArrows
			if _target != noone _target.shuffleBoard()
		} else {
			_code.step = (_digit == _code.keys[0]) ? 1 : 0
		}
	}
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

//true si toutes les parties en cours sont terminees, souffle retombe
function gamesFinished(){
	for(var g = 0; g < array_length(games); g++){
		var _s = games[g].state
		if _s != STATE_WIN && _s != STATE_LOSE return false;
		if games[g].isBlasting() return false;		//l'explosion a le dernier mot
	}
	return true
}

//abandonne les parties et revient au menu
function backToMenu(){
	games = []
	gameArrows = noone
	gameWasd = noone
	menuActive = true
}
