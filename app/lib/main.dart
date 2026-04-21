import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const AegisApp());
}

class AegisApp extends StatelessWidget {
  const AegisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'AEGIS',
        debugShowCheckedModeBanner: false,
        theme: aegisTheme.copyWith(
          textTheme: GoogleFonts.nunitoTextTheme(aegisTheme.textTheme),
        ),
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
