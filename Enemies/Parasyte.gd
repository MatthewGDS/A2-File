extends KinematicBody2D

const EnemyDeathEffect = preload("res://Effects/EnemyDeathEffect.tscn")

export var ACCELERATION = 300
export var MAX_SPEED = 50
export var FRICTION = 200
export var WANDER_TARGET_RANGE = 4

enum {
	IDLE,
	WANDER,
	CHASE
}

var velocity = Vector2.ZERO
var knockback = Vector2.ZERO

var state = CHASE
var STATE = "Idle"

onready var sprite = $Sprite
onready var stats = $Stats
onready var playerDetectionZone = $PlayerDetectionZone
onready var hurtbox = $Hurtbox
onready var softCollision = $SoftCollision
onready var wanderController = $WanderController
onready var blinkanimationPlayer = $BlinkAnimationPlayer
onready var animationPlayer = $AnimationPlayer

func _ready():
	state = pick_random_state([IDLE, WANDER])

func _physics_process(delta):	
	var player = get_parent().get_node("Player")
	var direction = (player.position - self.position).normalized()
	if STATE == "Chase":
		knockback = knockback.move_toward(Vector2.ZERO, FRICTION * delta)
		knockback = move_and_slide(knockback)
		get_node("AnimationPlayer").play("Run")
		if direction.x > 0:
			get_node("Sprite").flip_h = false
		else:
			get_node("Sprite").flip_h = true
	elif STATE == "Attack":
		if direction.x > 0:
			get_node("AnimationPlayer").play("Attack")
		else:	
			get_node("AnimationPlayer").play("Attack Left")
			
	elif STATE == "Idle":
		get_node("AnimationPlayer").play("Idle")
	
	match state:
		IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
			seek_player()			
			if wanderController.get_time_left() == 0:
				update_wander()
		
		WANDER:
			seek_player()
			if wanderController.get_time_left() == 0:
				update_wander()			
			accelerate_towards_point(wanderController.target_position, delta)			
			if global_position.distance_to(wanderController.target_position) <= WANDER_TARGET_RANGE:
				update_wander()
			else:
				STATE = "Run"
				
		CHASE:
			if player != null:
				accelerate_towards_point(player.global_position, delta)
			else:
				STATE = "Run"	
			
	if softCollision.is_colliding():
		velocity += softCollision.get_push_vector() * delta * 400		
	velocity = move_and_slide(velocity)
	
	
func _on_DetectPlayer_body_entered(body):
	if (body.name == "Player"):
		STATE = "Chase"
		
func _on_DetectPlayer_body_exited(body):
	if (body.name == "Player"):
		STATE = "Idle"
		
func _on_AttackRange_body_entered(body):
	if (body.name == "Player"):
		STATE = "Attack"
		
func _on_AttackRange_body_exited(body):
	if (body.name == "Player"):
		STATE = "Chase"
		
	
func accelerate_towards_point(point, delta):
	var direction = global_position.direction_to(point)
	velocity = velocity.move_toward(direction * MAX_SPEED, ACCELERATION * delta)
	sprite.flip_h = velocity.x < 0
			
func seek_player():
	if playerDetectionZone.can_see_player():
		state = CHASE
		
func update_wander():
	state = pick_random_state([IDLE, WANDER])
	wanderController.start_wander_timer(rand_range(1, 3))
		
func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func _on_Hurtbox_area_entered(area):
	stats.health -= area.damage
	knockback = area.knockback_vector * 150
	hurtbox.create_hit_effect()
	hurtbox.start_invincibility(0.4)

func _on_Stats_no_health():
	queue_free()
	var enemyDeathEffect = EnemyDeathEffect.instance()
	get_parent().add_child(enemyDeathEffect)
	enemyDeathEffect.global_position = global_position


func _on_Hurtbox_invincibility_started():
	blinkanimationPlayer.play("Start")

func _on_Hurtbox_invincibility_ended():
	blinkanimationPlayer.play("Stop")

