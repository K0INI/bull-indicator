import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models.dart';
import 'theme.dart';

/// Semicircular score gauge, hand-painted (no chart dependency).
class ScoreGauge extends StatelessWidget {
  final double score;
  final String regime;
  final double size;
  const ScoreGauge(
      {super.key, required this.score, required this.regime, this.size = 240});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cycle score ${score.round()} out of 100, regime $regime',
      child: SizedBox(
        width: size,
        height: size * 0.62,
        child: CustomPaint(
          painter: _GaugePainter(score),
          child: Align(
            alignment: const Alignment(0, 0.9),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${score.round()}',
                  style: TextStyle(
                      fontSize: size * 0.23,
                      fontWeight: FontWeight.w800,
                      color: Cp.scoreColor(score),
                      height: 1)),
              Text(regime,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Cp.text)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  _GaugePainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.92);
    final radius = size.width / 2 - 12;
    const start = math.pi, sweep = math.pi;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = Cp.border;
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), start, sweep, false, track);

    // colored segments for regimes
    const stops = [0.0, 20, 40, 60, 75, 88, 100.0];
    const colors = [Cp.bear, Cp.caution, Cp.neutral, Cp.bull, Cp.bull, Cp.euphoria];
    for (var i = 0; i < colors.length; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = colors[i].withValues(alpha: 0.85);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius + 16),
        start + sweep * stops[i] / 100,
        sweep * (stops[i + 1] - stops[i]) / 100 - 0.02,
        false,
        p,
      );
    }

    // filled value arc
    final value = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = Cp.scoreColor(score);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start,
        sweep * (score.clamp(0, 100)) / 100, false, value);

    // needle dot
    final ang = start + sweep * score.clamp(0, 100) / 100;
    final tip = center + Offset(math.cos(ang), math.sin(ang)) * radius;
    canvas.drawCircle(tip, 9, Paint()..color = Cp.text);
    canvas.drawCircle(tip, 5, Paint()..color = Cp.scoreColor(score));
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score;
}

/// Minimal sparkline.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  final double height;
  const Sparkline(
      {super.key, required this.values, required this.color, this.height = 36});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        child: CustomPaint(painter: _SparkPainter(values, color), size: Size.infinite),
      );
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  _SparkPainter(this.values, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce(math.min), max = values.reduce(math.max);
    final range = (max - min) == 0 ? 1.0 : max - min;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / range) * (size.height - 4) - 2;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.color != color;
}

/// Line chart with optional horizontal threshold bands (indicator detail).
class LineChart extends StatelessWidget {
  final List<double> values;
  final List<String> dates;
  final Color color;
  final bool logScale;
  const LineChart({
    super.key,
    required this.values,
    required this.dates,
    required this.color,
    this.logScale = false,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.9,
      child: CustomPaint(
        painter: _LinePainter(
            logScale ? values.map((v) => math.log(math.max(v, 1e-9))).toList() : values,
            color,
            rawForLabels: values,
            dates: dates),
        size: Size.infinite,
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final List<double> rawForLabels;
  final List<String> dates;
  final Color color;
  _LinePainter(this.values, this.color,
      {required this.rawForLabels, required this.dates});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final min = values.reduce(math.min), max = values.reduce(math.max);
    final range = (max - min) == 0 ? 1.0 : max - min;
    // gridlines
    final grid = Paint()..color = Cp.border..strokeWidth = 0.7;
    for (var g = 1; g <= 3; g++) {
      final y = size.height * g / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / range) * (size.height - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
          ).createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.values != values;
}

/// Horizontal bear→bull state strip for the timeline (one per indicator).
class StateStrip extends StatelessWidget {
  final List<double> scores; // 0–100 per day
  final double height;
  const StateStrip({super.key, required this.scores, this.height = 14});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(painter: _StripPainter(scores)),
        ),
      );
}

class _StripPainter extends CustomPainter {
  final List<double> scores;
  _StripPainter(this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;
    final w = size.width / scores.length;
    for (var i = 0; i < scores.length; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * w, 0, w + 0.5, size.height),
        Paint()..color = Cp.scoreColor(scores[i]),
      );
    }
  }

  @override
  bool shouldRepaint(_StripPainter old) => old.scores != scores;
}

/// Score pill used in Board rows and chips.
class ScorePill extends StatelessWidget {
  final double score;
  const ScorePill({super.key, required this.score});
  @override
  Widget build(BuildContext context) {
    final c = Cp.scoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.6)),
      ),
      child: Text('${score.round()}',
          style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

/// Full-screen states.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48, color: Cp.textDim),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Cp.textDim)),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry')),
          ]),
        ),
      );
}

String freshnessLine(CycleData d) {
  final age = DateTime.now().toUtc().difference(d.generatedAt.toUtc());
  final when = age.inHours < 1
      ? '${age.inMinutes} min ago'
      : age.inHours < 48
          ? '${age.inHours} h ago'
          : '${age.inDays} days ago';
  return 'Updated $when · Confidence: ${d.composite.confidence}';
}
