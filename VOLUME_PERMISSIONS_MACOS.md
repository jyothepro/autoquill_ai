# macOS Volume Control Permissions

## Auto-Mute System Volume Feature

The auto-mute system volume feature allows AutoQuill to automatically mute your system volume during recording to prevent audio interference from music, videos, or other media.

### macOS Limitations

On macOS, this feature may not work due to system security restrictions. macOS has strict controls over which apps can modify system volume, and the `volume_controller` package may not have the necessary permissions.

### Expected Behavior

If the feature works on your system:
- ✅ System volume will mute when recording starts
- ✅ Sound effects (start/stop recording) will still play before muting/after unmuting
- ✅ System volume will restore to original level when recording ends

If the feature doesn't work:
- ❌ You may see error messages in debug logs like "Error getting volume: 2003332927"
- ❌ System volume will continue playing during recording
- ✅ Recording and transcription will still work normally

### Workaround

If auto-mute doesn't work on your macOS system:
1. Manually pause/mute your media before recording
2. Use the push-to-talk feature for shorter recordings
3. Consider using headphones to isolate recording audio

### Why This Happens

macOS requires special entitlements or permissions for apps to control system volume. These permissions are typically reserved for system apps or apps distributed through the Mac App Store with specific entitlements.

### Future Improvements

We're investigating alternative approaches for macOS volume control, including:
- Requesting specific macOS permissions
- Using alternative volume control methods
- Providing better user guidance when the feature isn't available

## Support

This is a known limitation on macOS. The recording and transcription features will work perfectly regardless of whether volume control is available. 