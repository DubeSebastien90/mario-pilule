var press_left = keyboard_check_pressed(vk_left)
var press_right = keyboard_check_pressed(vk_right)

//control pill
if press_left{
	movePlayingPill(0,-1)
	updateBoard()
}

if press_right{
	movePlayingPill(0,1)
	updateBoard()
}


//drop pill
tickCooldown -= 1
if tickCooldown <= 0 {
	tickCooldown = TICK_COOLDOWN
	movePlayingPill(1,0)
	updateBoard()
}