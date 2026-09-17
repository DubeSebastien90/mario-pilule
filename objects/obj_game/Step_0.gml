//commandes
if keyboard_check_pressed(vk_tab){
	window_set_fullscreen(!window_get_fullscreen())
}

if menuActive {
	var _click = mouse_check_button_pressed(mb_left)

	for(var b = 0; b < array_length(buttons); b++){
		if _click && buttonHovered(buttons[b]){
			startGame(buttons[b].mode)
			break
		}
	}

	//raccourcis clavier : 1, 2, 3
	if keyboard_check_pressed(ord("1")) startGame(MODE_SOLO)
	if keyboard_check_pressed(ord("2")) startGame(MODE_DUO)
	if keyboard_check_pressed(ord("3")) startGame(MODE_DUO_TEST)

	exit;
}

//les morceaux en vol avancent quel que soit l'etat des parties
if photo != noone photo.step()

//partie finie : le bouton de retour devient cliquable
if gamesFinished(){
	if mouse_check_button_pressed(mb_left) && rectHovered(BACK_X, BACK_Y, BACK_W, BACK_H){
		backToMenu()
		exit;
	}
	if keyboard_check_pressed(vk_escape){
		backToMenu()
		exit;
	}
}

for(var g = 0; g < array_length(games); g++){
	games[g].step()
}