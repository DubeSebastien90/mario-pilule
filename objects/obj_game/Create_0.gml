randomise()
TILE_SIZE = 32

MAP_HEIGHT = 16
MAP_LENGTH = 8

EMPTY_TILE = 0
BLUE_PILL = 1
RED_PILL = 2
YELLOW_PILL = 3

BLUE_VIRUS = 4
RED_VIRUS = 5
YELLOW_VIRUS = 6

NB_INITIAL_VIRUS = 9

//lien d'une case vers l'autre moitié de sa pilule
LINK_NONE = 0
LINK_LEFT = 1
LINK_RIGHT = 2
LINK_UP = 3
LINK_DOWN = 4

board = setupBoard()
links = clearLinks()

//phases de jeu
STATE_CONTROL = 0		//le joueur dirige la pilule
STATE_CLEARING = 1		//les tuiles condamnées clignotent avant de disparaître
STATE_FALLING = 2		//ce qui n'est plus soutenu descend d'une rangée par tic
STATE_SPAWN = 3			//petit délai avant la pilule suivante
STATE_WIN = 4			//plus aucun virus
STATE_LOSE = 5			//la pilule ne peut plus apparaître

state = STATE_SPAWN
stateTimer = 0

TICK_COOLDOWN = 30		//descente de la pilule dirigée
tickCooldown = TICK_COOLDOWN

DOWN_COOLDOWN_FIRST = 20
downCooldown = 0
goingFast = false
DOWN_COOLDOWN_FAST = 5

CLEAR_COOLDOWN = 30		//durée du clignotement
NEW_PILL_COOLDOWN = 30

//cases condamnées en attente d'effacement, noone hors de STATE_CLEARING
marks = noone

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

//les virus et les cases vides n'ont aucun lien
function clearLinks(){
	var _links = noone
	for(var i = 0; i < MAP_HEIGHT; i++){
		for(var j = 0; j < MAP_LENGTH; j++){
			_links[i][j] = LINK_NONE
		}
	}
	return _links
}

//lien qui pointe de (_fi,_fj) vers (_ti,_tj), deux cases forcement adjacentes
function linkBetween(_fi, _fj, _ti, _tj){
	if _tj > _fj return LINK_RIGHT;
	if _tj < _fj return LINK_LEFT;
	if _ti > _fi return LINK_DOWN;
	return LINK_UP;
}

//casse le lien de la case et celui de son partenaire, qui devient une moitié orpheline
function breakLink(_i, _j){
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

function setupBoard(){
	var _board = clearBoard()
	for (var n = 0; n < NB_INITIAL_VIRUS; n++){
		var _i = MAP_HEIGHT - irandom(5) - 1
		var _j = irandom(MAP_LENGTH-1)
		while _board[_i][_j] != EMPTY_TILE{
			_i = MAP_HEIGHT - irandom(5) - 1
			_j = irandom(MAP_LENGTH-1)
		}
		_board[_i][_j] = BLUE_VIRUS + n%3
	}
	return _board
}

function spawnPill(){
	//défaite : la zone d'apparition est bouchée
	if !cellIsFree(0, (MAP_LENGTH/2)-1) || !cellIsFree(0, MAP_LENGTH/2) {
		state = STATE_LOSE
		exit;
	}

	playingPillA = new Pill(0,(MAP_LENGTH/2)-1,choose(1,2,3))
	playingPillB = new Pill(0,MAP_LENGTH/2,choose(1,2,3))
	tickCooldown = TICK_COOLDOWN
	state = STATE_CONTROL
}

function dropPillOnBoard(){
	board[playingPillA.i][playingPillA.j] = playingPillA.color
	board[playingPillB.i][playingPillB.j] = playingPillB.color

	//les deux moitiés restent liées tant qu'aucune n'est détruite
	links[playingPillA.i][playingPillA.j] = linkBetween(playingPillA.i, playingPillA.j, playingPillB.i, playingPillB.j)
	links[playingPillB.i][playingPillB.j] = linkBetween(playingPillB.i, playingPillB.j, playingPillA.i, playingPillA.j)

	playingPillA = noone
	playingPillB = noone
	startResolving()
}

//nombre de virus encore sur le plateau
function countViruses(){
	var _n = 0
	for(var i = 0; i < MAP_HEIGHT; i++){
		for(var j = 0; j < MAP_LENGTH; j++){
			if board[i][j] > YELLOW_PILL _n += 1
		}
	}
	return _n
}

//cherche des suites : clignotement si on en trouve, sinon pilule suivante
function startResolving(){
	marks = findWinningTiles()
	if marks != noone {
		state = STATE_CLEARING
		stateTimer = CLEAR_COOLDOWN
	} else if countViruses() == 0 {
		//victoire seulement une fois le plateau stabilisé, après l'animation
		state = STATE_WIN
	} else {
		state = STATE_SPAWN
		stateTimer = NEW_PILL_COOLDOWN
	}
}

//true si la case est dans le plateau et libre
function cellIsFree(_i, _j){
	if _j < 0 || _j >= MAP_LENGTH return false;
	if _i >= MAP_HEIGHT return false;
	if _i < 0 return true;				//au-dessus du plateau = toléré au spawn
	return board[_i][_j] == EMPTY_TILE;
}

function rotatePlayingPill(_clockwise){
	if playingPillA == noone || playingPillB == noone exit;

	//offset actuel du pivot (A) vers B
	var _di = playingPillB.i - playingPillA.i;
	var _dj = playingPillB.j - playingPillA.j;

	//rotation du vecteur (i grandit vers le bas)
	var _ni, _nj;
	if _clockwise {
		_ni =  _dj;  _nj = -_di;
	} else {
		_ni = -_dj;  _nj =  _di;
	}

	var _ai = playingPillA.i,	_aj = playingPillA.j;
	var _bi = _ai + _ni,		_bj = _aj + _nj;

	//wall kick : tel quel, puis décalé à gauche, puis à droite
	var _kicks = [0, -1, 1];
	for(var k = 0; k < array_length(_kicks); k++){
		var _o = _kicks[k];
		if cellIsFree(_ai, _aj + _o) && cellIsFree(_bi, _bj + _o){
			playingPillA.i = _ai;	playingPillA.j = _aj + _o;
			playingPillB.i = _bi;	playingPillB.j = _bj + _o;
			exit;
		}
	}
	//aucune position valide -> rotation refusée
}

function movePlayingPill(_i, _j){
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

//cherche les suites de 4+ tuiles de même couleur (lignes et colonnes)
//retourne le tableau des cases condamnées, ou noone s'il n'y a rien
function findWinningTiles(){
	//tableau de marquage, pour effacer seulement après avoir tout scanné
	var _marks = noone
	//couleur de chaque case : un virus compte comme la pilule de même couleur
	var _colors = noone
	for(var i = 0; i < MAP_HEIGHT; i++){
		for(var j = 0; j < MAP_LENGTH; j++){
			_marks[i][j] = false
			var _t = board[i][j]
			_colors[i][j] = (_t > YELLOW_PILL) ? _t - YELLOW_PILL : _t
		}
	}

	//suites horizontales
	for(var i = 0; i < MAP_HEIGHT; i++){
		var _runStart = 0
		for(var j = 1; j <= MAP_LENGTH; j++){
			var _same = (j < MAP_LENGTH) && (_colors[i][j] == _colors[i][_runStart]) && (_colors[i][j] != EMPTY_TILE)
			if !_same {
				if _colors[i][_runStart] != EMPTY_TILE && (j - _runStart) >= 4 {
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
					for(var k = _runStart; k < i; k++){
						_marks[k][j] = true
					}
				}
				_runStart = i
			}
		}
	}

	//rien trouvé : on ne renvoie pas un tableau vide, plus simple à tester
	var _found = false
	for(var i = 0; i < MAP_HEIGHT && !_found; i++){
		for(var j = 0; j < MAP_LENGTH && !_found; j++){
			if _marks[i][j] _found = true
		}
	}
	if !_found return noone;

	return _marks
}

//efface les cases marquées, en cassant les liens des moitiés survivantes
function applyWinningTiles(_marks){
	if _marks == noone exit;
	for(var i = 0; i < MAP_HEIGHT; i++){
		for(var j = 0; j < MAP_LENGTH; j++){
			if _marks[i][j] {
				breakLink(i, j)
				board[i][j] = EMPTY_TILE
			}
		}
	}
}

//deplace une tuile et son lien vers une case vide
function moveTile(_fi, _fj, _ti, _tj){
	board[_ti][_tj] = board[_fi][_fj]
	links[_ti][_tj] = links[_fi][_fj]
	board[_fi][_fj] = EMPTY_TILE
	links[_fi][_fj] = LINK_NONE
}

//true si la case peut accueillir une tuile qui tombe
function canFallInto(_i, _j){
	if _i >= MAP_HEIGHT return false;
	return board[_i][_j] == EMPTY_TILE;
}

//descend d'une rangée tout ce qui n'est plus soutenu
//retourne true si au moins une unité a bougé
function applyGravityStep(){
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

//dessine une tuile du plateau, _x et _y etant le coin haut-gauche de la case
function drawTile(_tile, _link, _x, _y){
	var _frame = _tile
	var _angle = 0
	if _tile > YELLOW_PILL {
		//virus : jamais tourné
	} else if _link == LINK_NONE {
		_frame = _tile + 6				//moitié orpheline, ronde des deux côtés
	} else {
		_angle = linkAngle(_link)		//moitié liée, bord plat vers le partenaire
	}
	draw_sprite_ext(spr_square, _frame, _x + TILE_SIZE/2, _y + TILE_SIZE/2, 1, 1, _angle, c_white, 1)
}
