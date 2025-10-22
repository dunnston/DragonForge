# Dragon Color System Integration Guide

## ✅ What's Implemented

### Core System (COMPLETE)
1. **Shader** - `assets/shaders/dragon_color.gdshader`
   - Uses mask texture to identify head (red channel), body (green), tail (blue)
   - Multiplies element colors with base texture for realistic shading
   - Preserves alpha transparency

2. **DragonVisual Component** - `scripts/ui/dragon_visual.gd`
   - Controls dragon coloring based on element types
   - Element color mapping:
     - FIRE: Orange-red (#FF6B35)
     - ICE: Light cyan (#6FDBFF)
     - LIGHTNING: Bright yellow (#FFEB3B)
     - NATURE: Green (#4CAF50)
     - SHADOW: Dark purple (#6A0572)
   - Methods: `set_dragon_colors()`, `set_dragon_colors_from_parts()`

3. **Dragon Base Scene** - `assets/Icons/dragons/dragon-base.tscn`
   - Instantiable scene with shader material
   - References: dragon-base-clean.png + dragon-mask.png
   - Scale: Adjust per use case

4. **Test Scene** - `scenes/test/dragon_color_test.tscn`
   - Interactive UI to test all element combinations
   - Preset buttons (All Fire, Rainbow, Random)
   - ✅ VERIFIED WORKING with scale 0.3

5. **DragonCard Component** - `scenes/ui/dragon_card.tscn` + `scripts/ui/dragon_card.gd`
   - Reusable card for displaying dragons in lists
   - Shows dragon visual with correct colors + name/stats/state
   - Emits `card_clicked(dragon)` signal
   - Ready to use in factory_manager and other UIs

### Updated Systems
1. **DragonDisplay** - `scenes/dragon_system/dragon_display.tscn`
   - Now uses DragonVisual instead of colored rectangles
   - Automatically applies colors based on dragon parts

---

## 🔧 Manual Changes Needed

### Factory Manager Dragon List
**File**: `scripts/ui/factory_manager.gd`
**Function**: `_create_dragon_entry()` (line 381-426)

**Current Code** (lines 388-396):
```gdscript
# Dragon image
var dragon_image = TextureRect.new()
dragon_image.custom_minimum_size = Vector2(60, 60)
dragon_image.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
dragon_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
var texture = load("res://assets/Icons/dragons/fire-dragon.png")
if texture:
    dragon_image.texture = texture
hbox.add_child(dragon_image)
```

**Replace With**:
```gdscript
# Dragon visual with shader-based coloring
var dragon_visual_scene = load("res://assets/Icons/dragons/dragon-base.tscn")
var dragon_visual: DragonVisual = dragon_visual_scene.instantiate()
dragon_visual.custom_minimum_size = Vector2(60, 60)
dragon_visual.scale = Vector2(0.15, 0.15)  # Scale down for list display

# Apply colors based on dragon's parts
dragon_visual.set_dragon_colors_from_parts(
    dragon.head_part,
    dragon.body_part,
    dragon.tail_part
)

hbox.add_child(dragon_visual)
```

**Why this change?**
- Removes hardcoded "fire-dragon.png" texture
- Shows each dragon with unique colors based on its parts
- Uses the shader system for realistic coloring

---

## 📝 Alternative: Use DragonCard Component

Instead of manually creating dragon entries, you can use the pre-built DragonCard:

```gdscript
func _create_dragon_entry(dragon: Dragon) -> PanelContainer:
    var dragon_card_scene = load("res://scenes/ui/dragon_card.tscn")
    var dragon_card: DragonCard = dragon_card_scene.instantiate()

    dragon_card.set_dragon(dragon)
    dragon_card.card_clicked.connect(func(d): _on_dragon_entry_input(null, d))

    return dragon_card
```

This is much simpler and reuses the DragonCard component!

---

## 🎨 Updating the Mask

**File**: `assets/Icons/dragons/dragon-mask.png`

You can update this file at any time - the shader will automatically use the new mask!

**Mask Format**:
- Red channel (R): Head region
- Green channel (G): Body region
- Blue channel (B): Tail region
- Black (RGB 0,0,0): No coloring

**Tips**:
- Pure red (255,0,0) = 100% head color
- Pure green (0,255,0) = 100% body color
- Pure blue (0,0,255) = 100% tail color
- Gradients blend colors smoothly

---

## 🔍 Testing Checklist

### Test Scene (dragon_color_test.tscn)
- [x] Loads without errors
- [x] Dragon displays at correct scale
- [ ] Click Fire/Ice/Lightning/Nature/Shadow buttons
- [ ] Each element shows distinct color
- [ ] Colors apply to correct regions (head/body/tail)
- [ ] "Random" button creates varied combinations

### Dragon Display (dragon_display.tscn)
- [ ] Create a test dragon with mixed parts
- [ ] Open dragon_display scene
- [ ] Set the dragon
- [ ] Verify colors match parts

### Factory Manager
- [ ] Create multiple dragons with different parts
- [ ] Check dragons list displays unique colors per dragon
- [ ] Click dragon to open details modal
- [ ] Verify colors are consistent everywhere

---

## 📦 Files Created/Modified

### New Files
- `assets/shaders/dragon_color.gdshader` - Color shader
- `scripts/ui/dragon_visual.gd` - Visual controller
- `assets/Icons/dragons/dragon-base.tscn` - Base scene
- `scenes/test/dragon_color_test.tscn` - Test scene
- `scripts/test/dragon_color_test.gd` - Test script
- `scenes/ui/dragon_card.tscn` - Reusable card component
- `scripts/ui/dragon_card.gd` - Card script
- `scripts/ui/factory_manager_dragon_visual_patch.txt` - Change guide

### Modified Files
- `scenes/dragon_system/dragon_display.tscn` - Uses DragonVisual
- `scripts/dragon_system/dragon_display.gd` - Updated to use colors
- `scenes/test/dragon_color_test.tscn` - Fixed scale to 0.3

### Files You Created
- `assets/Icons/dragons/dragon-base-clean.png` - Base texture (cleaned up edges)
- `assets/Icons/dragons/dragon-mask.png` - Color mask (can be updated anytime!)

---

## 🚀 Next Steps

1. **Update the mask** - Improve dragon-mask.png for better coloring
2. **Apply factory_manager changes** - Replace dragon image code (see above)
3. **Test everywhere** - Create dragons and verify colors show up correctly
4. **Optional**: Replace other dragon displays with DragonCard component

---

## ✨ Benefits of This System

- **Dynamic**: Each dragon shows unique colors based on parts
- **Performant**: One base texture + shader (no 125 texture files!)
- **Flexible**: Update mask anytime without code changes
- **Realistic**: Shader preserves shading/highlights from base texture
- **Reusable**: DragonVisual and DragonCard work anywhere
