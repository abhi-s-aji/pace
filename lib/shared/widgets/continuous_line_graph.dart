import 'package:flutter/material.dart';
import '../../core/domain/calculators/statistics_engine.dart';
import '../../core/theme/pace_colors.dart';
import '../../core/utils/date_utils.dart';

enum GraphMetric { completion, focus, activities }

extension GraphMetricExtension on GraphMetric {
  String get label {
    switch (this) {
      case GraphMetric.completion:
        return 'Completion';
      case GraphMetric.focus:
        return 'Focus';
      case GraphMetric.activities:
        return 'Activities';
    }
  }
}

class ContinuousLineGraph extends StatefulWidget {
  final List<DailyTrendPoint> trends;
  final Function(DateTime date) onViewDay;

  const ContinuousLineGraph({
    super.key,
    required this.trends,
    required this.onViewDay,
  });

  @override
  State<ContinuousLineGraph> createState() => _ContinuousLineGraphState();
}

class _ContinuousLineGraphState extends State<ContinuousLineGraph> {
  GraphMetric _selectedMetric = GraphMetric.completion;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    // Default select the latest day if available
    if (widget.trends.isNotEmpty) {
      _selectedIndex = widget.trends.length - 1;
    }
  }

  @override
  void didUpdateWidget(covariant ContinuousLineGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trends.isNotEmpty && (_selectedIndex == null || _selectedIndex! >= widget.trends.length)) {
      _selectedIndex = widget.trends.length - 1;
    }
  }

  double _getValue(DailyTrendPoint pt) {
    switch (_selectedMetric) {
      case GraphMetric.completion:
        return pt.completionPercentage.clamp(0.0, 100.0);
      case GraphMetric.focus:
        return pt.focusMinutes.toDouble();
      case GraphMetric.activities:
        return pt.activityCount.toDouble();
    }
  }

  String _formatValue(double val) {
    switch (_selectedMetric) {
      case GraphMetric.completion:
        return '${val.toInt()}%';
      case GraphMetric.focus:
        final mins = val.toInt();
        if (mins < 60) return '${mins}m';
        final h = mins ~/ 60;
        final m = mins % 60;
        return m > 0 ? '${h}h ${m}m' : '${h}h';
      case GraphMetric.activities:
        return '${val.toInt()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trends.isEmpty) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        child: Text(
          'No activity recorded for this period.',
          style: TextStyle(fontSize: 13, color: PaceColors.lightTextMuted),
        ),
      );
    }

    final selectedPoint = _selectedIndex != null && _selectedIndex! < widget.trends.length
        ? widget.trends[_selectedIndex!]
        : widget.trends.last;

    final values = widget.trends.map(_getValue).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric Selector Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: GraphMetric.values.map((metric) {
            final isSelected = _selectedMetric == metric;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                label: '${metric.label} metric',
                selected: isSelected,
                button: true,
                child: ChoiceChip(
                  label: Text(metric.label),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedMetric = metric;
                      });
                    }
                  },
                  selectedColor: PaceColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? PaceColors.primary : PaceColors.lightTextSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected ? PaceColors.primary : PaceColors.lightBorder,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // Selected Point Summary Banner / Tooltip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: PaceColors.lightSurfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PaceColors.lightBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PaceDateUtils.formatFullDate(selectedPoint.dateTime),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: PaceColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedMetric.label}: ${_formatValue(_getValue(selectedPoint))}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: PaceColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => widget.onViewDay(selectedPoint.dateTime),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('View day', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PaceColors.primary,
                  side: BorderSide(color: PaceColors.primary.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Continuous Line Chart Canvas
        LayoutBuilder(
          builder: (context, constraints) {
            final chartWidth = constraints.maxWidth;
            const chartHeight = 160.0;

            return Semantics(
              label: 'Continuous progress line graph over time',
              child: GestureDetector(
                onTapDown: (details) {
                  _handleTouch(details.localPosition, chartWidth, widget.trends.length);
                },
                onPanUpdate: (details) {
                  _handleTouch(details.localPosition, chartWidth, widget.trends.length);
                },
                child: CustomPaint(
                  size: Size(chartWidth, chartHeight),
                  painter: _LineGraphPainter(
                    values: values,
                    selectedIndex: _selectedIndex,
                    lineColor: PaceColors.primary,
                    gridColor: PaceColors.lightBorder.withValues(alpha: 0.5),
                    textStyle: TextStyle(fontSize: 10, color: PaceColors.lightTextMuted),
                    dates: widget.trends.map((t) => t.dateTime).toList(),
                    metric: _selectedMetric,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleTouch(Offset localPos, double width, int count) {
    if (count <= 0) return;
    const paddingLeft = 28.0;
    const paddingRight = 16.0;
    final availableWidth = width - paddingLeft - paddingRight;
    final dx = (localPos.dx - paddingLeft).clamp(0.0, availableWidth);
    final step = count > 1 ? availableWidth / (count - 1) : availableWidth;
    final index = (dx / step).round().clamp(0, count - 1);
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }
}

class _LineGraphPainter extends CustomPainter {
  final List<double> values;
  final int? selectedIndex;
  final Color lineColor;
  final Color gridColor;
  final TextStyle textStyle;
  final List<DateTime> dates;
  final GraphMetric metric;

  _LineGraphPainter({
    required this.values,
    required this.selectedIndex,
    required this.lineColor,
    required this.gridColor,
    required this.textStyle,
    required this.dates,
    required this.metric,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const paddingLeft = 28.0;
    const paddingRight = 16.0;
    const paddingTop = 12.0;
    const paddingBottom = 24.0;

    final width = size.width - paddingLeft - paddingRight;
    final height = size.height - paddingTop - paddingBottom;

    if (values.isEmpty) return;

    // Determine Y range
    double maxY = 1.0;
    double minY = 0.0;

    if (metric == GraphMetric.completion) {
      maxY = 100.0;
      minY = 0.0;
    } else {
      for (final v in values) {
        if (v > maxY) maxY = v;
      }
      maxY = (maxY * 1.15).ceilToDouble();
      if (maxY == 0) maxY = 10.0;
    }

    // Grid lines (3 horizontal lines)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i <= 2; i++) {
      final yVal = minY + (maxY - minY) * (i / 2);
      final yPos = paddingTop + height - (height * (i / 2));

      canvas.drawLine(
        Offset(paddingLeft, yPos),
        Offset(size.width - paddingRight, yPos),
        gridPaint,
      );

      // Y-axis label
      String label;
      if (metric == GraphMetric.completion) {
        label = '${yVal.toInt()}%';
      } else {
        label = '${yVal.toInt()}';
      }

      textPainter.text = TextSpan(text: label, style: textStyle);
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, yPos - textPainter.height / 2));
    }

    // Compute point coordinates
    final count = values.length;
    final stepX = count > 1 ? width / (count - 1) : width / 2;

    final List<Offset> points = [];
    for (int i = 0; i < count; i++) {
      final x = paddingLeft + (count > 1 ? i * stepX : width / 2);
      final normY = ((values[i] - minY) / (maxY - minY)).clamp(0.0, 1.0);
      final y = paddingTop + height - (normY * height);
      points.add(Offset(x, y));
    }

    // Draw continuous path
    if (points.length > 1) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        // Control points for smooth continuous line
        final controlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, linePaint);
    } else if (points.length == 1) {
      canvas.drawCircle(points.first, 4, Paint()..color = lineColor);
    }

    // Draw subtle data dots & selected point
    final dotPaint = Paint()..color = lineColor;
    final whitePaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSelected = i == selectedIndex;

      if (isSelected) {
        // Draw larger ring for selected point
        canvas.drawCircle(pt, 7, dotPaint);
        canvas.drawCircle(pt, 4, whitePaint);
        canvas.drawCircle(pt, 2.5, dotPaint);
      } else {
        canvas.drawCircle(pt, 3, dotPaint);
      }
    }

    // Draw X-axis date labels (Start, Middle, End)
    if (dates.length >= 2) {
      final indicesToLabel = <int>{0, dates.length - 1};
      if (dates.length >= 5) {
        indicesToLabel.add(dates.length ~/ 2);
      }

      for (final idx in indicesToLabel) {
        final d = dates[idx];
        final labelText = '${d.month}/${d.day}';
        textPainter.text = TextSpan(text: labelText, style: textStyle);
        textPainter.layout();

        double xPos = points[idx].dx - (textPainter.width / 2);
        xPos = xPos.clamp(paddingLeft, size.width - paddingRight - textPainter.width);

        textPainter.paint(canvas, Offset(xPos, size.height - textPainter.height));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LineGraphPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.metric != metric;
  }
}
