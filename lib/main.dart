import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'session/session_manager.dart';
import 'widgets/connectivity_guard.dart';
import 'widgets/professional_page_transitions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  await SessionManager().initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Helperr4U - Demo',
      theme: AppTheme.light().copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ProfessionalPageTransitionsBuilder(),
            TargetPlatform.iOS: ProfessionalPageTransitionsBuilder(),
            TargetPlatform.macOS: ProfessionalPageTransitionsBuilder(),
            TargetPlatform.windows: ProfessionalPageTransitionsBuilder(),
            TargetPlatform.linux: ProfessionalPageTransitionsBuilder(),
            TargetPlatform.fuchsia: ProfessionalPageTransitionsBuilder(),
          },
        ),
      ),
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes(),
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }

        return ConnectivityGuard(child: child);
      },
    );
  }
}
