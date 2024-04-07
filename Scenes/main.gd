extends Node

#preload obstacles
var barrel_scene = preload("res://Scenes/barrel.tscn")
var box_scene = preload("res://Scenes/box.tscn")
var stump_scene = preload("res://Scenes/stump.tscn")
var tallrock_scene = preload("res://Scenes/tall_rock.tscn")
var shortrock_scene = preload("res://Scenes/short_rock.tscn")
var hedgehog_scene = preload("res://Scenes/hedgehog.tscn")
var porcupine_scene = preload("res://Scenes/porcupine.tscn")
var raven_scene = preload("res://Scenes/raven.tscn")
var obstacle_types : = [barrel_scene, box_scene, tallrock_scene, shortrock_scene, stump_scene]
var ground_creature_types := [porcupine_scene, hedgehog_scene]
var obstacles: Array
var bird_heights := [200, 390]

#game variables
const FOX_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(576, 324)
var difficulty
const MAX_DIFFICULTY : int = 2
var score : int
const SCORE_MODIFIER : int = 10
var high_score : int
var speed : float
const START_SPEED : float = 10.0
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	new_game()

func new_game():
	#reset variables
	score = 0
	show_score()
	game_running = false
	difficulty = 0
	
	#reset the nodes
	$Fox.position = FOX_START_POS
	$Fox.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
	#reset hud
	$HUD.get_node("StartLabel").show()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_running:
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED :
			speed = MAX_SPEED
		adjust_difficulty()
		
		#generate obstacles
		generate_obs()
		
		#move fox and camera
		$Fox.position.x += speed
		$Camera2D.position.x += speed
		
		#update score
		score += speed
		show_score()
		
		#update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x

		#remove obstacles that have gone off screen
		for obs in obstacles:
			if obs.position.x < ($Camera2D.position.x - screen_size.x):
				remove_obs(obs)

	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func generate_obs():
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			var obs_type = obstacle_types[randi() % obstacle_types.size()]
			var obs = obs_type.instantiate()
			setup_obstacle(obs, i)
			
		if difficulty == 0: #MAX_DIFFICULTY
			if (randi() % 2) == 0:  # Condition for spawning birds
				var obs = raven_scene.instantiate()
				var obs_x = screen_size.x + score + 100
				var obs_y = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func setup_obstacle(obs, i):
	var obs_height
	var obs_scale = obs.scale
	if obs is AnimatedSprite2D:
		var frame_texture = obs.frames.get_frame("default", 0)
		obs_height = frame_texture.get_height() * obs_scale.y
	elif obs.has_node("Sprite2D"):
		obs_height = obs.get_node("Sprite2D").texture.get_height() * obs_scale.y

	var obs_x = screen_size.x + score + 100 + (i * 100)
	var obs_y = screen_size.y - ground_height - (obs_height / 2) + 5
	last_obs = obs
	add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY
	
