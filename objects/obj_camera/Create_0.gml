// Create Event
cam          = view_camera[0];
camW         = room_width;
camH         = room_height;
x            = room_width  / 2;
y            = room_height / 2 - 20;
zoom_ammount = 0.75;
zoom_dir = zoom_ammount;
isDragging   = false;
dragStartX   = 0;
dragStartY   = 0;

speedx = 0
speedy = 0

view_enabled    = true;
view_visible[0] = true;

//shake
shake_magnitude = 0;
shake_remain = 0;
shake_lenght = 0;