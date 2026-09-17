var press_left = keyboard_check_pressed(vk_left)
var press_right = keyboard_check_pressed(vk_right)
var rotate_up = keyboard_check_pressed(vk_up)
var rotate_down = false
var press_down =  keyboard_check(vk_down)

switch(state){

	//le joueur dirige la pilule
	case STATE_CONTROL:
		if press_left	movePlayingPill(0,-1)
		if press_right	movePlayingPill(0,1)

		//descente manuelle : on relance le tic pour ne pas enchainer deux descentes
		if press_down{
			downCooldown -= 1
			if downCooldown <= 0 || !goingFast{
				movePlayingPill(1,0)
				tickCooldown = TICK_COOLDOWN
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

		if rotate_up	rotatePlayingPill(true)
		if rotate_down	rotatePlayingPill(false)

		//descente automatique, peut poser la pilule et changer d'état
		tickCooldown -= 1
		if tickCooldown <= 0 {
			tickCooldown = TICK_COOLDOWN
			movePlayingPill(1,0)
		}
		break

	//les tuiles condamnées clignotent, puis on les efface
	case STATE_CLEARING:
		stateTimer -= 1
		if stateTimer <= 0 {
			applyWinningTiles(marks)
			marks = noone
			state = STATE_FALLING
			stateTimer = TICK_COOLDOWN
		}
		break

	//une rangée de chute par tic, jusqu'à ce que plus rien ne bouge
	case STATE_FALLING:
		stateTimer -= 1
		if stateTimer <= 0 {
			stateTimer = TICK_COOLDOWN
			//plus rien ne tombe : on recherche des suites, d'où les cascades
			if !applyGravityStep() startResolving()
		}
		break

	//délai avant la pilule suivante
	case STATE_SPAWN:
		stateTimer -= 1
		if stateTimer <= 0 spawnPill()
		break

	//états terminaux : plus rien ne tourne
	case STATE_WIN:
	case STATE_LOSE:
		break
}
