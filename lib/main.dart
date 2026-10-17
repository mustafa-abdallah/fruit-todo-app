import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// الفواكه
// ============================================================
class Fruit {
  final String name;
  final String icon;
  final int minutes;
  final Color color;
  const Fruit(this.name, this.icon, this.minutes, this.color);
}

// الترتيب هنا من اليمين لليسار (نفس ترتيب الصورة)
const List<Fruit> kFruits = [
  Fruit('زيتونة', '🫒', 5, Color(0xFF9CCC65)),
  Fruit('ليمونة', '🍋', 10, Color(0xFFFDD835)),
  Fruit('خيار', '🥒', 15, Color(0xFF66BB6A)),
  Fruit('فلفل', '🫑', 20, Color(0xFFFFCA28)),
  Fruit('طماطم', '🍅', 25, Color(0xFFEF5350)),
  Fruit('جزر', '🥕', 30, Color(0xFFFF8A3D)),
  Fruit('أفوكادو', '🥑', 40, Color(0xFFA1887F)),
  Fruit('شمندر', '🍠', 50, Color(0xFFCE6FA5)),
  Fruit('كرنب', '🥬', 60, Color(0xFF7CB342)),
];

// ============================================================
// النماذج
// ============================================================
class Session {
  final String fruitName;
  final String fruitIcon;
  final int minutes;
  String project; // فاضي = بدون نشاط
  final DateTime endedAt;

  Session({
    required this.fruitName,
    required this.fruitIcon,
    required this.minutes,
    required this.project,
    required this.endedAt,
  });

  Map<String, dynamic> toJson() => {
        'fn': fruitName,
        'fi': fruitIcon,
        'm': minutes,
        'p': project,
        't': endedAt.millisecondsSinceEpoch,
      };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
        fruitName: j['fn'] as String,
        fruitIcon: j['fi'] as String,
        minutes: j['m'] as int,
        project: j['p'] as String,
        endedAt: DateTime.fromMillisecondsSinceEpoch(j['t'] as int),
      );
}

class TaskItem {
  String title;
  bool done;
  TaskItem({required this.title, this.done = false});

  Map<String, dynamic> toJson() => {'t': title, 'd': done};

  factory TaskItem.fromJson(Map<String, dynamic> j) =>
      TaskItem(title: j['t'] as String, done: j['d'] as bool);
}

class Habit {
  String name;
  Set<String> days;
  Habit({required this.name, Set<String>? days}) : days = days ?? <String>{};

  Map<String, dynamic> toJson() => {'n': name, 'd': days.toList()};

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
        name: j['n'] as String,
        days: Set<String>.from(j['d'] as List),
      );
}

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// السلسلة الحالية: أيام متتالية حتى اليوم (أو حتى أمس لو اليوم لم يكتمل بعد)
int currentStreak(Set<String> days) {
  final now = DateTime.now();
  var d = DateTime(now.year, now.month, now.day);
  if (!days.contains(dayKey(d))) d = DateTime(d.year, d.month, d.day - 1);
  int n = 0;
  while (days.contains(dayKey(d))) {
    n++;
    d = DateTime(d.year, d.month, d.day - 1);
  }
  return n;
}

// أطول سلسلة أيام متتالية في التاريخ كله
int bestStreak(Set<String> days) {
  if (days.isEmpty) return 0;
  final list = days.map((k) {
    final p = k.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }).toList()
    ..sort();
  int best = 1;
  int run = 1;
  for (int i = 1; i < list.length; i++) {
    final prev = list[i - 1];
    if (DateTime(prev.year, prev.month, prev.day + 1) == list[i]) {
      run++;
    } else {
      run = 1;
    }
    if (run > best) best = run;
  }
  return best;
}

// ============================================================
// حالة التطبيق + الحفظ
// ============================================================
class AppState extends ChangeNotifier {
  List<Session> sessions = [];
  List<String> projects = ['عام'];
  List<TaskItem> tasks = [];
  List<Habit> habits = [];
  String? currentProject;

  int themeMode = 2; // 0 تلقائي، 1 نهاري، 2 ليلي
  double fontScale = 1.0;
  int starMinutes = 60;
  bool vibration = true;
  bool sound = true;

  SharedPreferences? _prefs;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    try {
      final s = p.getString('sessions');
      if (s != null) {
        sessions = (jsonDecode(s) as List)
            .map((e) => Session.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final t = p.getString('tasks');
      if (t != null) {
        tasks = (jsonDecode(t) as List)
            .map((e) => TaskItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      final h = p.getString('habits');
      if (h != null) {
        habits = (jsonDecode(h) as List)
            .map((e) => Habit.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {
      // بيانات تالفة: نكمل بقوائم فاضية
    }
    projects = p.getStringList('projects') ?? ['عام'];
    currentProject = p.getString('currentProject');
    themeMode = p.getInt('themeMode') ?? 2;
    fontScale = p.getDouble('fontScale') ?? 1.0;
    starMinutes = p.getInt('starMinutes') ?? 60;
    vibration = p.getBool('vibration') ?? true;
    sound = p.getBool('sound') ?? true;
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setString('sessions', jsonEncode(sessions.map((e) => e.toJson()).toList()));
    p.setString('tasks', jsonEncode(tasks.map((e) => e.toJson()).toList()));
    p.setString('habits', jsonEncode(habits.map((e) => e.toJson()).toList()));
    p.setStringList('projects', projects);
    if (currentProject == null) {
      p.remove('currentProject');
    } else {
      p.setString('currentProject', currentProject!);
    }
    p.setInt('themeMode', themeMode);
    p.setDouble('fontScale', fontScale);
    p.setInt('starMinutes', starMinutes);
    p.setBool('vibration', vibration);
    p.setBool('sound', sound);
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  // ---------- الجلسات ----------
  void addSession(Session s) {
    sessions.add(s);
    _changed();
  }

  void removeSession(Session s) {
    sessions.remove(s);
    _changed();
  }

  int minutesOnDay(DateTime d) {
    final k = dayOf(d);
    int total = 0;
    for (final s in sessions) {
      if (dayOf(s.endedAt) == k) total += s.minutes;
    }
    return total;
  }

  List<Session> sessionsOnDay(DateTime d) {
    final k = dayOf(d);
    return sessions.where((s) => dayOf(s.endedAt) == k).toList();
  }

  Map<String, int> projectTotals(DateTime from, DateTime to) {
    final map = <String, int>{};
    for (final s in sessions) {
      if (!s.endedAt.isBefore(from) && s.endedAt.isBefore(to)) {
        map[s.project] = (map[s.project] ?? 0) + s.minutes;
      }
    }
    return map;
  }

  int projectTotal(String name) {
    int total = 0;
    for (final s in sessions) {
      if (s.project == name) total += s.minutes;
    }
    return total;
  }

  int starsFor(int minutes) {
    final s = minutes ~/ starMinutes;
    return s > 3 ? 3 : s;
  }

  // ---------- المشاريع ----------
  bool addProject(String name) {
    final n = name.trim();
    if (n.isEmpty || projects.contains(n)) return false;
    projects.add(n);
    _changed();
    return true;
  }

  void renameProject(String old, String neu) {
    final n = neu.trim();
    final i = projects.indexOf(old);
    if (i < 0 || n.isEmpty || projects.contains(n)) return;
    projects[i] = n;
    for (final s in sessions) {
      if (s.project == old) s.project = n;
    }
    if (currentProject == old) currentProject = n;
    _changed();
  }

  void deleteProject(String name) {
    projects.remove(name);
    if (currentProject == name) currentProject = null;
    _changed();
  }

  void selectProject(String? name) {
    currentProject = name;
    _changed();
  }

  // ---------- المهام ----------
  void addTask(String title) {
    tasks.add(TaskItem(title: title.trim()));
    _changed();
  }

  void toggleTask(TaskItem t, bool value) {
    t.done = value;
    _changed();
  }

  void removeTask(TaskItem t) {
    tasks.remove(t);
    _changed();
  }

  // ---------- العادات والسلسلة ----------
  Set<String> get focusDays => sessions.map((s) => dayKey(s.endedAt)).toSet();

  bool addHabit(String name) {
    final n = name.trim();
    if (n.isEmpty || habits.any((h) => h.name == n)) return false;
    habits.add(Habit(name: n));
    _changed();
    return true;
  }

  void renameHabit(Habit h, String name) {
    final n = name.trim();
    if (n.isEmpty || habits.any((x) => x.name == n)) return;
    h.name = n;
    _changed();
  }

  void deleteHabit(Habit h) {
    habits.remove(h);
    _changed();
  }

  void toggleHabit(Habit h, DateTime day) {
    final k = dayKey(day);
    if (!h.days.remove(k)) h.days.add(k);
    _changed();
  }

  // ---------- الإعدادات ----------
  void setTheme(int v) {
    themeMode = v;
    _changed();
  }

  void setFontScale(double v) {
    fontScale = v;
    _changed();
  }

  void setStarMinutes(int v) {
    starMinutes = v;
    _changed();
  }

  void setVibration(bool v) {
    vibration = v;
    _changed();
  }

  void setSound(bool v) {
    sound = v;
    _changed();
  }

  void clearAll() {
    sessions = [];
    tasks = [];
    habits = [];
    projects = ['عام'];
    currentProject = null;
    _changed();
  }
}

final AppState app = AppState();

// ============================================================
// أدوات مساعدة
// ============================================================
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

const List<String> _dayNames = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const List<String> _monthNames = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String arDate(DateTime d) =>
    '${_dayNames[d.weekday - 1]}، ${d.day} ${_monthNames[d.month - 1]} ${d.year}';

String hm(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String fmtMinutes(int m) {
  if (m < 60) return '$m د';
  return '${m ~/ 60} س ${m % 60} د';
}

String projName(String p) => p.isEmpty ? 'بدون نشاط' : p;

Color cardColor(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFF363A48)
    : Colors.white;

Color subtle(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark ? Colors.white60 : Colors.black54;

Color trackColor(BuildContext c) => Theme.of(c).brightness == Brightness.dark
    ? const Color(0xFF1F222C)
    : const Color(0xFFD9DDE3);

Color accentOf(BuildContext c) => Theme.of(c).colorScheme.primary;

Future<bool> confirmDialog(BuildContext context, String title, String message,
    {String ok = 'تأكيد'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r == true;
}

// نافذة إدخال نص تظهر فوق الكيبورد (الحقل يفضل ظاهر)
Future<String?> askText(BuildContext context, String title,
    {String initial = '', String hint = ''}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _TextSheet(title: title, initial: initial, hint: hint),
  );
}

class _TextSheet extends StatefulWidget {
  final String title;
  final String initial;
  final String hint;
  const _TextSheet(
      {required this.title, required this.initial, required this.hint});

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final t = _c.text.trim();
    if (t.isNotEmpty) Navigator.pop(context, t);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: _c,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: widget.hint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: _submit, child: const Text('حفظ')),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// التطبيق
// ============================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.load();
  runApp(const FruitApp());
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final accent = dark ? const Color(0xFF1DE9B6) : const Color(0xFF00897B);
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor:
        dark ? const Color(0xFF2B2E3A) : const Color(0xFFF2F4F7),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF00A99D),
      brightness: b,
    ).copyWith(primary: accent),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF1F222C) : Colors.white,
      foregroundColor: accent,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: accent,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: dark ? const Color(0xFF2B2E3A) : Colors.white,
    ),
  );
}

class FruitApp extends StatelessWidget {
  const FruitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return MaterialApp(
          title: 'فروت بومودورو',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: ThemeMode.values[app.themeMode],
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(app.fontScale)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            );
          },
          home: const HomeScreen(),
        );
      },
    );
  }
}

// ============================================================
// الشاشة الرئيسية
// ============================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final today = app.minutesOnDay(DateTime.now());
        final stars = app.starsFor(today);
        final goal = app.starMinutes * 3;
        final progress = (today / goal).clamp(0.0, 1.0).toDouble();
        final accent = accentOf(context);
        final dark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(title: Text(arDate(DateTime.now()))),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 0.95,
                  padding: const EdgeInsets.all(12),
                  children: kFruits.map((f) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimerScreen(fruit: f),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(f.icon, style: const TextStyle(fontSize: 54)),
                          const SizedBox(height: 4),
                          Text(
                            '${f.minutes}',
                            style: TextStyle(
                              fontSize: 30,
                              color: f.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const TodayCard(),
                const SizedBox(height: 12),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                color: dark ? const Color(0xFF23262F) : Colors.white,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('🥗', style: TextStyle(fontSize: 40)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'إنجاز اليوم: $today دقيقة',
                              style: TextStyle(
                                fontSize: 18,
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Row(
                            children: List.generate(3, (i) {
                              return Icon(
                                i < stars ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 30,
                              );
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 16,
                          backgroundColor: trackColor(context),
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'كل ${app.starMinutes} دقيقة = نجمة (الحد الأقصى 3 نجوم)',
                        style: TextStyle(color: subtle(context), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// القائمة الجانبية
// ============================================================
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _go(BuildContext context, Widget page) {
    final nav = Navigator.of(context);
    nav.pop();
    nav.push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentOf(context);
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 140,
              alignment: Alignment.center,
              color: trackColor(context),
              child: const Text('🥗', style: TextStyle(fontSize: 70)),
            ),
            ListTile(
              leading: Icon(Icons.checklist, color: accent),
              title: const Text('المهام'),
              onTap: () => _go(context, const TasksScreen()),
            ),
            ListTile(
              leading: Icon(Icons.local_fire_department, color: accent),
              title: const Text('متعقب العادات'),
              onTap: () => _go(context, const HabitsScreen()),
            ),
            ListTile(
              leading: Icon(Icons.assignment, color: accent),
              title: const Text('سجل الجلسات'),
              onTap: () => _go(context, const SessionsScreen()),
            ),
            ListTile(
              leading: Icon(Icons.category, color: accent),
              title: const Text('أنشطة ومشروعات'),
              onTap: () => _go(context, const ProjectsScreen()),
            ),
            ListTile(
              leading: Icon(Icons.bar_chart, color: accent),
              title: const Text('إحصائيات'),
              onTap: () => _go(context, const StatsScreen()),
            ),
            ListTile(
              leading: Icon(Icons.settings, color: accent),
              title: const Text('إعدادات'),
              onTap: () => _go(context, const SettingsScreen()),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.info_outline, color: accent),
              title: const Text('عن التطبيق'),
              onTap: () {
                Navigator.pop(context);
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('فروت بومودورو 🥗'),
                    content: const Text(
                      'تطبيق لتنظيم وقتك بطريقة البومودورو: اختر فاكهة، ركّز حتى ينتهي الوقت، واجمع نجومك اليومية.\n\nالإصدار 1.0.0',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('حسناً'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: accent),
              title: const Text('شارك التطبيق'),
              onTap: () {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                Clipboard.setData(const ClipboardData(
                  text:
                      'جرّب تطبيق فروت بومودورو لتنظيم وقتك وتركيزك 🥗',
                ));
                messenger.showSnackBar(
                  const SnackBar(content: Text('تم نسخ رسالة المشاركة')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// شاشة المؤقت
// ============================================================
class RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color track;
  RingPainter(this.progress, this.color, this.track);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = track;
    canvas.drawCircle(center, radius, base);

    if (progress > 0) {
      final fg = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, fg);
    }
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}

class TimerScreen extends StatefulWidget {
  final Fruit fruit;
  const TimerScreen({super.key, required this.fruit});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late DateTime _end;
  late Duration _remaining;
  Timer? _ticker;
  bool _paused = false;
  bool _finished = false;
  String? _project;

  Duration get _total => Duration(minutes: widget.fruit.minutes);

  @override
  void initState() {
    super.initState();
    _project = app.currentProject;
    _remaining = _total;
    _end = DateTime.now().add(_total);
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final left = _end.difference(DateTime.now());
      if (left <= Duration.zero) {
        _complete();
      } else {
        setState(() => _remaining = left);
      }
    });
  }

  void _complete() {
    _ticker?.cancel();
    setState(() {
      _remaining = Duration.zero;
      _finished = true;
    });
    unawaited(_alert());
  }

  Future<void> _alert() async {
    for (int i = 0; i < 3; i++) {
      if (app.vibration) HapticFeedback.vibrate();
      if (app.sound) SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 700));
    }
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        _end = DateTime.now().add(_remaining);
        _paused = false;
        _startTicker();
      } else {
        _ticker?.cancel();
        _paused = true;
      }
    });
  }

  Future<void> _cancel() async {
    final ok = await confirmDialog(
      context,
      'إلغاء الجلسة؟',
      'لن يتم حفظ هذه الجلسة.',
      ok: 'إلغاء الجلسة',
    );
    if (ok && mounted) Navigator.pop(context);
  }

  void _save() {
    app.addSession(Session(
      fruitName: widget.fruit.name,
      fruitIcon: widget.fruit.icon,
      minutes: widget.fruit.minutes,
      project: _project ?? '',
      endedAt: DateTime.now(),
    ));
    Navigator.pop(context);
  }

  Future<void> _pickProject() async {
    final res = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: const Text('بدون نشاط'),
              onTap: () => Navigator.pop(ctx, ''),
            ),
            ...app.projects.map(
              (p) => ListTile(
                title: Text(p),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ),
          ],
        ),
      ),
    );
    if (res != null) {
      setState(() => _project = res.isEmpty ? null : res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.fruit.color;
    final secs = (_remaining.inMilliseconds / 1000).ceil();
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    final progress =
        _finished ? 0.0 : _remaining.inMilliseconds / _total.inMilliseconds;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _pickProject,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: trackColor(context), width: 2),
                  color: cardColor(context),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_project ?? 'اختر نشاط / مشروع',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 290,
                  height: 290,
                  child: CustomPaint(
                    painter: RingPainter(progress, color, trackColor(context)),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(widget.fruit.icon,
                              style: const TextStyle(fontSize: 80)),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: trackColor(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$mm : $ss',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!_finished) ...[
              GestureDetector(
                onTap: _togglePause,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(
                    _paused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              OutlinedButton.icon(
                onPressed: _cancel,
                icon: const Icon(Icons.close, color: Colors.red),
                label: const Text('إلغاء / رجوع'),
              ),
              const SizedBox(height: 36),
            ] else ...[
              Text(
                'أحسنت! أتممت ${widget.fruit.minutes} دقيقة 🎉',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('حفظ وإنهاء الجلسة'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('تجاهل الحفظ',
                    style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// المهام
// ============================================================
class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('المهام')),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final t = await askText(context, 'إضافة مهمة جديدة',
                  hint: 'اكتب اسم المهمة...');
              if (t != null) app.addTask(t);
            },
            child: const Icon(Icons.add),
          ),
          body: app.tasks.isEmpty
              ? Center(
                  child: Text('لا توجد مهام بعد',
                      style: TextStyle(color: subtle(context))),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: app.tasks.length,
                  itemBuilder: (context, i) {
                    final task = app.tasks[i];
                    return Dismissible(
                      key: ObjectKey(task),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => app.removeTask(task),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardColor(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CheckboxListTile(
                          value: task.done,
                          onChanged: (v) => app.toggleTask(task, v ?? false),
                          title: Text(
                            task.title,
                            style: TextStyle(
                              color: task.done ? subtle(context) : null,
                              decoration:
                                  task.done ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ============================================================
// سجل الجلسات
// ============================================================
class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final sorted = List<Session>.from(app.sessions)
          ..sort((a, b) => b.endedAt.compareTo(a.endedAt));

        final items = <Widget>[];
        DateTime? lastDay;
        for (final s in sorted) {
          final d = dayOf(s.endedAt);
          if (lastDay == null || d != lastDay) {
            final total = app.minutesOnDay(d);
            items.add(Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(arDate(d),
                        style: TextStyle(
                            color: accentOf(context),
                            fontWeight: FontWeight.w600)),
                  ),
                  Text(fmtMinutes(total),
                      style: TextStyle(color: subtle(context))),
                ],
              ),
            ));
            lastDay = d;
          }
          items.add(Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(s.fruitIcon, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(projName(s.project),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${s.fruitName} • ${hm(s.endedAt)}',
                          style: TextStyle(
                              color: subtle(context), fontSize: 13)),
                    ],
                  ),
                ),
                Text('${s.minutes} د',
                    style: TextStyle(
                        color: accentOf(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await confirmDialog(
                        context, 'حذف الجلسة؟', 'سيتم حذف الجلسة من السجل.',
                        ok: 'حذف');
                    if (ok) app.removeSession(s);
                  },
                ),
              ],
            ),
          ));
        }

        return Scaffold(
          appBar: AppBar(title: const Text('سجل الجلسات')),
          body: sorted.isEmpty
              ? Center(
                  child: Text('لا توجد جلسات بعد',
                      style: TextStyle(color: subtle(context))),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: items,
                ),
        );
      },
    );
  }
}

// ============================================================
// الأنشطة والمشروعات
// ============================================================
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('أنشطة ومشروعات')),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final t = await askText(context, 'نشاط / مشروع جديد',
                  hint: 'مثال: مذاكرة، برمجة...');
              if (t != null) {
                final ok = app.addProject(t);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('هذا الاسم موجود بالفعل')),
                  );
                }
              }
            },
            child: const Icon(Icons.add),
          ),
          body: app.projects.isEmpty
              ? Center(
                  child: Text('لا توجد أنشطة بعد',
                      style: TextStyle(color: subtle(context))),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'اضغط على نشاط لاختياره للعمل عليه في الجلسات القادمة.',
                        style: TextStyle(color: subtle(context), fontSize: 13),
                      ),
                    ),
                    ...app.projects.map((p) {
                      final selected = app.currentProject == p;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: cardColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: selected
                              ? Border.all(color: accentOf(context), width: 2)
                              : null,
                        ),
                        child: ListTile(
                          onTap: () =>
                              app.selectProject(selected ? null : p),
                          leading: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: accentOf(context),
                          ),
                          title: Text(p),
                          subtitle: Text(
                            fmtMinutes(app.projectTotal(p)),
                            style: TextStyle(color: accentOf(context)),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'rename') {
                                final t = await askText(
                                    context, 'تعديل الاسم',
                                    initial: p);
                                if (t != null) app.renameProject(p, t);
                              } else if (v == 'delete') {
                                final ok = await confirmDialog(
                                    context,
                                    'حذف النشاط؟',
                                    'سيبقى وقته محفوظاً في سجل الجلسات.',
                                    ok: 'حذف');
                                if (ok) app.deleteProject(p);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                  value: 'rename', child: Text('تعديل الاسم')),
                              PopupMenuItem(value: 'delete', child: Text('حذف')),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }
}

// ============================================================
// الإحصائيات
// ============================================================
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  const StatCard(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: cardColor(context),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: accentOf(context))),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(color: subtle(context), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class ProjectBars extends StatelessWidget {
  final Map<String, int> totals;
  const ProjectBars(this.totals, {super.key});

  @override
  Widget build(BuildContext context) {
    if (totals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('لا توجد جلسات في هذه الفترة',
            style: TextStyle(color: subtle(context))),
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: entries.map((e) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(projName(e.key))),
                    Text(fmtMinutes(e.value),
                        style: TextStyle(color: accentOf(context))),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: e.value / maxV,
                    minHeight: 8,
                    backgroundColor: trackColor(context),
                    color: accentOf(context),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إحصائيات'),
          bottom: const TabBar(
            tabs: [Tab(text: 'اليوم'), Tab(text: 'الأسبوع')],
          ),
        ),
        body: ListenableBuilder(
          listenable: app,
          builder: (context, _) {
            return TabBarView(
              children: [
                _dailyView(context),
                _weeklyView(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(t,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      );

  Widget _dailyView(BuildContext context) {
    final now = DateTime.now();
    final start = dayOf(now);
    final end = DateTime(now.year, now.month, now.day + 1);
    final total = app.minutesOnDay(now);
    final count = app.sessionsOnDay(now).length;
    final stars = app.starsFor(total);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(arDate(now), style: TextStyle(color: subtle(context))),
        const SizedBox(height: 12),
        Row(
          children: [
            StatCard('وقت التركيز', fmtMinutes(total)),
            StatCard('عدد الجلسات', '$count'),
            StatCard('النجوم', '$stars / 3'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            StatCard('السلسلة الحالية', '🔥 ${currentStreak(app.focusDays)} يوم'),
            StatCard('أطول سلسلة', '🏆 ${bestStreak(app.focusDays)} يوم'),
          ],
        ),
        _title(context, 'حسب النشاط'),
        ProjectBars(app.projectTotals(start, end)),
      ],
    );
  }

  Widget _weeklyView(BuildContext context) {
    final now = DateTime.now();
    // آخر 7 أيام (الأحدث أولاً)
    final days = List.generate(
        7, (i) => DateTime(now.year, now.month, now.day - i));
    final mins = days.map((d) => app.minutesOnDay(d)).toList();
    final total = mins.fold<int>(0, (a, b) => a + b);
    final active = mins.where((m) => m > 0).length;
    final avg7 = (total / 7).round();
    final avgActive = active == 0 ? 0 : (total / active).round();
    final maxV = mins.fold<int>(1, (a, b) => b > a ? b : a);

    final from = days.last;
    final to = DateTime(now.year, now.month, now.day + 1);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            StatCard('إجمالي الأسبوع', fmtMinutes(total)),
            StatCard('متوسط يومي (7 أيام)', '$avg7 د'),
            StatCard('متوسط أيام العمل', '$avgActive د'),
          ],
        ),
        _title(context, 'إنجاز آخر 7 أيام'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardColor(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final d = days[i];
              final m = mins[i];
              return Expanded(
                child: Column(
                  children: [
                    Text('$m', style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      width: 18,
                      height: 120,
                      decoration: BoxDecoration(
                        color: trackColor(context),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: m / maxV,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentOf(context),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_dayNames[d.weekday - 1],
                          style: TextStyle(
                              fontSize: 11, color: subtle(context))),
                    ),
                    Text('${d.day}/${d.month}',
                        style:
                            TextStyle(fontSize: 11, color: subtle(context))),
                  ],
                ),
              );
            }),
          ),
        ),
        _title(context, 'حسب النشاط (آخر 7 أيام)'),
        ProjectBars(app.projectTotals(from, to)),
      ],
    );
  }
}

// ============================================================
// الإعدادات
// ============================================================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Text(t,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('إعدادات')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section('المظهر'),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('تلقائي')),
                  ButtonSegment(value: 1, label: Text('نهاري')),
                  ButtonSegment(value: 2, label: Text('ليلي')),
                ],
                selected: {app.themeMode},
                onSelectionChanged: (s) => app.setTheme(s.first),
              ),
              _section('حجم الخط (${(app.fontScale * 100).round()}%)'),
              Slider(
                value: app.fontScale,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                label: '${(app.fontScale * 100).round()}%',
                onChanged: (v) => app.setFontScale(v),
              ),
              _section('النجوم'),
              Text('عدد الدقائق لكل نجمة: ${app.starMinutes} دقيقة',
                  style: TextStyle(color: subtle(context))),
              Slider(
                value: app.starMinutes.toDouble(),
                min: 30,
                max: 120,
                divisions: 6,
                label: '${app.starMinutes}',
                onChanged: (v) => app.setStarMinutes(v.round()),
              ),
              _section('التنبيه عند انتهاء الجلسة'),
              SwitchListTile(
                title: const Text('اهتزاز الهاتف'),
                value: app.vibration,
                onChanged: (v) => app.setVibration(v),
              ),
              SwitchListTile(
                title: const Text('صوت التنبيه'),
                value: app.sound,
                onChanged: (v) => app.setSound(v),
              ),
              _section('البيانات'),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await confirmDialog(
                    context,
                    'مسح كل البيانات؟',
                    'سيتم حذف الجلسات والمهام والأنشطة. لا يمكن التراجع.',
                    ok: 'مسح',
                  );
                  if (ok) app.clearAll();
                },
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('مسح كل البيانات',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
    );
  }
}


// ============================================================
// كارت "اليوم" في الشاشة الرئيسية: السلسلة + العادات + المهام
// ============================================================
class TodayCard extends StatelessWidget {
  const TodayCard({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final streak = currentStreak(app.focusDays);
    final best = bestStreak(app.focusDays);
    final doneToday = app.minutesOnDay(now) > 0;
    final pending = app.tasks.where((t) => !t.done).toList();
    final shown = pending.take(3).toList();

    String motive;
    if (streak == 0) {
      motive = 'ابدأ جلسة اليوم لتبدأ سلسلتك';
    } else if (doneToday) {
      motive = 'رائع! حافظت على سلسلتك اليوم';
    } else {
      motive = 'لا تقطع السلسلة! جلسة واحدة تكفي';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$streak يوم متتالي',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(motive,
                        style:
                            TextStyle(color: subtle(context), fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: trackColor(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('🏆 $best',
                    style: TextStyle(color: accentOf(context))),
              ),
            ],
          ),
          const Divider(height: 24),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HabitsScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'عادات اليوم (${app.habits.where((h) => h.days.contains(dayKey(now))).length}/${app.habits.length})',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: accentOf(context)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (app.habits.isEmpty)
            Text('أضف عاداتك من القائمة الجانبية',
                style: TextStyle(color: subtle(context), fontSize: 13))
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: app.habits.map((h) {
                return FilterChip(
                  label: Text(h.name),
                  selected: h.days.contains(dayKey(now)),
                  onSelected: (_) => app.toggleHabit(h, now),
                );
              }).toList(),
            ),
          const Divider(height: 24),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TasksScreen()),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'المهام المتبقية (${pending.length})',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: accentOf(context)),
              ),
            ),
          ),
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                app.tasks.isEmpty ? 'لم تضف مهام بعد' : 'أنجزت كل مهامك 🎉',
                style: TextStyle(color: subtle(context), fontSize: 13),
              ),
            )
          else
            ...shown.map((t) {
              return InkWell(
                onTap: () => app.toggleTask(t, true),
                child: Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (_) => app.toggleTask(t, true),
                    ),
                    Expanded(
                      child: Text(t.title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              );
            }),
          if (pending.length > 3)
            Text('+ ${pending.length - 3} مهام أخرى',
                style: TextStyle(color: subtle(context), fontSize: 13)),
        ],
      ),
    );
  }
}

// ============================================================
// متعقب العادات
// ============================================================
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final now = DateTime.now();
        final days =
            List.generate(7, (i) => DateTime(now.year, now.month, now.day - i));
        final dark = Theme.of(context).brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(title: const Text('متعقب العادات')),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final t = await askText(context, 'عادة جديدة',
                  hint: 'مثال: ورد القرآن، رياضة...');
              if (t != null) {
                final ok = app.addHabit(t);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('هذه العادة موجودة بالفعل')),
                  );
                }
              }
            },
            child: const Icon(Icons.add),
          ),
          body: app.habits.isEmpty
              ? Center(
                  child: Text('لا توجد عادات بعد، أضف أول عادة',
                      style: TextStyle(color: subtle(context))),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  children: app.habits.map((h) {
                    final cur = currentStreak(h.days);
                    final best = bestStreak(h.days);
                    final week =
                        days.where((d) => h.days.contains(dayKey(d))).length;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardColor(context),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(h.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600)),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (v) async {
                                  if (v == 'rename') {
                                    final t = await askText(
                                        context, 'تعديل الاسم',
                                        initial: h.name);
                                    if (t != null) app.renameHabit(h, t);
                                  } else if (v == 'delete') {
                                    final ok = await confirmDialog(
                                        context,
                                        'حذف العادة؟',
                                        'سيتم حذف سجل هذه العادة بالكامل.',
                                        ok: 'حذف');
                                    if (ok) app.deleteHabit(h);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'rename',
                                      child: Text('تعديل الاسم')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('حذف')),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            '🔥 $cur يوم • 🏆 أفضل: $best • هذا الأسبوع: $week/7',
                            style: TextStyle(
                                color: subtle(context), fontSize: 13),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: days.map((d) {
                              final done = h.days.contains(dayKey(d));
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => app.toggleHabit(h, d),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: done
                                              ? accentOf(context)
                                              : trackColor(context),
                                        ),
                                        child: done
                                            ? Icon(Icons.check,
                                                size: 20,
                                                color: dark
                                                    ? Colors.black87
                                                    : Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(_dayNames[d.weekday - 1],
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: subtle(context))),
                                      ),
                                      Text('${d.day}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: subtle(context))),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }
}
