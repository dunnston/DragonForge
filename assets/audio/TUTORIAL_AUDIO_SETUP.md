# Tutorial Audio Setup

This document explains which audio files to use for the tutorial system.

## Available Audio Files

Your project already contains these audio files that can be used for the tutorial:

### For Opening Letter Scene

**Typewriter Sound:**
- Use: `typewriter-typing-68696.mp3`
- Purpose: Looping typewriter clicking sound
- Node: `TypingSound` in `opening_letter.tscn`

**Thunder Sound:**
- Use: `loud-rolling-thunder-with-gentle-rainfall-422430.mp3`
- Purpose: Dramatic thunder crash on "They will come"
- Node: `ThunderSound` in `opening_letter.tscn`

**Dramatic Music:**
- Use: `The Clockwork Ghost.mp3` (atmospheric, fitting for gothic theme)
- Alternative: `Dragon Lab Blues.mp3` (more upbeat)
- Purpose: Background music during letter reading
- Node: `DramaticMusic` in `opening_letter.tscn`

### For Tutorial System

**UI Sounds (Optional):**
- Click sounds: Use existing UI sounds from your game
- Tutorial complete: `ReadyToWork.mp3` or `DragonsFinished.mp3`

## How to Assign Audio

1. Open `scenes/opening/opening_letter.tscn` in Godot
2. Select each audio node and assign the stream:

### TypingSound Node
- Stream: `res://assets/audio/typewriter-typing-68696.mp3`
- Volume DB: -10.0 (already set)
- Autoplay: false (controlled by script)

### ThunderSound Node
- Stream: `res://assets/audio/loud-rolling-thunder-with-gentle-rainfall-422430.mp3`
- Volume DB: -5.0 (already set)
- Autoplay: false (triggered on dramatic moments)

### DramaticMusic Node
- Stream: `res://assets/audio/The Clockwork Ghost.mp3`
- Volume DB: -15.0 (already set)
- Autoplay: false (starts on scene ready)

## Audio Import Settings

If audio doesn't loop properly, check import settings:

1. Select the audio file in FileSystem
2. Click "Import" tab
3. For typewriter sound:
   - Enable "Loop"
   - Loop Mode: Forward
4. Click "Reimport"

## Testing Audio

To test the audio setup:

1. Open `scenes/opening/opening_letter.tscn`
2. Press F6 (or click "Play Scene")
3. You should hear:
   - Dramatic music starts immediately
   - Typewriter sound loops while text appears
   - Thunder crashes around "They will come"
   - Music fades out when transitioning

## Customization

### Adjust Volume

In `scripts/opening/opening_letter.gd`, you can adjust volumes:

```gdscript
# Make typewriter quieter
typing_sound.volume_db = -20.0

# Make thunder louder
thunder_sound.volume_db = 0.0

# Make music quieter
dramatic_music.volume_db = -25.0
```

### Change Thunder Timing

The thunder is triggered when text reaches "They will come" phrase. To change timing:

```gdscript
# In opening_letter.gd, around line 90
if current_char_index >= 250 and current_char_index <= 280:
```

Adjust the character index range to change when thunder plays.

### Use Different Music

To use a different background track:

1. Change the Stream in `opening_letter.tscn`
2. Or reference it in code (not recommended)

## Audio Licensing

Make sure to credit the audio creators if required for your game jam submission!
