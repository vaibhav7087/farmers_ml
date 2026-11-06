import 'package:flutter_localizations/flutter_localizations.dart';
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
        title: 'Kisaan-ML Demo',
        builder: (context, child) => Banner(message: 'DEMO', location: BannerLocation.topEnd, child: child!),
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        locale: const Locale('en', 'US'),
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('hi', 'IN'),
          Locale('mr', 'IN'),
        ],
      ),
    );
  }
}



