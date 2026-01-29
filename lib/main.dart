import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syncfusion_flutter_core/core.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 註冊 Syncfusion Community License
  SyncfusionLicense.registerLicense(
    'Ngo9BigBOggjHTQxAR8/V1JGaF5cXGpCf1FpRmJGdld5fUVHYVZUTXxaS00DNHVRdkdmWH1ceXRSRWVZUEx2XkRWYEs='
  );
  
  // 載入 .env 檔案
  // 在開發階段，.env 檔案應該在專案根目錄
  // 在生產環境，.env 檔案應該在 assets 目錄中（需要先在 pubspec.yaml 中配置）
  try {
    await dotenv.load(fileName: '.env');
    print('✓ .env file loaded successfully');
    
    // 驗證必要的環境變數是否存在
    if (dotenv.env['GEMINI_API_KEY'] == null || dotenv.env['GEMINI_API_KEY']!.isEmpty) {
      print('⚠ Warning: GEMINI_API_KEY is not set in .env file');
    }
    if (dotenv.env['TIINGO_API_TOKEN'] == null || dotenv.env['TIINGO_API_TOKEN']!.isEmpty) {
      print('⚠ Warning: TIINGO_API_TOKEN is not set in .env file');
    }
  } catch (e) {
    print('⚠ Warning: Could not load .env file: $e');
    print('⚠ Application will continue, but API services may not work without proper configuration');
    print('⚠ Please ensure .env file exists in the project root with GEMINI_API_KEY and TIINGO_API_TOKEN');
  }

  runApp(const ProviderScope(child: StockKolTrackerApp()));
}

class StockKolTrackerApp extends StatelessWidget {
  const StockKolTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock KOL Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('zh', 'TW'), // Traditional Chinese
      ],
      home: const HomeScreen(),
    );
  }
}

