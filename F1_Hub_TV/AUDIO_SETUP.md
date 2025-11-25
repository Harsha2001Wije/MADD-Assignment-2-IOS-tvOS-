# Audio Setup Instructions

## Audio Files Required

To complete the audio experience, you need to add the following audio files to your Xcode project:

### 1. Splash Screen Sound
- **Filename**: `f1_engine.mp3`
- **Purpose**: Plays during the splash screen animation
- **Duration**: Recommended 1-2 seconds
- **Type**: F1 engine rev or startup sound

### 2. Background Music
- **Filename**: `background_music.mp3`
- **Purpose**: Loops continuously throughout the app
- **Duration**: Recommended 30-60 seconds (will loop)
- **Type**: Ambient F1-themed music or instrumental

## How to Add Audio Files

1. **Find or Create Audio Files**
   - Download F1 engine sounds (royalty-free)
   - Create or download background music
   - Ensure files are in MP3 format

2. **Add to Xcode Project**
   - Open your Xcode project
   - Drag and drop the audio files into the project navigator
   - Make sure "Copy items if needed" is checked
   - Select your app target in "Add to targets"

3. **Verify Files**
   - Files should appear in your project navigator
   - They should have a checkmark next to your target name

## Audio Settings

### Splash Screen Sound
- Volume: 60% (0.6)
- Plays once when splash screen appears
- Configured in `SplashView.swift`

### Background Music
- Volume: 30% (0.3) - adjustable
- Loops indefinitely
- Starts after splash screen finishes
- Managed by `AudioManager.swift`

## Customization

To change audio settings, modify these files:

**SplashView.swift** - Line with `audioPlayer?.volume = 0.6`
```swift
audioPlayer?.volume = 0.6  // Change volume (0.0 to 1.0)
```

**AudioManager.swift** - In `playBackgroundMusic()` method
```swift
func playBackgroundMusic(fileName: String = "background_music", 
                        fileExtension: String = "mp3", 
                        volume: Float = 0.3) {
    // Change defaults here
}
```

**F1_Race_Hub_TV_2_0App.swift** - When calling playBackgroundMusic()
```swift
audioManager.playBackgroundMusic(fileName: "your_file", volume: 0.5)
```

## Troubleshooting

If audio doesn't play:
1. Check that audio files are added to the target
2. Check file names match exactly (case-sensitive)
3. Check console for error messages
4. Verify tvOS audio permissions if needed

## Free F1 Sound Resources

- **Freesound.org** - Search for "F1 engine" or "race car"
- **YouTube Audio Library** - Instrumental/ambient music
- **Incompetech** - Royalty-free music

**Note**: Always ensure you have the right to use audio files in your app.
