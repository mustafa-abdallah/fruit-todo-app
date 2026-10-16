import 'dart:async';
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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff000000),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xff26C6DA),
          secondary: Color(0xff1E1E1E),
          surface: Color(0xff1E1E1E),
          onPrimary: Colors.black,
          onSurface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

// 1. شاشة الترحيب
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const Text(
                'نظم مهامك واجمع فواكه الإنتاجية بتصميم داكن مريح للعين.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
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
      ),
    );
  }
}

// نموذج المهمة
class TaskItem {
  String title;
  bool isDone;
  TaskItem({required this.title, this.isDone = false});
}

// نموذج الفواكه
class FruitModel {
  final String name;
  final int minutes;
  final String icon;
  FruitModel({required this.name, required this.minutes, required this.icon});
}

// 2. الشاشة الرئيسية واللوحة المتكاملة
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<TaskItem> _tasks = [
    TaskItem(title: 'مراجعة أكواد البرمجة', isDone: false),
    TaskItem(title: 'قراءة كتاب تقني لمدة 20 دقيقة', isDone: true),
  ];

  final TextEditingController _taskController = TextEditingController();

  // قائمة الفواكه ومقاديرها الزمنية
  final List<FruitModel> _fruits = [
    FruitModel(name: 'زيتونة', minutes: 5, icon: '🫒'),
    FruitModel(name: 'فراولة', minutes: 10, icon: '🍓'),
    FruitModel(name: 'عنب', minutes: 15, icon: '🍇'),
    FruitModel(name: 'برتقال', minutes: 20, icon: '🍊'),
    FruitModel(name: 'تفاحة', minutes: 25, icon: '🍎'),
    FruitModel(name: 'موز', minutes: 30, icon: '🍌'),
    FruitModel(name: 'مانجو', minutes: 40, icon: '🥭'),
    FruitModel(name: 'بطيخ', minutes: 50, icon: '🍉'),
  ];

  int totalMinutesHarvested = 0;
  final List<String> harvestedBasket = [];

  void _addNewTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(TaskItem(title: _taskController.text));
        _taskController.clear();
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboardTab(),
      _buildTimerTab(),
      _buildStatsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0
            ? 'المهام اليومية'
            : _currentIndex == 1
                ? 'مؤقت الفواكه'
                : 'سلة الحصاد والإحصائيات'),
        backgroundColor: const Color(0xff1E1E1E),
        centerTitle: true,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xff1E1E1E),
        selectedItemColor: const Color(0xff26C6DA),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'المهام'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'المؤقت'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'الحصاد'),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xff26C6DA),
              child: const Icon(Icons.add, color: Colors.black),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xff1E1E1E),
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('إضافة مهمة جديدة',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            hintText: 'اكتب اسم المهمة...',
                            filled: true,
                            fillColor: Colors.black,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _addNewTask,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff26C6DA),
                              foregroundColor: Colors.black),
                          child: const Text('حفظ المهمة'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  // تبويب المهام
  Widget _buildDashboardTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xff1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CheckboxListTile(
            title: Text(
              task.title,
              style: TextStyle(
                color: task.isDone ? Colors.grey : Colors.white,
                decoration: task.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            value: task.isDone,
            activeColor: const Color(0xff26C6DA),
            onChanged: (val) {
              setState(() {
                task.isDone = val ?? false;
              });
            },
          ),
        );
      },
    );
  }

  // تبويب مؤقت الفواكه
  Widget _buildTimerTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text('اختر فاكهة التركيز:',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 15),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _fruits.length,
              itemBuilder: (context, index) {
                final fruit = _fruits[index];
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ActiveTimerScreen(
                          fruit: fruit,
                          onFinished: (mins) {
                            setState(() {
                              totalMinutesHarvested += mins;
                              harvestedBasket.add(fruit.icon);
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text(fruit.icon, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fruit.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${fruit.minutes} دقيقة',
                                style: const TextStyle(
                                    color: Color(0xff26C6DA), fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // تبويب الإحصائيات والحصاد
  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xff1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('إجمالي وقت التركيز اليوم',
                    style: TextStyle(color: Colors.grey, fontSize: 16)),
                const SizedBox(height: 10),
                Text('$totalMinutesHarvested دقيقة',
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff26C6DA))),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text('سلة الفواكه المحصودة اليوم:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: harvestedBasket.isEmpty
                ? const Center(
                    child: Text('لم تجمع أي فواكه اليوم بعد، ابدأ جلسة تركيز!',
                        style: TextStyle(color: Colors.grey)))
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: harvestedBasket
                        .map((icon) => Chip(
                              backgroundColor: const Color(0xff1E1E1E),
                              label: Text(icon,
                                  style: const TextStyle(fontSize: 22)),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

// 3. شاشة المؤقت النشط أثناء العد التنازلي
class ActiveTimerScreen extends StatefulWidget {
  final FruitModel fruit;
  final Function(int) onFinished;

  const ActiveTimerScreen(
      {super.key, required this.fruit, required this.onFinished});

  @override
  State<ActiveTimerScreen> createState() => _ActiveTimerScreenState();
}

class _ActiveTimerScreenState extends State<ActiveTimerScreen> {
  late int remainingSeconds;
  Timer? _timer;
  bool isRunning = true;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.fruit.minutes * 60;
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        widget.onFinished(widget.fruit.minutes);
        _showFinishedDialog();
      }
    });
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1E1E1E),
        title: Text('أحسنت! 🥳 حصلت على ${widget.fruit.icon}'),
        content: Text(
            'أتممت جلسة ${widget.fruit.name} بنجاح (${widget.fruit.minutes} دقيقة).'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // إغلاق النافذة
              Navigator.pop(context); // العودة للخروج
            },
            child: const Text('رائع',
                style: TextStyle(color: Color(0xff26C6DA))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    String timeFormatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('جلسة ${widget.fruit.name} ${widget.fruit.icon}'),
        backgroundColor: const Color(0xff1E1E1E),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.fruit.icon, style: const TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            Text(
              timeFormatted,
              style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff26C6DA)),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isRunning) {
                        _timer?.cancel();
                      } else {
                        startTimer();
                      }
                      isRunning = !isRunning;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1E1E1E),
                    foregroundColor: const Color(0xff26C6DA),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                  child: Text(isRunning ? 'إيقاف مؤقت' : 'استئناف'),
                ),
                const SizedBox(width: 15),
                OutlinedButton(
                  onPressed: () {
                    _timer?.cancel();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('إنهاء الجلسة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
