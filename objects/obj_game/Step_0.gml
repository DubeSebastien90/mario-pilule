tickCooldown -= 1
if tickCooldown <= 0 {
	tickCooldown = TICK_COOLDOWN
	simulate()
}