extends Node
class_name DialogManager

# Resources
const DIALOG_SCENE = preload("res://Scenes/UI/dialog_scroll.tscn")

# Canvas layer for dialogs
var canvas_layer: CanvasLayer = null
var active_dialogs: Dictionary = {}

func _ready() -> void:
	# Create canvas layer
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	canvas_layer.name = "DialogLayer"
	add_child(canvas_layer)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# Clean up all active dialogs
		for dialog_id in active_dialogs.keys():
			remove_dialog(dialog_id)
      
func create_dialog(owner_id: int, text: String) -> Control:
	if active_dialogs.has(owner_id):
		return active_dialogs[owner_id]
		
	var dialog = DIALOG_SCENE.instantiate()
	canvas_layer.add_child(dialog)
	
	var dialog_label = dialog.get_node_or_null("DialogBox/Label")
	if dialog_label:
		dialog_label.text = text
		
	dialog.visible = false
	active_dialogs[owner_id] = dialog
	return dialog
	
func remove_dialog(owner_id: int) -> void:
	if active_dialogs.has(owner_id):
		if is_instance_valid(active_dialogs[owner_id]):
			active_dialogs[owner_id].queue_free()
		active_dialogs.erase(owner_id)

func has_dialog(owner_id: int) -> bool:
	return active_dialogs.has(owner_id)
