import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tagtoyota/firebase_options.dart';
import 'package:tagtoyota/screen/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:tagtoyota/util/Theme_Provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
     final themeProvider = Provider.of<ThemeProvider>(context);
      return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: themeProvider.theme,
      home: SplashScreen(),
    );
  }
}
