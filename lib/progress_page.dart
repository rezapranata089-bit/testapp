import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'main.dart';

// ---------------------------------------------------------------------
// Halaman utama tab Progress
// ---------------------------------------------------------------------

class ProgressPage extends StatelessWidget {
  const ProgressPage({required this.appState, this.scrollController, super.key});

  final WorkoutAppState appState;
  // Dipakai _MainShellState untuk mereset scroll tab ini ke atas secara
  // diam-diam begitu user berpindah ke tab lain.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      bottom: false,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + 32,
          20,
          120,
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
          Text(
            'Aktivitas mingguan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'DMSerifDisplay',
              fontWeight: FontWeight.w400,
            ),
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
              if (appState.history.length > 5)
                TextButton(
                  onPressed: () =>
                      pushPanel(context, HistoryAllPage(appState: appState)),
                  child: const Text('Lihat semua'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (appState.history.isEmpty)
            const _HistoryEmptyState()
          else
            ...appState.history.take(5).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _HistoryTile(
                      item: item,
                      onTap: () =>
                          pushPanel(context, HistoryDetailPage(item: item)),
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

// ---------------------------------------------------------------------
// Chart aktivitas mingguan: bisa ganti metrik, navigasi minggu, dan tap
// bar untuk lihat detail hari itu.
// ---------------------------------------------------------------------

enum _ActivityMetric { duration, calories, sessions }

// Menurunkan gradasi warna untuk tiap metrik dari warna aksen yang sedang
// dipakai user, dengan menggeser hue-nya sedikit -- supaya tiap metrik
// terlihat beda tapi tetap terasa satu keluarga warna dengan tema aplikasi.
List<Color> _metricGradient(Color base, _ActivityMetric metric) {
  final hsl = HSLColor.fromColor(base);
  double hueShift;
  double lightBoost;
  switch (metric) {
    case _ActivityMetric.duration:
      hueShift = 0;
      lightBoost = 0.14;
      break;
    case _ActivityMetric.calories:
      hueShift = 26; // geser ke arah oranye/hangat
      lightBoost = 0.10;
      break;
    case _ActivityMetric.sessions:
      hueShift = -30; // geser ke arah ungu/biru
      lightBoost = 0.12;
      break;
  }
  final shifted = hsl.withHue((hsl.hue + hueShift) % 360);
  final start = shifted
      .withSaturation((shifted.saturation + 0.08).clamp(0.0, 1.0))
      .toColor();
  final end = shifted
      .withLightness((shifted.lightness + lightBoost).clamp(0.0, 0.9))
      .withSaturation((shifted.saturation + 0.22).clamp(0.0, 1.0))
      .toColor();
  return [start, end];
}

// Tombol navigasi minggu (kiri/kanan) berbentuk lingkaran, meredup saat
// dinonaktifkan (mis. panah kanan saat sudah di minggu berjalan).
class _WeekNavButton extends StatelessWidget {
  const _WeekNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.35,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface.withOpacity(0.6),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _WeeklyActivityCard extends StatefulWidget {
  const _WeeklyActivityCard({required this.appState});

  final WorkoutAppState appState;

  @override
  State<_WeeklyActivityCard> createState() => _WeeklyActivityCardState();
}

class _WeeklyActivityCardState extends State<_WeeklyActivityCard> {
  // 0 = minggu ini, -1 = minggu lalu, dst. Tidak boleh lebih besar dari 0
  // (tidak bisa lihat minggu yang belum terjadi).
  int _weekOffset = 0;
  _ActivityMetric _metric = _ActivityMetric.duration;
  // Arah slide animasi label minggu: 1 = maju (kanan), -1 = mundur (kiri).
  double _slideDirection = -1.0;

  static const _dayLabels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
  static const _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  DateTime get _mondayOfSelectedWeek {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    return thisMonday.add(Duration(days: 7 * _weekOffset));
  }

  List<WorkoutHistory> _historyForDay(DateTime day) {
    return widget.appState.history.where((item) {
      final d = item.completedAt;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  double _valueFor(List<WorkoutHistory> items) {
    switch (_metric) {
      case _ActivityMetric.duration:
        return items.fold<int>(0, (t, i) => t + i.durationMinutes).toDouble();
      case _ActivityMetric.calories:
        return items.fold<int>(0, (t, i) => t + i.calories).toDouble();
      case _ActivityMetric.sessions:
        return items.length.toDouble();
    }
  }

  String get _weekRangeLabel {
    final monday = _mondayOfSelectedWeek;
    final sunday = monday.add(const Duration(days: 6));
    final sameMonth = monday.month == sunday.month;
    final startFmt =
        DateFormat(sameMonth ? 'd' : 'd MMM', 'id_ID').format(monday);
    final endFmt = DateFormat('d MMM', 'id_ID').format(sunday);
    return '$startFmt–$endFmt';
  }

  String get _weekRelativeLabel {
    final weeksAgo = -_weekOffset;
    return '$weeksAgo minggu lalu';
  }

  void _changeWeek(int delta) {
    setState(() {
      _slideDirection = delta > 0 ? 1.0 : -1.0;
      _weekOffset += delta;
    });
    HapticFeedback.selectionClick();
  }

  void _jumpToCurrentWeek() {
    if (_weekOffset == 0) return;
    setState(() {
      _slideDirection = _weekOffset > 0 ? 1.0 : -1.0;
      _weekOffset = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _showDayDetail(DateTime day, List<WorkoutHistory> items) {
    final theme = Theme.of(context);
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.72;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(day),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '${items.length} sesi',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Tidak ada latihan di hari ini.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryTile(
                        item: item,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          pushPanel(context, HistoryDetailPage(item: item));
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monday = _mondayOfSelectedWeek;
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    final dayHistories = days.map(_historyForDay).toList();
    final values = dayHistories.map(_valueFor).toList();
    final maxValue = values.fold<double>(0, (m, v) => v > m ? v : m);
    final chartMax = maxValue <= 0 ? 10.0 : maxValue * 1.25;

    final today = DateTime.now();
    final todayIndex = days.indexWhere(
      (d) => d.year == today.year && d.month == today.month && d.day == today.day,
    );
    final metricGradient = _metricGradient(theme.colorScheme.primary, _metric);
    final mutedGradient =
        metricGradient.map((c) => c.withOpacity(0.55)).toList();
    final minEmptyBarHeight = chartMax * 0.045;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _WeekNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _changeWeek(-1),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _weekOffset == 0 ? null : _jumpToCurrentWeek,
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            final slide = Tween<Offset>(
                              begin: Offset(_slideDirection * 0.4, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                                parent: animation, curve: Curves.easeOutCubic));
                            return SlideTransition(
                              position: slide,
                              child: FadeTransition(opacity: animation, child: child),
                            );
                          },
                          child: Column(
                            key: ValueKey(_weekOffset),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _weekOffset == 0 ? 'Minggu ini' : _weekRelativeLabel,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _weekRangeLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _WeekNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: _weekOffset >= 0 ? null : () => _changeWeek(1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: _ActivityMetric.values.map((metric) {
                final selected = metric == _metric;
                final label = switch (metric) {
                  _ActivityMetric.duration => 'Durasi',
                  _ActivityMetric.calories => 'Kalori',
                  _ActivityMetric.sessions => 'Sesi',
                };
                final metricIcon = switch (metric) {
                  _ActivityMetric.duration => Icons.timer_rounded,
                  _ActivityMetric.calories => Icons.local_fire_department_rounded,
                  _ActivityMetric.sessions => Icons.bolt_rounded,
                };
                final chipGradient =
                    _metricGradient(theme.colorScheme.primary, metric);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setState(() => _metric = metric),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          gradient: selected
                              ? LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: chipGradient,
                                )
                              : null,
                          color:
                              selected ? null : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: chipGradient.last.withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              metricIcon,
                              size: 15,
                              color: selected
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onHorizontalDragEnd: (details) {
                final velocity = details.primaryVelocity ?? 0;
                if (velocity < -250 && _weekOffset < 0) {
                  _changeWeek(1);
                } else if (velocity > 250) {
                  _changeWeek(-1);
                }
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: SizedBox(
                  key: ValueKey('$_weekOffset-$_metric'),
                  height: 150,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMax,
                      minY: 0,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final suffix = switch (_metric) {
                              _ActivityMetric.duration => ' menit',
                              _ActivityMetric.calories => ' kcal',
                              _ActivityMetric.sessions => ' sesi',
                            };
                            final hasValue = values[groupIndex] > 0;
                            return BarTooltipItem(
                              '${_dayNames[groupIndex]}\n',
                              const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                              children: [
                                TextSpan(
                                  text: hasValue
                                      ? '${rod.toY.round()}$suffix'
                                      : 'Tidak ada latihan',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          if (event is FlTapUpEvent &&
                              response != null &&
                              response.spot != null) {
                            final dayIndex = response.spot!.touchedBarGroupIndex;
                            if (dayIndex >= 0 && dayIndex < days.length) {
                              _showDayDetail(days[dayIndex], dayHistories[dayIndex]);
                            }
                          }
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= _dayLabels.length) {
                                return const SizedBox.shrink();
                              }
                              final isToday = index == todayIndex;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _dayLabels[index],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: isToday
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: values.asMap().entries.map((entry) {
                        final hasValue = entry.value > 0;
                        final isToday = entry.key == todayIndex;
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: hasValue ? entry.value : minEmptyBarHeight,
                              width: 24,
                              borderRadius:
                                  BorderRadius.circular(hasValue ? 10 : 20),
                              gradient: hasValue
                                  ? LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors:
                                          isToday ? metricGradient : mutedGradient,
                                    )
                                  : null,
                              color: hasValue
                                  ? null
                                  : theme.colorScheme.outlineVariant
                                      .withOpacity(0.3),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    duration: const Duration(milliseconds: 450),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.touch_app_outlined, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ketuk salah satu batang untuk lihat detail harinya.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

// ---------------------------------------------------------------------
// Panel "Lihat semua" riwayat, dikelompokkan per bulan dengan animasi
// stagger fade + slide (mirip rangkaian gerakan di tab Home).
// ---------------------------------------------------------------------

class HistoryAllPage extends StatelessWidget {
  const HistoryAllPage({required this.appState, super.key});

  final WorkoutAppState appState;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = appState.history;

    // Riwayat sudah terurut terbaru -> terlama, jadi grouping cukup dengan
    // menelusuri berurutan dan menambah ke grup bulan yang sesuai.
    final groups = <String, List<WorkoutHistory>>{};
    for (final item in history) {
      final key = DateFormat('MMMM yyyy', 'id_ID').format(item.completedAt);
      groups.putIfAbsent(key, () => []).add(item);
    }

    var runningIndex = 0;

    return Scaffold(
      backgroundColor: _panelBackgroundColor(context),
      appBar: AppBar(
        systemOverlayStyle: _panelOverlayStyle(context),
        title: const Text(
          'Semua Riwayat',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: _HistoryEmptyState(),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 18, 2, 10),
                    child: Text(
                      entry.key,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final item in entry.value)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryRevealItem(
                        staggerIndex: runningIndex++,
                        child: _HistoryTile(
                          item: item,
                          onTap: () =>
                              pushPanel(context, HistoryDetailPage(item: item)),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

// Membungkus tiap tile riwayat agar muncul dengan animasi fade + slide,
// dengan delay bertahap (stagger) antar item -- pola yang sama dipakai
// untuk daftar gerakan di tab Home.
class _HistoryRevealItem extends StatefulWidget {
  const _HistoryRevealItem({required this.child, required this.staggerIndex});

  final Widget child;
  final int staggerIndex;

  @override
  State<_HistoryRevealItem> createState() => _HistoryRevealItemState();
}

class _HistoryRevealItemState extends State<_HistoryRevealItem>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(widget.staggerIndex.isEven ? -0.35 : 0.35, 0),
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  void _checkVisibility() {
    if (!mounted) return;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return;

    final viewportHeight = MediaQuery.of(context).size.height;
    final position = renderObject.localToGlobal(Offset.zero);
    final itemHeight = renderObject.size.height;
    final isVisible =
        position.dy < viewportHeight * 0.95 && (position.dy + itemHeight) > 0;

    if (!_revealed && isVisible) {
      _revealed = true;
      _scrollPosition?.removeListener(_checkVisibility);
      final cappedIndex = widget.staggerIndex.clamp(0, 10);
      final delay = Duration(milliseconds: 60 * cappedIndex);
      Future.delayed(delay, () {
        if (mounted && _revealed) _controller.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_checkVisibility);
    _controller.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
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
    final displayExercises = item.exercises.isNotEmpty
        ? item.exercises
        : workoutDataForType(item.title).exercises;
    return Scaffold(
      backgroundColor: _panelBackgroundColor(context),
      appBar: AppBar(
        systemOverlayStyle: _panelOverlayStyle(context),
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
          ...displayExercises.asMap().entries.map(
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

Color _panelBackgroundColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF111310)
      : const Color(0xFFF4F3F0);
}

SystemUiOverlayStyle _panelOverlayStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

String _formatDate(DateTime date) {
  return DateFormat('d MMM yyyy', 'id_ID').format(date);
}

String _formatClock(DateTime date) {
  return DateFormat('HH:mm').format(date);
}