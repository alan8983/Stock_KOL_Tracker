import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 載入 .env 檔案
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Warning: Could not load .env file: $e');
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
      home: const HomeScreen(),
    );
  }
}

