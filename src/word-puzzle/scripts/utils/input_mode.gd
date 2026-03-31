## input_mode.gd
## Input mode enum. Determined by the currently active input device.
class_name InputMode


enum Type {
	TOUCH,   ## Mobile touchscreen (drag + tap).
	MOUSE,   ## PC mouse (click + drag).
	DPAD,    ## TV/console D-pad (focus navigation).
}
