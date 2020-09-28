extends KinematicBody


export var speed = 20
export var air_speed = 20
export var air_acceleration = 1
export var ground_acceleration = 10
export var gravity = 9.8
export var jump = 5
export var jumps = 1

export var mouse_sensitivity = 0.05

var acceleration = 0
var jumps_remaining = 0
var can_turn = true


var grounded = false

#this should point up
var orientation = Vector3(0, 1, 0)
var direction = Vector3()
var velocity = Vector3()
var fall = Vector3()
#this should point down
var snap = Vector3(0, -1, 0)
var snap_vec = Vector3()

var orientation_axis = Vector3()
var orientation_rotation = 0


onready var head = $Head



# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _self_rotate(interpolated_orientation):
	var tween_rot = orientation.angle_to(interpolated_orientation)
	orientation = interpolated_orientation.normalized()
	rotate(orientation_axis, tween_rot / 2)


	
func reorient(oc):
	if oc != orientation:
		can_turn = false
		orientation_rotation = orientation.angle_to(oc)
		orientation_axis = orientation.cross(oc)
		$Tween.interpolate_method(self, '_self_rotate', orientation, oc, 0.5)
		$Tween.start()
		velocity = velocity.rotated(orientation_axis, orientation_rotation)		
		orientation = oc


	
func _input(event):
	
	#handle escaping window with mouse
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == 2:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		if can_turn:
			rotate(orientation, deg2rad(-event.relative.x * mouse_sensitivity))
			head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
			head.rotation.x = clamp(head.rotation.x, deg2rad(-90), deg2rad(90))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	direction = Vector3()
	
	if is_on_floor():
		fall = orientation * -0.8
		acceleration = ground_acceleration
		jumps_remaining = jumps
		snap = (orientation * -1).round()
		snap_vec = snap
		grounded = true
	else:
		fall = -1 * orientation * gravity * delta
		acceleration = air_acceleration
		grounded = false
		


	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x	
		
	direction = direction.normalized()
	
		
	if Input.is_action_just_pressed("jump"):
		print(self.rotation)
		if jumps_remaining > 0:
			snap_vec = Vector3()
			fall = orientation * jump 
			jumps_remaining -= 1
			if not grounded:
				velocity = direction * speed

	
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	velocity += fall
	velocity = move_and_slide_with_snap(velocity, snap_vec, orientation, true)



func _on_Tween_tween_all_completed():
	orientation.round()
	can_turn = true
