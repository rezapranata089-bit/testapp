import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';

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
    this.photoBytesBase64,
  });

  final String name;
  final String email;
  // Foto disimpan sebagai base64 (bukan path file) agar kompatibel di Flutter
  // Web, di mana dart:io/File tidak tersedia.
  final String? photoBytesBase64;

  UserProfile copyWith({
    String? name,
    String? email,
    String? photoBytesBase64,
    bool clearPhoto = false,
  }) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        photoBytesBase64:
            clearPhoto ? null : (photoBytesBase64 ?? this.photoBytesBase64),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'photoBytesBase64': photoBytesBase64,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String? ?? 'Andi Ramadhan',
        email: json['email'] as String? ?? 'andi@example.com',
        photoBytesBase64: json['photoBytesBase64'] as String?,
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
    String? day,
    String? time,
    String? workout,
    bool? active,
    bool? reminderEnabled,
    int? reminderMinutes,
  }) =>
      ScheduleItem(
        id: id,
        day: day ?? this.day,
        time: time ?? this.time,
        workout: workout ?? this.workout,
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
  // Cache hasil decode agar instance Uint8List tetap sama antar rebuild.
  // MemoryImage membandingkan kesamaan lewat referensi bytes, jadi kalau
  // di-decode ulang tiap build (instance baru), Flutter menganggapnya
  // gambar berbeda dan me-redecode -> menyebabkan blink saat pindah tab.
  Uint8List? _cachedPhotoBytes;
  Uint8List? get profilePhotoBytes => _cachedPhotoBytes;
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
      _syncPhotoCache();

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

  void _syncPhotoCache() {
    final base64Photo = profile.photoBytesBase64;
    if (base64Photo == null) {
      _cachedPhotoBytes = null;
      return;
    }
    try {
      _cachedPhotoBytes = base64Decode(base64Photo);
    } catch (_) {
      _cachedPhotoBytes = null;
    }
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

  void updateProfile({
    required String name,
    required String email,
    String? photoBytesBase64,
    bool clearPhoto = false,
  }) {
    profile = profile.copyWith(
      name: name.trim().isEmpty ? profile.name : name.trim(),
      email: email.trim(),
      photoBytesBase64: photoBytesBase64,
      clearPhoto: clearPhoto,
    );
    _syncPhotoCache();
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

  void updateSchedule(
    String id, {
    required String day,
    required String time,
    required String workout,
    required bool reminderEnabled,
    required int reminderMinutes,
  }) {
    schedules = schedules.map((item) {
      if (item.id == id) {
        return item.copyWith(
          day: day,
          time: time,
          workout: workout,
          reminderEnabled: reminderEnabled,
          reminderMinutes: reminderMinutes,
        );
      }
      return item;
    }).toList();
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
  late PageController _pageController;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onItemTapped(int index) async {
    if (selectedIndex == index) return;
    setState(() {
      selectedIndex = index;
      _isNavigating = true; // Kunci onPageChanged sementara
    });
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    if (mounted) {
      setState(() => _isNavigating = false); // Buka kunci
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _KeepAlivePage(
        child: HomePage(
          appState: widget.appState,
          isActive: selectedIndex == 0,
          pageController: _pageController,
        ),
      ),
      _KeepAlivePage(child: SchedulePage(appState: widget.appState)),
      _KeepAlivePage(child: ProgressPage(appState: widget.appState)),
      _KeepAlivePage(child: ProfilePage(appState: widget.appState)),
    ];
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // Hanya ubah state jika pengguna yang menggeser manual (swipe)
          if (!_isNavigating) {
            setState(() => selectedIndex = index);
          }
        },
        children: pages,
      ),
      bottomNavigationBar: _SlidingNavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onItemTapped,
      ),
    );
  }
}

class _SlidingNavigationBar extends StatelessWidget {
  const _SlidingNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Jadwal'),
      (Icons.insights_outlined, Icons.insights_rounded, 'Progress'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
    ];

    // Background default dari Material 3 Navigation Bar
    final bgColor = theme.navigationBarTheme.backgroundColor ?? 
                    theme.colorScheme.surfaceContainer;

    return Container(
      height: 80 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      color: bgColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;
          const indicatorWidth = 64.0;
          const indicatorHeight = 32.0;

          return Stack(
            children: [
              // Pill indicator dengan efek squash & stretch (fluid) saat
              // berpindah tab, mirip navbar Play Store.
              _FluidPillIndicator(
                selectedIndex: selectedIndex,
                itemWidth: itemWidth,
                indicatorWidth: indicatorWidth,
                indicatorHeight: indicatorHeight,
                color: theme.colorScheme.secondaryContainer,
              ),
              // Ikon dan Label Text
              Row(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final isSelected = selectedIndex == index;
                  final item = entry.value;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onDestinationSelected(index),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 32,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              // Key dipindah ke AnimatedScale (child langsung
                              // dari AnimatedSwitcher) agar transisi fade tetap
                              // terdeteksi saat isSelected berubah.
                              child: AnimatedScale(
                                key: ValueKey(isSelected),
                                // Curve overshoot memberi efek "bounce" khas
                                // seperti navbar Play Store saat icon dipilih.
                                scale: isSelected ? 1.18 : 1.0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isSelected ? item.$2 : item.$1,
                                  color: isSelected
                                      ? theme.colorScheme.onSecondaryContainer
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 250),
                            style: theme.textTheme.labelSmall!.copyWith(
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                              fontFamily: 'Satoshi',
                            ),
                            child: Text(item.$3),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FluidPillIndicator extends StatefulWidget {
  const _FluidPillIndicator({
    required this.selectedIndex,
    required this.itemWidth,
    required this.indicatorWidth,
    required this.indicatorHeight,
    required this.color,
  });

  final int selectedIndex;
  final double itemWidth;
  final double indicatorWidth;
  final double indicatorHeight;
  final Color color;

  @override
  State<_FluidPillIndicator> createState() => _FluidPillIndicatorState();
}

class _FluidPillIndicatorState extends State<_FluidPillIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _stretchAnimation;
  late int _previousIndex;

  double _leftFor(int index) =>
      (index * widget.itemWidth) + (widget.itemWidth - widget.indicatorWidth) / 2;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _positionAnimation = AlwaysStoppedAnimation(_leftFor(widget.selectedIndex));
    _stretchAnimation = const AlwaysStoppedAnimation(1.0);
  }

  @override
  void didUpdateWidget(covariant _FluidPillIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final indexChanged = widget.selectedIndex != oldWidget.selectedIndex;
    final layoutChanged = widget.itemWidth != oldWidget.itemWidth ||
        widget.indicatorWidth != oldWidget.indicatorWidth;
    if (indexChanged) {
      final beginLeft = _leftFor(_previousIndex);
      final endLeft = _leftFor(widget.selectedIndex);
      _previousIndex = widget.selectedIndex;

      _positionAnimation = Tween<double>(begin: beginLeft, end: endLeft).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      // Pill meregang mengikuti arah geser lalu menyusut kembali ke ukuran
      // normal saat sampai, memberi kesan cair (fluid) seperti navbar
      // Play Store, bukan sekadar geser kaku.
      _stretchAnimation = TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.4)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(begin: 1.4, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 60,
        ),
      ]).animate(_controller);

      _controller
        ..stop()
        ..reset()
        ..forward();
    } else if (layoutChanged) {
      _positionAnimation = AlwaysStoppedAnimation(_leftFor(widget.selectedIndex));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final stretch = _stretchAnimation.value;
        final width = widget.indicatorWidth * stretch;
        // Lebar diseimbangkan dari titik tengah pill (bukan dari sisi kiri)
        // agar efek regang terasa memuai ke dua arah secara natural.
        final left = _positionAnimation.value -
            (width - widget.indicatorWidth) / 2;
        return Positioned(
          left: left,
          top: 14,
          child: Container(
            width: width,
            height: widget.indicatorHeight,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.appState,
    this.isActive = true,
    this.pageController,
    super.key,
  });

  final WorkoutAppState appState;
  final bool isActive;
  final PageController? pageController;

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
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 32, 20, 0),
            child: Row(
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
                  backgroundImage: appState.profilePhotoBytes != null
                      ? MemoryImage(appState.profilePhotoBytes!)
                      : null,
                  child: appState.profilePhotoBytes == null
                      ? Text(
                          _initials(appState.profile.name),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _AiPromptInput(),
          ),
          const SizedBox(height: 16),
          _TodayWorkoutCard(
            appState: appState,
            isActive: isActive,
            pageController: pageController,
          ),
          const SizedBox(height: 4), // Jarak diperkecil
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
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
          ),
          const SizedBox(height: 12),
          ...workoutOfTheDay.exercises.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: _ScrollRevealItem(
                    staggerIndex: entry.key,
                    child: ExerciseListTile(
                      index: entry.key + 1,
                      exercise: entry.value,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: nextSchedule != null
                ? _NextScheduleCard(schedule: nextSchedule)
                : _EmptyInlineState(
                    icon: Icons.event_available_rounded,
                    title: 'Belum ada jadwal',
                    action: 'Buat jadwal di tab Jadwal',
                  ),
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

class _AiPromptInput extends StatelessWidget {
  const _AiPromptInput();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1D1A) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        // Blur di box shadow kecil seperti ini murah (hanya dirender di
        // area sekitar box, bukan seluruh layar tiap frame), beda dengan
        // ShaderMask/BackdropFilter yang sebelumnya bikin wave berat.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(isDark ? 0.2 : 0.6),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Minta AI sesuaikan jadwal...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                filled: false,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: theme.colorScheme.onPrimary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayWorkoutCard extends StatefulWidget {
  const _TodayWorkoutCard({
    required this.appState,
    this.isActive = true,
    this.pageController,
  });

  final WorkoutAppState appState;
  final bool isActive;
  final PageController? pageController;

  @override
  State<_TodayWorkoutCard> createState() => _TodayWorkoutCardState();
}

class _TodayWorkoutCardState extends State<_TodayWorkoutCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier(0.0);
  // Menahan frame terakhir yang sudah diproses agar ticker bisa dibatasi
  // ke ~25fps, bukan 60fps, untuk mengurangi beban repaint wave.
  int _lastFrameMicros = 0;
  // Shader di-cache sekali saja, tidak dibuat ulang tiap frame agar hemat resource.
  ui.FragmentShader? _shader;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shader = wavesProgram?.fragmentShader();
    _ticker = createTicker((elapsed) {
      if (!mounted) return;
      // Batasi update ke ~25fps agar repaint + composite wave tidak
      // berjalan di setiap frame 60fps, sehingga terasa lebih smooth
      // dan hemat resource.
      final micros = elapsed.inMicroseconds;
      if (micros - _lastFrameMicros < 40000) return;
      _lastFrameMicros = micros;
      _time.value = micros / 1000000.0;
    });
    if (widget.isActive) _startTicker();
  }

  // Ticker.elapsed selalu dihitung ulang dari 0 setiap kali start()
  // dipanggil, sedangkan _lastFrameMicros masih menyimpan nilai lama dari
  // sesi sebelumnya (bisa sangat besar). Tanpa direset, elapsed yang baru
  // butuh waktu sangat lama untuk "menyusul" nilai lama tsb, sehingga
  // _time.value tidak pernah ter-update -> wave terlihat mati/freeze
  // setelah berpindah tab lalu kembali. Reset di sini memastikan animasi
  // langsung berjalan lagi begitu tab aktif.
  void _startTicker() {
    _lastFrameMicros = 0;
    _ticker.start();
  }

  @override
  void didUpdateWidget(covariant _TodayWorkoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _startTicker();
      } else {
        _ticker.stop();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.isActive) _startTicker();
    } else {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.appState.completedToday ? 1.0 : 0.0;

    final content = Container(
      // Padding atas dikurangi agar tidak terlalu jauh dari form AI,
      // Padding bawah dikurangi agar jarak ke seksi selanjutnya lebih dekat.
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Memaksa lebar Stack memenuhi layar agar posisi kanan bisa diandalkan
              const SizedBox(width: double.infinity, height: 0),
              
              // Lottie ditempatkan di urutan PERTAMA agar dirender di BELAKANG teks
              Positioned(
                right: -37, // Geser sedikit ke kiri dari posisi sebelumnya
                bottom: -21, // Dinaikkan sedikit dari posisi sebelumnya
                child: SizedBox(
                  width: 280, 
                  height: 280,
                  child: Lottie.asset(
                    'assets/lottie/gym.json',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomRight,
                    animate: widget.isActive,
                  ),
                ),
              ),
              // Teks dirender di DEPAN animasi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final labelText = widget.appState.completedToday
                          ? 'LATIHAN SELESAI'
                          : 'LATIHAN HARI INI';
                      // Warna dicampur ke arah putih agar tetap kontras di atas
                      // background wave yang gelap, tapi tetap terasa mengikuti
                      // warna aksen yang dipilih pengguna.
                      final fillColor = Color.lerp(
                            widget.appState.accentColor,
                            Colors.white,
                            0.55,
                          ) ??
                          Colors.white;
                      final baseStyle = theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      );
                      final isLight = theme.brightness == Brightness.light;
                      return Stack(
                        children: [
                          // Lapisan stroke (border hitam tipis) hanya dirender
                          // di mode light, karena di mode dark teks sudah cukup
                          // kontras tanpa border.
                          if (isLight)
                            Text(
                              labelText,
                              style: baseStyle?.copyWith(
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 1.2
                                  // Warna border mengikuti aksen, digelapkan
                                  // sedikit ke arah hitam agar tetap terlihat
                                  // sebagai outline, bukan hitam polos.
                                  ..color = (Color.lerp(
                                        widget.appState.accentColor,
                                        Colors.black,
                                        0.45,
                                      ) ??
                                      widget.appState.accentColor)
                                      .withOpacity(0.65),
                              ),
                            ),
                          Text(
                            labelText,
                            style: baseStyle?.copyWith(color: fillColor),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Text(
                    workoutOfTheDay.title,
                    softWrap: false,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.0,
                      shadows: [
                        const Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: Text(
                      workoutOfTheDay.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        shadows: [
                          const Shadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1))
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _WhiteMeta(
                        icon: Icons.timer_outlined,
                        text: '${workoutOfTheDay.durationMinutes} menit',
                      ),
                      _WhiteMeta(
                        icon: Icons.fitness_center_outlined,
                        text: '${workoutOfTheDay.exercises.length} gerakan',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          ),
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

    return AnimatedBuilder(
      animation: widget.pageController ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        final controller = widget.pageController;
        final page = (controller != null && controller.hasClients)
            ? (controller.page ?? 0.0)
            : 0.0;
        final distance = page.abs().clamp(0.0, 1.0);
        // Saat diam (distance 0), lewati ShaderMask sepenuhnya. Tanpa ini,
        // Flutter tetap melakukan saveLayer + composite ekstra tiap frame
        // walau efek fade-nya sebenarnya tidak terlihat sama sekali.
        if (distance <= 0.0) {
          return child!;
        }
        // Mask mati total saat diam (baseFadeWidth 0). Begitu mulai digeser,
        // lebar fade langsung melonjak cepat (easeOut) baru melandai menuju
        // lebar maksimal saat sudah dekat tab sebelah.
        const baseFadeWidth = 0.0;
        const swipeFadeWidth = 0.32;
        final easedDistance = Curves.easeOut.transform(distance);
        final fadeWidth =
            baseFadeWidth + (swipeFadeWidth - baseFadeWidth) * easedDistance;
        final fadeStart = (1.0 - fadeWidth).clamp(0.0, 1.0);
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, fadeStart, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: child,
        );
      },
      child: Stack(
      children: [
        Positioned.fill(
          child: Stack(
            children: [
              if (_shader != null)
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      // Di mode terang, warna primary cenderung terlihat pudar
                      // setelah dicampur ke hitam/putih untuk shading wave.
                      // Saturasi dinaikkan dulu sebelum di-lerp agar warna
                      // wave tetap terlihat jelas/vivid, bukan keabu-abuan.
                      final primary = theme.brightness == Brightness.light
                          ? _saturateColor(theme.colorScheme.primary, 0.35)
                          : theme.colorScheme.primary;

                      final baseColor = Color.lerp(primary, Colors.black, 0.3) ?? Colors.black;
                      final deepWave = Color.lerp(primary, Colors.black, 0.7) ?? Colors.black;
                      final brightCrest = Color.lerp(primary, Colors.white, 0.15) ?? primary;

                      return RepaintBoundary(
                        child: ValueListenableBuilder<double>(
                          valueListenable: _time,
                          builder: (context, timeValue, _) {
                            return CustomPaint(
                              isComplex: true,
                              willChange: true,
                              painter: WavePainter(
                                _shader!,
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
              // Overlay gelap dengan gradient multi-stop mengikuti kurva sinus
              // (bukan 3-stop berbentuk V). Gradient V-shape menyebabkan Mach
              // band -- garis horizontal tipis yang terlihat jelas walau nilai
              // warnanya sendiri kontinu, karena kemiringannya patah tajam di
              // titik tengah. Kurva sinus mulus di puncaknya sehingga garis
              // itu tidak muncul lagi.
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final peakOpacity =
                        theme.brightness == Brightness.light ? 0.45 : 0.2;
                    const sineStops = [
                      0.0,
                      0.125,
                      0.25,
                      0.375,
                      0.5,
                      0.625,
                      0.75,
                      0.875,
                      1.0,
                    ];
                    // Nilai dipangkatkan 1.8 (sama seperti fade di shader
                    // wave) agar area dekat tepi lebih transparan lebih
                    // lama, membuat overlay ikut blend halus ke background.
                    const sineValues = [
                      0.0,
                      0.2354,
                      0.6067,
                      0.8656,
                      1.0,
                      0.8656,
                      0.6067,
                      0.2354,
                      0.0,
                    ];
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: sineStops,
                          colors: [
                            for (final v in sineValues)
                              Colors.black.withOpacity(v * peakOpacity),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        content,
      ],
    ),
    );
  }
}

// Menaikkan saturasi HSL sebuah warna sebanyak [amount] (0.0-1.0), dipakai
// khusus untuk warna wave di mode terang agar tidak terlihat pudar/keabuan
// setelah dicampur dengan hitam/putih untuk shading.
Color _saturateColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final boosted = hsl.withSaturation((hsl.saturation + amount).clamp(0.0, 1.0));
  return boosted.toColor();
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
      mainAxisSize: MainAxisSize.min,
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

// Membungkus tiap card exercise agar muncul dengan animasi fade + slide up
// tepat saat card itu masuk ke area layar saat di-scroll, dengan delay
// bertahap (stagger) antar card agar terasa muncul satu per satu.
//
// Memakai ScrollPosition dari Scrollable terdekat (bukan NotificationListener)
// karena widget ini berada DI DALAM ListView -- notifikasi scroll hanya
// bisa ditangkap oleh listener yang berada di ATAS Scrollable, sedangkan
// ScrollPosition bisa didengarkan langsung oleh descendant seperti ini.
class _ScrollRevealItem extends StatefulWidget {
  const _ScrollRevealItem({
    required this.child,
    required this.staggerIndex,
  });

  final Widget child;
  final int staggerIndex;

  @override
  State<_ScrollRevealItem> createState() => _ScrollRevealItemState();
}

class _ScrollRevealItemState extends State<_ScrollRevealItem>
    with SingleTickerProviderStateMixin {
  // Durasi dinaikkan agar efek bounce (overshoot lalu memantul balik)
  // punya cukup waktu untuk terasa fluid, bukan terpotong terlalu cepat.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    // Fade selesai lebih cepat (interval 0.0-0.6) daripada slide/bounce,
    // supaya card sudah terlihat penuh sebelum efek bounce-nya selesai --
    // meniru cara Play Store/Material motion memisah opacity & posisi.
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );
  // Card index genap slide masuk dari kiri, index ganjil dari kanan,
  // sehingga barisan card terlihat silang-silang (zig-zag) saat muncul.
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(widget.staggerIndex.isEven ? -0.45 : 0.45, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  ScrollPosition? _scrollPosition;
  bool _revealed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.of(context).position;
    if (!identical(newPosition, _scrollPosition)) {
      _scrollPosition?.removeListener(_checkVisibility);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_checkVisibility);
    }
    // Cek juga setelah frame pertama, untuk card yang sudah langsung
    // terlihat di layar tanpa perlu di-scroll sama sekali.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;
    final viewportHeight = MediaQuery.of(context).size.height;
    final position = renderObject.localToGlobal(Offset.zero);
    final itemHeight = renderObject.size.height;
    // Card dianggap "masuk layar" begitu sisi atasnya sudah berada dalam
    // area layar (dengan sedikit margin agar animasi mulai terasa lebih
    // awal), dan belum sepenuhnya lewat di sisi atas.
    final isVisible = position.dy < viewportHeight * 0.92 &&
        (position.dy + itemHeight) > 0;

    if (!_revealed && isVisible) {
      _revealed = true;
      final delay = Duration(milliseconds: 70 * widget.staggerIndex);
      Future.delayed(delay, () {
        // Cek ulang _revealed di sini: kalau selama delay card sudah
        // ter-scroll keluar layar lagi (reset di bawah), batalkan supaya
        // tidak forward() untuk state yang sudah tidak relevan lagi.
        if (mounted && _revealed) _controller.forward(from: 0);
      });
    } else if (_revealed && !isVisible) {
      // Card sudah keluar area layar sepenuhnya -- reset agar animasi
      // fade+slide+bounce-nya bisa terulang lagi saat di-scroll masuk ke
      // layar berikutnya (termasuk saat tab dikunjungi ulang, karena
      // AutomaticKeepAlive membuat state ini tidak pernah dibuang).
      _revealed = false;
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
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
        // Menghapus padding horizontal ListView agar area swipe meluas sampai ke tepi layar
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 32,
          bottom: 40,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
              ],
            ),
          ),
          const SizedBox(height: 42),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _WeekStrip(appState: appState),
          ),
          const SizedBox(height: 42),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
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
          ),
          const SizedBox(height: 10),
          if (appState.schedules.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: _ScheduleEmptyState(),
            )
          else
            _ScheduleList(appState: appState),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Card(
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
                            style: TextStyle(fontWeight: FontWeight.w600),
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
  const _WeekStrip({required this.appState});
  final WorkoutAppState appState;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Cari tanggal hari Senin minggu ini
    final monday = today.subtract(Duration(days: now.weekday - 1));
    
    const labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
    const dayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    return SizedBox(
      height: 90, // Beri ruang agar efek lonjong dan animasi membal tetap aman di dalam row
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(7, (index) {
          final date = monday.add(Duration(days: index));
          final isToday = date == today;
          final daySchedules = appState.schedules
              .where((s) => s.day == dayNames[index] && s.active)
              .toList();
          
          final distance = (index - 3).abs(); // Jarak posisi dari tengah (Kamis)

          return _DayStripItem(
            label: labels[index],
            date: date,
            isToday: isToday,
            dayName: dayNames[index],
            schedules: daySchedules,
            distance: distance,
          );
        }),
      ),
    );
  }
}

class _DayStripItem extends StatefulWidget {
  const _DayStripItem({
    required this.label,
    required this.date,
    required this.isToday,
    required this.dayName,
    required this.schedules,
    required this.distance,
  });

  final String label;
  final DateTime date;
  final bool isToday;
  final String dayName;
  final List<ScheduleItem> schedules;
  final int distance;

  @override
  State<_DayStripItem> createState() => _DayStripItemState();
}

class _DayStripItemState extends State<_DayStripItem> {
  bool _isPressed = false;

  void _handleTap() {
    HapticFeedback.lightImpact();
    final msg = widget.schedules.isEmpty
        ? 'Waktunya istirahat! Tidak ada jadwal hari ${widget.dayName}.'
        : '${widget.dayName}: Ada ${widget.schedules.length} jadwal latihan aktif.';
    
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Ukuran dinamis: pill tengah membesar, pinggir semakin mengecil untuk efek melengkung
    final double width = 48.0 - (widget.distance * 3.0);
    final double height = 86.0 - (widget.distance * 8.0);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.75 : 1.0,
        // Durasi diperlama dengan curve elasticOut saat dilepas untuk memberikan efek fluid/membal
        duration: Duration(milliseconds: _isPressed ? 150 : 500),
        curve: _isPressed ? Curves.easeOutQuad : Curves.elasticOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: widget.isToday
                ? theme.colorScheme.primary
                : (widget.schedules.isNotEmpty
                    ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                    : theme.colorScheme.surfaceContainerHighest),
            borderRadius: BorderRadius.circular(100), // Membentuk pill lonjong penuh
            border: widget.isToday
                ? null
                : Border.all(
                    color: widget.schedules.isNotEmpty
                        ? theme.colorScheme.primary.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1.5,
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: widget.isToday 
                      ? theme.colorScheme.onPrimary.withOpacity(0.8) 
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 4.0 - (widget.distance * 0.5)),
              Text(
                '${widget.date.day}',
                style: TextStyle(
                  color: widget.isToday
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.0 - (widget.distance * 0.8), // Teks sedikit menyesuaikan ukuran pill
                ),
              ),
              if (widget.schedules.isNotEmpty) ...[
                SizedBox(height: 4.0 - (widget.distance * 0.5)),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.isToday
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Menyimpan progress swipe kartu yang sedang di-drag beserta index-nya,
// dibagikan lewat ValueNotifier agar kartu tetangga bisa ikut bereaksi
// (efek "tertarik") secara real-time saat salah satu kartu di-swipe.
class _ScheduleDragState {
  const _ScheduleDragState({required this.index, required this.progress});

  final int index;
  final double progress;
}

// Membangun daftar _ScheduleTile sekaligus memegang ValueNotifier yang
// dipakai bersama untuk efek rubber-band antar kartu.
class _ScheduleList extends StatefulWidget {
  const _ScheduleList({required this.appState});

  final WorkoutAppState appState;

  @override
  State<_ScheduleList> createState() => _ScheduleListState();
}

class _ScheduleListState extends State<_ScheduleList> {
  final ValueNotifier<_ScheduleDragState?> _dragNotifier = ValueNotifier(null);

  @override
  void dispose() {
    _dragNotifier.dispose();
    super.dispose();
  }

  Future<void> _showEditSchedule(BuildContext context, ScheduleItem schedule) async {
    final dayController = ValueNotifier(schedule.day);
    final workoutController = ValueNotifier(schedule.workout);
    
    TimeOfDay parseTime(String timeString) {
      try {
        final clean = timeString.replaceAll(RegExp(r'[^0-9:]'), '').trim();
        final parts = clean.split(':');
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        if (timeString.toLowerCase().contains('pm') && hour < 12) hour += 12;
        if (timeString.toLowerCase().contains('am') && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      } catch (_) {
        return const TimeOfDay(hour: 18, minute: 30);
      }
    }
    
    TimeOfDay selectedTime = parseTime(schedule.time);
    bool reminderEnabled = schedule.reminderEnabled;
    int reminderMinutes = schedule.reminderMinutes;

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
                    'Edit jadwal',
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
                        widget.appState.updateSchedule(
                          schedule.id,
                          day: dayController.value,
                          time: selectedTime.format(context),
                          workout: workoutController.value,
                          reminderEnabled: reminderEnabled,
                          reminderMinutes: reminderMinutes,
                        );
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Jadwal berhasil diperbarui.'),
                          ),
                        );
                      },
                      child: const Text('Simpan Perubahan'),
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

  @override
  Widget build(BuildContext context) {
    final schedules = widget.appState.schedules;
    return Column(
      children: [
        for (var i = 0; i < schedules.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ScheduleTile(
              index: i,
              dragNotifier: _dragNotifier,
              schedule: schedules[i],
              onToggle: () => widget.appState.toggleSchedule(schedules[i].id),
              onReminderToggle: () => widget.appState.setScheduleReminder(
                schedules[i].id,
                !schedules[i].reminderEnabled,
              ),
              onEdit: () => _showEditSchedule(context, schedules[i]),
              onDelete: () => widget.appState.removeSchedule(schedules[i].id),
            ),
          ),
      ],
    );
  }
}

class _ScheduleTile extends StatefulWidget {
  const _ScheduleTile({
    required this.index,
    required this.dragNotifier,
    required this.schedule,
    required this.onToggle,
    required this.onReminderToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final ValueNotifier<_ScheduleDragState?> dragNotifier;
  final ScheduleItem schedule;
  final VoidCallback onToggle;
  final VoidCallback onReminderToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ScheduleTile> createState() => _ScheduleTileState();
}

class _ScheduleTileState extends State<_ScheduleTile> with TickerProviderStateMixin {
  double _swipeProgress = 0.0;
  late AnimationController _sizeController;
  late Animation<double> _sizeAnimation;

  // Custom Drag State untuk efek "Berat" (Resistance)
  double _dragExtent = 0.0;
  bool _hapticTriggered = false;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _sizeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _sizeAnimation = CurvedAnimation(
      parent: _sizeController,
      curve: Curves.easeInOutCubic,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideController.addListener(() {
      setState(() {
        _dragExtent = _slideAnimation.value;
        _swipeProgress = _dragExtent;
        widget.dragNotifier.value = _ScheduleDragState(
          index: widget.index,
          progress: _swipeProgress,
        );
      });
    });
  }

  @override
  void dispose() {
    _sizeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_slideController.isAnimating) {
      _slideController.stop();
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Delta dinegatifkan agar swipe kiri (Delete) bernilai positif, sesuai sistem _swipeProgress
    final delta = -details.primaryDelta! / MediaQuery.of(context).size.width;
    double rawExtent = _dragExtent + delta;
    
    // Threshold 45% (Hampir setengah layar, terasa pas di jari untuk Trigger UX)
    const limit = 0.45;
    if (rawExtent.abs() > limit) {
      final extra = rawExtent.abs() - limit;
      // Berikan efek berat (gesekan/resistansi), jarak geser ditambah secara sangat lambat (dikali 0.15)
      rawExtent = (limit + extra * 0.15) * rawExtent.sign;
    }

    setState(() {
      _dragExtent = rawExtent;
      _swipeProgress = _dragExtent;
      widget.dragNotifier.value = _ScheduleDragState(
        index: widget.index,
        progress: _swipeProgress,
      );
    });

    // Getar saat tepat menyentuh batas (threshold) 50%
    if (_dragExtent.abs() >= limit && !_hapticTriggered) {
      _hapticTriggered = true;
      HapticFeedback.mediumImpact();
    } else if (_dragExtent.abs() < limit) {
      _hapticTriggered = false;
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    const limit = 0.45;
    final isDelete = _dragExtent >= limit; // Kiri
    final isEdit = _dragExtent <= -limit;  // Kanan

    // Begitu dilepas, card otomatis memantul (snap) kembali ke posisi semula (0.0)
    _slideAnimation = Tween<double>(
      begin: _dragExtent,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward(from: 0).then((_) {
      _hapticTriggered = false;
    });

    // Jika melewati batas, LANGSUNG panggil aksi/popup tanpa menunggu animasi selesai!
    if (isDelete) {
      _handleDeleteConfirmation(Theme.of(context));
    } else if (isEdit) {
      widget.onEdit();
    }
  }

  Future<void> _handleDeleteConfirmation(ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jadwal?'),
        content: Text('Apakah kamu yakin ingin menghapus jadwal ${widget.schedule.workout} di hari ${widget.schedule.day}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _sizeController.reverse();
      if (mounted) widget.onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Perhitungan warna Delete (Saat geser ke kiri)
    final deleteIntensity = (_swipeProgress / 0.5).clamp(0.0, 1.0);
    final deleteBgColor = Color.lerp(theme.colorScheme.errorContainer, theme.colorScheme.error, deleteIntensity) ?? theme.colorScheme.error;
    final deleteIconColor = Color.lerp(theme.colorScheme.onErrorContainer, theme.colorScheme.onError, deleteIntensity) ?? theme.colorScheme.onError;

    // Perhitungan warna Edit (Saat geser ke kanan)
    final editIntensity = (_swipeProgress.abs() / 0.5).clamp(0.0, 1.0);
    final editBgColor = Color.lerp(theme.colorScheme.primaryContainer, theme.colorScheme.primary, editIntensity) ?? theme.colorScheme.primary;
    final editIconColor = Color.lerp(theme.colorScheme.onPrimaryContainer, theme.colorScheme.onPrimary, editIntensity) ?? theme.colorScheme.onPrimary;

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      child: Stack(
        children: [
          // CARD EDIT (BELAKANG KIRI) - Muncul saat ditarik ke kanan
          if (_swipeProgress < 0)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: editBgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 22),
                child: Icon(Icons.edit_outlined, color: editIconColor),
              ),
            ),

          // CARD DELETE (BELAKANG KANAN) - Muncul saat ditarik ke kiri
          if (_swipeProgress > 0)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: deleteBgColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 22),
                child: Icon(Icons.delete_outline_rounded, color: deleteIconColor),
              ),
            ),

          // CARD UTAMA (DEPAN)
          ValueListenableBuilder<_ScheduleDragState?>(
            valueListenable: widget.dragNotifier,
            builder: (context, dragState, dismissibleChild) {
              final isNeighbor = dragState != null && (dragState.index - widget.index).abs() == 1;
              final pull = isNeighbor ? dragState!.progress : 0.0;
              return Transform.translate(
                offset: Offset(-pull * 14.0, 0),
                child: Transform.scale(
                  scaleY: 1 - (pull.abs() * 0.015),
                  child: Opacity(
                    opacity: 1 - (pull.abs() * 0.12),
                    child: dismissibleChild,
                  ),
                ),
              );
            },
            child: GestureDetector(
              key: ValueKey(widget.schedule.id),
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              behavior: HitTestBehavior.opaque,
              child: Transform.translate(
                // Mengubah _swipeProgress menjadi posisi piksel aktual di layar
                offset: Offset(-_swipeProgress * MediaQuery.of(context).size.width, 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Material(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    child: InkWell(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: widget.schedule.active
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.fitness_center_rounded,
                                color: widget.schedule.active
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.schedule.workout,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${widget.schedule.day} • ${widget.schedule.time}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: widget.onReminderToggle,
                                    behavior: HitTestBehavior.opaque,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.schedule.reminderEnabled
                                              ? Icons.notifications_active_rounded
                                              : Icons.notifications_off_outlined,
                                          size: 14,
                                          color: widget.schedule.reminderEnabled
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.schedule.reminderEnabled
                                              ? '${widget.schedule.reminderMinutes} mnt sebelumnya'
                                              : 'Reminder mati',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: widget.schedule.reminderEnabled
                                                ? theme.colorScheme.primary
                                                : theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: widget.schedule.active,
                              onChanged: (_) => widget.onToggle(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
            style: TextStyle(fontWeight: FontWeight.w600),
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
                      backgroundImage: appState.profilePhotoBytes != null
                          ? MemoryImage(appState.profilePhotoBytes!)
                          : null,
                      child: appState.profilePhotoBytes == null
                          ? Text(
                              _initials(appState.profile.name),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                              ),
                            )
                          : null,
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
    Uint8List? pickedPhotoBytes = appState.profile.photoBytesBase64 != null
        ? base64Decode(appState.profile.photoBytesBase64!)
        : null;
    bool removePhoto = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickPhoto() async {
            final picker = ImagePicker();
            final picked = await picker.pickImage(
              source: ImageSource.gallery,
              imageQuality: 85,
              maxWidth: 800,
            );
            if (picked == null) return;
            // readAsBytes() bekerja di semua platform (web & mobile),
            // beda dengan picked.path yang di web berupa blob URL saja.
            final bytes = await picked.readAsBytes();
            if (!context.mounted) return;
            setModalState(() {
              pickedPhotoBytes = bytes;
              removePhoto = false;
            });
          }

          final sheetTheme = Theme.of(context);
          final showsImage = pickedPhotoBytes != null && !removePhoto;

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
                  'Edit profil',
                  style: sheetTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: pickPhoto,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: sheetTheme.colorScheme.primaryContainer,
                          backgroundImage: showsImage
                              ? MemoryImage(pickedPhotoBytes!)
                              : null,
                          child: !showsImage
                              ? Text(
                                  _initials(nameController.text),
                                  style: TextStyle(
                                    color: sheetTheme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 22,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: sheetTheme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: sheetTheme.cardTheme.color ??
                                    sheetTheme.colorScheme.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: sheetTheme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showsImage)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setModalState(() => removePhoto = true);
                      },
                      child: const Text('Hapus foto'),
                    ),
                  ),
                const SizedBox(height: 6),
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
                      FocusScope.of(context).unfocus();
                      final capturedName = nameController.text;
                      final capturedEmail = emailController.text;
                      final capturedPhoto = (removePhoto || pickedPhotoBytes == null)
                          ? null
                          : base64Encode(pickedPhotoBytes!);
                      final capturedRemove = removePhoto;
                      Navigator.pop(sheetContext);
                      // Tunda update state (notifyListeners) sampai setelah frame
                      // pop selesai, agar tidak bentrok dengan Element tree yang
                      // masih dibongkar oleh transisi penutupan sheet.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        appState.updateProfile(
                          name: capturedName,
                          email: capturedEmail,
                          photoBytesBase64: capturedPhoto,
                          clearPhoto: capturedRemove,
                        );
                      });
                    },
                    child: const Text('Simpan profil'),
                  ),
                ),
              ],
            ),
          );
        },
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