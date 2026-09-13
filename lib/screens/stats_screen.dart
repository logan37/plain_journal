import 'package:flutter/material.dart';

import '../models/mood.dart';
import '../state/app_state.dart';
import '../utils/date_utils.dart';

/// Insights: streak, mood distribution + trend for a chosen month,
/// and the most-used tags.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, required this.app});

  final AppState app;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) {
          if (!app.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final moodCounts = app.moodCounts(lookback: 60);
          final series = app.moodSeriesForMonth(_month);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  _StatCard(
                    icon: Icons.local_fire_department,
                    value: '${app.currentStreak}',
                    label: 'day streak',
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.calendar_today,
                    value: '${app.totalDays}',
                    label: 'days logged',
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.article_outlined,
                    value: '${app.totalEntries}',
                    label: 'entries',
                    color: Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatCard(
                    icon: Icons.favorite,
                    value: '${app.periodDayCount}',
                    label: 'period days',
                    color: const Color(0xFFE91E63),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.label_outline,
                    value: '${app.tagCounts().length}',
                    label: 'tags used',
                    color: Colors.indigo,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Mood last 60 entries', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _MoodBarChart(counts: moodCounts),
              const SizedBox(height: 24),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Previous month',
                  ),
                  Expanded(
                    child: Text(
                      formatMonth(_month),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Next month',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (series.every((w) => w == 0))
                Text(
                  'No moods recorded this month yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                SizedBox(
                  height: 140,
                  child: MoodTrendChart(series: series),
                ),
              const SizedBox(height: 24),
              Text('Top tags', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _TagBars(counts: app.tagCounts()),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.titleLarge),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodBarChart extends StatelessWidget {
  const _MoodBarChart({required this.counts});

  final Map<Mood, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    if (total == 0) {
      return Text(
        'No moods recorded yet.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      children: [
        for (final mood in Mood.values) ...[
          Expanded(
            child: Column(
              children: [
                Text('${counts[mood] ?? 0}'),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 60,
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        FractionallySizedBox(
                          heightFactor: (counts[mood] ?? 0) / total,
                          child: Container(
                            width: double.infinity,
                            color: mood.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(mood.emoji),
              ],
            ),
          ),
          if (mood != Mood.values.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _TagBars extends StatelessWidget {
  const _TagBars({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = counts.entries.take(8).toList();
    final max = top.isEmpty ? 1 : top.first.value;

    return Column(
      children: [
        for (final entry in top)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    '#${entry.key}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: entry.value / max,
                      minHeight: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${entry.value}',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Simple line chart of daily mood weights (1..5) for a month.
class MoodTrendChart extends StatelessWidget {
  const MoodTrendChart({super.key, required this.series});

  final List<int> series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      size: const Size(double.infinity, 140),
      painter: _MoodTrendPainter(
        series: series,
        lineColor: theme.colorScheme.primary,
        fillColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        gridColor: theme.colorScheme.outlineVariant,
        textStyle: theme.textTheme.labelSmall,
      ),
    );
  }
}

class _MoodTrendPainter extends CustomPainter {
  _MoodTrendPainter({
    required this.series,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textStyle,
  });

  final List<int> series;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final TextStyle? textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    const maxWeight = 5.0;
    const leftPad = 24.0;
    const rightPad = 8.0;
    const topPad = 8.0;
    const bottomPad = 20.0;

    final chartWidth = size.width - leftPad - rightPad;
    final chartHeight = size.height - topPad - bottomPad;

    // Horizontal gridlines at each mood grade.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var weight = 1; weight <= maxWeight; weight++) {
      final y = topPad + chartHeight - (weight / maxWeight) * chartHeight;
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );
      if (textStyle != null) {
        final painter = TextPainter(
          text: TextSpan(text: '$weight', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(
          canvas,
          Offset(leftPad - painter.width - 6, y - painter.height / 2),
        );
      }
    }

    final n = series.length;
    if (n == 0) return;

    final points = <Offset>[];
    for (var i = 0; i < n; i++) {
      final weight = series[i];
      if (weight <= 0) continue;
      final x = leftPad + chartWidth * (i / (n - 1));
      final y = topPad + chartHeight - (weight / maxWeight) * chartHeight;
      points.add(Offset(x, y));
    }
    if (points.isEmpty) return;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, topPad + chartHeight)
      ..lineTo(points.first.dx, topPad + chartHeight)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()..color = fillColor..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dotPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_MoodTrendPainter oldDelegate) =>
      oldDelegate.series != series ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.fillColor != fillColor;
}