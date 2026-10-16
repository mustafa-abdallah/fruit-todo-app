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
      // نحدد الثيم الداكن هنا
      theme: ThemeData(
        brightness: Brightness.dark,
        // الخلفية السوداء الأساسية من الصورة
        scaffoldBackgroundColor: const Color(0xff000000), 
        // الألوان الداكنة للعناصر الأخرى
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff26C6DA), // الأزرق التيل التميزي
          secondary: Color(0xff1E1E1E), // لون البطاقات
          surface: Color(0xff1E1E1E), // لون خلفية العناصر
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // أيقونة بسيطة بلون التمييز
            const Icon(
              Icons.timer_outlined,
              size: 80,
              color: Color(0xff26C6DA),
            ),
            const SizedBox(height: 30),
            const Text(
              '🫒 فروت بومودورو والمهام',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'تنظيم المهام ومؤقت الإنتاجية بأحدث تصميم داكن ومريح للعين.',
                style: TextStyle(
                  fontSize: 16, 
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 50),
            // زر داكن بألوان التمييز
            ElevatedButton(
              onPressed: () {
                // سنضيف الانتقال للشاشة التالية هنا لاحقاً
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1E1E1E),
                foregroundColor: const Color(0xff26C6DA),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xff26C6DA), width: 1),
                ),
              ),
              child: const Text(
                'ابدأ الآن',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
