import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

ui.FragmentProgram? wavesProgram;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    wavesProgram = await ui.FragmentProgram.fromAsset('shaders/waves.frag');
    debugPrint('BERHASIL: Shader GradientWaves berhasil dimuat!');
  } catch (e) {
    debugPrint('Gagal memuat shader: $e');
  }

  // Memaksa mesin Flutter memuat font Satoshi secara dinamis di runtime.
  try {
    final fontLoader = FontLoader('Satoshi');
    fontLoader.addFont(rootBundle.load('assets/fonts/satoshi_regular.otf'));
    await fontLoader.load();
    debugPrint('BERHASIL: Font Satoshi berhasil dimuat secara manual!');
  } catch (e) {
    debugPrint('\n=========== ERROR FONT ===========');
    debugPrint('Gagal memuat font Satoshi: $e');
    debugPrint('Pastikan file assets/fonts/satoshi_regular.otf benar-benar ada.');
    debugPrint('==================================\n');
  }

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  runApp(const WorkoutRumahApp());
}

class ExerciseData {
  const ExerciseData({
    required this.name,
    required this.subtitle,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.durationSeconds,
    required this.color,
    required this.icon,
  });

  final String name;
  final String subtitle;
  final int sets;
  final int reps;
  final int restSeconds;
  final int? durationSeconds;
  final Color color;
  final IconData icon;
}

class WorkoutHistory {
  const WorkoutHistory({
    required this.title,
    required this.completedAt,
    required this.durationMinutes,
    required this.exerciseCount,
    required this.calories,
  });

  final String title;
  final DateTime completedAt;
  final int durationMinutes;
  final int exerciseCount;
  final int calories;

  Map<String, dynamic> toJson() => {
        'title': title,
        'completedAt': completedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'exerciseCount': exerciseCount,
        'calories': calories,
      };

  factory WorkoutHistory.fromJson(Map<String, dynamic> json) {
    return WorkoutHistory(
      title: json['title'] as String? ?? 'Workout',
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      exerciseCount: json['exerciseCount'] as int? ?? 0,
      calories: json['calories'] as int? ?? 0,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  UserProfile copyWith({String? name, String? email}) => UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'Andi Ramadhan',
        email: json['email'] as String? ?? 'andi@example.com',
      );
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.day,
    required this.time,
    required this.workout,
    required this.active,
    this.reminderEnabled = true,
    this.reminderMinutes = 30,
  });

  final String id;
  final String day;
  final String time;
  final String workout;
  final bool active;
  final bool reminderEnabled;
  final int reminderMinutes;

  ScheduleItem copyWith({
    bool? active,
    bool? reminderEnabled,
    int? reminderMinutes,
  }) =>
      ScheduleItem(
        id: id,
        day: day,
        time: time,
        workout: workout,
        active: active ?? this.active,
        reminderEnabled: reminderEnabled ?? this.reminderEnabled,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'day': day,
        'time': time,
        'workout': workout,
        'active': active,
        'reminderEnabled': reminderEnabled,
        'reminderMinutes': reminderMinutes,
      };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        id: json['id'] as String? ?? DateTime.now().toIso8601String(),
        day: json['day'] as String? ?? 'Senin',
        time: json['time'] as String? ?? '18:30',
        workout: json['workout'] as String? ?? 'Full Body',
        active: json['active'] as bool? ?? true,
        reminderEnabled: json['reminderEnabled'] as bool? ?? true,
        reminderMinutes: json['reminderMinutes'] as int? ?? 30,
      );
}

class WorkoutData {
  const WorkoutData({
    required this.title,
    required this.description,
    required this.difficulty,
    required this.durationMinutes,
    required this.exercises,
  });

  final String title;
  final String description;
  final String difficulty;
  final int durationMinutes;
  final List<ExerciseData> exercises;
}

const workoutOfTheDay = WorkoutData(
  title: 'Full Body',
  description: 'Bangun kekuatan dan energi dari rumah.',
  difficulty: 'Pemula',
  durationMinutes: 24,
  exercises: [
    ExerciseData(
      name: 'Push Up',
      subtitle: 'Dada & lengan',
      sets: 3,
      reps: 12,
      restSeconds: 30,
      color: Color(0xFFFFD5C2),
      icon: Icons.fitness_center_rounded,
    ),
    ExerciseData(
      name: 'Bodyweight Squat',
      subtitle: 'Kaki & glutes',
      sets: 3,
      reps: 15,
      restSeconds: 30,
      color: Color(0xFFD9E7FF),
      icon: Icons.accessibility_new_rounded,
    ),
    ExerciseData(
      name: 'Reverse Lunges',
      subtitle: 'Kaki & keseimbangan',
      sets: 3,
      reps: 10,
      restSeconds: 30,
      color: Color(0xFFE8DFFF),
      icon: Icons.directions_walk_rounded,
    ),
    ExerciseData(
      name: 'Plank',
      subtitle: 'Core',
      sets: 3,
      reps: 1,
      restSeconds: 30,
      durationSeconds: 30,
      color: Color(0xFFD5F2E3),
      icon: Icons.horizontal_rule_rounded,
    ),
    ExerciseData(
      name: 'Mountain Climbers',
      subtitle: 'Cardio & core',
      sets: 3,
      reps: 20,
      restSeconds: 30,
      color: Color(0xFFFFE5B8),
      icon: Icons.directions_run_rounded,
    ),
    ExerciseData(
      name: 'Glute Bridge',
      subtitle: 'Glutes & core',
      sets: 3,
      reps: 15,
      restSeconds: 30,
      color: Color(0xFFFFD8E4),
      icon: Icons.self_improvement_rounded,
    ),
  ],
);

class WorkoutAppState extends ChangeNotifier {
  WorkoutAppState() {
    _load();
  }

  ThemeMode themeMode = ThemeMode.system;
  int accentIndex = 0;
  bool isLoading = true;
  UserProfile profile = const UserProfile(
    name: 'Andi Ramadhan',
    email: 'andi@example.com',
  );
  List<WorkoutHistory> history = [];
  List<ScheduleItem> schedules = [
    const ScheduleItem(
      id: 'default-1',
      day: 'Senin',
      time: '18:30',
      workout: 'Full Body',
      active: true,
      reminderEnabled: true,
      reminderMinutes: 30,
    ),
    const ScheduleItem(
      id: 'default-2',
      day: 'Rabu',
      time: '18:30',
      workout: 'Full Body',
      active: true,
      reminderEnabled: true,
      reminderMinutes: 30,
    ),
    const ScheduleItem(
      id: 'default-3',
      day: 'Jumat',
      time: '18:30',
      workout: 'Full Body',
      active: true,
      reminderEnabled: true,
      reminderMinutes: 30,
    ),
  ];

  static const accentColors = [
    Color(0xFFE76F51),
    Color(0xFF3E7BFA),
    Color(0xFF25A66F),
    Color(0xFF8C5CF6),
    Color(0xFFE04474),
  ];

  Color get accentColor => accentColors[accentIndex];

  int get completedThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return history
        .where((item) => item.completedAt.isAfter(
              DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day),
            ))
        .length;
  }

  int get totalMinutes =>
      history.fold(0, (total, item) => total + item.durationMinutes);

  int get totalExercises =>
      history.fold(0, (total, item) => total + item.exerciseCount);

  int get totalCalories =>
      history.fold(0, (total, item) => total + item.calories);

  bool get completedToday {
    final now = DateTime.now();
    return history.any(
      (item) =>
          item.completedAt.year == now.year &&
          item.completedAt.month == now.month &&
          item.completedAt.day == now.day,
    );
  }

  bool get remindersEnabled =>
      schedules.any((item) => item.active && item.reminderEnabled);

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString('themeMode');
      if (savedTheme == 'light') {
        themeMode = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        themeMode = ThemeMode.dark;
      }
      accentIndex =
          (prefs.getInt('accentIndex') ?? 0)
              .clamp(0, accentColors.length - 1)
              .toInt();

      final savedProfile = prefs.getString('profile');
      if (savedProfile != null) {
        profile = UserProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(savedProfile) as Map),
        );
      }

      final savedHistory = prefs.getString('history');
      if (savedHistory != null) {
        final decoded = jsonDecode(savedHistory) as List<dynamic>;
        history = decoded
            .map((item) => WorkoutHistory.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }

      final savedSchedules = prefs.getString('schedules');
      if (savedSchedules != null) {
        final decoded = jsonDecode(savedSchedules) as List<dynamic>;
        schedules = decoded
            .map((item) => ScheduleItem.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      }
    } catch (_) {
      // Data yang rusak tidak boleh membuat aplikasi gagal dibuka.
      history = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.name);
    await prefs.setInt('accentIndex', accentIndex);
    await prefs.setString('profile', jsonEncode(profile.toJson()));
    await prefs.setString(
      'history',
      jsonEncode(history.map((item) => item.toJson()).toList()),
    );
    await prefs.setString(
      'schedules',
      jsonEncode(schedules.map((item) => item.toJson()).toList()),
    );
  }

  void setThemeMode(ThemeMode value) {
    themeMode = value;
    notifyListeners();
    unawaited(_persist());
  }

  void setAccentIndex(int value) {
    accentIndex = value;
    notifyListeners();
    unawaited(_persist());
  }

  void addHistory({
    required int durationMinutes,
    required int calories,
  }) {
    history = [
      WorkoutHistory(
        title: workoutOfTheDay.title,
        completedAt: DateTime.now(),
        durationMinutes: durationMinutes,
        exerciseCount: workoutOfTheDay.exercises.length,
        calories: calories,
      ),
      ...history,
    ];
    notifyListeners();
    unawaited(_persist());
  }

  void updateProfile({required String name, required String email}) {
    profile = profile.copyWith(
      name: name.trim().isEmpty ? profile.name : name.trim(),
      email: email.trim(),
    );
    notifyListeners();
    unawaited(_persist());
  }

  void addSchedule({
    required String day,
    required String time,
    required String workout,
    required bool reminderEnabled,
    required int reminderMinutes,
  }) {
    schedules = [
      ...schedules,
      ScheduleItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        day: day,
        time: time,
        workout: workout,
        active: true,
        reminderEnabled: reminderEnabled,
        reminderMinutes: reminderMinutes,
      ),
    ];
    notifyListeners();
    unawaited(_persist());
  }

  void toggleSchedule(String id) {
    schedules = schedules
        .map((item) =>
            item.id == id ? item.copyWith(active: !item.active) : item)
        .toList();
    notifyListeners();
    unawaited(_persist());
  }

  void setScheduleReminder(String id, bool enabled) {
    schedules = schedules
        .map((item) => item.id == id
            ? item.copyWith(reminderEnabled: enabled)
            : item)
        .toList();
    notifyListeners();
    unawaited(_persist());
  }

  void setAllRemindersEnabled(bool enabled) {
    schedules = schedules
        .map((item) => item.copyWith(reminderEnabled: enabled))
        .toList();
    notifyListeners();
    unawaited(_persist());
  }

  void removeSchedule(String id) {
    schedules = schedules.where((item) => item.id != id).toList();
    notifyListeners();
    unawaited(_persist());
  }
}

class WorkoutRumahApp extends StatefulWidget {
  const WorkoutRumahApp({super.key});

  @override
  State<WorkoutRumahApp> createState() => _WorkoutRumahAppState();
}

class _WorkoutRumahAppState extends State<WorkoutRumahApp> {
  final appState = WorkoutAppState();

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final seed = appState.accentColor;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Workout Rumah',
          themeMode: appState.themeMode,
          theme: _buildTheme(seed, Brightness.light),
          darkTheme: _buildTheme(seed, Brightness.dark),
          builder: (context, child) {
            final resolvedBrightness = Theme.of(context).brightness;
            final isDark = resolvedBrightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness:
                    isDark ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: Colors.transparent,
                systemNavigationBarIconBrightness:
                    isDark ? Brightness.light : Brightness.dark,
                systemNavigationBarContrastEnforced: false,
              ),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontFamily: 'Satoshi'),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: appState.isLoading
              ? const SplashScreen()
              : MainShell(appState: appState),
        );
      },
    );
  }

  ThemeData _buildTheme(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      surface: brightness == Brightness.light
          ? const Color(0xFFF9F8F6)
          : const Color(0xFF111310),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
        colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    fontFamily: 'Satoshi',
    textTheme: ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: 'Satoshi',
        ),
    appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1B1D1A),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF0EFEB)
            : const Color(0xFF20231F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Workout Rumah',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 100,
              child: LinearProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({
    required this.appState,
    this.initialIndex = 0,
    super.key,
  });

  final WorkoutAppState appState;
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(appState: widget.appState),
      SchedulePage(appState: widget.appState),
      ProgressPage(appState: widget.appState),
      ProfilePage(appState: widget.appState),
    ];
    return Scaffold(
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({required this.appState, super.key});

  final WorkoutAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeSchedules =
        appState.schedules.where((item) => item.active).toList();
    final nextSchedule =
        activeSchedules.isEmpty ? null : activeSchedules.first;
    return SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 32,
          20,
          40,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Siap bergerak hari ini?',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _initials(appState.profile.name),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          _TodayWorkoutCard(appState: appState),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rangkaian hari ini',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'DMSerifDisplay',
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                '${workoutOfTheDay.exercises.length} gerakan',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...workoutOfTheDay.exercises.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ExerciseListTile(
                    index: entry.key + 1,
                    exercise: entry.value,
                  ),
                ),
              ),
          const SizedBox(height: 14),
          if (nextSchedule != null)
            _NextScheduleCard(schedule: nextSchedule)
          else
            _EmptyInlineState(
              icon: Icons.event_available_rounded,
              title: 'Belum ada jadwal',
              action: 'Buat jadwal di tab Jadwal',
            ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final firstName = appState.profile.name.split(' ').first;
    if (hour < 11) return 'Selamat pagi, $firstName';
    if (hour < 15) return 'Selamat siang, $firstName';
    if (hour < 18) return 'Selamat sore, $firstName';
    return 'Selamat malam, $firstName';
  }
}

class _TodayWorkoutCard extends StatefulWidget {
  const _TodayWorkoutCard({required this.appState});

  final WorkoutAppState appState;

  @override
  State<_TodayWorkoutCard> createState() => _TodayWorkoutCardState();
}

class _TodayWorkoutCardState extends State<_TodayWorkoutCard>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      _time.value = elapsed.inMicroseconds / 1000000.0;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.appState.completedToday ? 1.0 : 0.0;

    final content = Container(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.appState.completedToday
                      ? 'LATIHAN SELESAI'
                      : 'LATIHAN HARI INI',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    shadows: [
                      const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  'PEMULA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            workoutOfTheDay.title,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              shadows: [
                const Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            workoutOfTheDay.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
              shadows: [
                const Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _WhiteMeta(
                icon: Icons.timer_outlined,
                text: '${workoutOfTheDay.durationMinutes} menit',
              ),
              const SizedBox(width: 16),
              _WhiteMeta(
                icon: Icons.fitness_center_outlined,
                text: '${workoutOfTheDay.exercises.length} gerakan',
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkoutSessionPage(appState: widget.appState),
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.95),
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Text(
                widget.appState.completedToday ? 'Ulangi Latihan' : 'Mulai Latihan',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            if (wavesProgram != null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    final primary = theme.colorScheme.primary;
                    
                    // Gelapkan background card secara keseluruhan agar efek ombak
                    // lebih terlihat dan teks putih di atasnya jauh lebih kontras.
                    final baseColor = Color.lerp(primary, Colors.black, 0.3) ?? Colors.black;
                    final deepWave = Color.lerp(primary, Colors.black, 0.7) ?? Colors.black;
                    final brightCrest = Color.lerp(primary, Colors.white, 0.15) ?? primary;

                    // RepaintBoundary mengunci koordinat lokal shader dan sangat menaikkan FPS
                    return RepaintBoundary(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _time,
                        builder: (context, timeValue, _) {
                          return CustomPaint(
                            painter: WavePainter(
                              wavesProgram!.fragmentShader(),
                              timeValue,
                              size,
                              baseColor,
                              deepWave,
                              brightCrest,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              )
            else
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(theme.colorScheme.primary, Colors.black, 0.2)!,
                        Color.lerp(theme.colorScheme.primary, Colors.black, 0.6)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            // Overlay transparan hitam tanpa blur agar tidak memberatkan device
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.2)),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final double time;
  final Size resolution;
  final Color horizonColor;
  final Color waveColor;
  final Color crestColor;

  WavePainter(this.shader, this.time, this.resolution, this.horizonColor, this.waveColor, this.crestColor);

  @override
  void paint(Canvas canvas, Size size) {
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, 0.4);
    shader.setFloat(4, 2.5);
    shader.setFloat(5, 0.6);
    shader.setFloat(6, 0.9);
    shader.setFloat(7, 35.0);
    shader.setFloat(8, 20.0);
    shader.setFloat(9, 1.11);
    shader.setFloat(10, 1.0);
    shader.setFloat(11, 5.5);
    shader.setFloat(12, 15.0);
    shader.setFloat(13, 70.0);
    shader.setFloat(14, 1.0);
    shader.setFloat(15, 1.0);
    shader.setFloat(16, 1.0);
    shader.setFloat(17, 0.05);
    shader.setFloat(18, 0.5); // mouse.dx dibuat tetap
    shader.setFloat(19, 0.5); // mouse.dy dibuat tetap
    shader.setFloat(20, 0.0); // parallax dinonaktifkan
    shader.setFloat(21, 0.0); // uEnableMouse dinonaktifkan

    shader.setFloat(22, horizonColor.red / 255.0);
    shader.setFloat(23, horizonColor.green / 255.0);
    shader.setFloat(24, horizonColor.blue / 255.0);
    
    shader.setFloat(25, waveColor.red / 255.0);
    shader.setFloat(26, waveColor.green / 255.0);
    shader.setFloat(27, waveColor.blue / 255.0);
    
    shader.setFloat(28, crestColor.red / 255.0);
    shader.setFloat(29, crestColor.green / 255.0);
    shader.setFloat(30, crestColor.blue / 255.0);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => oldDelegate.time != time;
}

class _WhiteMeta extends StatelessWidget {
  const _WhiteMeta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class ExerciseListTile extends StatelessWidget {
  const ExerciseListTile({
    required this.exercise,
    required this.index,
    super.key,
  });

  final ExerciseData exercise;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: exercise.color,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                exercise.icon,
                color: Colors.black.withOpacity(0.64),
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. ${exercise.name}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  exercise.durationSeconds != null
                      ? '${exercise.sets} × ${exercise.durationSeconds}s'
                      : '${exercise.sets} × ${exercise.reps}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'rest ${exercise.restSeconds}s',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NextScheduleCard extends StatelessWidget {
  const _NextScheduleCard({required this.schedule});

  final ScheduleItem schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(
            Icons.alarm_rounded,
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
        title: const Text(
          'Jadwal berikutnya',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${schedule.day}, ${schedule.time} • ${schedule.workout}'),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EmptyInlineState extends StatelessWidget {
  const _EmptyInlineState({
    required this.icon,
    required this.title,
    required this.action,
  });

  final IconData icon;
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                action,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SchedulePage extends StatelessWidget {
  const SchedulePage({required this.appState, super.key});

  final WorkoutAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 32,
          20,
          40,
        ),
        children: [
          Text(
            'Jadwal & Pengingat',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Atur ritme latihan yang bisa kamu jalani.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 42),
          _WeekStrip(),
          const SizedBox(height: 42),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jadwal mingguan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'DMSerifDisplay',
                  fontWeight: FontWeight.w400,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => _showAddSchedule(context),
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Tambah jadwal',
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (appState.schedules.isEmpty)
            const _ScheduleEmptyState()
          else
            ...appState.schedules.map(
              (schedule) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScheduleTile(
                  schedule: schedule,
                  onToggle: () => appState.toggleSchedule(schedule.id),
                  onReminderToggle: () => appState.setScheduleReminder(
                    schedule.id,
                    !schedule.reminderEnabled,
                  ),
                  onDelete: () => appState.removeSchedule(schedule.id),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder latihan',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Pengingat akan mengikuti jadwal yang aktif.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: appState.remindersEnabled,
                    onChanged: appState.schedules.isEmpty
                        ? null
                        : appState.setAllRemindersEnabled,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSchedule(BuildContext context) async {
    final dayController = ValueNotifier('Senin');
    final workoutController = ValueNotifier('Full Body');
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 30);
    bool reminderEnabled = true;
    int reminderMinutes = 30;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buat jadwal baru',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: dayController.value,
                    decoration: const InputDecoration(labelText: 'Hari'),
                    items: const [
                      'Senin',
                      'Selasa',
                      'Rabu',
                      'Kamis',
                      'Jumat',
                      'Sabtu',
                      'Minggu',
                    ]
                        .map((day) =>
                            DropdownMenuItem(value: day, child: Text(day)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) dayController.value = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: workoutController.value,
                    decoration: const InputDecoration(labelText: 'Workout'),
                    items: const ['Full Body', 'Upper Body', 'Lower Body']
                        .map((workout) => DropdownMenuItem(
                              value: workout,
                              child: Text(workout),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) workoutController.value = value;
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Waktu'),
                    subtitle: Text(selectedTime.format(context)),
                    leading: const Icon(Icons.schedule_rounded),
                    trailing: IconButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktifkan reminder'),
                    subtitle: Text('$reminderMinutes menit sebelum latihan'),
                    value: reminderEnabled,
                    onChanged: (value) {
                      setModalState(() => reminderEnabled = value);
                    },
                  ),
                  if (reminderEnabled)
                    DropdownButtonFormField<int>(
                      value: reminderMinutes,
                      decoration: const InputDecoration(
                        labelText: 'Ingatkan saya',
                      ),
                      items: const [5, 15, 30, 60]
                          .map(
                            (minutes) => DropdownMenuItem(
                              value: minutes,
                              child: Text('$minutes menit sebelumnya'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => reminderMinutes = value);
                        }
                      },
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        appState.addSchedule(
                          day: dayController.value,
                          time: selectedTime.format(context),
                          workout: workoutController.value,
                          reminderEnabled: reminderEnabled,
                          reminderMinutes: reminderMinutes,
                        );
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Jadwal berhasil disimpan.'),
                          ),
                        );
                      },
                      child: const Text('Simpan Jadwal'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    dayController.dispose();
    workoutController.dispose();
  }
}

class _WeekStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().weekday;
    const labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayNumber = index + 1;
        final isToday = dayNumber == today;
        return Column(
          children: [
            Text(
              labels[index],
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 38,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isToday
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  color: isToday
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.schedule,
    required this.onToggle,
    required this.onReminderToggle,
    required this.onDelete,
  });

  final ScheduleItem schedule;
  final VoidCallback onToggle;
  final VoidCallback onReminderToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: ValueKey(schedule.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      child: Card(
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: CircleAvatar(
            backgroundColor: schedule.active
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.fitness_center_rounded,
              color: schedule.active
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          title: Text(
            schedule.workout,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
           subtitle: Text(
             '${schedule.day} • ${schedule.time}\n'
             '${schedule.reminderEnabled ? 'Reminder ${schedule.reminderMinutes} menit sebelumnya' : 'Reminder mati'}',
           ),
           isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Switch(
                  value: schedule.active,
                  onChanged: (_) => onToggle(),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: schedule.reminderEnabled
                      ? 'Matikan reminder'
                      : 'Nyalakan reminder',
                  onPressed: onReminderToggle,
                  icon: Icon(
                    schedule.reminderEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_outlined,
                    color: schedule.reminderEnabled
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_note_rounded,
            size: 44,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada jadwal latihan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Buat jadwal pertamamu agar lebih konsisten.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({required this.appState, super.key});

  final WorkoutAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 32,
          20,
          40,
        ),
        children: [
          Text(
            'Rekap Progress',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sedikit demi sedikit, kamu makin kuat.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 42),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Workout',
                  value: '${appState.completedThisWeek}',
                  suffix: ' minggu ini',
                  icon: Icons.bolt_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Durasi',
                  value: '${appState.totalMinutes}',
                  suffix: ' menit',
                  icon: Icons.timer_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Exercise',
                  value: '${appState.totalExercises}',
                  suffix: ' selesai',
                  icon: Icons.fitness_center_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Streak',
                  value: '${appState.completedThisWeek}',
                  suffix: ' hari',
                  icon: Icons.local_fire_department_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas minggu ini',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'DMSerifDisplay',
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                'Minggu',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _WeeklyActivityCard(appState: appState),
          const SizedBox(height: 42),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat latihan',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (appState.history.isNotEmpty)
                Text(
                  '${appState.history.length} total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (appState.history.isEmpty)
            const _HistoryEmptyState()
          else
            ...appState.history.take(8).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                     child: _HistoryTile(
                       item: item,
                       onTap: () => Navigator.of(context).push(
                         MaterialPageRoute(
                           builder: (_) => HistoryDetailPage(item: item),
                         ),
                       ),
                     ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
  });

  final String label;
  final String value;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(icon, size: 18, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            Text(
              suffix,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyActivityCard extends StatelessWidget {
  const _WeeklyActivityCard({required this.appState});

  final WorkoutAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final values = List<double>.generate(7, (index) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - index));
      final hasWorkout = appState.history.any(
        (item) =>
            item.completedAt.year == day.year &&
            item.completedAt.month == day.month &&
            item.completedAt.day == day.day,
      );
      return hasWorkout ? 0.82 : (index == 6 ? 0.18 : 0.08);
    });
    const labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        child: Column(
          children: [
            SizedBox(
              height: 135,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: values.asMap().entries.map((entry) {
                  final isLatest = entry.key == values.length - 1;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24,
                        height: 100 * entry.value + 10,
                        decoration: BoxDecoration(
                          color: entry.value > 0.2
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        labels[entry.key],
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isLatest
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Konsistensi kecil hari ini membangun progres besar.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

  final WorkoutHistory item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
       onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.check_rounded,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${_formatDate(item.completedAt)} • ${item.durationMinutes} menit • ${item.exerciseCount} exercise',
        ),
        trailing: Text(
          '${item.calories} kcal',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class HistoryDetailPage extends StatelessWidget {
  const HistoryDetailPage({required this.item, super.key});

  final WorkoutHistory item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail latihan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_formatDate(item.completedAt)} • ${_formatClock(item.completedAt)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _CompletionStat(
                          value: '${item.durationMinutes}',
                          label: 'menit',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompletionStat(
                          value: '${item.exerciseCount}',
                          label: 'exercise',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompletionStat(
                          value: '${item.calories}',
                          label: 'kcal',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Gerakan yang diselesaikan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...workoutOfTheDay.exercises.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ExerciseListTile(
                    index: entry.key + 1,
                    exercise: entry.value,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 44,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada riwayat latihan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Selesaikan workout pertamamu untuk melihat progress.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({required this.appState, super.key});

  final WorkoutAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 32,
          20,
          40,
        ),
        children: [
          Text(
            'Profil & Tampilan',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 42),
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _showEditProfile(context),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        _initials(appState.profile.name),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appState.profile.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(appState.profile.email),
                          const SizedBox(height: 4),
                          Text(
                            '${appState.history.length} workout • ${appState.totalMinutes} menit',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Tema aplikasi',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                _ThemeOption(
                  label: 'Ikuti sistem',
                  icon: Icons.brightness_auto_rounded,
                  selected: appState.themeMode == ThemeMode.system,
                  onTap: () => appState.setThemeMode(ThemeMode.system),
                ),
                _ThemeOption(
                  label: 'Terang',
                  icon: Icons.light_mode_rounded,
                  selected: appState.themeMode == ThemeMode.light,
                  onTap: () => appState.setThemeMode(ThemeMode.light),
                ),
                _ThemeOption(
                  label: 'Gelap',
                  icon: Icons.dark_mode_rounded,
                  selected: appState.themeMode == ThemeMode.dark,
                  onTap: () => appState.setThemeMode(ThemeMode.dark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Warna aksen',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Wrap(
                spacing: 14,
                runSpacing: 14,
                children: WorkoutAppState.accentColors.asMap().entries.map(
                  (entry) {
                    final selected = appState.accentIndex == entry.key;
                    return GestureDetector(
                      onTap: () => appState.setAccentIndex(entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: entry.value,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: theme.colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ).toList(),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_off_outlined),
                  title: const Text(
                    'Mode offline',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Data workout tersimpan di perangkat'),
                  trailing: Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Divider(height: 1, indent: 68),
                 ListTile(
                   leading: const Icon(Icons.insights_outlined),
                   title: const Text(
                     'Ringkasan sepanjang waktu',
                     style: TextStyle(fontWeight: FontWeight.w700),
                   ),
                   subtitle: Text(
                     '${appState.totalExercises} exercise • ${appState.totalCalories} kcal',
                   ),
                ),
                 const Divider(height: 1, indent: 68),
                 const ListTile(
                   leading: Icon(Icons.info_outline_rounded),
                   title: Text(
                     'Tentang Workout Rumah',
                     style: TextStyle(fontWeight: FontWeight.w700),
                   ),
                   subtitle: Text('Versi MVP 1.1.0'),
                 ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProfile(BuildContext context) async {
    final nameController = TextEditingController(text: appState.profile.name);
    final emailController = TextEditingController(text: appState.profile.email);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit profil',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  appState.updateProfile(
                    name: nameController.text,
                    email: emailController.text,
                  );
                  Navigator.pop(sheetContext);
                },
                child: const Text('Simpan profil'),
              ),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    emailController.dispose();
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color:
            selected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? Icon(Icons.radio_button_checked_rounded,
              color: theme.colorScheme.primary)
          : const Icon(Icons.radio_button_off_rounded),
    );
  }
}

class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({required this.appState, super.key});

  final WorkoutAppState appState;

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  int exerciseIndex = 0;
  int currentSet = 1;
  int currentRep = 0;
  int secondsRemaining = 0;
  bool paused = false;
  bool isResting = false;
  DateTime? startedAt;
  Timer? timer;

  ExerciseData get exercise => workoutOfTheDay.exercises[exerciseIndex];

  @override
  void initState() {
    super.initState();
    startedAt = DateTime.now();
    if (exercise.durationSeconds != null) {
      secondsRemaining = exercise.durationSeconds!;
      _startTimer();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || paused || isResting) return;
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else if (exercise.durationSeconds != null) {
        _advanceAfterSet();
      }
    });
  }

  void _togglePause() {
    setState(() => paused = !paused);
  }

  void _completeSet() {
    if (exercise.durationSeconds == null &&
        currentRep < exercise.reps) {
      setState(() => currentRep++);
      return;
    }
    _advanceAfterSet();
  }

  void _advanceAfterSet() {
    if (currentSet < exercise.sets) {
      timer?.cancel();
      setState(() {
        currentSet++;
        currentRep = 0;
        isResting = true;
        secondsRemaining = exercise.restSeconds;
      });
      _showRestSheet();
    } else if (exerciseIndex < workoutOfTheDay.exercises.length - 1) {
      final nextIndex = exerciseIndex + 1;
      final nextExercise = workoutOfTheDay.exercises[nextIndex];
      setState(() {
        exerciseIndex = nextIndex;
        currentSet = 1;
        currentRep = 0;
        isResting = false;
        secondsRemaining = nextExercise.durationSeconds ?? 0;
      });
      if (nextExercise.durationSeconds != null) _startTimer();
    } else {
      _finishWorkout();
    }
  }

  void _skipExercise() {
    if (exerciseIndex < workoutOfTheDay.exercises.length - 1) {
      timer?.cancel();
      final nextIndex = exerciseIndex + 1;
      final nextExercise = workoutOfTheDay.exercises[nextIndex];
      setState(() {
        exerciseIndex = nextIndex;
        currentSet = 1;
        currentRep = 0;
        isResting = false;
        secondsRemaining = nextExercise.durationSeconds ?? 0;
      });
      if (nextExercise.durationSeconds != null) _startTimer();
    } else {
      _finishWorkout();
    }
  }

  void _showRestSheet() {
    Timer? restTimer;
    var restSeconds = secondsRemaining;
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            restTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              if (restSeconds > 0) {
                restSeconds--;
                if (mounted) {
                  setModalState(() => secondsRemaining = restSeconds);
                }
              } else if (Navigator.of(context).canPop()) {
                restTimer?.cancel();
                Navigator.pop(context);
              }
            });
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 6, 24, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Istirahat dulu',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Tarik napas. Kamu melakukan pekerjaan yang hebat.'),
                  const SizedBox(height: 18),
                  Text(
                    _formatDuration(restSeconds),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setModalState(() {
                              restSeconds += 15;
                              secondsRemaining = restSeconds;
                            });
                          },
                          child: const Text('+15 detik'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Lanjut'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      restTimer?.cancel();
      if (mounted && isResting) {
        _finishRest();
      }
    });
  }

  void _finishRest() {
    if (!mounted) return;
    final nextSeconds = exercise.durationSeconds ?? 0;
    setState(() {
      isResting = false;
      secondsRemaining = nextSeconds;
    });
    if (exercise.durationSeconds != null) {
      _startTimer();
    }
  }

  void _finishWorkout() {
    timer?.cancel();
    final duration =
        DateTime.now().difference(startedAt ?? DateTime.now()).inMinutes;
    final safeDuration = duration.clamp(1, 999).toInt();
    final calories = 180 + (workoutOfTheDay.exercises.length * 12);
    widget.appState.addHistory(
      durationMinutes: safeDuration,
      calories: calories,
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WorkoutCompletePage(
          durationMinutes: safeDuration,
          calories: calories,
          appState: widget.appState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overallProgress =
        (exerciseIndex + (currentSet - 1) / exercise.sets) /
            workoutOfTheDay.exercises.length;
    final displayTarget = exercise.durationSeconds != null
        ? '${secondsRemaining}s'
        : '$currentRep / ${exercise.reps}';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => _confirmExit(context),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(
          'Workout ${exerciseIndex + 1}/${workoutOfTheDay.exercises.length}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _togglePause,
            icon: Icon(
              paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            ),
            tooltip: paused ? 'Lanjutkan' : 'Pause',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: overallProgress.clamp(0.0, 1.0).toDouble(),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 32),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 230,
              decoration: BoxDecoration(
                color: exercise.color,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                exercise.icon,
                size: 110,
                color: Colors.black.withOpacity(0.62),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              exercise.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              exercise.subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SessionMetric(
                  label: 'SET',
                  value: '$currentSet / ${exercise.sets}',
                ),
                _SessionMetric(
                  label: exercise.durationSeconds != null
                      ? 'WAKTU'
                      : 'REPETISI',
                  value: displayTarget,
                  emphasized: true,
                ),
                _SessionMetric(
                  label: 'REST',
                  value: '${exercise.restSeconds}s',
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (exercise.durationSeconds == null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    onPressed: currentRep > 0
                        ? () => setState(() => currentRep--)
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                    iconSize: 28,
                  ),
                  const SizedBox(width: 28),
                  Text(
                    '$currentRep',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 28),
                  IconButton.filled(
                    onPressed: currentRep < exercise.reps
                        ? () => setState(() => currentRep++)
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    iconSize: 28,
                  ),
                ],
              )
            else
              Center(
                child: Text(
                  _formatDuration(secondsRemaining),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            FilledButton(
              onPressed: paused ? null : _completeSet,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 17),
              ),
              child: Text(
                exercise.durationSeconds != null
                    ? 'Selesai'
                    : currentRep >= exercise.reps
                        ? 'Selesai Set'
                        : 'Tambah Repetisi',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _skipExercise,
              child: const Text('Lewati gerakan'),
            ),
            if (paused)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Workout dijeda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari workout?'),
        content: const Text('Progress sesi ini belum akan disimpan ke riwayat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Lanjut latihan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) Navigator.pop(context);
  }
}

class _SessionMetric extends StatelessWidget {
  const _SessionMetric({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: (emphasized
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.titleMedium)
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class WorkoutCompletePage extends StatelessWidget {
  const WorkoutCompletePage({
    required this.durationMinutes,
    required this.calories,
    required this.appState,
    super.key,
  });

  final int durationMinutes;
  final int calories;
  final WorkoutAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 26),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Workout selesai!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kamu baru saja meluangkan waktu untuk dirimu sendiri.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _CompletionStat(
                      value: '$durationMinutes',
                      label: 'menit',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CompletionStat(
                      value: '${workoutOfTheDay.exercises.length}',
                      label: 'exercise',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CompletionStat(
                      value: '$calories',
                      label: 'kcal',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                   onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                     MaterialPageRoute(
                       builder: (_) => MainShell(
                         appState: appState,
                         initialIndex: 2,
                       ),
                     ),
                     (route) => false,
                   ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  child: const Text(
                    'Lihat Progress',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                 onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                   MaterialPageRoute(
                     builder: (_) => MainShell(appState: appState),
                   ),
                   (route) => false,
                 ),
                child: const Text('Kembali ke Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionStat extends StatelessWidget {
  const _CompletionStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
}

String _formatClock(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'WR';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}