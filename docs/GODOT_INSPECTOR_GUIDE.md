# Finding Inspector Settings in Godot

## How to Set "Unique Name in Owner"

### Step-by-Step:
1. **Select the node** in the Scene tree (e.g., `StitcherPanel`)
2. **Look at the Inspector panel** on the right side
3. **At the very top** of the Inspector, you'll see the node name and some icons
4. **Look for one of these**:
   - A checkbox labeled "Unique Name in Owner"
   - An icon button that looks like a **%** symbol
   - Or in older Godot versions, it might be under Node → Access as Unique Name

### Where to Look:
```
┌─ Inspector ────────────────────┐
│ ┌─ StitcherPanel ────────────┐ │
│ │  [icons row]               │ │  ← Look here for % icon or checkbox
│ └────────────────────────────┘ │
│                                │
│ ▼ Node                         │
│   Type: ScientistPanel         │
│   [ ] Unique Name in Owner     │  ← Or it might be here
```

## How to Set Script Variables

### Step-by-Step:
1. **Select the node** in the Scene tree (e.g., `StitcherPanel`)
2. **Look in the Inspector panel**
3. **Scroll down** past the Node section
4. **Find the section** that shows the script variables - it might be labeled:
   - "Script Variables"
   - Or just show the variable name directly
5. **Look for** `scientist_type` or `Scientist Type`

### Where to Look:
```
┌─ Inspector ────────────────────┐
│ ▼ Node                         │
│   Name: StitcherPanel          │
│   Type: ScientistPanel         │
│                                │
│ ▼ ScientistPanel               │  ← Script section
│   scientist_type: [dropdown]   │  ← This is what you need!
│       0 - STITCHER             │
│       1 - CARETAKER            │
│       2 - TRAINER              │
```

### Values to Set:
- **StitcherPanel**: Set `scientist_type` to **0** (or select "STITCHER" from dropdown)
- **CaretakerPanel**: Set `scientist_type` to **1** (or select "CARETAKER")
- **TrainerPanel**: Set `scientist_type` to **2** (or select "TRAINER")

---

## Alternative: If You Can't Find These Settings

### For Unique Name in Owner:
If you can't find the checkbox, you can do it in code instead:
1. In `factory_manager.gd`, instead of using `%StitcherPanel`
2. Use the full path: `$MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/StitcherPanel`

**Change from:**
```gdscript
@onready var stitcher_panel = %StitcherPanel
```

**To:**
```gdscript
@onready var stitcher_panel = $MarginContainer/MainVBox/MainContent/LeftPanel/ScientistsVBox/StitcherPanel
```

### For Script Variables:
You can also set them in code:
```gdscript
func _ready():
    # ... other code ...
    stitcher_panel.scientist_type = ScientistManager.ScientistType.STITCHER
    caretaker_panel.scientist_type = ScientistManager.ScientistType.CARETAKER
    trainer_panel.scientist_type = ScientistManager.ScientistType.TRAINER
```

---

## The Error is Now Fixed!

I updated `scientist_panel.gd` to properly wait for ScientistManager to be ready before connecting signals. This should fix the errors you were seeing in the console.

### What Changed:
- Added `await get_tree().process_frame` to wait for managers to initialize
- Added null check for `ScientistManager.instance`
- Moved signal connections to happen after the wait

---

## Quick Test

After setting up the panels, do a quick test:
1. **Save the scene** (Ctrl+S)
2. **Run the scene** (F6 or click Run button)
3. **Check the console** - there should be no red errors
4. **Look at the scientist panels** - they should show "Click to hire scientist" with green borders

If you still see errors, let me know what the error message says!
