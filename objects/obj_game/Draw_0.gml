if menuActive {
	draw_set_halign(fa_center)
	draw_set_valign(fa_middle)

	draw_set_color(c_white)
	draw_text_transformed(room_width/2, buttons[0].y - 80, "DR MARIO", 3, 3, 0)

	for(var b = 0; b < array_length(buttons); b++){
		var _b = buttons[b]
		var _hover = buttonHovered(_b)

		draw_set_color(_hover ? c_white : c_gray)
		draw_rectangle(_b.x, _b.y, _b.x + BUTTON_W, _b.y + BUTTON_H, true)

		draw_set_color(_hover ? c_yellow : c_white)
		draw_text_transformed(_b.x + BUTTON_W/2, _b.y + BUTTON_H/2, _b.text, 2, 2, 0)
	}

	draw_set_color(c_gray)
	draw_text(room_width/2, buttons[array_length(buttons)-1].y + BUTTON_H + 48, "1 / 2 / 3 au clavier")

	draw_set_halign(fa_left)
	draw_set_valign(fa_top)
	draw_set_color(c_white)
	exit;
}

for(var g = 0; g < array_length(games); g++){
	games[g].draw()
}

if showPhoto{
	draw_sprite_ext(spr_photo, 0, photoX, photoY, photoScale, photoScale, 0, c_white, 1)
}


//bouton de retour au menu, une fois la partie finie
if gamesFinished(){
	var _hover = rectHovered(BACK_X, BACK_Y, BACK_W, BACK_H)

	draw_set_halign(fa_center)
	draw_set_valign(fa_middle)

	//fond plein : le bouton passe par dessus le plateau du centre
	draw_set_color(c_black)
	draw_rectangle(BACK_X, BACK_Y, BACK_X + BACK_W, BACK_Y + BACK_H, false)

	draw_set_color(_hover ? c_white : c_gray)
	draw_rectangle(BACK_X, BACK_Y, BACK_X + BACK_W, BACK_Y + BACK_H, true)

	draw_set_color(_hover ? c_yellow : c_white)
	draw_text(BACK_X + BACK_W/2, BACK_Y + BACK_H/2, "BACK TO MENU")

	draw_set_halign(fa_left)
	draw_set_valign(fa_top)
	draw_set_color(c_white)
}
