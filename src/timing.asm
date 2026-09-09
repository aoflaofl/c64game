; Frame synchronisation. frame_counter is bumped once per frame by raster_irq;
; the main loop compares it against last_frame to run exactly one game_tick
; per displayed frame.

frame_counter:  !byte 0
last_frame:     !byte 0
