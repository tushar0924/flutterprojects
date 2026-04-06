# Fixes for Alert Sound & Black Screen Issues

## Issue 1: Alert Sound Not Playing

### Problem
The audio player is using `.play(AssetSource())` but needs proper initialization with `setSourceAsset()` first.

### Fix in booking_socket_controller.dart (Line 162-190)

Replace the `_playAlertSound()` method with:

```dart
Future<void> _playAlertSound() async {
  try {
    // Release any previous audio
    await _audioPlayer.release();
    
    // Try to set and play the custom alert sound
    await _audioPlayer.setSourceAsset('alert_sounds/alert_sound.mp3');
    await _audioPlayer.resume();
  } catch (e) {
    try {
      // Try WAV format
      await _audioPlayer.release();
      await _audioPlayer.setSourceAsset('alert_sounds/alert_sound.wav');
      await _audioPlayer.resume();
    } catch (e2) {
      // Fallback to system sound
      SystemSound.play(SystemSoundType.alert);
    }
  }
}
```

---

## Issue 2: Black Screen After Reject

### Problem
After rejection, the dialog closes but the booking state is cleared immediately, causing the UI to become unresponsive or show a black screen.

### Fix in helperr_home.dart (Line 103-145)

Replace the `_showBookingAlert()` method with:

```dart
Future<void> _showBookingAlert(BookingAlertModel booking) async {
  if (!mounted) return;

  _bookingAlertVisible = true;
  final result = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => BookingAlert(
      booking: booking,
      onAccept: (item) =>
          ref.read(bookingSocketProvider.notifier).acceptBooking(item),
      onReject: (item) =>
          ref.read(bookingSocketProvider.notifier).rejectBooking(item),
    ),
  );

  _bookingAlertVisible = false;

  if (!mounted) return;

  // Handle result based on user action
  if (result == 'accepted') {
    AppToast.showSuccess('Booking accepted');
    
    // Give a small delay for UI to update
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    
    // Navigate to job details screen
    final bookingId = ref.read(bookingSocketProvider).lastAcceptedBookingId;
    if (bookingId != null && bookingId > 0) {
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => JobDetailsScreen(bookingId: bookingId),
          ),
        );
      }
    }
  } else if (result == 'rejected') {
    AppToast.showNeutral('Booking rejected');
    
    // Give a small delay before clearing booking
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Clear the booking after handling the result
  if (mounted) {
    ref
        .read(bookingSocketProvider.notifier)
        .clearActiveBooking(booking.requestId);
  }

  if (!mounted) return;

  // Check for pending bookings
  final pendingBooking = _pendingBooking;
  _pendingBooking = null;
  final currentBooking = ref.read(bookingSocketProvider).activeBooking;
  if (pendingBooking != null &&
      currentBooking?.requestId == pendingBooking.requestId &&
      pendingBooking.requestId != booking.requestId) {
    await _showBookingAlert(pendingBooking);
  }
}
```

---

## Steps to Apply Fixes

1. **Update booking_socket_controller.dart** - Fix the `_playAlertSound()` method
2. **Update helperr_home.dart** - Fix the `_showBookingAlert()` method
3. **Ensure audio file exists** at `assets/alert_sounds/alert_sound.mp3`
4. **Run** `flutter pub get`
5. **Rebuild** your app

---

## Key Changes

### Audio Fix:
- Uses `setSourceAsset()` to properly load the audio
- Calls `resume()` instead of `play()`
- Returns audio player to initial state with `release()`
- Better error handling with fallback to system sound

### Black Screen Fix:
- Added delays between actions to let UI update
- Moved `clearActiveBooking()` to after handling the result
- Added `mounted` checks before each operation
- Ensures smooth transition back to home screen
