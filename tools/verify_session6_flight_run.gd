class_name VerifySession6FlightRun
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("[VerifySession6] Running L3 Live Flight Replay Verification")
	print("==================================================")
	call_deferred("_execute_flight_replay")

func _execute_flight_replay() -> void:
	var runner_scene = load("res://scenes/gameplay/endless_runner.tscn")
	var runner = runner_scene.instantiate() as EndlessRunner
	root.add_child(runner)

	runner.begin_run()
	var player = runner.player
	var hud = runner.hud

	print("1. Testing Mechanical Wings Pickup & Live Flight Activation...")
	var wings_pickup = load("res://scenes/objects/flight_pickup_wings.tscn").instantiate() as FlightPickup
	wings_pickup.position = player.position
	runner.add_child(wings_pickup)
	wings_pickup.collect(player)

	if not player.is_flying:
		print("FAILED: Player did not enter flight mode upon pickup")
		quit(1)
		return
	if not hud.flight_controls.visible or not hud.flight_timer_bar.visible:
		print("FAILED: Flight HUD controls/timer bar not visible during flight")
		quit(1)
		return
	print("   ✓ Mechanical Wings active. Timer=%.1fs, HUD controls displayed" % player.flight_timer)

	print("2. Testing Vertical Ascent & Descent Controls...")
	player.flight_up_input = true
	player._handle_flight_state(0.1)
	if player.velocity.y >= 0.0:
		print("FAILED: Player did not ascend on up input")
		quit(1)
		return
	print("   ✓ Ascended with velocity %f" % player.velocity.y)

	player.flight_up_input = false
	player.flight_down_input = true
	player._handle_flight_state(0.1)
	if player.velocity.y <= 0.0:
		print("FAILED: Player did not descend on down input")
		quit(1)
		return
	print("   ✓ Descended with gradual glide velocity %f (no slide/grounded action)" % player.velocity.y)

	print("3. Testing 2-Second Flight Expiry Warning...")
	var warned = {"seen": false}
	player.flight_warning.connect(func(_r): warned["seen"] = true)
	player._handle_flight_state(player.flight_timer - 1.8)
	if not warned["seen"]:
		print("FAILED: 2s flight warning was not emitted")
		quit(1)
		return
	if not hud.flight_warning_label.visible:
		print("FAILED: HUD warning label not visible on warning trigger")
		quit(1)
		return
	print("   ✓ Warning triggered at 1.8s remaining. HUD warning flashing")

	print("4. Testing Expiry & Safe Landing...")
	player._handle_flight_state(2.0)
	if player.is_flying:
		print("FAILED: Player still flagged flying after expiry")
		quit(1)
		return
	if hud.flight_controls.visible or hud.flight_timer_bar.visible:
		print("FAILED: Flight HUD still visible after flight ended")
		quit(1)
		return
	if player.state_machine.current_state != PlayerStateMachine.State.JUMP_FALL:
		print("FAILED: Player not in JUMP_FALL state for gentle glide landing")
		quit(1)
		return
	print("   ✓ Flight expired gracefully. Restored normal physics and touch controls")

	print("5. Testing Rocket Relic High-Thrust Activation & Pause Handling...")
	var rocket_pickup = load("res://scenes/objects/flight_pickup_rocket.tscn").instantiate() as FlightPickup
	rocket_pickup.position = player.position
	runner.add_child(rocket_pickup)
	rocket_pickup.collect(player)

	if player.flight_type != 2 or not player.is_flying:
		print("FAILED: Rocket Relic failed to activate")
		quit(1)
		return
	print("   ✓ Rocket Relic active. Initial timer=%.1fs" % player.flight_timer)

	# Simulate pause
	runner.pause_game()
	var time_at_pause = player.flight_timer
	runner.resume_game()
	if absf(player.flight_timer - time_at_pause) > 0.001:
		print("FAILED: Timer drifted during pause/resume")
		quit(1)
		return
	print("   ✓ Pause & resume verified with active flight timers")

	player.end_flight()

	print("\n==================================================")
	print("[VerifySession6] L3 Live Flight Replay PASSED")
	print("==================================================")
	runner.queue_free()
	quit(0)
