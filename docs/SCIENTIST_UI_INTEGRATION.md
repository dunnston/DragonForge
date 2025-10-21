# Scientist UI Integration Guide

## Overview

I've created a complete scientist UI system with:
- **ScientistPanel**: Reusable panel showing scientist image, status, progress bar, and fire button
- **ScientistHireModal**: Modal dialog with scientist image and hire information
- **Demo Scene**: Working example showing all features

## Files Created

### Core Components
1. **[scenes/ui/scientist_panel.tscn](scenes/ui/scientist_panel.tscn)** - Reusable scientist panel
2. **[scripts/ui/scientist_panel.gd](scripts/ui/scientist_panel.gd)** - Panel logic
3. **[scenes/ui/scientist_hire_modal.tscn](scenes/ui/scientist_hire_modal.tscn)** - Hire modal
4. **[scripts/ui/scientist_hire_modal.gd](scripts/ui/scientist_hire_modal.gd)** - Modal logic
5. **[resources/ui/green_border_style.tres](resources/ui/green_border_style.tres)** - Green border styling

### Demo
6. **[scenes/ui/scientist_panel_demo.tscn](scenes/ui/scientist_panel_demo.tscn)** - Working demo
7. **[scripts/ui/scientist_panel_demo.gd](scripts/ui/scientist_panel_demo.gd)** - Demo script

### Updated
8. **[scripts/managers/scientist_manager.gd](scripts/managers/scientist_manager.gd)** - Added helper methods

---

## Features

### When Scientist is NOT Hired
- Black square with green border
- Text: "Click to hire scientist"
- Click opens hire modal with:
  - Scientist image
  - Name and description
  - Hire cost and ongoing cost
  - Disabled "OK" button if not enough gold

### When Scientist IS Hired
- Displays scientist image
- Shows "Active (-X gold/min)" status
- Progress bar showing work timer
  - Stitcher: "Creating dragon..." (60 seconds)
  - Caretaker: "Caring for dragons..." (30 seconds)
  - Trainer: "Training dragons..." (30 seconds)
- Red "X" button in top-left corner to fire scientist
  - Shows confirmation dialog before firing

---

## How to Test the Demo

1. Open Godot
2. Navigate to [scenes/ui/scientist_panel_demo.tscn](scenes/ui/scientist_panel_demo.tscn)
3. Run the scene (F6)
4. Try:
   - Clicking a scientist panel to hire
   - Watching the progress bar fill
   - Clicking the X button to fire
   - Trying to hire without enough gold

---

## How to Integrate into factory_manager.tscn

### Option 1: Manual Integration (Recommended)

1. **Open factory_manager.tscn in Godot**

2. **Remove old scientist panels**:
   - Delete `BreederPanel`, `TrainerPanel`, `CaretakerPanel` nodes

3. **Add new ScientistPanels**:
   - In the same location (`LeftPanel/ScientistsVBox`)
   - Right-click → "Instantiate Child Scene"
   - Select `scenes/ui/scientist_panel.tscn`
   - Repeat 3 times for each scientist

4. **Configure each panel**:
   - **First panel**:
     - Rename to `StitcherPanel`
     - In Inspector → Script Variables → `scientist_type` = `0` (STITCHER)
     - Check "Unique Name in Owner"
   - **Second panel**:
     - Rename to `CaretakerPanel`
     - `scientist_type` = `1` (CARETAKER)
     - Check "Unique Name in Owner"
   - **Third panel**:
     - Rename to `TrainerPanel`
     - `scientist_type` = `2` (TRAINER)
     - Check "Unique Name in Owner"

5. **Add hire modal**:
   - In root of factory_manager scene
   - Right-click → "Instantiate Child Scene"
   - Select `scenes/ui/scientist_hire_modal.tscn`
   - Rename to `ScientistHireModal`
   - Check "Unique Name in Owner"

6. **Save the scene**

### Option 2: Code Integration

Update [factory_manager.gd](scripts/ui/factory_manager.gd):

1. **Remove old scientist UI references** (lines 18-24):
   ```gdscript
   # DELETE THESE LINES
   @onready var breeder_panel: PanelContainer = $MarginContainer/...
   @onready var breeder_status: Label = $MarginContainer/...
   # etc.
   ```

2. **Add new panel references**:
   ```gdscript
   # === UI ELEMENTS - Scientists ===
   @onready var stitcher_panel = %StitcherPanel
   @onready var caretaker_panel = %CaretakerPanel
   @onready var trainer_panel = %TrainerPanel
   @onready var hire_modal = %ScientistHireModal
   ```

3. **Replace `_setup_scientist_panel_buttons()`** (line 134-140):
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

4. **Remove old `_on_scientist_panel_input()` method** (line 142-144)

5. **Replace hire/fire methods** (lines 491-552):
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

   # DELETE the old _show_scientist_hire_dialog() and _show_scientist_fire_dialog() methods
   ```

6. **Remove `_update_scientists_display()` method** (lines 357-367):
   - No longer needed! The ScientistPanels update themselves automatically

7. **Remove calls to `_update_scientists_display()`**:
   - In `_update_display()` (line 319)
   - In `_on_scientist_hired()` (line 556)
   - In `_on_scientist_fired()` (line 561)

---

## What You Get

### Visual Improvements
- ✅ Scientist images displayed when hired
- ✅ Clear "click to hire" prompt when not hired
- ✅ Green border on empty panels
- ✅ Progress bars showing work progress in real-time
- ✅ Obvious fire button (red X)

### Functional Improvements
- ✅ Automatic visual updates (no manual refresh needed)
- ✅ Progress tracking for all scientist work
- ✅ Better hire modal with images
- ✅ Clear confirmation before firing
- ✅ Disabled hire button when not enough gold

### Code Improvements
- ✅ Reusable ScientistPanel component
- ✅ Cleaner separation of concerns
- ✅ Less manual UI update code
- ✅ Signals for all interactions

---

## Testing Checklist

After integration, test:
- [ ] Scientist panels show "click to hire" when not hired
- [ ] Green border visible on empty panels
- [ ] Click opens hire modal with scientist image
- [ ] Hire button disabled when not enough gold
- [ ] Hiring works and shows scientist image
- [ ] Progress bar fills as scientist works
- [ ] Progress bar resets when task completes
- [ ] Fire button (X) visible when hired
- [ ] Fire confirmation dialog appears
- [ ] Firing works and returns to empty state
- [ ] Auto-fire (insufficient gold) works
- [ ] All 3 scientists work independently

---

## Troubleshooting

### Scientist images not showing
- Check file paths in `assets/Icons/scientists/`
- Note: `stitcher.png` is named `sticher.png` (typo in filename)
- Images should be: `sticher.png`, `caretaker.png`, `trainer.png`

### Progress bars not updating
- Check that ScientistManager instance is available
- Check that work timers are running
- Check console for errors

### Green border not showing
- Check that `green_border_style.tres` exists
- Check that it's referenced in `scientist_panel.tscn`

### Panels not responding to clicks
- Check that signals are connected in `_setup_scientist_panel_buttons()`
- Check that `scientist_type` is set correctly on each panel

---

## Next Steps

Once integrated, you can:
1. Customize the green border color in `green_border_style.tres`
2. Adjust progress bar colors/styles
3. Add more visual feedback (animations, particles, etc.)
4. Add tooltips with more scientist info
5. Add upgrade buttons to scientist panels

---

## Questions?

If you need help integrating or encounter issues, check:
1. The demo scene to see it working
2. Console output for error messages
3. Inspector to verify scene structure
4. Signal connections in the editor
