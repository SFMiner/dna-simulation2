extends Node3D

# Constants for helix structure
const NUCLEOTIDE_OFFSET = Vector3(-0.067, 1.484, 0.864)
const ROTATION_STEP = 36.0



# Nucleotide scene paths
const NUCLEOTIDE_SCENES = {
	"adenine": "res://adenine.tscn",
	"thymine": "res://thymine.tscn",
	"guanine": "res://guanine.tscn",
	"cytosine": "res://cytosine.tscn"
}

# References
@onready var strand_container: Node3D = $StrandContainer
@onready var ui = $UI
@onready var camera = $Camera3D

# Track the growing strand
var last_nucleotide: Node3D = null
var camera_start_pos : Vector3
var camera_start_rot

func _ready():
	# Connect UI signals
	ui.reset_level_requested.connect(_on_reset_level_requested)
	ui.nucleotide_requested.connect(_on_nucleotide_requested)
	ui.clear_strand_requested.connect(_on_clear_strand_requested)
	camera_start_pos = camera.position
	camera_start_rot = camera.rotation
	
func _on_nucleotide_requested(base_type: String):
	print("Received request for: ", base_type)
	spawn_nucleotide(base_type)

func spawn_nucleotide(base_type: String):
	# Load the nucleotide scene
	var scene_path = NUCLEOTIDE_SCENES.get(base_type)
	if scene_path == null:
		push_error("Unknown nucleotide type: " + base_type)
		return
	
	var nucleotide_scene = load(scene_path)
	var new_base = nucleotide_scene.instantiate()
	
	if last_nucleotide == null:
		# First nucleotide - add to strand container at origin
		strand_container.add_child(new_base)
		new_base.position = Vector3.ZERO
	else:
		# Parent to previous nucleotide
		last_nucleotide.add_child(new_base)
		new_base.position = NUCLEOTIDE_OFFSET
		new_base.rotation.y = deg_to_rad(ROTATION_STEP)
	
	last_nucleotide = new_base

func _on_clear_strand_requested():
	clear_strand()

func _on_reset_level_requested():
	print("_on_rest_level")
	reset_level()

func reset_level():
	print("rest_level")
	camera.position = camera_start_pos
	camera.rotation = camera_start_rot
	clear_strand()

func clear_strand():
	# Remove all children from strand container
	for child in strand_container.get_children():
		child.queue_free()
	
	last_nucleotide = null
