extends CharacterBody2D

const GRAVITY : int = 4200
const JUMP_SPEED : int = -1500

# Called every frame. 'Delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	velocity.y += GRAVITY * delta
	if is_on_floor():
		if not get_parent().game_running:
			$AnimatedSprite2D.play("idle")
		else:
			$RunCol.disabled = false
			if Input.is_action_pressed("ui_accept"):
				velocity.y = JUMP_SPEED
				$JumpCol.disabled = false
				$RunCol.disabled = true
				$JumpSound.play()
			else:
					$AnimatedSprite2D.play("run")
					$JumpCol.disabled = true
	else:
		$AnimatedSprite2D.play("jump")
	move_and_slide()
