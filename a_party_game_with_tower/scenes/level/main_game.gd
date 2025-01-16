extends Node2D

var sounds = preload("res://library/sound.gd").new()

var smoothing_speed := 1.0
var game_time = 0.0 # in seconds

const DIFFDROPPER = 500
const DIFFCAMERA = 0

const SPAWNCHECKPOINT0 = 0
const SPAWNCHECKPOINT1 = -450
const SPAWNCHECKPOINT2 = -1000
var piece_spawn_position_y = SPAWNCHECKPOINT0

var nextPieceNumber = generateRandomNumber()
var buttons = []

@onready var camera = $Camera2D
@onready var beam = $Beam
@onready var isFalling = $pieces/isFalling
@onready var hasFallen = $pieces/hasFallen
@onready var gameTimeLbl = $CanvasLayer/gameTime

func _ready():
	InitializeSound()
	var button_restart = $CanvasLayer/resetButton
	buttons.append(button_restart)
	Global.syncButtonsBottomRight(buttons)

func InitializeSound():
	add_child(sounds)

func _process(delta: float) -> void:
	inst()
	TimeSpent(delta)
	handle_user_input_screen_size()
	updateCamera(delta)
	if is_instance_valid(beam):
		beam.updateBeam(isFalling,beam)

func TimeSpent(delta):
	if is_instance_valid(gameTimeLbl):
		game_time += delta
		gameTimeLbl.text = format_time(game_time)

func format_time(seconds: float) -> String:
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	var millis = int((seconds - int(seconds)) * 1000)
	return "%02d:%02d.%03d" % [minutes, secs, millis]

func handle_user_input_screen_size():
	if Input.is_action_just_pressed("fullscreen"):
		Global.change_screen_mode()
		Global.syncButtonsBottomRight(buttons)

func updateCamera(delta):
	if is_instance_valid(camera):
		camera.position.y = lerp(camera.position.y, getMax(hasFallen), smoothing_speed * delta)

func generateRandomNumber():
	return randi() % Global.pieces.size()  # Sélectionne une pièce aléatoirement

func inst():
	if Global.spawnBloc:
		var pieces_node = $pieces
		var is_falling_node = pieces_node.get_node("isFalling")
		var has_fallen_node = pieces_node.get_node("hasFallen")

		for piece in is_falling_node.get_children():
			is_falling_node.remove_child(piece)
			has_fallen_node.add_child(piece)
		var piece_data = Global.pieces[nextPieceNumber]  # Récupère les données de la pièce
		nextPieceNumber = generateRandomNumber()
		var piece_instance = piece_data["scene"].instantiate()  # Instancie la scène de la pièce
		
		var next_piece_data = Global.pieces[nextPieceNumber]
		display_next_piece(next_piece_data)
		
		var max_height = getMax(hasFallen)
		piece_instance.position = Vector2(540, max_height-DIFFDROPPER)
		piece_instance.set_meta("isFalling", true)
		
		is_falling_node.add_child(piece_instance)
		Global.spawnBloc = false

func display_next_piece(next_piece_data):
	var next_piece_preview_node = $CanvasLayer/nextPiecePreview
	#clean old piece
	for child in next_piece_preview_node.get_children():
		next_piece_preview_node.remove_child(child)
		child.queue_free()
	
	var next_piece_instance = next_piece_data["scene"].instantiate()
	
	for square in next_piece_instance.get_children():
		if square.has_node("TextureRect"):  # Vérifier si le carré a un TextureRect
			var texture_rect = square.get_node("TextureRect")
			
			# Créer un nouveau TextureRect pour la prévisualisation
			var preview_texture = TextureRect.new()
			preview_texture.texture = texture_rect.texture
			preview_texture.position = square.position
			preview_texture.size = texture_rect.size
			preview_texture.scale = Vector2(0.16, 0.16) # TODO - that is hard coded value,
			
			# Ajouter le TextureRect à la zone de prévisualisation
			next_piece_preview_node.add_child(preview_texture)

func getMax(hasFallen: Node2D) -> float:
	var max = 600
	for piece in hasFallen.get_children():
		var corner_list = piece.get_node("border")
		for corner in corner_list.get_children():
			var rotated_position = piece.to_global(corner.position)
			if (rotated_position.y < max):
				max = rotated_position.y
	return max

func _on_reset_button_pressed() -> void:
	for child in hasFallen.get_children():
		child.queue_free()
	game_time = 0.0

func _on_end_area_entered(area: Area2D) -> void:
	if area.get_parent().get_meta("isFalling"):
		return
	for child in self.get_children():
		child.queue_free()
	
	var label = Label.new()
	label.text = "Vous avez gagné en %s !" % format_time(game_time)
	add_child(label)
