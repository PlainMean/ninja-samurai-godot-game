extends Button
## One activation on a fresh down; no built-in pressed signal is connected.
signal activated
static var pointer_owner: Button = null
var pointer_id := -2

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func cancel_pointer() -> void:
	if pointer_owner == self:
		pointer_owner = null
	pointer_id = -2
	set_pressed_no_signal(false)

func _exit_tree() -> void:
	cancel_pointer()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.canceled or not event.pressed:
			if pointer_id == event.index:
				cancel_pointer()
		elif get_global_rect().has_point(event.position):
			_accept_down(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			if pointer_id == -1:
				cancel_pointer()
		elif get_global_rect().has_point(event.position):
			_accept_down(-1)

func _accept_down(index: int) -> void:
	if not is_visible_in_tree() or pointer_owner != null:
		return
	# Even a disabled down owns the pointer until release, so enabling cannot fire it.
	pointer_owner = self
	pointer_id = index
	if not disabled:
		set_pressed_no_signal(true)
		activated.emit()
