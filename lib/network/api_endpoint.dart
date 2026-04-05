class ApiEndpoint {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.zynexxindia.com/api/',
  );
}

class AuthApiEndpoint {
  static const String login = 'auth/login';
  static const String signup = 'auth/signup';
  static const String verifyOtp = 'auth/verify-otp';
  static const String helperVerifyOtp = 'auth/helper/verify-otp';
  static const String refreshToken = 'auth/refresh-token';
  static const String logout = 'auth/logout';
}

class PartnerApiEndpoint {
  static const String onboardingStatus = 'partner/onboarding/status';
  static const String onboardingProfile = 'partner/onboarding/profile';
  static const String onboardingBank = 'partner/onboarding/bank';

  static const String uploadSelfie = 'partner/kyc/upload-selfie';
  static const String uploadPan = 'partner/kyc/upload-pan';
  static const String uploadAadhar = 'partner/kyc/upload-aadhar';
  static const String uploadPolice = 'partner/kyc/upload-police';

  static const String earningsSummary = 'partner/earnings/summary';
  static const String earningsHistory = 'partner/earnings/history';
  static const String helperEarningsDashboard = 'helper/earnings/dashboard';
  static const String helperEarningsHistory = 'helper/earnings/history';
  static const String helperBank = 'partner/bank-details';
  static String helperEarningsTransaction(String id) =>
      'helper/earnings/transaction/$id';

  static const String opsDashboard = 'partner/ops/dashboard';
  static const String opsStatus = 'partner/ops/status';
  static const String profile = 'partner/profile';
  static const String address = 'partner/address';
  static const String reviews = 'partner/reviews';
  static const String services = 'partner/services';

  static const String publicJobs = 'partner/jobs';
  static const String bookings = 'partner/bookings';
  static const String upcomingBookings = 'partner/bookings/upcoming';
  static const String bookingsHistory = 'partner/bookings/history';

  static String bookingDetail(int bookingId) => '$bookings/$bookingId';
}

class ServicesApiEndpoint {
  static const String list = 'services';

  static String detail(int serviceId) => '$list/$serviceId';
}

class UserApiEndpoint {
  static const String profile = 'user/profile';
  static const String registerHelper = 'user/register-helper';
}
