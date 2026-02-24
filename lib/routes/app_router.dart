import 'package:flutter/widgets.dart';
import '../screens/onboarding/step2_basic_info.dart';
import '../screens/onboarding/step3_kyc_upload.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/language_screen.dart';
import '../screens/onboarding/choose_role_screen.dart';
import '../screens/helperr_home.dart';

class AppRouter {
  static const String login = '/';
    static const String splash = '/splash';
  static const String chooseRole = '/choose-role';
  static const String signup = '/signup';
  static const String onboardingStep2 = '/onboarding/step2';
  static const String onboardingStep3 = '/onboarding/step3';
  static const String otp = '/otp';
  static const String language = '/language';
  static const String home = '/home';

    static Map<String, WidgetBuilder> routes() => {
      splash: (_) => const SplashScreen(),
      login: (_) => const LoginScreen(),
        signup: (_) => const SignupScreen(),
        otp: (_) => const OtpScreen(),
        language: (_) => const LanguageScreen(),
        chooseRole: (_) => const ChooseRoleScreen(),
        onboardingStep2: (_) => const OnboardingStep2(),
        onboardingStep3: (_) => const OnboardingStep3(),
        home: (_) => const HelperrHome(),
      };
}
