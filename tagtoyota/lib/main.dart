import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tagtoyota/firebase_options.dart';
import 'package:tagtoyota/helper/background_notification_service.dart';
import 'package:tagtoyota/helper/fcm_service.dart';
import 'package:tagtoyota/screen/splash_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FCMService.initialize();

 
  await BackgroundNotificationService.initialize();
  await BackgroundNotificationService.registerPeriodicTask();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TAG Toyota',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
