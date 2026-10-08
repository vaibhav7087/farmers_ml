import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/advisory/providers/advisory_provider.dart';
import 'features/profile/providers/profile_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KisaanMLApp());
}

class KisaanMLApp extends StatelessWidget {
  const KisaanMLApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => AdvisoryProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..load()),
      ],
      child: MaterialApp.router(
        title: 'Kisaan-ML',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('hi', 'IN'),
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('hi', 'IN'),
          Locale('mr', 'IN'),
        ],
      ),
    );
  }
}