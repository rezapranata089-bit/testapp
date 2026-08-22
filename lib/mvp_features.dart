import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MvpExercise {
  const MvpExercise({
    required this.id,
    required this.name,
    required this.detail,
    required this.icon,
    required this.tags,
    required this.defaultReps,
    required this.defaultSeconds,
    required this.noisy,
  });

  final String id;
  final String name;
  final String detail;
  final IconData icon;
  final List<String> tags;
  final int defaultReps;
  final int defaultSeconds;
  final bool noisy;
}

const mvpExercises = <MvpExercise>[
  MvpExercise(
    id: 'squat',
    name: 'Bodyweight Squat',
    detail: 'Kaki & glutes',
    icon: Icons.accessibility_new_rounded,
    tags: ['legs', 'strength', 'quiet'],
    defaultReps: 12,
    defaultSeconds: 0,
    noisy: false,
  ),
  MvpExercise(
    id: 'pushup',
    name: 'Push Up',
    detail: 'Dada & lengan',
    icon: Icons.fitness_center_rounded,
    tags: ['upper', 'strength', 'quiet'],
    defaultReps: 8,
    defaultSeconds: 0,
    noisy: false,
  ),
  MvpExercise(
    id: 'glute_bridge',
    name: 'Glute Bridge',
    detail: 'Glutes & core',
    icon: Icons.self_improvement_rounded,
    tags: ['legs', 'core', 'recovery', 'quiet'],
    defaultReps: 14,
    defaultSeconds: 0,
    noisy: false,
  ),
  MvpExercise(
    id: 'plank',
    name: 'Plank',
    detail: 'Core & stabilitas',
    icon: Icons.horizontal_rule_rounded,
    tags: ['core', 'strength', 'quiet'],
    defaultReps: 0,
    defaultSeconds: 30,
    noisy: false,
  ),
  MvpExercise(
    id: 'mountain',
    name: 'Mountain Climbers',
    detail: 'Cardio & core',
    icon: Icons.directions_run_rounded,
    tags: ['cardio', 'core'],
    defaultReps: 20,
    defaultSeconds: 0,
    noisy: true,
  ),
  MvpExercise(
    id: 'step_jack',
    name: 'Step Jack',
    detail: 'Cardio hening',
    icon: Icons.directions_walk_rounded,
    tags: ['cardio', 'quiet', 'small-space'],
    defaultReps: 20,
    defaultSeconds: 0,
    noisy: false,
  ),
  MvpExercise(
    id: 'dead_bug',
    name: 'Dead Bug',
    detail: 'Core low-impact',
    icon: Icons.airline_seat_flat_rounded,
    tags: ['core', 'recovery', 'quiet'],
    defaultReps: 10,
    defaultSeconds: 0,
    noisy: false,
  ),
];

class MvpWorkout {
  MvpWorkout({
    required this.id,
    required this.name,
    required this.goal,
    required this.minutes,
    required this.rounds,
    required this.restSeconds,
    required this.exerciseIds,
    this.quiet = false,
  });

  final String id;
  final String name;
  final String goal;
  final int minutes;
  final int rounds;
  final int restSeconds;
  final List<String> exerciseIds;
  final bool quiet;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'goal': goal,
        'minutes': minutes,
        'rounds': rounds,
        'restSeconds': restSeconds,
        'exerciseIds': exerciseIds,
        'quiet': quiet,
      };

  factory MvpWorkout.fromJson(Map<String, dynamic> json) => MvpWorkout(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? 'Workout baru',
        goal: json['goal'] as String? ?? 'Full body',
        minutes: (json['minutes'] as num?)?.toInt() ?? 10,
        rounds: (json['rounds'] as num?)?.toInt() ?? 2,
        restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 30,
        exerciseIds: (json['exerciseIds'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList(),
        quiet: json['quiet'] as bool? ?? false,
      );
}

class MvpFeatureHub extends StatefulWidget {
  const MvpFeatureHub({required this.onWorkoutSaved, super.key});

  final void Function({
    required int durationMinutes,
    required int calories,
  }) onWorkoutSaved;

  @override
  State<MvpFeatureHub> createState() => _MvpFeatureHubState();
}

class _MvpFeatureHubState extends State<MvpFeatureHub> {
  static const _workoutKey = 'homefit_mvp_workouts';
  static const _checkInKey = 'homefit_mvp_last_checkin';
  final _workouts = <MvpWorkout>[];
  bool _loading = true;
  int _energy = 3;
  int _availableMinutes = 10;
  String _soreness = 'Tidak ada';
  bool _quietMode = false;
  MvpWorkout? _recommendation;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workoutKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _workouts
        ..clear()
        ..addAll(decoded.map(
          (item) => MvpWorkout.fromJson(Map<String, dynamic>.from(item as Map)),
        ));
    }
    final checkIn = prefs.getString(_checkInKey);
    if (checkIn != null) {
      final json = Map<String, dynamic>.from(jsonDecode(checkIn) as Map);
      _energy = (json['energy'] as num?)?.toInt() ?? _energy;
      _availableMinutes = (json['minutes'] as num?)?.toInt() ?? _availableMinutes;
      _soreness = json['soreness'] as String? ?? _soreness;
      _quietMode = json['quiet'] as bool? ?? _quietMode;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _workoutKey,
      jsonEncode(_workouts.map((workout) => workout.toJson()).toList()),
    );
    await prefs.setString(
      _checkInKey,
      jsonEncode({
        'energy': _energy,
        'minutes': _availableMinutes,
        'soreness': _soreness,
        'quiet': _quietMode,
      }),
    );
  }

  List<MvpExercise> _exercisesFor(MvpWorkout workout) => workout.exerciseIds
      .map((id) => mvpExercises.where((exercise) => exercise.id == id))
      .where((matches) => matches.isNotEmpty)
      .map((matches) => matches.first)
      .toList();

  void _createRecommendation() {
    final excluded = <String>{};
    if (_quietMode) {
      excluded.addAll(
        mvpExercises.where((exercise) => exercise.noisy).map((exercise) => exercise.id),
      );
    }
    if (_soreness == 'Lutut') excluded.addAll(['squat']);
    if (_soreness == 'Pergelangan tangan') {
      excluded.addAll(['pushup', 'mountain', 'plank']);
    }
    final preferred = mvpExercises
        .where((exercise) => !excluded.contains(exercise.id))
        .toList();
    final count = _availableMinutes <= 5 ? 3 : (_availableMinutes <= 10 ? 4 : 5);
    final selected = preferred.take(count).toList();
    final recovery = _energy <= 2 || _soreness != 'Tidak ada';
    setState(() {
      _recommendation = MvpWorkout(
        id: 'recommendation-${DateTime.now().millisecondsSinceEpoch}',
        name: recovery ? 'Recovery yang realistis' : 'Latihan sesuai kondisimu',
        goal: recovery ? 'Recovery' : 'Full body',
        minutes: _availableMinutes,
        rounds: _energy <= 2 ? 1 : (_availableMinutes <= 5 ? 2 : 3),
        restSeconds: _energy <= 2 ? 45 : 30,
        exerciseIds: selected.map((exercise) => exercise.id).toList(),
        quiet: _quietMode,
      );
    });
    unawaited(_save());
  }

  Future<void> _openCheckIn() async {
    var energy = _energy;
    var minutes = _availableMinutes;
    var soreness = _soreness;
    var quiet = _quietMode;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Check-in hari ini', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Jawab singkat. HomeFit akan menyesuaikan latihan secara offline.'),
                const SizedBox(height: 20),
                Text('Energi: $energy / 5', style: const TextStyle(fontWeight: FontWeight.w800)),
                Slider(
                  value: energy.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) => setSheetState(() => energy = value.round()),
                ),
                const SizedBox(height: 8),
                const Text('Waktu tersedia', style: TextStyle(fontWeight: FontWeight.w800)),
                Wrap(
                  spacing: 8,
                  children: [3, 5, 8, 10, 15, 20].map((value) {
                    return ChoiceChip(
                      label: Text('$value m'),
                      selected: minutes == value,
                      onSelected: (_) => setSheetState(() => minutes = value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                const Text('Area pegal / ingin dihindari', style: TextStyle(fontWeight: FontWeight.w800)),
                Wrap(
                  spacing: 8,
                  children: ['Tidak ada', 'Lutut', 'Punggung', 'Pergelangan tangan'].map((value) {
                    return ChoiceChip(
                      label: Text(value),
                      selected: soreness == value,
                      onSelected: (_) => setSheetState(() => soreness = value),
                    );
                  }).toList(),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mode hening / tetangga'),
                  subtitle: const Text('Hindari gerakan dengan hentakan keras'),
                  value: quiet,
                  onChanged: (value) => setSheetState(() => quiet = value),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () {
                    this._energy = energy;
                    this._availableMinutes = minutes;
                    this._soreness = soreness;
                    this._quietMode = quiet;
                    Navigator.pop(context);
                    _createRecommendation();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Sesuaikan latihanku'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createWorkout() async {
    final nameController = TextEditingController(text: 'Workout custom');
    var goal = 'Full body';
    var minutes = 10;
    var rounds = 2;
    var rest = 30;
    var quiet = false;
    final selected = <String>{'squat', 'pushup', 'plank'};
    final result = await showModalBottomSheet<MvpWorkout>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buat workout sendiri', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama workout'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: goal,
                  decoration: const InputDecoration(labelText: 'Tujuan'),
                  items: ['Full body', 'Strength', 'Cardio', 'Recovery', 'Mobility']
                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) => setSheetState(() => goal = value ?? goal),
                ),
                const SizedBox(height: 12),
                Text('Durasi: $minutes menit'),
                Slider(
                  value: minutes.toDouble(),
                  min: 3,
                  max: 30,
                  divisions: 27,
                  onChanged: (value) => setSheetState(() => minutes = value.round()),
                ),
                Text('Ronde: $rounds'),
                Slider(
                  value: rounds.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) => setSheetState(() => rounds = value.round()),
                ),
                Text('Rest antar ronde: $rest detik'),
                Slider(
                  value: rest.toDouble(),
                  min: 10,
                  max: 90,
                  divisions: 8,
                  onChanged: (value) => setSheetState(() => rest = value.round()),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanpa gerakan berisik'),
                  value: quiet,
                  onChanged: (value) => setSheetState(() => quiet = value),
                ),
                const Text('Pilih gerakan', style: TextStyle(fontWeight: FontWeight.w800)),
                ...mvpExercises.map(
                  (exercise) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected.contains(exercise.id),
                    title: Text(exercise.name),
                    subtitle: Text(exercise.detail),
                    secondary: Icon(exercise.icon),
                    onChanged: (value) => setSheetState(() {
                      if (value == true) {
                        selected.add(exercise.id);
                      } else if (selected.length > 1) {
                        selected.remove(exercise.id);
                      }
                    }),
                  ),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    MvpWorkout(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: nameController.text.trim().isEmpty ? 'Workout custom' : nameController.text.trim(),
                      goal: goal,
                      minutes: minutes,
                      rounds: rounds,
                      restSeconds: rest,
                      exerciseIds: selected.toList(),
                      quiet: quiet,
                    ),
                  ),
                  child: const Text('Simpan workout'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    if (result == null) return;
    setState(() => _workouts.insert(0, result));
    await _save();
  }

  Future<void> _exportData() async {
    final payload = jsonEncode({
      'workouts': _workouts.map((workout) => workout.toJson()).toList(),
      'checkIn': {
        'energy': _energy,
        'minutes': _availableMinutes,
        'soreness': _soreness,
        'quiet': _quietMode,
      },
    });
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup data'),
        content: SelectableText(payload),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Future<void> _importData() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import backup'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Tempel JSON backup di sini',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final json = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final imported = (json['workouts'] as List<dynamic>? ?? const [])
          .map((item) => MvpWorkout.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
      final checkIn = Map<String, dynamic>.from(
        (json['checkIn'] as Map?) ?? const {},
      );
      setState(() {
        _workouts
          ..clear()
          ..addAll(imported);
        _energy = (checkIn['energy'] as num?)?.toInt() ?? _energy;
        _availableMinutes = (checkIn['minutes'] as num?)?.toInt() ?? _availableMinutes;
        _soreness = checkIn['soreness'] as String? ?? _soreness;
        _quietMode = checkIn['quiet'] as bool? ?? _quietMode;
      });
      await _save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup berhasil dipulihkan')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Format backup tidak valid')),
        );
      }
    }
  }

  Future<void> _startWorkout(MvpWorkout workout) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MvpSessionPage(
          workout: workout,
          onWorkoutSaved: widget.onWorkoutSaved,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('HomeFit fleksibel'),
        actions: [
          IconButton(
            tooltip: 'Backup data',
            onPressed: _exportData,
            icon: const Icon(Icons.ios_share_rounded),
          ),
          IconButton(
            tooltip: 'Import backup',
            onPressed: _importData,
            icon: const Icon(Icons.file_download_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _MvpHeroCard(
            energy: _energy,
            minutes: _availableMinutes,
            quiet: _quietMode,
            onCheckIn: _openCheckIn,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Check-in',
                  subtitle: 'Sesuaikan hari ini',
                  onTap: _openCheckIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_rounded,
                  title: 'Buat workout',
                  subtitle: 'Atur sesukamu',
                  onTap: _createWorkout,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_recommendation != null) ...[
            _SectionHeader(
              title: 'Rekomendasi untukmu',
              action: TextButton(onPressed: _openCheckIn, child: const Text('Ubah')),
            ),
            _WorkoutCard(
              workout: _recommendation!,
              exercises: _exercisesFor(_recommendation!),
              onStart: () => _startWorkout(_recommendation!),
            ),
            const SizedBox(height: 24),
          ],
          _SectionHeader(
            title: 'Workout milikku',
            action: TextButton(onPressed: _createWorkout, child: const Text('Tambah')),
          ),
          if (_workouts.isEmpty)
            _EmptyMvpState(onCreate: _createWorkout)
          else
            ..._workouts.map(
              (workout) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkoutCard(
                  workout: workout,
                  exercises: _exercisesFor(workout),
                  onStart: () => _startWorkout(workout),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text(
            'Semua pengaturan disimpan di perangkatmu. Tidak perlu akun dan tetap bisa dipakai offline.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _MvpHeroCard extends StatelessWidget {
  const _MvpHeroCard({
    required this.energy,
    required this.minutes,
    required this.quiet,
    required this.onCheckIn,
  });

  final int energy;
  final int minutes;
  final bool quiet;
  final VoidCallback onCheckIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer.withOpacity(.72),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  energy <= 2 ? 'Pelan juga tetap maju.' : 'Siap bergerak?',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  'Energi $energy/5  •  $minutes menit  •  ${quiet ? 'mode hening' : 'bebas suara'}',
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onCheckIn,
                  child: const Text('Update kondisiku'),
                ),
              ],
            ),
          ),
          Icon(Icons.bolt_rounded, size: 54, color: theme.colorScheme.primary),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        action,
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.workout,
    required this.exercises,
    required this.onStart,
  });

  final MvpWorkout workout;
  final List<MvpExercise> exercises;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      workout.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  Icon(Icons.play_circle_fill_rounded, color: theme.colorScheme.primary),
                ],
              ),
              const SizedBox(height: 6),
              Text('${workout.goal}  •  ${workout.minutes} menit  •  ${workout.rounds} ronde'),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercises
                    .map((exercise) => Chip(
                          avatar: Icon(exercise.icon, size: 16),
                          label: Text(exercise.name),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 4),
              Text(
                workout.quiet ? 'Mode hening aktif' : 'Tap untuk mulai',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMvpState extends StatelessWidget {
  const _EmptyMvpState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const Icon(Icons.tune_rounded, size: 38),
            const SizedBox(height: 10),
            const Text('Belum ada workout custom.', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Atur gerakan, ronde, rest, dan durasi sesuai harimu.', textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: onCreate, child: const Text('Buat workout pertama')),
          ],
        ),
      ),
    );
  }
}

class MvpSessionPage extends StatefulWidget {
  const MvpSessionPage({
    required this.workout,
    required this.onWorkoutSaved,
    super.key,
  });

  final MvpWorkout workout;
  final void Function({
    required int durationMinutes,
    required int calories,
  }) onWorkoutSaved;

  @override
  State<MvpSessionPage> createState() => _MvpSessionPageState();
}

class _MvpSessionPageState extends State<MvpSessionPage> {
  Timer? _timer;
  int _elapsed = 0;
  int _exerciseIndex = 0;
  int _round = 1;
  bool _paused = false;
  bool _completed = false;
  late List<MvpExercise> _exercises;

  @override
  void initState() {
    super.initState();
    _exercises = widget.workout.exerciseIds
        .map((id) => mvpExercises.where((item) => item.id == id))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .toList();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_paused && !_completed) setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  MvpExercise get _current => _exercises[_exerciseIndex];

  void _next() {
    if (_exerciseIndex < _exercises.length - 1) {
      setState(() => _exerciseIndex++);
      return;
    }
    if (_round < widget.workout.rounds) {
      setState(() {
        _round++;
        _exerciseIndex = 0;
      });
      return;
    }
    _finish(partial: false);
  }

  Future<void> _replace() async {
    final candidates = mvpExercises.where((item) => item.id != _current.id).toList();
    final result = await showModalBottomSheet<MvpExercise>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text('Ganti gerakan', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Pilih gerakan yang terasa lebih cocok untuk kondisi hari ini.'),
          const SizedBox(height: 12),
          ...candidates.map(
            (item) => ListTile(
              leading: Icon(item.icon),
              title: Text(item.name),
              subtitle: Text(item.detail),
              onTap: () => Navigator.pop(context, item),
            ),
          ),
        ],
      ),
    );
    if (result != null) setState(() => _exercises[_exerciseIndex] = result);
  }

  void _finish({required bool partial}) {
    if (_completed) return;
    _completed = true;
    final minutes = (_elapsed / 60).ceil().clamp(1, 999).toInt();
    widget.onWorkoutSaved(
      durationMinutes: minutes,
      calories: (minutes * (partial ? 5 : 7)).toInt(),
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(partial ? 'Tersimpan sebagai sesi parsial' : 'Workout selesai'),
        content: Text(
          partial
              ? 'Tidak apa-apa berhenti di tengah. Konsistensi tetap dihitung.'
              : 'Mantap. Sesi ${widget.workout.name} sudah masuk ke Progress.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }

  String _format(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = ((_round - 1) * _exercises.length + _exerciseIndex + 1) /
        (widget.workout.rounds * _exercises.length);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workout.name),
        actions: [
          IconButton(
            tooltip: 'Simpan sesi parsial',
            onPressed: () => _finish(partial: true),
            icon: const Icon(Icons.save_alt_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0).toDouble(), minHeight: 8),
          const SizedBox(height: 26),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: Container(
              key: ValueKey('${_round}_$_exerciseIndex'),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  Icon(_current.icon, size: 54, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(_current.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(_current.detail),
                  const SizedBox(height: 18),
                  Text(
                    _current.defaultSeconds > 0
                        ? '${_current.defaultSeconds} detik'
                        : '${_current.defaultReps} repetisi',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ronde $_round/${widget.workout.rounds}'),
              Text('Waktu ${_format(_elapsed)}'),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.check_rounded),
            label: Text(_exerciseIndex == _exercises.length - 1 && _round == widget.workout.rounds
                ? 'Selesaikan workout'
                : 'Selesai, lanjut'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _replace,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Ganti gerakan'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => setState(() => _paused = !_paused),
            icon: Icon(_paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
            label: Text(_paused ? 'Lanjutkan timer' : 'Pause timer'),
          ),
          const SizedBox(height: 12),
          Text(
            'Sesi dapat disimpan kapan saja sebagai parsial. Kamu tidak harus mengulang dari awal.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}