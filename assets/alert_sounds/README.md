# Alert Sounds

This folder contains audio files used for notifications and alerts.

## Required Files

- **alert_sound** - Place your alert sound file here
  - Supported formats: `.mp3`, `.wav`, `.ogg`, `.m4a`
  - Recommended: Use `.mp3` format for best compatibility across all platforms
  - Filename must be: `alert_sound.mp3` (or other supported extension)

## How to Add Your Alert Sound

1. Prepare your audio file in any of these formats: MP3, WAV, OGG, or M4A
2. Name it as: `alert_sound.mp3` (replace `.mp3` with your file extension if different)
3. Place it in this `alert_sounds/` folder
4. Run `flutter pub get` to ensure the asset is recognized
5. The alert sound will automatically play when a new booking alert is triggered

## Audio File Specifications

- **Format**: MP3 (recommended), WAV, OGG, or M4A
- **Duration**: 1-3 seconds (for alert sounds)
- **Sample Rate**: 44.1 kHz or higher
- **Bit Rate**: 128 kbps or higher
- **Expected Size**: 50-300 KB

## Testing

Once you add the audio file:
1. Run `flutter pub get` to sync dependencies
2. Build and run your app
3. When a new booking alert comes in, the alert sound will play along with haptic feedback

If the custom alert sound fails to load, it will automatically fall back to the system alert sound.
