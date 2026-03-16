import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/draw_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MukkilapediaApp());
}

class MukkilapediaApp extends StatelessWidget {
  const MukkilapediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DrawProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mukkilapedia Lucky Draw',
        theme: AppTheme.premiumTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
