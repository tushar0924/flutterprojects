import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/partner_repository.dart';
import '../repositories/services_repository.dart';
import '../repositories/user_repository.dart';
import '../routes/app_router.dart';
import 'partner_provider.dart';

const List<String> kDefaultPartnerServices = <String>[
  'Maid',
  'Cook',
  'Shop-helper',
  'Driver',
  'Nanny',
  'Elder Care',
  'Baby Sitter',
  'Patient Care',
];

enum PartnerOnboardingStep { basicInfo, kyc, bank, verificationPending, home }

String onboardingRouteForStep(PartnerOnboardingStep step) {
  switch (step) {
    case PartnerOnboardingStep.basicInfo:
      return AppRouter.onboardingStep2;
    case PartnerOnboardingStep.kyc:
      return AppRouter.onboardingStep3;
    case PartnerOnboardingStep.bank:
      return AppRouter.onboardingStep4;
    case PartnerOnboardingStep.verificationPending:
      return AppRouter.onboardingStep5;
    case PartnerOnboardingStep.home:
      return AppRouter.home;
  }
}

String helperLaunchRouteForState(PartnerOnboardingState state) {
  switch (state.currentStep) {
    case PartnerOnboardingStep.home:
      return AppRouter.home;
    case PartnerOnboardingStep.verificationPending:
      return AppRouter.onboardingStep5;
    case PartnerOnboardingStep.basicInfo:
    case PartnerOnboardingStep.kyc:
    case PartnerOnboardingStep.bank:
      return AppRouter.chooseRole;
  }
}

String formatOnboardingStatus(String rawStatus) {
  final normalized = rawStatus.trim();
  if (normalized.isEmpty) return 'Pending';
  return normalized
      .split('_')
      .where((part) => part.trim().isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

bool onboardingStatusIsApproved(String rawStatus) {
  final status = rawStatus.trim().toUpperCase();
  return status == 'APPROVED' || status == 'ACTIVE';
}

bool onboardingStatusIsRejected(String rawStatus) {
  return rawStatus.trim().toUpperCase().contains('REJECT');
}

bool onboardingStatusNeedsReview(String rawStatus) {
  final status = rawStatus.trim().toUpperCase();
  if (status.isEmpty) return false;
  if (onboardingStatusIsApproved(status) ||
      onboardingStatusIsRejected(status)) {
    return true;
  }
  return status.contains('REVIEW') ||
      status.contains('VERIFY') ||
      status.contains('PENDING') ||
      status.contains('APPROVAL') ||
      status.contains('SUBMITTED');
}

PartnerOnboardingStep resolvePartnerOnboardingStep({
  required String rawStatus,
  required bool profileCompleted,
  required bool kycCompleted,
  required bool bankCompleted,
}) {
  final status = rawStatus.trim().toUpperCase();

  if (onboardingStatusIsApproved(status)) {
    return PartnerOnboardingStep.home;
  }
  if (!profileCompleted &&
      (status.isEmpty ||
          status.contains('PROFILE') ||
          status.contains('BASIC'))) {
    return PartnerOnboardingStep.basicInfo;
  }
  if (!kycCompleted &&
      (status.contains('KYC') ||
          status.contains('PAN') ||
          status.contains('SELFIE') ||
          status.contains('POLICE'))) {
    return PartnerOnboardingStep.kyc;
  }
  if (!bankCompleted && status.contains('BANK')) {
    return PartnerOnboardingStep.bank;
  }
  if (onboardingStatusNeedsReview(status)) {
    return PartnerOnboardingStep.verificationPending;
  }
  if (!profileCompleted) return PartnerOnboardingStep.basicInfo;
  if (!kycCompleted) return PartnerOnboardingStep.kyc;
  if (!bankCompleted) return PartnerOnboardingStep.bank;
  return PartnerOnboardingStep.verificationPending;
}

class PartnerOnboardingState {
  const PartnerOnboardingState({
    this.isBootstrapping = false,
    this.isSubmitting = false,
    this.hasLoaded = false,
    this.errorMessage = '',
    this.status = '',
    this.profileCompleted = false,
    this.kycCompleted = false,
    this.bankCompleted = false,
    this.selfieUploaded = false,
    this.panUploaded = false,
    this.panVerified = false,
    this.policeUploaded = false,
    this.panVerificationStatus = '',
    this.fullName = '',
    this.phone = '',
    this.availableServices = kDefaultPartnerServices,
    this.helperId = '',
    this.requestId = '',
    this.rejectionReason = '',
    this.submittedAt = '',
    this.dashboardData = const <String, dynamic>{},
  });

  final bool isBootstrapping;
  final bool isSubmitting;
  final bool hasLoaded;
  final String errorMessage;
  final String status;
  final bool profileCompleted;
  final bool kycCompleted;
  final bool bankCompleted;
  final bool selfieUploaded;
  final bool panUploaded;
  final bool panVerified;
  final bool policeUploaded;
  final String panVerificationStatus;
  final String fullName;
  final String phone;
  final List<String> availableServices;
  final String helperId;
  final String requestId;
  final String rejectionReason;
  final String submittedAt;
  final Map<String, dynamic> dashboardData;

  String get effectiveStatus {
    final helper = dashboardData['helper'];
    if (helper is Map) {
      final status = (helper['onboardingStatus'] as String? ?? '').trim();
      if (status.isNotEmpty) return status;
    }

    final dashboardStatus = (dashboardData['onboardingStatus'] as String? ?? '')
        .trim();
    if (dashboardStatus.isNotEmpty) return dashboardStatus;

    return status;
  }

  PartnerOnboardingStep get currentStep => resolvePartnerOnboardingStep(
    rawStatus: effectiveStatus,
    profileCompleted: profileCompleted,
    kycCompleted: kycCompleted,
    bankCompleted: bankCompleted,
  );

  bool get isKycReadyForNext => selfieUploaded && panVerified && policeUploaded;

  PartnerOnboardingState copyWith({
    bool? isBootstrapping,
    bool? isSubmitting,
    bool? hasLoaded,
    String? errorMessage,
    String? status,
    bool? profileCompleted,
    bool? kycCompleted,
    bool? bankCompleted,
    bool? selfieUploaded,
    bool? panUploaded,
    bool? panVerified,
    bool? policeUploaded,
    String? panVerificationStatus,
    String? fullName,
    String? phone,
    List<String>? availableServices,
    String? helperId,
    String? requestId,
    String? rejectionReason,
    String? submittedAt,
    Map<String, dynamic>? dashboardData,
  }) {
    return PartnerOnboardingState(
      isBootstrapping: isBootstrapping ?? this.isBootstrapping,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      errorMessage: errorMessage ?? this.errorMessage,
      status: status ?? this.status,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      kycCompleted: kycCompleted ?? this.kycCompleted,
      bankCompleted: bankCompleted ?? this.bankCompleted,
      selfieUploaded: selfieUploaded ?? this.selfieUploaded,
      panUploaded: panUploaded ?? this.panUploaded,
      panVerified: panVerified ?? this.panVerified,
      policeUploaded: policeUploaded ?? this.policeUploaded,
      panVerificationStatus:
          panVerificationStatus ?? this.panVerificationStatus,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      availableServices: availableServices ?? this.availableServices,
      helperId: helperId ?? this.helperId,
      requestId: requestId ?? this.requestId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      dashboardData: dashboardData ?? this.dashboardData,
    );
  }
}

class PartnerOnboardingNotifier extends StateNotifier<PartnerOnboardingState> {
  PartnerOnboardingNotifier(
    this._partnerRepository,
    this._servicesRepository,
    this._userRepository,
  ) : super(const PartnerOnboardingState());

  final PartnerRepository _partnerRepository;
  final ServicesRepository _servicesRepository;
  final UserRepository _userRepository;

  Future<void> bootstrap({bool loadServices = false}) async {
    if (state.isBootstrapping) return;
    state = state.copyWith(isBootstrapping: true, errorMessage: '');

    try {
      final results = await Future.wait<Map<String, dynamic>>([
        _safeGetOnboardingStatus(),
        loadServices ? _safeGetServices() : Future.value(<String, dynamic>{}),
        _safeGetProfile(),
        _safeGetOpsDashboard(),
      ]);

      _mergeBootstrapPayloads(
        statusPayload: results[0],
        servicesPayload: results[1],
        profilePayload: results[2],
        dashboardPayload: results[3],
      );
    } finally {
      state = state.copyWith(isBootstrapping: false, hasLoaded: true);
    }
  }

  Future<Map<String, dynamic>> submitProfile({
    required String fullName,
    required String city,
    required String serviceArea,
    required List<String> skills,
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      final res = await _partnerRepository.submitOnboardingProfile(
        fullName: fullName,
        city: city,
        serviceArea: serviceArea,
        skills: skills,
        latitude: latitude,
        longitude: longitude,
      );
      final success = res['success'] == true;
      state = state.copyWith(
        isSubmitting: false,
        fullName: fullName,
        profileCompleted: success || state.profileCompleted,
        status: success ? 'PENDING_KYC' : state.status,
        errorMessage: success ? '' : _messageFromPayload(res),
      );
      if (success) {
        await refreshStatus();
      }
      return res;
    } catch (e) {
      final message = e.toString();
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      return <String, dynamic>{'success': false, 'message': message};
    }
  }

  void prepareForSelfieUpload() {
    state = state.copyWith(
      selfieUploaded: false,
      kycCompleted: false,
      errorMessage: '',
    );
  }

  void prepareForPanUpload() {
    state = state.copyWith(
      panUploaded: false,
      panVerified: false,
      policeUploaded: false,
      kycCompleted: false,
      panVerificationStatus: '',
      errorMessage: '',
    );
  }

  void prepareForPoliceUpload() {
    state = state.copyWith(
      policeUploaded: false,
      kycCompleted: false,
      errorMessage: '',
    );
  }

  Future<Map<String, dynamic>> uploadSelfie(File file) async {
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      final res = await _partnerRepository.uploadKycSelfie(file);
      final success = res['success'] == true;
      state = state.copyWith(
        isSubmitting: false,
        selfieUploaded: success,
        errorMessage: success ? '' : _messageFromPayload(res),
      );
      return res;
    } catch (e) {
      final message = e.toString();
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      return <String, dynamic>{'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> verifyPan(File file) async {
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      final res = await _partnerRepository.verifyKycPan(file);
      final verificationStatus = (res['verificationStatus'] as String? ?? '')
          .trim()
          .toUpperCase();
      final uploadSucceeded = res['success'] == true;
      final canProceedToPolice =
          uploadSucceeded &&
          (verificationStatus.isEmpty || verificationStatus == 'VERIFIED');
      state = state.copyWith(
        isSubmitting: false,
        panUploaded: uploadSucceeded,
        panVerified: canProceedToPolice,
        policeUploaded: canProceedToPolice ? state.policeUploaded : false,
        panVerificationStatus: verificationStatus.isNotEmpty
            ? verificationStatus
            : (uploadSucceeded ? 'UPLOADED' : ''),
        errorMessage: uploadSucceeded ? '' : _messageFromPayload(res),
      );
      return res;
    } catch (e) {
      final message = e.toString();
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      return <String, dynamic>{'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> uploadPolice(File file) async {
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      final res = await _partnerRepository.uploadKycPolice(file);
      final success = res['success'] == true;
      state = state.copyWith(
        isSubmitting: false,
        policeUploaded: success,
        kycCompleted: success || state.kycCompleted,
        status: success ? 'PENDING_BANK' : state.status,
        errorMessage: success ? '' : _messageFromPayload(res),
      );
      if (success) {
        await refreshStatus();
      }
      return res;
    } catch (e) {
      final message = e.toString();
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      return <String, dynamic>{'success': false, 'message': message};
    }
  }

  Future<Map<String, dynamic>> submitBank({
    required String accountName,
    required String accountNumber,
    required String ifsc,
    required String bankName,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      final res = await _partnerRepository.submitOnboardingBank(
        accountName: accountName,
        accountNumber: accountNumber,
        ifsc: ifsc,
        bankName: bankName,
      );
      final success = res['success'] == true;
      final bankPayload = _extractNestedMap(res['data']);
      final bankData = _extractNestedMap(bankPayload['bank']);
      final helperId = _firstNonEmptyString(<dynamic>[
        bankPayload['helperId'],
        bankData['helperId'],
      ]);
      final submittedAt = _firstNonEmptyString(<dynamic>[
        bankData['updatedAt'],
        bankData['createdAt'],
        res['submittedAt'],
      ]);
      state = state.copyWith(
        isSubmitting: false,
        bankCompleted: success || state.bankCompleted,
        status: success ? 'PENDING_REVIEW' : state.status,
        helperId: helperId.isNotEmpty ? helperId : state.helperId,
        submittedAt: submittedAt.isNotEmpty ? submittedAt : state.submittedAt,
        errorMessage: success ? '' : _messageFromPayload(res),
      );
      if (success) {
        await refreshStatus();
      }
      return res;
    } catch (e) {
      final message = e.toString();
      state = state.copyWith(isSubmitting: false, errorMessage: message);
      return <String, dynamic>{'success': false, 'message': message};
    }
  }

  Future<void> refreshStatus() async {
    final results = await Future.wait<Map<String, dynamic>>([
      _safeGetOnboardingStatus(),
      _safeGetOpsDashboard(),
    ]);
    _mergeStatusPayload(results[0]);
    _mergeDashboardPayload(results[1]);
  }

  Future<Map<String, dynamic>> _safeGetOnboardingStatus() async {
    try {
      return await _partnerRepository.getOnboardingStatus();
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _safeGetServices() async {
    try {
      return await _servicesRepository.getServices();
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _safeGetProfile() async {
    try {
      return await _userRepository.getProfile();
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _safeGetOpsDashboard() async {
    try {
      return await _partnerRepository.getOpsDashboard();
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': e.toString()};
    }
  }

  void _mergeBootstrapPayloads({
    required Map<String, dynamic> statusPayload,
    required Map<String, dynamic> servicesPayload,
    required Map<String, dynamic> profilePayload,
    required Map<String, dynamic> dashboardPayload,
  }) {
    _mergeStatusPayload(statusPayload);
    _mergeDashboardPayload(dashboardPayload);

    final serviceNames = _extractServices(servicesPayload);
    final user = profilePayload['user'];
    final fullName = user is Map<String, dynamic>
        ? (user['name'] as String? ?? '').trim()
        : '';
    final phone = user is Map<String, dynamic>
        ? (user['phone'] as String? ?? '').trim()
        : '';

    state = state.copyWith(
      availableServices: serviceNames.isNotEmpty
          ? serviceNames
          : state.availableServices,
      fullName: fullName.isNotEmpty ? fullName : state.fullName,
      phone: phone.isNotEmpty ? phone : state.phone,
    );
  }

  void _mergeDashboardPayload(Map<String, dynamic> payload) {
    final dashboard = _extractDashboardData(payload);
    if (dashboard.isEmpty) return;

    final helper = dashboard['helper'];
    final helperMap = helper is Map
        ? Map<String, dynamic>.from(helper)
        : const <String, dynamic>{};
    final dashboardStatus = _firstNonEmptyString(<dynamic>[
      helperMap['onboardingStatus'],
      dashboard['onboardingStatus'],
      payload['status'],
    ]);
    final helperName = (helperMap['name'] as String? ?? '').trim();
    final helperId = _firstNonEmptyString(<dynamic>[helperMap['id']]);
    final isReviewStage =
        onboardingStatusNeedsReview(dashboardStatus) ||
        onboardingStatusIsApproved(dashboardStatus);

    state = state.copyWith(
      dashboardData: dashboard,
      status: dashboardStatus.isNotEmpty ? dashboardStatus : state.status,
      fullName: helperName.isNotEmpty ? helperName : state.fullName,
      helperId: helperId.isNotEmpty ? helperId : state.helperId,
      profileCompleted: isReviewStage ? true : state.profileCompleted,
      kycCompleted: isReviewStage ? true : state.kycCompleted,
      bankCompleted: isReviewStage ? true : state.bankCompleted,
      selfieUploaded: isReviewStage ? true : state.selfieUploaded,
      panUploaded: isReviewStage ? true : state.panUploaded,
      panVerified: isReviewStage ? true : state.panVerified,
      policeUploaded: isReviewStage ? true : state.policeUploaded,
      panVerificationStatus: isReviewStage
          ? (state.panVerificationStatus.isNotEmpty
                ? state.panVerificationStatus
                : 'VERIFIED')
          : state.panVerificationStatus,
    );
  }

  void _mergeStatusPayload(Map<String, dynamic> payload) {
    final steps = payload['steps'];
    final backendProfileCompleted = _stepFlag(steps, 'profile');
    final backendKycCompleted = _stepFlag(steps, 'kyc');
    final backendBankCompleted = _stepFlag(steps, 'bank');
    final rawStatus = (payload['status'] as String? ?? '').trim();
    final requestId = _firstNonEmptyString(<dynamic>[
      payload['requestId'],
      payload['onboardingRequestId'],
      payload['id'],
    ]);
    final rejectionReason = _firstNonEmptyString(<dynamic>[
      payload['rejectionReason'],
      payload['reason'],
    ]);

    state = state.copyWith(
      status: rawStatus.isNotEmpty ? rawStatus : state.status,
      profileCompleted: backendProfileCompleted || state.profileCompleted,
      kycCompleted: backendKycCompleted || state.kycCompleted,
      bankCompleted: backendBankCompleted || state.bankCompleted,
      selfieUploaded: backendKycCompleted || state.selfieUploaded,
      panUploaded: backendKycCompleted || state.panUploaded,
      panVerified: backendKycCompleted || state.panVerified,
      policeUploaded: backendKycCompleted || state.policeUploaded,
      panVerificationStatus: backendKycCompleted
          ? 'VERIFIED'
          : state.panVerificationStatus,
      requestId: requestId.isNotEmpty ? requestId : state.requestId,
      rejectionReason: rejectionReason.isNotEmpty
          ? rejectionReason
          : state.rejectionReason,
      submittedAt: _firstNonEmptyString(<dynamic>[
        payload['submittedAt'],
        payload['updatedAt'],
        payload['createdAt'],
        state.submittedAt,
      ]),
      errorMessage: payload['success'] == false
          ? _messageFromPayload(payload)
          : '',
    );
  }

  Map<String, dynamic> _extractDashboardData(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    final dashboard = payload['dashboard'];
    if (dashboard is Map) {
      return Map<String, dynamic>.from(dashboard);
    }

    if (payload['helper'] is Map ||
        payload.containsKey('pendingRequestsCount') ||
        payload.containsKey('activeBooking')) {
      return Map<String, dynamic>.from(payload);
    }

    return const <String, dynamic>{};
  }

  List<String> _extractServices(Map<String, dynamic> payload) {
    final services = payload['services'];
    if (services is! List) return const <String>[];

    final names = <String>{};
    for (final service in services) {
      if (service is Map<String, dynamic>) {
        final name = service['name'];
        if (name is String && name.trim().isNotEmpty) {
          names.add(name.trim());
        }
      } else if (service is String && service.trim().isNotEmpty) {
        names.add(service.trim());
      }
    }

    final list = names.toList()..sort();
    return list;
  }

  bool _stepFlag(dynamic steps, String key) {
    if (steps is! Map) return false;
    final value = steps[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value.trim().toLowerCase() == 'true';
    }
    return false;
  }

  String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      if (value is num) {
        return value.toString();
      }
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  Map<String, dynamic> _extractNestedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  String _messageFromPayload(Map<String, dynamic> payload) {
    final message = payload['message'] ?? payload['error'] ?? payload['detail'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }
    return 'Request failed';
  }
}

final partnerOnboardingProvider =
    StateNotifierProvider<PartnerOnboardingNotifier, PartnerOnboardingState>((
      ref,
    ) {
      return PartnerOnboardingNotifier(
        ref.read(partnerRepositoryProvider),
        ref.read(servicesRepositoryProvider),
        ref.read(userRepositoryProvider),
      );
    });
