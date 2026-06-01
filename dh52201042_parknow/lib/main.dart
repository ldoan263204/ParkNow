import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/authentication/views/welcome_view.dart';

void main() {
  runApp(const ParkNowApp());
}

class ParkNowApp extends StatelessWidget {
  const ParkNowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkNow',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'), // Thiết lập ngôn ngữ mặc định là Tiếng Việt
      home: const WelcomeView(), // Bắt đầu từ màn hình chào mừng
    );
  }
}