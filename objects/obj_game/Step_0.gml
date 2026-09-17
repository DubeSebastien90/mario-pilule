var press_left = keyboard_check_pressed(vk_left)
var press_right = keyboard_check_pressed(vk_right)
var press_down = keyboard_check_pressed(vk_down)
var press_rot_cw = keyboard_check_pressed(ord("X"))
var press_rot_ccw = keyboard_check_pressed(ord("Z"))

//control pill
if press_left{
	movePlayingPill(0,-1)
}

if press_right{
	movePlayingPill(0,1)
}

if press_down{
	movePlayingPill(1,0)
	tickCooldown = TICK_COOLDOWN
}

if press_rot_cw{
	rotatePlayingPill(true)
}

if press_rot_ccw{
	rotatePlayingPill(false)
}


//drop pill
tickCooldown -= 1
if tickCooldown <= 0 {
	tickCooldown = TICK_COOLDOWN
	movePlayingPill(1,0)
}

if playingPillA == noone && playingPillB == noone{
	newPillCooldown -= 1
	if newPillCooldown <= 0{
		newPillCooldown = NEW_PILL_COOLDOWN
		spawnPill()
	}
}
