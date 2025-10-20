extends Dragon
class_name DragonPhase3

# Phase 3: Dragon Combat Interface & Exploration Systems
# Built on top of Phase 1 (core systems) and Phase 2 (state management)

# Phase 3: Additional constants (inherits base constants from Dragon class)

# Phase 3: Combat Constants
const FATIGUE_PER_COMBAT: float = 0.1  # 10% fatigue per battle
const FATIGUE_RECOVERY_RATE: float = 0.05  # 5% per minute when idle
const COMBAT_XP_BASE: int = 10  # Base XP per victory
const EXPLORATION_FATIGUE = {
	15: 0.15,  # 15min = 15% fatigue
	30: 0.25,  # 30min = 25% fatigue
	60: 0.40   # 60min = 40% fatigue
}
const FATIGUE_THRESHOLD: float = 0.8  # Auto-remove at 80%+ fatigue

# Phase 3: Additional Properties (inherits core properties from Dragon)
@export var exploration_start_time: int = 0
@export var exploration_duration: int = 0

# Phase 3: New Signals for Combat & Exploration (inherits base signals from Dragon)
signal assignment_changed(dragon: DragonPhase3, old_state: DragonState, new_state: DragonState)
signal exploration_started(dragon: DragonPhase3, duration_minutes: int)
signal exploration_completed(dragon: DragonPhase3)

func _init(head: DragonPart = null, body: DragonPart = null, tail: DragonPart = null):
	super(head, body, tail)  # Call parent Dragon._init()
# ===== PHASE 3: COMBAT INTERFACE =====
