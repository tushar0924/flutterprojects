import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'session/session_manager.dart';
import 'widgets/connectivity_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
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
