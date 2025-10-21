# Factory Manager Scientist UI Update Guide

## Step-by-Step Instructions for Updating factory_manager.tscn

### Part 1: Update the Scene in Godot Editor

1. **Open factory_manager.tscn in Godot**
   - Navigate to `scenes/ui/factory_manager.tscn`
   - Double-click to open in the editor

2. **Delete the old scientist panels**
   - In the Scene tree, find `MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox`
   - Select `BreederPanel` and press Delete
   - Select `TrainerPanel` and press Delete
   - Select `CaretakerPanel` and press Delete

3. **Add the first ScientistPanel (Stitcher)**
   - Right-click on `ScientistsVBox`
   - Choose "Instantiate Child Scene"
   - Navigate to `scenes/ui/scientist_panel.tscn` and click "Open"
   - With the new panel selected:
     - In the Scene tree, rename it to `StitcherPanel`
     - In the Inspector, under "Node":
       - Check ☑ "Unique Name in Owner" (this makes it accessible via %)
     - Under "Script Variables":
       - Set `Scientist Type` to `0` (STITCHER)
     - Click "Move Up" until it's right below the "Title" label

4. **Add the second ScientistPanel (Caretaker)**
   - Right-click on `ScientistsVBox` again
   - Choose "Instantiate Child Scene"
   - Select `scenes/ui/scientist_panel.tscn`
   - With the new panel selected:
     - Rename to `CaretakerPanel`
     - Check ☑ "Unique Name in Owner"
     - Set `Scientist Type` to `1` (CARETAKER)

5. **Add the third ScientistPanel (Trainer)**
   - Right-click on `ScientistsVBox` again
   - Choose "Instantiate Child Scene"
   - Select `scenes/ui/scientist_panel.tscn`
   - With the new panel selected:
     - Rename to `TrainerPanel`
     - Check ☑ "Unique Name in Owner"
     - Set `Scientist Type` to `2` (TRAINER)

6. **Add the Hire Modal**
   - In the Scene tree, select the root `FactoryManager` node
   - Right-click → "Instantiate Child Scene"
   - Select `scenes/ui/scientist_hire_modal.tscn`
   - With the modal selected:
     - Rename to `ScientistHireModal`
     - Check ☑ "Unique Name in Owner"
     - In Inspector → Visibility → Set `Visible` to OFF (uncheck it)

7. **Save the scene** (Ctrl+S)

### Part 2: Update factory_manager.gd Script

Now update the code in `scripts/ui/factory_manager.gd`:

#### Step 2.1: Replace scientist panel references (lines 18-24)

**FIND:**
```gdscript
# === UI ELEMENTS - Scientists ===
@onready var breeder_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/BreederPanel
@onready var breeder_status: Label = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/BreederPanel/VBox/StatusLabel
@onready var trainer_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/TrainerPanel
@onready var trainer_status: Label = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/TrainerPanel/VBox/StatusLabel
@onready var caretaker_panel: PanelContainer = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/CaretakerPanel
@onready var caretaker_status: Label = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/CaretakerPanel/VBox/StatusLabel
```

**REPLACE WITH:**
```gdscript
# === UI ELEMENTS - Scientists ===
@onready var stitcher_panel = %StitcherPanel
@onready var caretaker_panel = %CaretakerPanel
@onready var trainer_panel = %TrainerPanel
@onready var hire_modal = %ScientistHireModal
```

#### Step 2.2: Replace `_setup_scientist_panel_buttons()` function (around line 134)

**FIND:**
```gdscript
func _setup_scientist_panel_buttons():
	# Connect click handlers for scientist panels
	breeder_panel.gui_input.connect(func(event): _on_scientist_panel_input(event, ScientistManager.ScientistType.STITCHER))
	trainer_panel.gui_input.connect(func(event): _on_scientist_panel_input(event, ScientistManager.ScientistType.TRAINER))
	caretaker_panel.gui_input.connect(func(event): _on_scientist_panel_input(event, ScientistManager.ScientistType.CARETAKER))

	print("[FactoryManager] Scientist panel buttons set up")
```

**REPLACE WITH:**
```gdscript
func _setup_scientist_panel_buttons():
	# Connect scientist panel signals
	stitcher_panel.hire_requested.connect(_on_scientist_hire_requested)
	stitcher_panel.fire_requested.connect(_on_scientist_fire_requested)

	caretaker_panel.hire_requested.connect(_on_scientist_hire_requested)
	caretaker_panel.fire_requested.connect(_on_scientist_fire_requested)

	trainer_panel.hire_requested.connect(_on_scientist_hire_requested)
	trainer_panel.fire_requested.connect(_on_scientist_fire_requested)

	print("[FactoryManager] Scientist panel buttons set up")
```

#### Step 2.3: Remove `_on_scientist_panel_input()` function (around line 142)

**DELETE THIS ENTIRE FUNCTION:**
```gdscript
func _on_scientist_panel_input(event: InputEvent, type: ScientistManager.ScientistType):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_scientist_panel_clicked(type)
```

#### Step 2.4: Remove `_update_scientists_display()` function (around line 357)

**DELETE THIS ENTIRE FUNCTION:**
```gdscript
func _update_scientists_display():
	if not scientist_manager:
		breeder_status.text = "Not hired"
		trainer_status.text = "Not hired"
		caretaker_status.text = "Not hired"
		return

	# Update each scientist's status
	breeder_status.text = scientist_manager.get_scientist_status_text(ScientistManager.ScientistType.STITCHER)
	trainer_status.text = scientist_manager.get_scientist_status_text(ScientistManager.ScientistType.TRAINER)
	caretaker_status.text = scientist_manager.get_scientist_status_text(ScientistManager.ScientistType.CARETAKER)
```

#### Step 2.5: Remove calls to `_update_scientists_display()` (3 places)

**FIND and REMOVE these lines:**
```gdscript
# In _update_display() function (around line 319)
_update_scientists_display()  # DELETE THIS LINE

# In _on_scientist_hired() function (around line 556)
_update_scientists_display()  # DELETE THIS LINE

# In _on_scientist_fired() function (around line 561)
_update_scientists_display()  # DELETE THIS LINE
```

#### Step 2.6: Replace hire/fire functions (around lines 491-552)

**FIND:**
```gdscript
func _on_scientist_panel_clicked(type: ScientistManager.ScientistType):
	if not scientist_manager:
		return

	# Toggle hire/fire based on current state
	if scientist_manager.is_scientist_hired(type):
		# Show confirmation dialog for firing
		_show_scientist_fire_dialog(type)
	else:
		# Try to hire
		_show_scientist_hire_dialog(type)

func _show_scientist_hire_dialog(type: ScientistManager.ScientistType):
	var info = scientist_manager.get_scientist_info(type)
	var scientist_name = info["name"]
	var hire_cost = info["hire_cost"]
	var ongoing_cost = info["ongoing_cost_per_minute"]

	# Create confirmation dialog
	var dialog = AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Hire %s?" % scientist_name
	dialog.dialog_text = "Hire %s for %d gold?\n\nOngoing cost: %d gold/minute\n\n%s" % [
		scientist_name,
		hire_cost,
		ongoing_cost,
		info["description"]
	]

	dialog.confirmed.connect(func():
		if scientist_manager.hire_scientist(type):
			print("[FactoryManager] Successfully hired %s" % scientist_name)
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_centered()

func _show_scientist_fire_dialog(type: ScientistManager.ScientistType):
	var info = scientist_manager.get_scientist_info(type)
	var scientist_name = info["name"]

	# Create confirmation dialog
	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.title = "Fire %s?" % scientist_name
	dialog.dialog_text = "Fire %s?\n\nNo refund will be given.\nOngoing costs will stop." % scientist_name

	dialog.confirmed.connect(func():
		if scientist_manager.fire_scientist(type):
			print("[FactoryManager] Successfully fired %s" % scientist_name)
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_centered()
```

**REPLACE WITH:**
```gdscript
func _on_scientist_hire_requested(scientist_type: ScientistManager.ScientistType):
	"""Show hire modal when scientist panel is clicked"""
	hire_modal.show_for_scientist(scientist_type)

func _on_scientist_fire_requested(scientist_type: ScientistManager.ScientistType):
	"""Show confirmation dialog when fire button is clicked"""
	var scientist_name = ScientistManager.instance.get_scientist_name(scientist_type)

	var dialog = ConfirmationDialog.new()
	add_child(dialog)
	dialog.title = "Fire " + scientist_name + "?"
	dialog.dialog_text = "Are you sure you want to fire " + scientist_name + "?\n\nNo refund will be given.\nOngoing costs will stop."

	dialog.confirmed.connect(func():
		ScientistManager.instance.fire_scientist(scientist_type)
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

	dialog.popup_centered()
```

### Part 3: Test Everything

1. **Run the game** (F5)
2. **Test each scientist panel:**
   - Click on a scientist panel → Hire modal should appear with image
   - Hire a scientist → Image should appear, progress bar should start
   - Watch progress bar fill up
   - Click the X button → Confirmation dialog should appear
   - Fire the scientist → Should return to "click to hire" state

---

## What You Should See

### Before Hiring:
- Black square with green border
- "Click to hire scientist" text
- Scientist name below
- "Not hired (Cost: X gold)" status

### After Hiring:
- Scientist image displayed
- "Active (-X gold/min)" status in green
- Progress bar showing work progress
- Red X button in top-left corner

---

## Troubleshooting

### "Unique Name" errors
- Make sure you checked "Unique Name in Owner" for all 3 ScientistPanels and the HireModal

### Panels not responding
- Check that signals are connected in `_setup_scientist_panel_buttons()`
- Check console for errors

### Images not showing
- Verify files exist: `assets/Icons/scientists/sticher.png`, `caretaker.png`, `trainer.png`

### Progress bars not updating
- Check that ScientistManager.instance is available
- Look for errors in the console

---

## Summary of Changes

**Scene Changes:**
- Removed 3 old scientist panels (BreederPanel, TrainerPanel, CaretakerPanel)
- Added 3 new ScientistPanel instances (StitcherPanel, CaretakerPanel, TrainerPanel)
- Added ScientistHireModal

**Code Changes:**
- Simplified panel references (4 lines instead of 7)
- New signal-based setup for panel buttons
- Removed `_on_scientist_panel_input()` function
- Removed `_update_scientists_display()` function (auto-updates now!)
- Removed 3 calls to `_update_scientists_display()`
- Simplified hire/fire functions (2 functions instead of 3)

**Result:**
- ~60 lines of code removed
- Auto-updating UI (no manual refresh needed)
- Visual scientist images
- Progress bars for work tracking
- Clear fire button
