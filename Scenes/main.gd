extends Node

@onready var http_request = $HTTPRequest
@onready var score_value = $HUD/ScoreLabel
@onready var highscore_value = $HUD/HighScoreLabel


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
var high_score : int = 0
var speed : float
const START_SPEED : float = 10.0
const MAX_SPEED : int = 25
const SPEED_MODIFIER : int = 5000
var screen_size : Vector2i
var ground_height : int
var game_running : bool
var last_obs

var URL = "https://quantum-arcade.com/psp/addscore.php"
var dict = {}
var gameID = 3
var userID: int = 1 :
	set(value):
		userID = value


# Called when the node enters the scene tree for the first time.
func _ready():
	http_request.request("http://localhost/quantum-arcade/php/api.php")	
	screen_size = get_window().size
	ground_height = $Ground.get_node("Sprite2D").texture.get_height()
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()

func new_game():
	#reset variables
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	difficulty = 0
	
	# Stop the game over theme music if it's playing
	var game_over_audio = get_node("GameOver_Theme")
	if game_over_audio and game_over_audio.playing:
		game_over_audio.stop()
		
# reset the bgm from the beginning
	var bgm = $Foxbound_maintheme
	bgm.stop() #stop music
	bgm.play() #start music again
	
	#delete all obstacles
	for obs in obstacles:
		obs.queue_free()
	obstacles.clear()
	
	#reset the nodes
	$Fox.position = FOX_START_POS 
	$Fox.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
	#reset hud and game over screen
	$HUD.get_node("StartLabel").show()
	$HUD.get_node("Title").show()
	$GameOver.hide()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_running:
		#speed up and adjust difficulty
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
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
			$HUD.get_node("Title").hide()

func _on_request_completed(result, response_code, headers, body):
	var userID = body.get_string_from_utf8()
	if (userID != null):
		userID = userID

func generate_obs():
	#generate ground obstacles
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 100)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2) + 5
			last_obs = obs
			add_obs(obs, obs_x, obs_y)
			
		#additionally random chance to spawn a bird
		if difficulty == MAX_DIFFICULTY:
			if (randi() % 2) == 0:
				#generate bird obstacles
				obs = raven_scene.instantiate()
				var obs_x : int = screen_size.x + score + 100
				var obs_y : int = bird_heights[randi() % bird_heights.size()]
				add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2i(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)
	
func hit_obs(body):
	if body.name == "Fox":
		game_over()

func show_score():
	$HUD.get_node("ScoreLabel").text = "SCORE: " + str(score / SCORE_MODIFIER)

func check_high_score():
	if score > high_score:
		high_score = score
		$HUD.get_node("HighScoreLabel").text = "HIGH SCORE: " + str(high_score / SCORE_MODIFIER)

func adjust_difficulty():
	difficulty = score / SPEED_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	check_high_score()
	get_tree().paused = true
	game_running = false
	
	dict = {"userID":userID, "gameID":gameID, "score":score}
	if (score > high_score):
		high_score = score
		
	score_value.text = str(score)
	highscore_value.text = str(high_score)
	_make_post_request(URL, dict, false)
	
	# Directly access and play the GameOver_Theme AudioStreamPlayer
	var game_over_audio = get_node("GameOver_Theme")
	if game_over_audio:
		game_over_audio.play()
	# Show the game over screen
	get_node("GameOver").show()
	
func _make_post_request(url, data_to_send, use_ssl):
		var query = JSON.stringify(data_to_send)
		var headers = ["Content-Type: application/json"]
		http_request.request(url, headers, HTTPClient.METHOD_POST, query)
