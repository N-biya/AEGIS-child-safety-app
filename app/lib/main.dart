import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'services/share_intake_service.dart';
import 'utils/app_globals.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AegisApp());
}

class AegisApp extends StatefulWidget {
  const AegisApp({super.key});

  @override
  State<AegisApp> createState() => _AegisAppState();
}

class _AegisAppState extends State<AegisApp> {
  @override
  void initState() {
    super.initState();
    // Listen for locations shared into AEGIS from Google Maps' share sheet.
    // Deferred a frame so the root navigator is ready to show the chooser.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => ShareIntakeService.instance.init());
  }

  @override
  void dispose() {
    ShareIntakeService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (_, notifier, __) => MaterialApp(
          title: 'AEGIS',
          navigatorKey: rootNavigatorKey,
          debugShowCheckedModeBanner: false,
          themeMode: notifier.themeMode,
          theme: aegisLightTheme,
          darkTheme: aegisDarkTheme,
          initialRoute: '/',
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}
