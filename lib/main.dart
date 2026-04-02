import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'providers/recibo_provider.dart';
import 'providers/user_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Necessário para DateFormat em pt_BR
  await initializeDateFormatting('pt_BR', null);

  // Força barra de status com ícones claros (fundo escuro)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // TODO: RevenueCat — inicializar SDK aqui:
  // await Purchases.configure(PurchasesConfiguration('sua_api_key'));

  // TODO: Google Sign-In — configurar client_id no AndroidManifest/Info.plist

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadFromPrefs()),
        ChangeNotifierProvider(create: (_) => ReciboProvider()),
      ],
      child: const ReciboPro(),
    ),
  );
}

class ReciboPro extends StatelessWidget {
  const ReciboPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReciboPro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      home: const HomeScreen(),
    );
  }
}
