import 'package:flutter/material.dart';

import '../../models/booking_details_model.dart';
import 'before_work_photo_screen.dart';
import 'job_in_progress_screen.dart';
import 'selfie_verification_screen.dart';
import 'start_job_otp_screen.dart';

Widget screenForJobWorkflow({
  required int bookingId,
  required String status,
  required String workflowState,
  String customerName = '',
}) {
  final normalizedWorkflow = workflowState.trim().toUpperCase();
  final normalizedStatus = status.trim().toUpperCase();
  final resolvedCustomerName = customerName.trim().isNotEmpty
      ? customerName.trim()
      : 'Customer';

  switch (normalizedWorkflow) {
    case 'OTP_PENDING':
      return StartJobOtpScreen(
        bookingId: bookingId,
        customerName: resolvedCustomerName,
      );
    case 'OTP_VERIFIED':
    case 'SELFIE_PENDING':
      return SelfieVerificationScreen(bookingId: bookingId);
    case 'SELFIE_VERIFIED':
    case 'BEFORE_PHOTO_PENDING':
      return BeforeWorkPhotoScreen(bookingId: bookingId);
    case 'BEFORE_PHOTO_UPLOADED':
    case 'IN_PROGRESS':
    case 'AFTER_PHOTO_PENDING':
    case 'AFTER_PHOTO_UPLOADED':
    case 'COMPLETED':
      return JobInProgressScreen(bookingId: bookingId);
  }

  if (normalizedStatus == 'IN_PROGRESS') {
    return JobInProgressScreen(bookingId: bookingId);
  }

  return StartJobOtpScreen(
    bookingId: bookingId,
    customerName: resolvedCustomerName,
  );
}

void openJobWorkflowStep(
  BuildContext context, {
  required int bookingId,
  required String status,
  required String workflowState,
  String customerName = '',
  bool replace = false,
}) {
  if (bookingId <= 0) return;

  final route = MaterialPageRoute(
    builder: (_) => screenForJobWorkflow(
      bookingId: bookingId,
      status: status,
      workflowState: workflowState,
      customerName: customerName,
    ),
  );

  if (replace) {
    Navigator.of(context).pushReplacement(route);
  } else {
    Navigator.of(context).push(route);
  }
}

void openBookingWorkflowStep(
  BuildContext context, {
  required BookingDetailsModel booking,
  bool replace = false,
}) {
  openJobWorkflowStep(
    context,
    bookingId: booking.id,
    status: booking.status,
    workflowState: booking.workflowState,
    customerName: booking.customer.name,
    replace: replace,
  );
}
