import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/booking_details_repository.dart';
import '../../utils/toast_helper.dart';

Future<bool?> showJobCompletedPopup(
  BuildContext context, {
  required String timeTaken,
  Future<bool> Function()? onConfirmed,
}) {
  bool isCompleting = false;

  return showDialog<bool?>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54, // The darkened background behind the popup
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return WillPopScope(
            onWillPop: () async => !isCompleting,
            child: Dialog(
              // Makes the popup wider to match the screenshot
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: Colors.white, // Pure white background
              surfaceTintColor: Colors.white, // Prevents Material 3 from adding a tint
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Double Circle Green Icon ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FADF).withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD1FADF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF12B76A),
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // --- Title ---
                    const Text(
                      'Job Completed?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF101828),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // --- Subtitle Text ---
                    const Text(
                      'Have you completed all the work as per the\ndescription and uploaded after work\nphotos?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF475467),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // --- Time Taken Light Blue Box ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Time taken: $timeTaken',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF344054),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // --- "Yes" Green Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isCompleting
                            ? null
                            : () async {
                                setState(() => isCompleting = true);
                                final success = onConfirmed != null ? await onConfirmed() : false;
                                if (!context.mounted) return;
                                if (success) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  setState(() => isCompleting = false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C853), // Vibrant Green
                          disabledBackgroundColor: const Color(0xFFCCCCCC),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: isCompleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Yes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // --- "Continue Working" Grey Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isCompleting ? null : () => Navigator.of(context).pop(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF2F4F7), // Soft Grey
                          disabledBackgroundColor: const Color(0xFFE2E8F0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Continue Working',
                          style: TextStyle(
                            color: Color(0xFF344054),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showRateExperiencePopup(
  BuildContext context, {
  required int bookingId,
  String? customerName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (_) => _RateExperienceDialog(
      bookingId: bookingId,
      customerName: customerName,
    ),
  );
}

class _RateExperienceDialog extends ConsumerStatefulWidget {
  const _RateExperienceDialog({
    required this.bookingId,
    this.customerName,
  });

  final int bookingId;
  final String? customerName;

  @override
  ConsumerState<_RateExperienceDialog> createState() => _RateExperienceDialogState();
}

class _RateExperienceDialogState extends ConsumerState<_RateExperienceDialog> {
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _rating > 0;
    final displayName = widget.customerName?.isNotEmpty == true
        ? widget.customerName!
        : 'the customer';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D2A4F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_border, color: Colors.white, size: 29),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F4F7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF667085)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Rate Your Experience',
              style: TextStyle(fontSize: 30 / 2, fontWeight: FontWeight.w500, color: Color(0xFF101828)),
            ),
            const SizedBox(height: 4),
            Text(
              'How was your experience with $displayName?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475467), height: 1.35),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final isSelected = index < _rating;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _rating = index + 1),
                  icon: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: isSelected ? const Color(0xFFFDB022) : const Color(0xFFCDD5DF),
                    size: 41 / 1.3,
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Additional Feedback (Optional)',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF101828)),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _feedbackController,
              maxLength: 200,
              maxLines: 4,
              enabled: !_isSubmitting,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF98A2B3)),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_feedbackController.text.length}/200',
                style: const TextStyle(fontSize: 11, color: Color(0xFF98A2B3)),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: (canSubmit && !_isSubmitting)
                    ? () async {
                        setState(() {
                          _isSubmitting = true;
                        });
                        final repo = ref.read(bookingDetailsRepositoryProvider);
                        final success = await repo.submitRating(
                          bookingId: widget.bookingId,
                          serviceRating: _rating,
                          partnerRating: _rating,
                          review: _feedbackController.text.trim().isEmpty
                              ? null
                              : _feedbackController.text.trim(),
                        );
                        if (!mounted) return;
                        setState(() {
                          _isSubmitting = false;
                        });
                        if (success) {
                          AppToast.showSuccess('Feedback submitted successfully');
                          Navigator.of(context).pop();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: canSubmit ? const Color(0xFF0D2A4F) : const Color(0xFF98A2B3),
                  disabledBackgroundColor: const Color(0xFF98A2B3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Review',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: const Text(
                'Skip for Now',
                style: TextStyle(color: Color(0xFF344054), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
