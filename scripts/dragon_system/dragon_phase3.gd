extends Dragon
class_name DragonPhase3

# Phase 3: Dragon Combat Interface & Exploration Systems
# Built on top of Phase 1 (core systems) and Phase 2 (state management)
#
# NOTE: All constants, properties, and signals are inherited from the base Dragon class.
# The Dragon class already includes:
# - Combat constants (FATIGUE_PER_COMBAT, COMBAT_XP_BASE, etc.)
# - Exploration properties (exploration_start_time, exploration_duration)
# - Combat/exploration signals (assignment_changed, exploration_started, exploration_completed)

func _init(head: DragonPart = null, body: DragonPart = null, tail: DragonPart = null):
	super(head, body, tail)  # Call parent Dragon._init()

# ===== PHASE 3: COMBAT INTERFACE =====
