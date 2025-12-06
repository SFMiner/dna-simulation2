extends Camera3D

signal set_mode(camera_mode : bool)


# Target to orbit around
@export var target_path: NodePath
var target: Node3D



# Camera control settings
@export var mouse_sensitivity: float = 0.003
@export var move_speed: float = 0.5  # Units to move per wheel notch
@export var vertical_speed: float = 0.1  # Units to move per frame with arrow keys

# Mode toggle
enum CameraMode { INTERFACE, CAMERA }
var current_mode: CameraMode = CameraMode.INTERFACE

# Camera orbital position (tidally locked satellite)
var orbit_angle: float = 0.0  # Angle around Y-axis
var orbit_radius: float = 10.0  # Distance from Y-axis
var camera_height: float = 5.0  # Height on Y-axis
var pitch: float = 0.0  # Tilt to look up/down the strand

func _ready():
	# Try to get target from exported path
	if target_path:
		target = get_node(target_path)
	
	# Fallback: search for StrandContainer
	if not target:
		target = get_node_or_null("../StrandContainer")
	
	if not target:
		push_error("Camera: Could not find StrandContainer! Set Target Path in inspector.")
		return
	
	print("Camera target set to: ", target.name)
	
	update_camera_position()
	set_interface_mode()

func _process(delta):
	# Only handle camera controls in camera mode
	if current_mode != CameraMode.CAMERA:
		return
	
	# Vertical movement with arrow keys
	if Input.is_action_pressed("ui_up"):
		camera_height += vertical_speed
		update_camera_position()
	if Input.is_action_pressed("ui_down"):
		camera_height -= vertical_speed
		update_camera_position()

func _input(event):
	# Toggle mode with Tab key
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		toggle_mode()
		get_viewport().set_input_as_handled()
	
	# Only handle camera controls in camera mode
	if current_mode != CameraMode.CAMERA:
		return
	
	# Mouse movement
	if event is InputEventMouseMotion:
		# Horizontal: orbit around strand (like satellite revolving)
		orbit_angle -= event.relative.x * mouse_sensitivity * 60.0
		# Vertical: pitch to look up/down the strand
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity * 60.0, -89.0, 89.0)
		update_camera_position()
	
	# Mouse wheel - move forward/backward along view direction
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			move_forward()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			move_backward()

func toggle_mode():
	if current_mode == CameraMode.INTERFACE:
		set_camera_mode()
	else:
		set_interface_mode()

func set_camera_mode():
	set_mode.emit(true)
	current_mode = CameraMode.CAMERA
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	print("Camera Mode: Orbit with mouse, wheel to zoom. Press TAB to return to UI.")
	
func set_interface_mode():
	current_mode = CameraMode.INTERFACE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("Interface Mode: Click buttons to build. Press TAB for camera control.")
	set_mode.emit(false)

func get_look_at_point() -> Vector3:
	# Point on the strand Y-axis we're looking at, based on pitch
	var origin = target.global_position if target else Vector3.ZERO
	# Use pitch to determine height: 0° = camera height, positive = higher, negative = lower
	var look_height = camera_height + orbit_radius * tan(deg_to_rad(pitch))
	return Vector3(origin.x, look_height, origin.z)

func get_forward_direction() -> Vector3:
	# Direction from camera to look-at point
	var look_point = get_look_at_point()
	return (look_point - global_position).normalized()

func move_forward():
	# Move along view direction
	var forward = get_forward_direction()
	var new_pos = global_position + forward * move_speed
	
	# Update orbital parameters from new position
	var origin = target.global_position if target else Vector3.ZERO
	var offset = new_pos - origin
	orbit_radius = Vector2(offset.x, offset.z).length()
	camera_height = new_pos.y
	
	update_camera_position()

func move_backward():
	# Move opposite to view direction
	var forward = get_forward_direction()
	var new_pos = global_position - forward * move_speed
	
	# Update orbital parameters from new position
	var origin = target.global_position if target else Vector3.ZERO
	var offset = new_pos - origin
	orbit_radius = Vector2(offset.x, offset.z).length()
	camera_height = new_pos.y
	
	update_camera_position()

func update_camera_position():
	if not target:
		return
	
	var origin = target.global_position
	
	# Position camera in orbit around Y-axis
	var angle_rad = deg_to_rad(orbit_angle)
	global_position = Vector3(
		origin.x + orbit_radius * sin(angle_rad),
		camera_height,
		origin.z + orbit_radius * cos(angle_rad)
	)
	
	# Look at point on strand determined by pitch
	var look_point = get_look_at_point()
	look_at(look_point, Vector3.UP)
