extends CanvasLayer

signal reset_level_requested()
signal nucleotide_requested(base_type: String)
signal clear_strand_requested()

@onready var instruction_label : Label = %Instruction
@onready var main_scene : Node3D = get_parent()
@onready var camera : Camera3D = get_parent().get_node_or_null("Camera3D") 


const CAMERA_OFF_INSTRUCTIONS : String = "Press buttons to left to add nucleotides.\nPress 'Tab' to enter Camera mode."

const CAMERA_ON_INSTRUCTIONS : String = "Press 'Tab' to exit Camera mode and return to UI mode."


func _ready():
	print("UI is visible: ", visible)
	print("UI layer: ", layer)
	camera.set_mode.connect(_on_mode_switch)
	instruction_label.text = CAMERA_OFF_INSTRUCTIONS

func _on_mode_switch(camera_mode : bool):
	switch_mode(camera_mode)
	
func switch_mode(camera_mode : bool):
	if camera_mode: 
		instruction_label.text = CAMERA_ON_INSTRUCTIONS	
	else:
		instruction_label.text = CAMERA_OFF_INSTRUCTIONS

	
func _on_btn_adenine_pressed() -> void:
	nucleotide_requested.emit("adenine")


func _on_btn_guanine_pressed() -> void:
	nucleotide_requested.emit("guanine")


func _on_btn_cytosine_pressed() -> void:
	nucleotide_requested.emit("cytosine")


func _on_btn_thymine_pressed() -> void:
	nucleotide_requested.emit("thymine")

func _on_btn_clear_pressed() -> void:
	clear_strand_requested.emit()


func _on_btn_reset_pressed() -> void:
	print("_on_btn_reset_pressed!")
	reset_level_requested.emit()
