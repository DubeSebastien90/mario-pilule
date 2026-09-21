//=============================================================
// Couleurs. GML lit les litteraux hexa en BGR, donc on passe par
// make_colour_rgb : les valeurs restent lisibles en #RRGGBB.
//=============================================================

#macro BG_COLOR make_colour_rgb(0, 101, 84)				//#006554 fond d'ecran
#macro PANEL_COLOR make_colour_rgb(30, 64, 68)			//#1E4044 fond des boutons et de la photo
#macro BUTTON_TEXT_COLOR c_white
#macro BUTTON_TEXT_HL_COLOR make_colour_rgb(157, 230, 78)	//#9DE64E texte au survol
#macro BUTTON_BORDER_COLOR c_ltgray
#macro BUTTON_BORDER_HL_COLOR c_white


//=============================================================
// Constantes partagées par toutes les parties
//=============================================================

#macro TILE_SIZE 32
#macro MAP_HEIGHT 16
#macro MAP_LENGTH 8
#macro NB_INITIAL_VIRUS 12		//autant que de morceaux de photo a debloquer
#macro MAX_SETUP_TRIES 100		//essais avant d'accepter un plateau de depart imparfait

//vol d'un morceau de photo, du virus casse vers sa place sur le panneau
#macro FLY_DURATION 45			//en frames
#macro FLY_ARC 0.30				//hauteur de la courbe, en fraction de la distance
#macro FLY_SPIN 35				//rotation max au milieu du vol, en degres
#macro FLY_ALPHA_START 0.4		//meme opacite que la vignette sur le virus

//explosion de defaite : le plateau du perdant est souffle vers la photo
#macro BLAST_DURATION 100		//duree totale de l'effet, en frames
#macro BLAST_FLASH 14			//flash blanc du premier instant
#macro BLAST_SHAKE 30			//amplitude de la secousse de camera
#macro BLAST_SHAKE_LEN 45		//duree de la secousse, en frames
#macro BLAST_RINGS 5			//anneaux de choc, tires en rafale
#macro BLAST_SPARKS 120			//debris projetes du centre
#macro BLAST_SPARK_GRAVITY 0.35

//file d'attente des pilules, a droite du plateau
#macro PREVIEW_COUNT 3			//pilules montrees d'avance
#macro PREVIEW_SCALE 0.7		//taille d'une moitie, par rapport a une case
#macro PREVIEW_GAP 10			//espace entre le bord du plateau et la file
#macro PREVIEW_TOP 16			//hauteur de la premiere place, sous le haut du plateau
#macro PREVIEW_STEP 40			//ecart vertical entre deux places
#macro PREVIEW_ANIM 14			//frames de la montee, quand une pilule part

//melange secret : chaque tuile rejoint une autre case du meme plateau
#macro SHUFFLE_FLY_DURATION 40
#macro SHUFFLE_FLY_ARC 0.45		//arc plus haut : les trajets sont courts
#macro SHUFFLE_FLY_SPIN 200
#macro SHUFFLE_STAGGER 14		//retard maximal au depart, pour que ca parte en desordre

//vol d'une tuile soufflee, du plateau vers la photo qui l'avale
#macro TILE_FLY_DURATION 50
#macro TILE_FLY_ARC 0.35
#macro TILE_FLY_SPIN 240
#macro TILE_FLY_WAVE 3.0		//frames de retard par case d'eloignement du centre

#macro EMPTY_TILE 0
#macro BLUE_PILL 1
#macro RED_PILL 2
#macro YELLOW_PILL 3
#macro BLUE_VIRUS 4
#macro RED_VIRUS 5
#macro YELLOW_VIRUS 6

//lien d'une case vers l'autre moitié de sa pilule
#macro LINK_NONE 0
#macro LINK_LEFT 1
#macro LINK_RIGHT 2
#macro LINK_UP 3
#macro LINK_DOWN 4

//phases de jeu
#macro STATE_CONTROL 0		//le joueur dirige la pilule
#macro STATE_CLEARING 1		//les tuiles condamnées clignotent avant de disparaître
#macro STATE_FALLING 2		//ce qui n'est plus soutenu descend d'une rangée par tic
#macro STATE_SPAWN 3		//petit délai avant la pilule suivante
#macro STATE_WIN 4			//plus aucun virus
#macro STATE_LOSE 5			//la pilule ne peut plus apparaître
#macro STATE_READY 6		//choix de la difficulte, avant le depart

//modes de partie, choisis dans le menu
#macro MODE_SOLO 0
#macro MODE_DUO 1
#macro MODE_DUO_TEST 2		//le 2e plateau ne descend jamais, pour tester la victoire

//difficulte : chaque niveau retire 2 frames au tick de la pilule
#macro MIN_DIFFICULTY 1
#macro MAX_DIFFICULTY 10
#macro BASE_DIFFICULTY 3		//celle qui correspond a TICK_COOLDOWN tel quel
#macro DIFFICULTY_STEP 2

#macro TICK_COOLDOWN 30			//descente de la pilule dirigée a BASE_DIFFICULTY
#macro GRAVITY_TICK_COOLDOWN 10	//chute des cascades, plus rapide que la pilule
#macro CLEAR_COOLDOWN 30	//durée du clignotement
#macro NEW_PILL_COOLDOWN 30
#macro DOWN_COOLDOWN_FIRST 20
#macro DOWN_COOLDOWN_FAST 5


//=============================================================
// Helpers sans état, partagés
//=============================================================

function Pill(_i, _j, _c) constructor {
	i = _i;
	j = _j;
	color = _c
}

//couleur d'une case : un virus compte comme la pilule de meme couleur
function tileColor(_tile){
	return (_tile > YELLOW_PILL) ? _tile - YELLOW_PILL : _tile
}

//lien qui pointe de (_fi,_fj) vers (_ti,_tj), deux cases forcement adjacentes
function linkBetween(_fi, _fj, _ti, _tj){
	if _tj > _fj return LINK_RIGHT;
	if _tj < _fj return LINK_LEFT;
	if _ti > _fi return LINK_DOWN;
	return LINK_UP;
}

//angle du sprite : la frame de base a son bord plat vers la droite
function linkAngle(_link){
	switch(_link){
		case LINK_RIGHT:	return 0;
		case LINK_UP:		return 90;
		case LINK_LEFT:		return 180;
		case LINK_DOWN:		return 270;
	}
	return 0;
}

//dessine une tuile autour de (_cx,_cy), libre d'etre tournee, mise a l'echelle
//et rendue transparente : c'est ce qui sert aux tuiles soufflees vers la photo
function drawTileExt(_tile, _link, _cx, _cy, _scale, _spin, _alpha){
	var _frame = _tile
	var _angle = 0
	if _tile > YELLOW_PILL {
		//virus : jamais tourné
	} else if _link == LINK_NONE {
		_frame = _tile + 6				//moitié orpheline, ronde des deux côtés
	} else {
		_angle = linkAngle(_link)		//moitié liée, bord plat vers le partenaire
	}
	draw_sprite_ext(spr_square, _frame, _cx, _cy, _scale, _scale, _angle + _spin, c_white, _alpha)
}

//dessine une tuile posee dans sa case, _x et _y étant le coin haut-gauche
function drawTile(_tile, _link, _x, _y){
	drawTileExt(_tile, _link, _x + TILE_SIZE/2, _y + TILE_SIZE/2, 1, 0, 1)
}

//secoue la camera, si la room en contient une
function screenShake(_magnitude, _frames){
	if !instance_exists(obj_camera) exit;
	with(obj_camera){
		//une secousse deja plus forte n'est jamais affaiblie par une nouvelle
		shake_magnitude = max(shake_magnitude, _magnitude)
		shake_remain = max(shake_remain, _magnitude)
		shake_lenght = max(shake_lenght, _frames)
	}
}


//=============================================================
// La photo a reconstituer, decoupee en _cols x _rows morceaux.
// Sa grille n'a aucun rapport avec celle du plateau : le lien passe
// uniquement par le morceau attribue a chaque virus.
// _x/_y/_w/_h : le rectangle ou la photo s'affiche, coin haut-gauche.
//=============================================================

function PhotoBoard(_x, _y, _w, _h, _cols, _rows) constructor {

	px = _x
	py = _y
	pw = _w
	ph = _h
	cols = _cols
	rows = _rows

	revealed = array_create(cols*rows, false)
	flying = []						//morceaux en cours de vol vers leur place
	flyingTiles = []				//tuiles soufflees d'un plateau, avalees par la photo

	//taille d'un morceau, dans le sprite source et a l'ecran
	srcW = sprite_get_width(spr_photo2) / cols
	srcH = sprite_get_height(spr_photo2) / rows
	pieceW = pw / cols
	pieceH = ph / rows

	static reveal = function(_n){
		if _n < 0 || _n >= array_length(revealed) exit;
		revealed[_n] = true
	}

	//coin haut-gauche de la place d'un morceau sur le panneau
	static pieceX = function(_n){ return px + (_n mod cols)*pieceW }
	static pieceY = function(_n){ return py + (_n div cols)*pieceH }

	//lance le morceau _n depuis la case qui le retenait, vers sa place
	//_x/_y : coin haut-gauche de la case, _size : sa taille a l'ecran
	static flyPiece = function(_n, _x, _y, _size){
		if _n < 0 || _n >= cols*rows exit;

		var _fromX = _x + _size/2
		var _fromY = _y + _size/2
		var _toX = pieceX(_n) + pieceW/2
		var _toY = pieceY(_n) + pieceH/2

		//point de controle de la courbe : au dessus du milieu du trajet
		var _dist = point_distance(_fromX, _fromY, _toX, _toY)

		array_push(flying, {
			piece: _n,
			fromX: _fromX,	fromY: _fromY,
			toX: _toX,		toY: _toY,
			ctrlX: (_fromX + _toX)/2,
			ctrlY: (_fromY + _toY)/2 - _dist*FLY_ARC,
			fromSize: _size,
			spin: random_range(-FLY_SPIN, FLY_SPIN),
			timer: FLY_DURATION
		})
	}

	//une tuile arrachee a un plateau. une simple moitie de pilule se dissout
	//quelque part dans la photo ; un virus, lui, est bel et bien detruit, donc il
	//rejoint sa place et libere son morceau comme n'importe quel virus casse.
	//_delay : frames d'attente avant le depart, le temps que l'onde l'atteigne
	static flyTile = function(_tile, _link, _x, _y, _size, _piece, _delay){
		var _fromX = _x + _size/2
		var _fromY = _y + _size/2

		//un virus emporte un morceau : il vise sa case sur le panneau
		var _reveals = (_piece >= 0)
		var _toX, _toY;
		if _reveals {
			_toX = pieceX(_piece) + pieceW/2
			_toY = pieceY(_piece) + pieceH/2
		} else {
			//point de chute disperse dans la photo : le flux s'evase au lieu d'un trait
			_toX = px + pw/2 + random_range(-pw*0.32, pw*0.32)
			_toY = py + ph/2 + random_range(-ph*0.32, ph*0.32)
		}

		var _dist = point_distance(_fromX, _fromY, _toX, _toY)

		array_push(flyingTiles, {
			tile: _tile,	link: _link,	piece: _piece,	reveals: _reveals,
			fromX: _fromX,	fromY: _fromY,
			toX: _toX,		toY: _toY,
			ctrlX: (_fromX + _toX)/2 + random_range(-_dist*0.18, _dist*0.18),
			ctrlY: (_fromY + _toY)/2 - _dist*TILE_FLY_ARC,
			spin: random_range(-TILE_FLY_SPIN, TILE_FLY_SPIN),
			delay: _delay,
			timer: TILE_FLY_DURATION
		})
	}

	//avance tous les vols, et revele le morceau a l'arrivee
	static step = function(){
		for(var k = array_length(flying)-1; k >= 0; k--){
			flying[k].timer -= 1
			if flying[k].timer > 0 continue;

			reveal(flying[k].piece)
			array_delete(flying, k, 1)
		}

		//les tuiles soufflees : seules celles qui portaient un virus liberent un morceau
		for(var k = array_length(flyingTiles)-1; k >= 0; k--){
			if flyingTiles[k].delay > 0 {
				flyingTiles[k].delay -= 1
				continue;
			}
			flyingTiles[k].timer -= 1
			if flyingTiles[k].timer > 0 continue;

			if flyingTiles[k].reveals reveal(flyingTiles[k].piece)
			array_delete(flyingTiles, k, 1)
		}
	}

	//true tant qu'une tuile soufflee n'est pas arrivee
	static tilesInFlight = function(){
		return array_length(flyingTiles) > 0
	}

	//les tuiles soufflees : elles tremblent sur place, puis foncent vers la photo.
	//un virus y depose son morceau, une moitie de pilule s'y dissout
	static drawFlyingTiles = function(){
		for(var k = 0; k < array_length(flyingTiles); k++){
			var _f = flyingTiles[k]

			//l'onde ne l'a pas encore atteinte : elle vibre a sa place
			if _f.delay > 0 {
				var _jx = random_range(-2, 2)
				var _jy = random_range(-2, 2)
				drawTileExt(_f.tile, _f.link, _f.fromX + _jx, _f.fromY + _jy, 1, random_range(-4, 4), 1)
				if _f.piece >= 0 {
					drawPiece(_f.piece, _f.fromX + _jx - TILE_SIZE/2, _f.fromY + _jy - TILE_SIZE/2,
						TILE_SIZE, TILE_SIZE, 0.4)
				}
				continue;
			}

			//un virus prend la meme course adoucie que les morceaux ordinaires,
			//une moitie de pilule garde le depart sec du souffle
			var _t = 1 - _f.timer/TILE_FLY_DURATION
			if _f.reveals _t = _t*_t*(3 - 2*_t)

			var _u = 1 - _t
			var _cx = _u*_u*_f.fromX + 2*_u*_t*_f.ctrlX + _t*_t*_f.toX
			var _cy = _u*_u*_f.fromY + 2*_u*_t*_f.ctrlY + _t*_t*_f.toY

			if _f.reveals {
				//la coquille du virus se dissout, le morceau grandit jusqu'a sa place
				var _w = lerp(TILE_SIZE, pieceW, _t)
				var _h = lerp(TILE_SIZE, pieceH, _t)
				drawPiece(_f.piece, _cx - _w/2, _cy - _h/2, _w, _h, lerp(FLY_ALPHA_START, 1, _t))

				var _shell = 1 - min(1, _t/0.6)
				if _shell > 0 {
					drawTileExt(_f.tile, _f.link, _cx, _cy, _w/TILE_SIZE, _f.spin*_t, _shell)
				}
				continue;
			}

			//moitie de pilule : elle ne se resorbe qu'en fin de course, le vol reste lisible
			drawTileExt(_f.tile, _f.link, _cx, _cy, lerp(1, 0.15, _t*_t), _f.spin*_t, 1 - _t*_t)
		}
	}

	static drawFlying = function(){
		for(var k = 0; k < array_length(flying); k++){
			var _f = flying[k]

			//0 au depart, 1 a l'arrivee, adouci aux deux bouts
			var _t = 1 - _f.timer/FLY_DURATION
			_t = _t*_t*(3 - 2*_t)

			//courbe de Bezier quadratique : depart, point de controle, arrivee
			var _u = 1 - _t
			var _cx = _u*_u*_f.fromX + 2*_u*_t*_f.ctrlX + _t*_t*_f.toX
			var _cy = _u*_u*_f.fromY + 2*_u*_t*_f.ctrlY + _t*_t*_f.toY

			//la rotation part de 0 et y revient : le morceau se pose droit
			var _rot = _f.spin * dsin(180*_t)

			var _w = lerp(_f.fromSize, pieceW, _t)
			var _h = lerp(_f.fromSize, pieceH, _t)
			var _alpha = lerp(FLY_ALPHA_START, 1, _t)

			//draw_sprite_general tourne autour de son ancre : on recule du centre
			//vers le coin, dans le repere deja tourne
			var _ax = _cx - (lengthdir_x(_w/2, _rot) + lengthdir_x(_h/2, _rot-90))
			var _ay = _cy - (lengthdir_y(_w/2, _rot) + lengthdir_y(_h/2, _rot-90))

			var _left = (_f.piece mod cols) * srcW
			var _top = (_f.piece div cols) * srcH
			draw_sprite_general(spr_photo2, 0, _left, _top, srcW, srcH,
				_ax, _ay, _w/srcW, _h/srcH, _rot,
				c_white, c_white, c_white, c_white, _alpha)
		}
	}

	//dessine le morceau _n dans un rectangle quelconque : le panneau l'utilise
	//en grand et opaque, le plateau en vignette a 40%
	static drawPiece = function(_n, _x, _y, _w, _h, _alpha){
		if _n < 0 || _n >= cols*rows exit;

		var _left = (_n mod cols) * srcW
		var _top = (_n div cols) * srcH
		draw_sprite_part_ext(spr_photo2, 0, _left, _top, srcW, srcH,
			_x, _y, _w/srcW, _h/srcH, c_white, _alpha)
	}

	//tous les index de morceaux, melanges : de quoi repartir la photo au hasard
	static shuffledIds = function(){
		var _ids = []
		for(var n = 0; n < cols*rows; n++){
			array_push(_ids, n)
		}
		for(var k = array_length(_ids)-1; k > 0; k--){
			var _r = irandom(k)
			var _tmp = _ids[k]
			_ids[k] = _ids[_r]
			_ids[_r] = _tmp
		}
		return _ids
	}

	static draw = function(){
		//la forme de la photo, avant tout deblocage
		draw_set_color(PANEL_COLOR)
		draw_rectangle(px, py, px + pw, py + ph, false)
		draw_set_color(c_white)

		for(var n = 0; n < array_length(revealed); n++){
			if !revealed[n] continue;
			drawPiece(n, pieceX(n), pieceY(n), pieceW, pieceH, 1)
		}

		//les morceaux en vol passent par dessus tout le reste
		drawFlying()
		drawFlyingTiles()
	}
}


//=============================================================
// Une partie complète : plateau, état, contrôles, affichage
// _controls : { left, right, down, rotate }, des codes de touches
//=============================================================

function DrMarioGame(_boardX, _boardY, _controls) constructor {

	boardX = _boardX
	boardY = _boardY
	controls = _controls

	board = noone
	links = noone
	marks = noone					//cases condamnées, noone hors de STATE_CLEARING

	state = STATE_READY
	stateTimer = 0

	difficulty = BASE_DIFFICULTY
	ready = false
	tickMax = TICK_COOLDOWN			//recalcule au depart, selon la difficulte
	tickCooldown = TICK_COOLDOWN
	downCooldown = 0
	goingFast = false

	playingPillA = noone
	playingPillB = noone

	//file des pilules a venir, la premiere est celle qui entrera en jeu
	nextPills = []
	pendingPill = noone				//sortie de la file, en route vers le plateau
	previewTimer = 0				//frames restantes de la montee de la file
	previewMax = PREVIEW_ANIM		//duree de la montee en cours, calee sur l'attente
	previewFly = noone				//la pilule qui rejoint le plateau, noone sinon

	opponent = noone				//l'autre partie, pour se terminer ensemble
	autoFall = true					//false : la pilule ne descend jamais toute seule

	photo = noone					//panneau partage, noone si aucun
	pieceIds = noone				//morceaux attribues a cette partie, dans l'ordre des virus
	virusPiece = noone				//n-ieme virus occupant chaque case

	shuffling = []					//tuiles en train de rejoindre leur nouvelle case
	shuffleTimer = 0				//frames restantes du melange, 0 = plateau normal

	//explosion de defaite, purement visuelle : la partie est deja finie
	explosionTimer = 0				//frames restantes, 0 = pas d'explosion en cours
	explosionAge = 0
	rings = []						//anneaux de choc
	sparks = []						//debris projetes

	garbageQueue = []				//couleurs recues, en attente de la prochaine chute
	lastGroupColors = []			//couleurs des groupes du dernier effacement
	chainGroupColors = []			//idem, cumulees sur toute la resolution en cours


	//---------------------------------------------------------
	// Plateau
	//---------------------------------------------------------

	static clearBoard = function(){
		var _board = noone
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				_board[i][j] = EMPTY_TILE
			}
		}
		return _board
	}

	//les virus et les cases vides n'ont aucun lien
	static clearLinks = function(){
		var _links = noone
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				_links[i][j] = LINK_NONE
			}
		}
		return _links
	}

	//morceau de photo attribue au _n-ieme virus du plateau, -1 s'il n'y en a pas
	static pieceForVirus = function(_n){
		if _n < 0 return -1;
		if pieceIds == noone return _n;
		if _n >= array_length(pieceIds) return -1;
		return pieceIds[_n]
	}

	//morceau de photo cache par la case, -1 si elle ne porte pas de virus
	static pieceFor = function(_i, _j){
		return pieceForVirus(virusPiece[_i][_j])
	}

	//aucun morceau attribue tant qu'un virus n'occupe pas la case
	static clearVirusPiece = function(){
		var _pieces = noone
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				_pieces[i][j] = -1
			}
		}
		return _pieces
	}

	//true si ce plateau contient deja une suite de 4+ de meme couleur
	static boardHasRun = function(_board){
		//lignes
		for(var i = 0; i < MAP_HEIGHT; i++){
			var _run = 0
			var _prev = EMPTY_TILE
			for(var j = 0; j < MAP_LENGTH; j++){
				var _c = tileColor(_board[i][j])
				if _c == EMPTY_TILE {
					_run = 0
				} else if _c == _prev {
					_run += 1
				} else {
					_run = 1
				}
				_prev = _c
				if _run >= 4 return true;
			}
		}

		//colonnes
		for(var j = 0; j < MAP_LENGTH; j++){
			var _run = 0
			var _prev = EMPTY_TILE
			for(var i = 0; i < MAP_HEIGHT; i++){
				var _c = tileColor(_board[i][j])
				if _c == EMPTY_TILE {
					_run = 0
				} else if _c == _prev {
					_run += 1
				} else {
					_run = 1
				}
				_prev = _c
				if _run >= 4 return true;
			}
		}

		return false
	}

	//tire un placement de virus, et recommence tant qu'il contient une suite de 4+
	static setupBoard = function(){
		var _board = noone

		for(var _attempt = 0; _attempt < MAX_SETUP_TRIES; _attempt++){
			//chaque essai repart de zero, sinon les morceaux du tirage precedent restent
			virusPiece = clearVirusPiece()
			_board = clearBoard()

			for (var n = 0; n < NB_INITIAL_VIRUS; n++){
				var _i = MAP_HEIGHT - irandom(5) - 1
				var _j = irandom(MAP_LENGTH-1)
				while _board[_i][_j] != EMPTY_TILE{
					_i = MAP_HEIGHT - irandom(5) - 1
					_j = irandom(MAP_LENGTH-1)
				}
				_board[_i][_j] = BLUE_VIRUS + n%3
				virusPiece[_i][_j] = n			//le n-ieme virus cache le n-ieme morceau
			}

			if !boardHasRun(_board) break;
		}

		//au bout de MAX_SETUP_TRIES on garde le dernier tirage : les suites sauteront
		//au premier posé, ce qui debloquerait des morceaux sans que le joueur ait joue
		return _board
	}

	//nombre de virus encore en jeu, cases et melange en cours confondus
	static countViruses = function(){
		var _n = 0
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				if board[i][j] > YELLOW_PILL _n += 1
			}
		}

		//pendant un melange une tuile n'est sur aucune case : elle compte quand meme
		for(var k = 0; k < array_length(shuffling); k++){
			if shuffling[k].tile > YELLOW_PILL _n += 1
		}

		return _n
	}

	//true si la case est dans le plateau et libre
	static cellIsFree = function(_i, _j){
		if _j < 0 || _j >= MAP_LENGTH return false;
		if _i >= MAP_HEIGHT return false;
		if _i < 0 return true;				//au-dessus du plateau = toléré au spawn
		return board[_i][_j] == EMPTY_TILE;
	}

	//casse le lien de la case et celui de son partenaire, qui devient une moitié orpheline
	static breakLink = function(_i, _j){
		var _link = links[_i][_j]
		links[_i][_j] = LINK_NONE
		if _link == LINK_NONE exit;

		var _pi = _i, _pj = _j
		switch(_link){
			case LINK_LEFT:		_pj -= 1; break;
			case LINK_RIGHT:	_pj += 1; break;
			case LINK_UP:		_pi -= 1; break;
			case LINK_DOWN:		_pi += 1; break;
		}
		if _pi < 0 || _pi >= MAP_HEIGHT || _pj < 0 || _pj >= MAP_LENGTH exit;
		links[_pi][_pj] = LINK_NONE
	}

	//deplace une tuile et son lien vers une case vide
	static moveTile = function(_fi, _fj, _ti, _tj){
		board[_ti][_tj] = board[_fi][_fj]
		links[_ti][_tj] = links[_fi][_fj]
		board[_fi][_fj] = EMPTY_TILE
		links[_fi][_fj] = LINK_NONE
	}


	//---------------------------------------------------------
	// Pilule dirigée
	//---------------------------------------------------------

	//tick de descente correspondant a la difficulte choisie
	static tickForDifficulty = function(){
		return TICK_COOLDOWN - (difficulty - BASE_DIFFICULTY)*DIFFICULTY_STEP
	}

	static changeDifficulty = function(_delta){
		difficulty = clamp(difficulty + _delta, MIN_DIFFICULTY, MAX_DIFFICULTY)
	}

	//quitte l'ecran de preparation : la vitesse est figee, la premiere pilule tombe
	static startPlaying = function(){
		if state != STATE_READY exit;

		tickMax = tickForDifficulty()

		//la premiere pilule entre comme toutes les autres : le temps de l'animation
		state = STATE_SPAWN
		stateTimer = PREVIEW_ANIM + 1
	}

	//une pilule au hasard, pas encore posee sur le plateau
	static rollPill = function(){
		return {
			a: choose(BLUE_PILL, RED_PILL, YELLOW_PILL),
			b: choose(BLUE_PILL, RED_PILL, YELLOW_PILL)
		}
	}

	//remplit la file : le joueur voit les prochaines des l'ecran de preparation
	static fillPreview = function(){
		nextPills = []
		for(var k = 0; k < PREVIEW_COUNT; k++){
			array_push(nextPills, rollPill())
		}
	}

	//sort la tete de file, que la file remplace aussitot par le bas
	static takeNextPill = function(){
		var _p = nextPills[0]
		array_delete(nextPills, 0, 1)
		array_push(nextPills, rollPill())
		return _p
	}

	//lance l'entree de la prochaine pilule. _frames est ce qui reste avant qu'elle
	//apparaisse : le vol finit donc pile au moment ou le joueur prend la main
	static startPreviewFly = function(_frames){
		pendingPill = takeNextPill()
		previewFly = pendingPill
		previewMax = max(1, _frames)
		previewTimer = previewMax
	}

	static spawnPill = function(){
		//défaite : la zone d'apparition est bouchée
		if !cellIsFree(0, (MAP_LENGTH/2)-1) || !cellIsFree(0, MAP_LENGTH/2) {
			setEnding(STATE_LOSE)
			exit;
		}

		//celle qui volait se pose ici meme : le vol vient de finir, le raccord est net.
		//sans vol en cours (cas de repli), on depile a la volee
		var _next = (pendingPill != noone) ? pendingPill : takeNextPill()
		pendingPill = noone
		previewFly = noone
		previewTimer = 0

		playingPillA = new Pill(0,(MAP_LENGTH/2)-1,_next.a)
		playingPillB = new Pill(0,MAP_LENGTH/2,_next.b)

		tickCooldown = tickMax
		state = STATE_CONTROL
	}

	static dropPillOnBoard = function(){
		board[playingPillA.i][playingPillA.j] = playingPillA.color
		board[playingPillB.i][playingPillB.j] = playingPillB.color

		//les deux moitiés restent liées tant qu'aucune n'est détruite
		links[playingPillA.i][playingPillA.j] = linkBetween(playingPillA.i, playingPillA.j, playingPillB.i, playingPillB.j)
		links[playingPillB.i][playingPillB.j] = linkBetween(playingPillB.i, playingPillB.j, playingPillA.i, playingPillA.j)

		playingPillA = noone
		playingPillB = noone

		//nouvelle resolution : le combo repart de zero
		chainGroupColors = []
		startResolving()
	}

	static movePlayingPill = function(_i, _j){
		if playingPillA == noone || playingPillB == noone exit;

		var _ai = playingPillA.i + _i, _aj = playingPillA.j + _j;
		var _bi = playingPillB.i + _i, _bj = playingPillB.j + _j;

		if cellIsFree(_ai, _aj) && cellIsFree(_bi, _bj){
			playingPillA.i = _ai; playingPillA.j = _aj;
			playingPillB.i = _bi; playingPillB.j = _bj;
		} else if _i > 0 {
			//on bloquait en descendant -> la pilule se pose
			dropPillOnBoard();
		}
		//sinon (blocage latéral) : on ignore l'input
	}

	//rotation a la Dr Mario : la pilule ne sort jamais de son carre de 2x2
	//horizontale = (case d'ancrage, case a droite), verticale = (case d'ancrage, case au dessus)
	//un tour complet = 4 etats : horizontale, verticale, horizontale couleurs inversees, verticale inversee
	static rotatePlayingPill = function(_clockwise){
		if playingPillA == noone || playingPillB == noone exit;

		var _horizontal = (playingPillA.i == playingPillB.i);

		//_p1 : moitie gauche (horizontale) ou moitie basse (verticale), _p2 : l'autre
		var _p1, _p2;
		var _aFirst = _horizontal ? (playingPillA.j < playingPillB.j) : (playingPillA.i > playingPillB.i);
		if _aFirst {
			_p1 = playingPillA;	_p2 = playingPillB;
		} else {
			_p1 = playingPillB;	_p2 = playingPillA;
		}

		//ancre : le coin bas-gauche du carre, il ne bouge pas pendant la rotation
		var _i = _p1.i, _j = _p1.j;

		//les deux cases visees, puis qui occupe laquelle
		var _ci1, _cj1, _ci2, _cj2;
		var _first, _second;
		if _horizontal {
			//on passe a la verticale : ancre en bas, case au dessus
			_ci1 = _i;		_cj1 = _j;
			_ci2 = _i - 1;	_cj2 = _j;
			//horaire : la moitie gauche monte. antihoraire : elle reste en bas
			_first  = _clockwise ? _p2 : _p1;
			_second = _clockwise ? _p1 : _p2;
		} else {
			//on repasse a l'horizontale : ancre a gauche, case a droite
			_ci1 = _i;		_cj1 = _j;
			_ci2 = _i;		_cj2 = _j + 1;
			//horaire : la moitie basse reste a gauche. antihoraire : la moitie haute y va
			_first  = _clockwise ? _p1 : _p2;
			_second = _clockwise ? _p2 : _p1;
		}

		//wall kick : tel quel, puis decale d'une case a gauche (mur ou pile a droite)
		var _kicks = [0, -1];
		for(var k = 0; k < array_length(_kicks); k++){
			var _o = _kicks[k];
			if cellIsFree(_ci1, _cj1 + _o) && cellIsFree(_ci2, _cj2 + _o){
				_first.i  = _ci1;	_first.j  = _cj1 + _o;
				_second.i = _ci2;	_second.j = _cj2 + _o;
				exit;
			}
		}
		//aucune position valide -> rotation refusee
	}


	//---------------------------------------------------------
	// Résolution : suites, effacement, gravité
	//---------------------------------------------------------

	//cherche les suites de 4+ tuiles de même couleur (lignes et colonnes)
	//retourne le tableau des cases condamnées, ou noone s'il n'y a rien
	static findWinningTiles = function(){
		//tableau de marquage, pour effacer seulement après avoir tout scanné
		var _marks = noone
		//couleur de chaque case : un virus compte comme la pilule de même couleur
		var _colors = noone
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				_marks[i][j] = false
				var _t = board[i][j]
				_colors[i][j] = tileColor(_t)
			}
		}

		//chaque suite fermee de 4+ est un groupe : c'est ce qui determine l'attaque
		var _groups = []

		//suites horizontales
		for(var i = 0; i < MAP_HEIGHT; i++){
			var _runStart = 0
			for(var j = 1; j <= MAP_LENGTH; j++){
				var _same = (j < MAP_LENGTH) && (_colors[i][j] == _colors[i][_runStart]) && (_colors[i][j] != EMPTY_TILE)
				if !_same {
					if _colors[i][_runStart] != EMPTY_TILE && (j - _runStart) >= 4 {
						array_push(_groups, _colors[i][_runStart])
						for(var k = _runStart; k < j; k++){
							_marks[i][k] = true
						}
					}
					_runStart = j
				}
			}
		}

		//suites verticales
		for(var j = 0; j < MAP_LENGTH; j++){
			var _runStart = 0
			for(var i = 1; i <= MAP_HEIGHT; i++){
				var _same = (i < MAP_HEIGHT) && (_colors[i][j] == _colors[_runStart][j]) && (_colors[i][j] != EMPTY_TILE)
				if !_same {
					if _colors[_runStart][j] != EMPTY_TILE && (i - _runStart) >= 4 {
						array_push(_groups, _colors[_runStart][j])
						for(var k = _runStart; k < i; k++){
							_marks[k][j] = true
						}
					}
					_runStart = i
				}
			}
		}

		//rien trouvé : on ne renvoie pas un tableau vide, plus simple à tester
		lastGroupColors = _groups
		if array_length(_groups) == 0 return noone;

		return _marks
	}

	//efface les cases marquées, en cassant les liens des moitiés survivantes
	static applyWinningTiles = function(_marks){
		if _marks == noone exit;
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				if !_marks[i][j] continue;

				//un virus casse envoie son morceau rejoindre sa place sur la photo
				if board[i][j] > YELLOW_PILL && photo != noone {
					photo.flyPiece(pieceFor(i, j), boardX + j*TILE_SIZE, boardY + i*TILE_SIZE, TILE_SIZE)
				}

				breakLink(i, j)
				board[i][j] = EMPTY_TILE
			}
		}
	}

	//true si la case peut accueillir une tuile qui tombe
	static canFallInto = function(_i, _j){
		if _i >= MAP_HEIGHT return false;
		return board[_i][_j] == EMPTY_TILE;
	}

	//descend d'une rangée tout ce qui n'est plus soutenu
	//retourne true si au moins une unité a bougé
	static applyGravityStep = function(){
		var _moved = false

		//du bas vers le haut : une unité déjà descendue n'est pas revue dans la même passe
		for(var i = MAP_HEIGHT - 1; i >= 0; i--){
			for(var j = 0; j < MAP_LENGTH; j++){
				var _tile = board[i][j]
				if _tile == EMPTY_TILE continue;
				if _tile > YELLOW_PILL continue;			//les virus ne tombent jamais

				//une paire n'est traitée que depuis la moitié gauche ou la moitié du haut
				var _link = links[i][j]
				if _link == LINK_LEFT || _link == LINK_UP continue;

				if _link == LINK_RIGHT {
					//paire horizontale : il faut les deux cases du dessous
					if canFallInto(i+1, j) && canFallInto(i+1, j+1) {
						moveTile(i, j, i+1, j)
						moveTile(i, j+1, i+1, j+1)
						_moved = true
					}
				} else if _link == LINK_DOWN {
					//paire verticale : seule la case sous la moitié du bas compte
					if canFallInto(i+2, j) {
						moveTile(i+1, j, i+2, j)
						moveTile(i, j, i+1, j)
						_moved = true
					}
				} else {
					//moitié orpheline
					if canFallInto(i+1, j) {
						moveTile(i, j, i+1, j)
						_moved = true
					}
				}
			}
		}

		return _moved
	}

	//---------------------------------------------------------
	// Attaques
	//---------------------------------------------------------

	//nombre de moities envoyees pour un nombre de groupes elimines d'un coup
	//un seul groupe n'attaque pas : il faut une croix ou une cascade
	static garbageForGroups = function(_n){
		if _n <= 1 return 0;
		if _n == 2 return 2;
		if _n == 3 return 4;
		return 6;
	}

	//envoie a l'adversaire les moities dues pour toute la resolution ecoulee
	static sendGarbage = function(){
		var _src = chainGroupColors
		var _n = array_length(_src)
		chainGroupColors = []			//le combo est solde, quoi qu'il arrive
		if _n == 0 exit;

		var _count = garbageForGroups(_n)
		if _count <= 0 exit;
		if opponent == noone exit;

		//les couleurs envoyees sont celles des groupes elimines, en boucle
		var _colors = []
		for(var k = 0; k < _count; k++){
			array_push(_colors, _src[k % _n])
		}
		opponent.receiveGarbage(_colors)
	}

	//met l'attaque en file : elle n'apparait qu'a la prochaine phase de chute
	static receiveGarbage = function(_colors){
		for(var k = 0; k < array_length(_colors); k++){
			array_push(garbageQueue, _colors[k])
		}
	}

	//pose les moities en attente sur la rangee du haut, dans des colonnes libres
	//retourne true si au moins une a ete posee
	static spawnGarbage = function(){
		if array_length(garbageQueue) == 0 return false;

		//colonnes dont le haut est libre, melangees
		var _cols = []
		for(var j = 0; j < MAP_LENGTH; j++){
			if board[0][j] == EMPTY_TILE array_push(_cols, j)
		}
		for(var k = array_length(_cols)-1; k > 0; k--){
			var _r = irandom(k)
			var _tmp = _cols[k]
			_cols[k] = _cols[_r]
			_cols[_r] = _tmp
		}

		//ce qui ne rentre pas reste en file pour la vague suivante
		var _placed = 0
		while _placed < array_length(_cols) && array_length(garbageQueue) > 0 {
			var _color = garbageQueue[0]
			array_delete(garbageQueue, 0, 1)
			board[0][_cols[_placed]] = _color
			links[0][_cols[_placed]] = LINK_NONE		//toujours des moities orphelines
			_placed += 1
		}

		return _placed > 0
	}

	//---------------------------------------------------------
	// File des pilules a venir
	//---------------------------------------------------------

	//coin gauche de la file, juste a droite du plateau
	static previewX = function(){
		return boardX + MAP_LENGTH*TILE_SIZE + PREVIEW_GAP
	}

	//centre vertical de la place _slot, qui peut etre fractionnaire pendant la montee
	static previewY = function(_slot){
		return boardY + PREVIEW_TOP + _slot*PREVIEW_STEP
	}

	//une pilule couchee, centree en (_cx,_cy), a l'echelle demandee
	static drawPillAt = function(_a, _b, _cx, _cy, _scale, _alpha){
		var _half = TILE_SIZE*_scale/2
		drawTileExt(_a, LINK_RIGHT, _cx - _half, _cy, _scale, 0, _alpha)
		drawTileExt(_b, LINK_LEFT,  _cx + _half, _cy, _scale, 0, _alpha)
	}

	static drawPreview = function(){
		if state == STATE_WIN || state == STATE_LOSE exit;

		//0 au depart de la montee, 1 une fois la file en place
		var _t = 1
		if previewTimer > 0 {
			_t = 1 - previewTimer/previewMax
			_t = _t*_t*(3 - 2*_t)
		}

		var _cx = previewX() + TILE_SIZE*PREVIEW_SCALE

		for(var k = 0; k < array_length(nextPills); k++){
			//pendant la montee chaque pilule vient de la place d'en dessous
			var _slot = (previewTimer > 0) ? lerp(k + 1, k, _t) : k

			//la derniere n'existait pas encore : elle se fond dans la file
			var _alpha = (previewTimer > 0 && k == array_length(nextPills)-1) ? _t : 1

			drawPillAt(nextPills[k].a, nextPills[k].b, _cx, previewY(_slot), PREVIEW_SCALE, _alpha)
		}

		//la partante quitte la file et grandit jusqu'a sa case d'apparition, connue
		//d'avance : elle finit a l'echelle 1 la ou la vraie pilule prend le relais
		if previewTimer > 0 && previewFly != noone {
			var _toX = boardX + (MAP_LENGTH/2)*TILE_SIZE
			var _toY = boardY + TILE_SIZE/2

			drawPillAt(previewFly.a, previewFly.b,
				lerp(_cx, _toX, _t), lerp(previewY(0), _toY, _t),
				lerp(PREVIEW_SCALE, 1, _t), 1)
		}
	}


	//en duo c'est un duel : celui qui nettoie son plateau le premier fait sauter
	//celui de l'autre. une pile qui creve reste une defaite ordinaire, sans souffle,
	//et elle coule l'equipe : la photo ne sera de toute facon jamais complete.
	//_blast : seule une defaite infligee par la victoire de l'autre fait exploser
	static setEnding = function(_state, _blast = false){
		if state == STATE_WIN || state == STATE_LOSE exit;	//deja fini, coupe la recursion

		state = _state
		if _state == STATE_LOSE {
			if _blast explode()
			if opponent != noone opponent.setEnding(STATE_LOSE)
		} else if opponent != noone {
			//la victoire de l'un est la defaite de l'autre, et celle-la explose
			opponent.setEnding(STATE_LOSE, true)
		}
	}


	//---------------------------------------------------------
	// Melange secret
	//---------------------------------------------------------

	//true tant que les tuiles n'ont pas retrouve une case
	static isShuffling = function(){
		return shuffleTimer > 0
	}

	//redistribue tout le contenu du plateau sur les memes cases, au hasard.
	//la silhouette du plateau ne change pas : rien ne se met a flotter, rien ne
	//tombe, seules les couleurs et les virus changent de place
	static shuffleBoard = function(){
		if shuffleTimer > 0 exit;							//un melange a la fois
		if state == STATE_READY || state == STATE_WIN || state == STATE_LOSE exit;

		//contenu de chaque case occupee, avec sa provenance
		var _items = []
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				if board[i][j] == EMPTY_TILE continue;
				array_push(_items, { tile: board[i][j], virus: virusPiece[i][j], i: i, j: j })
			}
		}

		var _n = array_length(_items)
		if _n < 2 exit;

		//les cases d'arrivee sont les memes, dans un ordre melange
		var _slots = []
		for(var k = 0; k < _n; k++){
			array_push(_slots, { i: _items[k].i, j: _items[k].j })
		}
		for(var k = _n-1; k > 0; k--){
			var _r = irandom(k)
			var _tmp = _slots[k]
			_slots[k] = _slots[_r]
			_slots[_r] = _tmp
		}

		//le plateau se vide : tout n'existe plus que dans le vol
		board = clearBoard()
		links = clearLinks()
		virusPiece = clearVirusPiece()
		marks = noone

		var _longest = 0
		for(var k = 0; k < _n; k++){
			var _it = _items[k]
			var _to = _slots[k]
			var _delay = random(SHUFFLE_STAGGER)

			var _fromX = boardX + _it.j*TILE_SIZE + TILE_SIZE/2
			var _fromY = boardY + _it.i*TILE_SIZE + TILE_SIZE/2
			var _toX = boardX + _to.j*TILE_SIZE + TILE_SIZE/2
			var _toY = boardY + _to.i*TILE_SIZE + TILE_SIZE/2
			var _dist = point_distance(_fromX, _fromY, _toX, _toY)

			array_push(shuffling, {
				tile: _it.tile,	virus: _it.virus,
				ti: _to.i,		tj: _to.j,
				fromX: _fromX,	fromY: _fromY,
				toX: _toX,		toY: _toY,
				//les deux cases peuvent etre sur la meme ligne : l'arc passe sur le cote
				ctrlX: (_fromX + _toX)/2 + random_range(-_dist*0.25, _dist*0.25),
				ctrlY: (_fromY + _toY)/2 - max(_dist*SHUFFLE_FLY_ARC, TILE_SIZE*1.5),
				spin: random_range(-SHUFFLE_FLY_SPIN, SHUFFLE_FLY_SPIN),
				delay: _delay,
				timer: SHUFFLE_FLY_DURATION
			})

			_longest = max(_longest, _delay + SHUFFLE_FLY_DURATION)
		}

		shuffleTimer = _longest
	}

	//avance le melange : chaque tuile arrivee reprend sa place sur le plateau
	static stepShuffle = function(){
		shuffleTimer -= 1

		for(var k = array_length(shuffling)-1; k >= 0; k--){
			var _f = shuffling[k]
			if _f.delay > 0 {
				_f.delay -= 1
				continue;
			}

			_f.timer -= 1
			if _f.timer > 0 continue;

			//la tuile se repose : toujours seule, une paire ne survit pas au melange
			board[_f.ti][_f.tj] = _f.tile
			links[_f.ti][_f.tj] = LINK_NONE
			virusPiece[_f.ti][_f.tj] = _f.virus
			array_delete(shuffling, k, 1)
		}

		//securite : le compte des frames ne doit jamais finir avant les tuiles
		if shuffleTimer <= 0 && array_length(shuffling) > 0 shuffleTimer = 1
	}

	static drawShuffle = function(){
		for(var k = 0; k < array_length(shuffling); k++){
			var _f = shuffling[k]

			//pas encore partie : elle attend sur sa case, en tremblant un peu
			if _f.delay > 0 {
				var _jx = random_range(-1, 1)
				var _jy = random_range(-1, 1)
				drawTileExt(_f.tile, LINK_NONE, _f.fromX + _jx, _f.fromY + _jy, 1, 0, 1)
				if _f.tile > YELLOW_PILL && photo != noone {
					photo.drawPiece(pieceForVirus(_f.virus), _f.fromX + _jx - TILE_SIZE/2,
						_f.fromY + _jy - TILE_SIZE/2, TILE_SIZE, TILE_SIZE, 0.4)
				}
				continue;
			}

			var _t = 1 - _f.timer/SHUFFLE_FLY_DURATION
			_t = _t*_t*(3 - 2*_t)						//meme adoucissement que les morceaux

			var _u = 1 - _t
			var _cx = _u*_u*_f.fromX + 2*_u*_t*_f.ctrlX + _t*_t*_f.toX
			var _cy = _u*_u*_f.fromY + 2*_u*_t*_f.ctrlY + _t*_t*_f.toY

			//elle grossit a mi-parcours : elle passe visiblement au dessus du plateau
			var _scale = 1 + 0.35*dsin(180*_t)

			drawTileExt(_f.tile, LINK_NONE, _cx, _cy, _scale, _f.spin*_t, 1)

			//un virus emporte son apercu de morceau avec lui
			if _f.tile > YELLOW_PILL && photo != noone {
				var _s = TILE_SIZE*_scale
				photo.drawPiece(pieceForVirus(_f.virus), _cx - _s/2, _cy - _s/2, _s, _s, 0.4)
			}
		}
	}


	//---------------------------------------------------------
	// Explosion de defaite
	//---------------------------------------------------------

	//true tant que le souffle n'est pas retombe
	static isBlasting = function(){
		return explosionTimer > 0
	}

	//alpha du flash plein ecran : dessine par obj_game, par dessus toute la scene
	static blastFlash = function(){
		if explosionTimer <= 0 || explosionAge > BLAST_FLASH return 0;
		return 1 - explosionAge/BLAST_FLASH
	}

	//confie une tuile a la photo, avec le retard qu'il faut a l'onde pour l'atteindre
	static launchTile = function(_tile, _link, _i, _j, _piece, _cx, _cy){
		if photo == noone exit;

		var _x = boardX + _j*TILE_SIZE
		var _y = boardY + _i*TILE_SIZE
		var _d = point_distance(_x + TILE_SIZE/2, _y + TILE_SIZE/2, _cx, _cy)

		photo.flyTile(_tile, _link, _x, _y, TILE_SIZE, _piece, BLAST_FLASH + (_d/TILE_SIZE)*TILE_FLY_WAVE)
	}

	//souffle le plateau : flash, anneaux, debris, et toutes les tuiles aspirees
	//par la photo. le plateau est vide sur le champ, le reste n'est qu'affichage
	static explode = function(){
		if explosionTimer > 0 exit;

		explosionTimer = BLAST_DURATION
		explosionAge = 0
		rings = []
		sparks = []

		var _cx = boardX + (MAP_LENGTH*TILE_SIZE)/2
		var _cy = boardY + (MAP_HEIGHT*TILE_SIZE)/2

		//les anneaux partent en rafale, chacun plus large et plus lent que le precedent
		for(var k = 0; k < BLAST_RINGS; k++){
			array_push(rings, { x: _cx, y: _cy, delay: k*6, age: 0, life: 34 + k*4, max: 90 + k*70 })
		}

		//debris : projetes du centre, freines par l'air et rattrapes par la gravite
		for(var k = 0; k < BLAST_SPARKS; k++){
			var _dir = random(360)
			var _spd = random_range(4, 16)
			array_push(sparks, {
				x: _cx + lengthdir_x(random(40), _dir),
				y: _cy + lengthdir_y(random(40), _dir),
				vx: lengthdir_x(_spd, _dir),
				vy: lengthdir_y(_spd, _dir),
				size: random_range(2, 7),
				life: irandom_range(25, BLAST_DURATION),
				age: 0,
				color: choose(c_white, c_yellow, c_orange, c_red, BUTTON_TEXT_HL_COLOR)
			})
		}

		//tout ce qui trainait sur le plateau part vers la photo, du centre vers les bords.
		//seul un virus porte encore un morceau : virusPiece garde la trace des virus
		//deja casses, donc une pilule posee sur leur case ne doit rien liberer
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				var _tile = board[i][j]
				if _tile == EMPTY_TILE continue;

				var _piece = (_tile > YELLOW_PILL) ? pieceFor(i, j) : -1
				launchTile(_tile, links[i][j], i, j, _piece, _cx, _cy)
			}
		}

		//la pilule encore en main part avec le reste
		if playingPillA != noone launchTile(playingPillA.color, LINK_NONE, playingPillA.i, playingPillA.j, -1, _cx, _cy)
		if playingPillB != noone launchTile(playingPillB.color, LINK_NONE, playingPillB.i, playingPillB.j, -1, _cx, _cy)

		//le plateau est vide : les tuiles n'existent plus que dans le vol
		board = clearBoard()
		links = clearLinks()
		virusPiece = clearVirusPiece()
		marks = noone
		playingPillA = noone
		playingPillB = noone

		screenShake(BLAST_SHAKE, BLAST_SHAKE_LEN)
	}

	//avance l'effet, meme une fois la partie dans un etat terminal
	static stepExplosion = function(){
		explosionTimer -= 1
		explosionAge += 1

		for(var k = 0; k < array_length(rings); k++){
			if rings[k].delay > 0 {
				rings[k].delay -= 1
				continue;
			}
			rings[k].age += 1
		}

		for(var k = array_length(sparks)-1; k >= 0; k--){
			var _s = sparks[k]
			_s.age += 1
			_s.x += _s.vx
			_s.y += _s.vy
			_s.vy += BLAST_SPARK_GRAVITY
			_s.vx *= 0.96
			if _s.age >= _s.life array_delete(sparks, k, 1)
		}
	}

	static drawExplosion = function(){
		if explosionTimer <= 0 exit;

		var _right = boardX + MAP_LENGTH*TILE_SIZE
		var _bottom = boardY + MAP_HEIGHT*TILE_SIZE
		var _cx = (boardX + _right)/2
		var _cy = (boardY + _bottom)/2

		//le plateau reste noirci, et s'eclaircit a mesure que le souffle retombe
		draw_set_alpha(0.75 * (explosionTimer/BLAST_DURATION))
		draw_set_color(c_black)
		draw_rectangle(boardX, boardY, _right, _bottom, false)

		//anneaux de choc : tres rapides au depart, ils s'effacent en s'elargissant
		for(var k = 0; k < array_length(rings); k++){
			var _r = rings[k]
			if _r.delay > 0 || _r.age > _r.life continue;

			var _t = _r.age/_r.life
			var _rad = _r.max * (1 - power(1 - _t, 3))
			var _col = (k % 2 == 0) ? c_white : c_orange

			draw_set_alpha((1 - _t)*0.9)
			for(var w = 0; w < 4; w++){
				draw_circle_colour(_r.x, _r.y, _rad + w, _col, _col, true)
			}
		}

		//le noyau : une boule qui gonfle et s'eteint en une poignee de frames
		if explosionAge <= BLAST_FLASH*2 {
			var _t = explosionAge/(BLAST_FLASH*2)
			draw_set_alpha(1 - _t)
			draw_circle_colour(_cx, _cy, 40 + 220*_t, c_white, c_yellow, false)
		}

		//debris
		for(var k = 0; k < array_length(sparks); k++){
			var _s = sparks[k]
			draw_set_alpha(1 - _s.age/_s.life)
			draw_set_color(_s.color)
			draw_rectangle(_s.x - _s.size, _s.y - _s.size, _s.x + _s.size, _s.y + _s.size, false)
		}

		draw_set_alpha(1)
		draw_set_color(c_white)
	}

	//cherche des suites : clignotement si on en trouve, sinon pilule suivante
	static startResolving = function(){
		//une cascade en cours passe avant tout
		marks = findWinningTiles()
		if marks != noone {
			state = STATE_CLEARING
			stateTimer = CLEAR_COOLDOWN
			exit;
		}

		//victoire seulement une fois le plateau stabilisé, après l'animation
		if countViruses() == 0 {
			setEnding(STATE_WIN)
			exit;
		}

		//les attaques en attente tombent maintenant, jamais pendant STATE_CONTROL
		if spawnGarbage() {
			state = STATE_FALLING
			stateTimer = GRAVITY_TICK_COOLDOWN
			exit;
		}

		//la resolution est finie : le combo complet part d'un coup
		sendGarbage()
		state = STATE_SPAWN
		stateTimer = NEW_PILL_COOLDOWN
	}


	//---------------------------------------------------------
	// Boucle de jeu
	//---------------------------------------------------------

	static step = function(){
		//le souffle vit sa vie, meme une fois la partie perdue
		if explosionTimer > 0 stepExplosion()

		//pendant un melange la partie est figee : ni chute, ni commandes
		if shuffleTimer > 0 {
			stepShuffle()
			exit;
		}

		//la montee de la file avance au meme rythme que l'attente qui l'a lancee,
		//donc apres le melange : les deux doivent se terminer sur la meme frame
		if previewTimer > 0 {
			previewTimer -= 1
			if previewTimer <= 0 previewFly = noone
		}

		var press_left = keyboard_check_pressed(controls.left)
		var press_right = keyboard_check_pressed(controls.right)
		var press_rotate = keyboard_check_pressed(controls.rotate)
		var press_down = keyboard_check(controls.down)

		switch(state){

			//choix de la difficulte, en attendant que tout le monde soit pret
			case STATE_READY:
				if press_left	changeDifficulty(-1)
				if press_right	changeDifficulty(1)
				if press_rotate	ready = !ready			//bascule tant que rien n'est parti
				break

			//le joueur dirige la pilule
			case STATE_CONTROL:
				if press_left	movePlayingPill(0,-1)
				if press_right	movePlayingPill(0,1)

				//descente manuelle : on relance le tic pour ne pas enchainer deux descentes
				if press_down{
					downCooldown -= 1
					if downCooldown <= 0 || !goingFast{
						movePlayingPill(1,0)
						tickCooldown = tickMax
						if goingFast{
							downCooldown = DOWN_COOLDOWN_FAST
						} else {
							downCooldown = DOWN_COOLDOWN_FIRST
						}
						goingFast = true
					}
				} else {
					goingFast = false
				}

				if press_rotate	rotatePlayingPill(true)

				//descente automatique, peut poser la pilule et changer d'état
				if autoFall {
					tickCooldown -= 1
					if tickCooldown <= 0 {
						tickCooldown = tickMax
						movePlayingPill(1,0)
					}
				}
				break

			//les tuiles condamnées clignotent, puis on les efface
			case STATE_CLEARING:
				stateTimer -= 1
				if stateTimer <= 0 {
					applyWinningTiles(marks)

					//les groupes s'ajoutent au combo en cours : une cascade compte avec le reste
					for(var k = 0; k < array_length(lastGroupColors); k++){
						array_push(chainGroupColors, lastGroupColors[k])
					}

					marks = noone
					state = STATE_FALLING
					stateTimer = GRAVITY_TICK_COOLDOWN
				}
				break

			//une rangée de chute par tic, jusqu'à ce que plus rien ne bouge
			case STATE_FALLING:
				stateTimer -= 1
				if stateTimer <= 0 {
					stateTimer = GRAVITY_TICK_COOLDOWN
					//plus rien ne tombe : on recherche des suites, d'où les cascades
					if !applyGravityStep() startResolving()
				}
				break

			//délai avant la pilule suivante
			case STATE_SPAWN:
				stateTimer -= 1

				//le vol part assez tot pour finir exactement a l'apparition : le
				//joueur recupere une pilule deja posee, et le tick entier pour agir
				if pendingPill == noone && stateTimer > 0 && stateTimer <= PREVIEW_ANIM {
					startPreviewFly(stateTimer)
				}

				if stateTimer <= 0 spawnPill()
				break

			//états terminaux : plus rien ne tourne
			case STATE_WIN:
			case STATE_LOSE:
				break
		}
	}

	static draw = function(){
		//pendant le clignotement, les cases condamnées sont masquées une frame sur deux
		var _blinking = (state == STATE_CLEARING) && marks != noone && ((stateTimer div 4) % 2 == 0)

		//draw back
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				draw_sprite(spr_square,0,boardX + j*TILE_SIZE + TILE_SIZE/2,boardY + i*TILE_SIZE + TILE_SIZE/2)
			}
		}

		//draw_board
		for(var i = 0; i < MAP_HEIGHT; i++){
			for(var j = 0; j < MAP_LENGTH; j++){
				var _tile = board[i][j]
				if _tile == EMPTY_TILE continue;
				if _blinking && marks[i][j] continue;
				drawTile(_tile, links[i][j], boardX + j*TILE_SIZE, boardY + i*TILE_SIZE)

				//apercu du morceau que ce virus garde prisonnier
				if _tile > YELLOW_PILL && photo != noone {
					photo.drawPiece(pieceFor(i, j),
						boardX + j*TILE_SIZE, boardY + i*TILE_SIZE, TILE_SIZE, TILE_SIZE, 0.4)
				}
			}
		}

		//la file des prochaines, a droite du plateau
		drawPreview()

		//draw pilule en vol, par-dessus le plateau. le vol de la file est deja fini
		//quand elle apparait : les deux ne coexistent jamais
		if playingPillA != noone && playingPillB != noone{
			var _linkA = linkBetween(playingPillA.i, playingPillA.j, playingPillB.i, playingPillB.j)
			var _linkB = linkBetween(playingPillB.i, playingPillB.j, playingPillA.i, playingPillA.j)
			drawTile(playingPillA.color, _linkA, boardX + playingPillA.j*TILE_SIZE, boardY + playingPillA.i*TILE_SIZE)
			drawTile(playingPillB.color, _linkB, boardX + playingPillB.j*TILE_SIZE, boardY + playingPillB.i*TILE_SIZE)
		}

		//les tuiles en plein melange survolent le plateau
		drawShuffle()

		//le souffle passe par dessus le plateau, qu'il a deja vide
		drawExplosion()

		//ecran de preparation, par dessus le plateau deja genere
		if state == STATE_READY{
			draw_set_halign(fa_center)
			draw_set_valign(fa_middle)

			var _cx = boardX + (MAP_LENGTH*TILE_SIZE)/2
			var _cy = boardY + (MAP_HEIGHT*TILE_SIZE)/2

			//voile sombre pour que le texte reste lisible sur les virus
			draw_set_alpha(0.7)
			draw_set_color(c_black)
			draw_rectangle(boardX, _cy - 96, boardX + MAP_LENGTH*TILE_SIZE, _cy + 96, false)
			draw_set_alpha(1)

			draw_set_color(c_white)
			draw_text_transformed(_cx, _cy - 56, "DIFFICULTE", 1, 1, 0)
			draw_text_transformed(_cx, _cy - 16, string(difficulty), 4, 4, 0)
			draw_set_color(c_gray)
			draw_text(_cx, _cy + 28, "gauche / droite")

			draw_set_color(ready ? c_lime : c_gray)
			draw_text_transformed(_cx, _cy + 68, ready ? "PRET" : "haut = pret", 2, 2, 0)

			draw_set_halign(fa_left)
			draw_set_valign(fa_top)
			draw_set_color(c_white)
		}

		//bandeau du haut : le compte de virus pendant la partie, le verdict a la fin.
		//le perdant attend que la fumee retombe avant d'afficher quoi que ce soit
		var _over = (state == STATE_WIN || state == STATE_LOSE)
		if state != STATE_READY && (!_over || explosionTimer <= 0) {
			var _text, _color;
			if _over {
				_text = (state == STATE_WIN) ? "VICTOIRE" : "DEFAITE"
				_color = (state == STATE_WIN) ? c_white : c_red
			} else {
				_text = "VIRUS : " + string(countViruses()) + "/" + string(NB_INITIAL_VIRUS)
				_color = c_white
			}

			draw_set_halign(fa_center)
			draw_set_valign(fa_bottom)
			draw_set_color(_color)
			draw_text_transformed(boardX + (MAP_LENGTH*TILE_SIZE)/2, boardY - 8, _text, 2, 2, 0)
			draw_set_halign(fa_left)
			draw_set_valign(fa_top)
			draw_set_color(c_white)
		}
	}


	//---------------------------------------------------------
	// Init, une fois les méthodes déclarées
	//---------------------------------------------------------

	board = setupBoard()			//remplit aussi virusPiece
	links = clearLinks()
	fillPreview()					//les prochaines sont connues des l'ecran de preparation
}
