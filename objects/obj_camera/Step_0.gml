var mx = display_mouse_get_x();
var my = display_mouse_get_y();

var _camW = camW * zoom_ammount;
var _camH = camH * zoom_ammount;



zoom_ammount = lerp(zoom_ammount,zoom_dir,0.1)


if (isDragging) {
    x -= (mx - dragStartX) * zoom_ammount;
    y -= (my - dragStartY) * zoom_ammount;
	
	speedx = mx-dragStartX
	speedy = my-dragStartY
	
    dragStartX = mx;
    dragStartY = my;
	
} else {
	speedx = lerp(speedx,0,0.2)
	speedy = lerp(speedy,0,0.2)
	
	x -= speedx * zoom_ammount;
	y -= speedy * zoom_ammount;
}

//screen shake
var _x = random_range(-shake_remain,shake_remain)*zoom_ammount;
var _y = random_range(-shake_remain,shake_remain)*zoom_ammount;
shake_remain = max(0,shake_remain-((1/shake_lenght)*shake_magnitude));
if shake_lenght <= 0{
	shake_remain = 0
}

camera_set_view_pos(cam,  (x +_x) - _camW / 2, (y + _y) - _camH / 2);
camera_set_view_size(cam, _camW, _camH);