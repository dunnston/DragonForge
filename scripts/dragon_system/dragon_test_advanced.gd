extends Control

# Dragon Phase 2 Test Scene
# Tests all advanced systems: hunger, levels, mutations, AFK mechanics

@onready var dragon_display = %DragonDisplay
@onready var status_label = %StatusLabel
@onready var debug_panel = %DebugPanel

var factory: DragonFactory
var state_manager: DragonStateManager
var test_dragon: Dragon
var part_library: PartLibrary

func _ready():
	print("🧪 Starting Dragon Phase 2 Advanced System Tests")
	
	# Initialize systems
	part_library = PartLibrary.new()
	add_child(part_library)
	
	state_manager = DragonStateManager.new()
	add_child(state_manager)
	
	factory = DragonFactory.new()
	add_child(factory)
	
	# Connect signals for monitoring
	_connect_signals()
	
	# Start tests
	await get_tree().process_frame
	await get_tree().process_frame  # Wait for initialization
	_run_comprehensive_tests()

func _connect_signals():
	if state_manager:
		state_manager.dragon_level_up.connect(_on_dragon_level_up)
		state_manager.dragon_hunger_changed.connect(_on_hunger_changed)
		state_manager.dragon_health_changed.connect(_on_health_changed)
		state_manager.dragon_death.connect(_on_dragon_death)
		state_manager.chimera_mutation_discovered.connect(_on_mutation_discovered)
		state_manager.dragon_state_changed.connect(_on_state_changed)

func _run_comprehensive_tests():
	print("\n=== DRAGON PHASE 2 COMPREHENSIVE TESTS ===")
	
	# Test 1: Create dragon with mutation chance
	_test_dragon_creation()
	await get_tree().create_timer(1.0).timeout
	
	# Test 2: Experience and leveling
	_test_experience_system()
	await get_tree().create_timer(1.0).timeout
	
	# Test 3: State management
	_test_state_management()
	await get_tree().create_timer(1.0).timeout
	
	# Test 4: AFK time simulation
	_test_afk_mechanics()
	await get_tree().create_timer(1.0).timeout
	
	# Test 5: Force mutation (Holy Shit Moment!)
	_test_mutation_system()
	await get_tree().create_timer(1.0).timeout
	
	# Test 6: Death and revival
	_test_death_system()
	
	print("\n✅ All Phase 2 tests completed! Check the results above.")
	_update_status_display()

func _test_dragon_creation():
	print("\n🧪 TEST 1: Dragon Creation & Mutation System")
	
	# Create multiple dragons to try for natural mutation
	for i in range(10):
		var dragon = factory.create_random_dragon()
		if dragon.is_chimera_mutation:
			print("🎉 Natural mutation occurred on attempt %d!" % (i + 1))
			test_dragon = dragon
			state_manager.register_dragon(dragon)
			return
		else:
			factory.remove_dragon(dragon)
	
	# If no natural mutation, create regular dragon
	test_dragon = factory.create_random_dragon()
	state_manager.register_dragon(test_dragon)
	print("✓ Created dragon: %s (Level %d)" % [test_dragon.dragon_name, test_dragon.level])

func _test_experience_system():
	print("\n🧪 TEST 2: Experience & Leveling System")
	
	var initial_level = test_dragon.level
	print("Current level: %d, EXP: %d" % [test_dragon.level, test_dragon.experience])
	
	# Grant experience and test level ups
	for level in range(initial_level + 1, min(initial_level + 4, DragonStateManager.MAX_LEVEL + 1)):
		var exp_needed = state_manager.get_experience_for_level(level)
		test_dragon.experience = exp_needed
		state_manager._check_level_up(test_dragon)
		print("✓ Reached level %d (ATK:%d HP:%d SPD:%d)" % [
			test_dragon.level, test_dragon.total_attack, 
			test_dragon.total_health, test_dragon.total_speed
		])

func _test_state_management():
	print("\n🧪 TEST 3: Dragon State Management")
	
	var states = [
		Dragon.DragonState.TRAINING,
		Dragon.DragonState.EXPLORING,
		Dragon.DragonState.DEFENDING,
		Dragon.DragonState.RESTING,
		Dragon.DragonState.IDLE
	]
	
	for state in states:
		state_manager.set_dragon_state(test_dragon, state)
		await get_tree().create_timer(0.2).timeout

func _test_afk_mechanics():
	print("\n🧪 TEST 4: AFK Mechanics (Time Simulation)")
	
	print("Before time simulation:")
	_print_dragon_status()
	
	# Simulate 2 hours of AFK time
	print("⏰ Simulating 2 hours of AFK time...")
	state_manager.simulate_time_passage(test_dragon, 2.0)
	
	print("After 2 hours AFK:")
	_print_dragon_status()
	
	# Feed dragon to restore health
	print("🍖 Feeding dragon...")
	state_manager.feed_dragon(test_dragon)
	
	print("After feeding:")
	_print_dragon_status()

func _test_mutation_system():
	print("\n🧪 TEST 5: Mutation System (Holy Shit Moment!)")
	
	if test_dragon.is_chimera_mutation:
		print("✓ Dragon is already a Chimera! Stats before mutation:")
		_print_dragon_status()
	else:
		print("🔬 Forcing Chimera mutation...")
		var old_stats = "ATK:%d HP:%d SPD:%d" % [test_dragon.total_attack, test_dragon.total_health, test_dragon.total_speed]
		
		state_manager.force_mutation(test_dragon)
		
		print("✓ Mutation complete! Stats comparison:")
		print("  Before: %s" % old_stats)
		print("  After:  ATK:%d HP:%d SPD:%d" % [test_dragon.total_attack, test_dragon.total_health, test_dragon.total_speed])

func _test_death_system():
	print("\n🧪 TEST 6: Death & Starvation System")
	
	if test_dragon.is_dead:
		print("Dragon is already dead from previous tests")
		return
		
	print("⚰️ Testing death by starvation...")
	
	# Simulate extreme starvation
	state_manager.simulate_time_passage(test_dragon, 10.0)  # 10 hours without food
	test_dragon.current_health = 1  # Low health
	
	print("After extreme starvation:")
	_print_dragon_status()
	
	# Force update to trigger death check
	state_manager.update_dragon_systems(test_dragon)
	
	if test_dragon.is_dead:
		print("💀 Dragon died from starvation as expected")
	else:
		print("⚠️  Dragon survived extreme conditions")

func _print_dragon_status():
	var status = state_manager.get_dragon_status(test_dragon)
	print("  📊 %s | Lvl:%s | %s | Hunger:%s | Fatigue:%s | %s" % [
		status.name, status.level, status.health, 
		status.hunger_level, status.fatigue_level, status.state
	])

func _update_status_display():
	if not status_label or not test_dragon:
		return
		
	var status = state_manager.get_dragon_status(test_dragon)
	var text = """
🐉 DRAGON STATUS 🐉
Name: %s
Level: %d (%d EXP to next)
Health: %s
State: %s
Hunger: %s
Fatigue: %s
Stats: %s
Mutation: %s
Status: %s
""" % [
		status.name,
		status.level,
		status.exp_to_next,
		status.health,
		status.state,
		status.hunger_level,
		status.fatigue_level,
		status.stats,
		"🌟 CHIMERA" if status.is_chimera else "Normal",
		"💀 DEAD" if status.is_dead else "🟢 ALIVE"
	]
	
	status_label.text = text

# Signal handlers for monitoring
func _on_dragon_level_up(dragon: Dragon, new_level: int):
	print("🎉 LEVEL UP! %s reached level %d" % [dragon.dragon_name, new_level])

func _on_hunger_changed(dragon: Dragon, hunger_level: float):
	print("🍖 HUNGER: %s is %.0f%% hungry" % [dragon.dragon_name, hunger_level * 100])

func _on_health_changed(dragon: Dragon, current_health: int, max_health: int):
	print("❤️  HEALTH: %s has %d/%d HP" % [dragon.dragon_name, current_health, max_health])

func _on_dragon_death(dragon: Dragon):
	print("💀 DEATH: %s has died!" % dragon.dragon_name)

func _on_mutation_discovered(dragon: Dragon):
	print("🔥⚡ HOLY SHIT MOMENT! %s MUTATED INTO A CHIMERA! ⚡🔥" % dragon.dragon_name)

func _on_state_changed(dragon: Dragon, old_state: int, new_state: int):
	print("🔄 STATE: %s changed from %s to %s" % [
		dragon.dragon_name,
		_get_state_name(old_state),
		_get_state_name(new_state)
	])

func _get_state_name(state: int) -> String:
	match state:
		Dragon.DragonState.IDLE: return "IDLE"
		Dragon.DragonState.DEFENDING: return "DEFENDING"
		Dragon.DragonState.EXPLORING: return "EXPLORING"
		Dragon.DragonState.TRAINING: return "TRAINING"
		Dragon.DragonState.RESTING: return "RESTING"
		_: return "UNKNOWN"

# Debug controls
func _on_level_up_pressed():
	if test_dragon:
		state_manager.force_level_up(test_dragon)
		_update_status_display()

func _on_feed_pressed():
	if test_dragon:
		state_manager.feed_dragon(test_dragon)
		_update_status_display()

func _on_mutate_pressed():
	if test_dragon:
		state_manager.force_mutation(test_dragon)
		_update_status_display()

func _on_time_skip_pressed():
	if test_dragon:
		state_manager.simulate_time_passage(test_dragon, 1.0)  # Skip 1 hour
		_update_status_display()
