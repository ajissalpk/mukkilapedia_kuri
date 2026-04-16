import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mukkilapedia_lucky_draw/providers/draw_provider.dart';
import 'package:mukkilapedia_lucky_draw/screens/splash_screen.dart';
import 'package:mukkilapedia_lucky_draw/utils/app_theme.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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