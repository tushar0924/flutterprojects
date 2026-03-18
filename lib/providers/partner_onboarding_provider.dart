import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/partner_repository.dart';
import '../repositories/services_repository.dart';
import '../repositories/user_repository.dart';
import '../routes/app_router.dart';
import 'partner_provider.dart';

class ServiceModel {
  const ServiceModel({required this.id, required this.name});
  final int id;
  final String name;
}

enum PartnerOnboardingStep { basicInfo, kyc, bank, verificationPending, home }

PartnerOnboardingStep? onboardingStepFromCurrentStep(int currentStep) {
  switch (currentStep) {
    case 2:
      return PartnerOnboardingStep.basicInfo;
    case 3:
      return PartnerOnboardingStep.kyc;
    case 4:
      return PartnerOnboardingStep.bank;
    case 5:
      return PartnerOnboardingStep.verificationPending;
    case 0:
    case 1:
      return null;
    default:
      if (currentStep > 5) return PartnerOnboardingStep.home;
      return null;
  }
}

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
      return AppRouter.chooseRole;
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
  int? backendCurrentStep,
  required String rawStatus,
  required bool profileCompleted,
  required bool kycCompleted,
  required bool bankCompleted,
}) {
  final status = rawStatus.trim().toUpperCase();

  if (onboardingStatusIsApproved(status)) {
    return PartnerOnboardingStep.home;
  }
  final currentStepResolved = backendCurrentStep == null
      ? null
      : onboardingStepFromCurrentStep(backendCurrentStep);
  if (currentStepResolved != null) {
    return currentStepResolved;
  }
  // Each step must be completed before advancing, regardless of server status
  // string. This prevents a stale status (e.g. PENDING_KYC after KYC upload
  // but before the server updates to PENDING_BANK) from skipping the bank step.
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
    this.availableServices = const <ServiceModel>[],
    this.helperId = '',
    this.requestId = '',
    this.rejectionReason = '',
    this.submittedAt = '',
    this.backendCurrentStep,
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
  final List<ServiceModel> availableServices;
  final String helperId;
  final String requestId;
  final String rejectionReason;
  final String submittedAt;
  final int? backendCurrentStep;
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
    backendCurrentStep: backendCurrentStep,
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
    List<ServiceModel>? availableServices,
    String? helperId,
    String? requestId,
    String? rejectionReason,
    String? submittedAt,
    int? backendCurrentStep,
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
      backendCurrentStep: backendCurrentStep ?? this.backendCurrentStep,
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

  Future<void> bootstrapFromChooseRole() async {
    if (state.isBootstrapping) return;
    state = state.copyWith(isBootstrapping: true, errorMessage: '');

    try {
      final results = await Future.wait<Map<String, dynamic>>([
        _safeGetOnboardingStatus(),
        _safeGetServices(),
      ]);

      final statusPayload = results[0];
      final servicesPayload = results[1];

      _mergeStatusPayload(statusPayload);

      final serviceNames = _extractServices(servicesPayload);
      final statusData = statusPayload['data'];
      final statusUser = statusData is Map ? statusData['user'] : null;
      final fullNameFromStatus = statusUser is Map
          ? (statusUser['fullName'] as String? ?? '').trim()
          : '';

      state = state.copyWith(
        availableServices: serviceNames.isNotEmpty
            ? serviceNames
            : state.availableServices,
        fullName: fullNameFromStatus.isNotEmpty
            ? fullNameFromStatus
            : state.fullName,
      );
    } finally {
      state = state.copyWith(isBootstrapping: false, hasLoaded: true);
    }
  }

  Future<Map<String, dynamic>> submitProfile({
    required String fullName,
    String city = '',
    required String serviceArea,
    required List<int> serviceIds,
    String gender = '',
    List<String> workTypes = const [],
    double? latitude,
    double? longitude,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: '');
    try {
      final res = await _partnerRepository.submitOnboardingProfile(
        fullName: fullName,
        city: city,
        serviceArea: serviceArea,
        serviceIds: serviceIds,
        gender: gender,
        workTypes: workTypes,
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

  Future<void> refreshStatus({bool includeDashboard = false}) async {
    final statusPayload = await _safeGetOnboardingStatus();
    _mergeStatusPayload(statusPayload);

    if (!includeDashboard) return;

    final dashboardPayload = await _safeGetOpsDashboard();
    _mergeDashboardPayload(dashboardPayload);
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

    // fullName: try profile endpoint first (field: 'name'), then status
    // response (field: 'fullName' under data.user)
    final profileUser = profilePayload['user'];
    final fullNameFromProfile = profileUser is Map
        ? (profileUser['name'] as String? ?? '').trim()
        : '';
    final statusData = statusPayload['data'];
    final statusUser = statusData is Map ? statusData['user'] : null;
    final fullNameFromStatus = statusUser is Map
        ? (statusUser['fullName'] as String? ?? '').trim()
        : '';
    final fullName = fullNameFromProfile.isNotEmpty
        ? fullNameFromProfile
        : fullNameFromStatus;

    final phone = profileUser is Map
        ? (profileUser['phone'] as String? ?? '').trim()
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
    // New response shape:
    // { success, data: { user, helper: { helperId, onboardingStatus, profile, kyc, bank, services, submittedAt }, step } }
    final dataBag = payload['data'];
    final data = dataBag is Map
        ? Map<String, dynamic>.from(dataBag)
        : const <String, dynamic>{};
    final helperBag = data['helper'];
    final helper = helperBag is Map
        ? Map<String, dynamic>.from(helperBag)
        : const <String, dynamic>{};

    // Status — prefer helper.onboardingStatus, then data.step, then legacy payload.status
    final rawStatus = _firstNonEmptyString(<dynamic>[
      helper['onboardingStatus'],
      data['step'],
      payload['status'],
    ]);

    // Profile complete: profile object exists and has an address
    final profileBag = helper['profile'];
    final newProfileCompleted =
        profileBag is Map && profileBag['address'] != null;

    // KYC complete: all three document URLs present
    final kycBag = helper['kyc'];
    final newKycCompleted = kycBag is Map &&
        kycBag['selfieUrl'] != null &&
        kycBag['panUrl'] != null &&
        kycBag['policeUrl'] != null;

    // Bank complete: account number and IFSC present
    final bankBag = helper['bank'];
    final newBankCompleted = bankBag is Map &&
        bankBag['accountNumber'] != null &&
        bankBag['ifsc'] != null;

    // Legacy step flags (older API shape had payload['steps'])
    final steps = payload['steps'];
    final backendProfileCompleted =
        newProfileCompleted || _stepFlag(steps, 'profile');
    final backendKycCompleted = newKycCompleted || _stepFlag(steps, 'kyc');
    final backendBankCompleted = newBankCompleted || _stepFlag(steps, 'bank');

    final helperId = _firstNonEmptyString(<dynamic>[
      helper['helperId'],
      payload['helperId'],
    ]);
    final userBag = data['user'];
    final user = userBag is Map
        ? Map<String, dynamic>.from(userBag)
        : const <String, dynamic>{};
    final fullName = _firstNonEmptyString(<dynamic>[
      user['fullName'],
      payload['fullName'],
    ]);
    final backendCurrentStep = _extractCurrentStep(<dynamic>[
      data['currentStep'],
      helper['currentStep'],
      payload['currentStep'],
    ]);
    final requestId = _firstNonEmptyString(<dynamic>[
      payload['requestId'],
      payload['onboardingRequestId'],
      payload['id'],
    ]);
    final rejectionReason = _firstNonEmptyString(<dynamic>[
      helper['rejectionReason'],
      payload['rejectionReason'],
      payload['reason'],
    ]);
    final submittedAt = _firstNonEmptyString(<dynamic>[
      helper['submittedAt'],
      payload['submittedAt'],
      payload['updatedAt'],
      payload['createdAt'],
      state.submittedAt,
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
        fullName: fullName.isNotEmpty ? fullName : state.fullName,
      helperId: helperId.isNotEmpty ? helperId : state.helperId,
      requestId: requestId.isNotEmpty ? requestId : state.requestId,
      rejectionReason: rejectionReason.isNotEmpty
          ? rejectionReason
          : state.rejectionReason,
      submittedAt: submittedAt,
        backendCurrentStep: backendCurrentStep,
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

  List<ServiceModel> _extractServices(Map<String, dynamic> payload) {
    final raw = payload['data'] ?? payload['services'];
    if (raw is! List) return const <ServiceModel>[];

    final list = <ServiceModel>[];
    for (final service in raw) {
      if (service is Map<String, dynamic>) {
        final id = service['id'];
        final name = service['name'];
        if (id is int && name is String && name.trim().isNotEmpty) {
          list.add(ServiceModel(id: id, name: name.trim()));
        }
      }
    }
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

  int? _extractCurrentStep(List<dynamic> values) {
    for (final value in values) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return state.backendCurrentStep;
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
