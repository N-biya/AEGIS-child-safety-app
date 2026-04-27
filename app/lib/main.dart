import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'utils/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const AegisApp());
}

class AegisApp extends StatelessWidget {
  const AegisApp({super.key});

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
          debugShowCheckedModeBanner: false,
          themeMode: notifier.themeMode,
          theme: aegisTheme.copyWith(
            textTheme: GoogleFonts.nunitoTextTheme(aegisTheme.textTheme),
          ),
          darkTheme: aegisDarkTheme.copyWith(
            textTheme: GoogleFonts.nunitoTextTheme(aegisDarkTheme.textTheme),
          ),
          initialRoute: '/',
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}
