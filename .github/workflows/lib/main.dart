import 'package:flutter/material.dart';

void main() {
  runApp(const FruitTodoApp());
}

class FruitTodoApp extends StatelessWidget {
  const FruitTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فروت بومودورو',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('🫒 فروت بومودورو والمهام'),
          centerTitle: true,
          backgroundColor: Colors.green.shade100,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'أهلاً بك في تطبيق تنظيم المهام بالفاكهة!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'جاري بناء أول نسخة APK تلقائياً عبر GitHub...',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
