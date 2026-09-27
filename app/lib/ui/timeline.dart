import 'package:flutter/material.dart';
import '../models.dart';
import 'theme.dart';
import 'widgets.dart';

class TimelineScreen extends StatefulWidget {
  final CycleData data;
  final List<HistoryRow> history;
  final Map<String, dynamic>? charts;
  const TimelineScreen(
      {super.key, required this.data, required this.history, this.charts});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  int _rangeDays = 365;

  @override
  Widget build(BuildContext context) {
    final priceKey = _rangeDays <= 365 ? 'price1y' : 'price4y';
    final priceRaw = (widget.charts?[priceKey] as List?) ?? const [];
    final price = priceRaw
        .map((e) => PricePoint.fromJson(e as Map<String, dynamic>))
        .toList();
    final rows = widget.history.length > _rangeDays
        ? widget.history.sublist(widget.history.length - _rangeDays)
        : widget.history;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 365, label: Text('1Y')),
              ButtonSegment(value: 1461, label: Text('4Y')),
              ButtonSegment(value: 100000, label: Text('Max')),
            ],
            selected: {_rangeDays},
            onSelectionChanged: (s) => setState(() => _rangeDays = s.first),
          ),
        ),
        if (price.length > 2)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BTC price (log scale)',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Cp.textDim)),
                    const SizedBox(height: 8),
                    LineChart(
                      values: price.map((p) => p.value).toList(),
                      dates: price.map((p) => p.date).toList(),
                      color: Cp.accent,
                      logScale: true,
                    ),
                  ]),
            ),
          )
        else
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Price chart unavailable offline.',
                  style: TextStyle(color: Cp.textDim, fontSize: 13)),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Indicator states over time',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Cp.textDim)),
                const SizedBox(height: 4),
                const Text('blue = capitulation · cyan = accumulation · green = early expansion · yellow = mid bull · orange = late bull · red = euphoria',
                    style: TextStyle(fontSize: 11, color: Cp.textDim)),
                const SizedBox(height: 12),
                if (rows.length < 8)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                        'Strips build up as daily history accumulates — check back in a week.',
                        style: TextStyle(color: Cp.textDim, fontSize: 13)),
                  )
                else ...[
                  for (final ind in widget.data.indicators) ...[
                    _stripRow(
                        ind.name,
                        rows
                            .map((r) => r.indicatorScores[ind.key])
                            .whereType<double>()
                            .toList()),
                    const SizedBox(height: 10),
                  ],
                  const Divider(),
                  const SizedBox(height: 6),
                  _stripRow('CYCLE SCORE', rows.map((r) => r.score).toList(),
                      bold: true),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _stripRow(String name, List<double> scores, {bool bold = false}) =>
      Semantics(
        label: '$name state strip',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold ? Cp.text : Cp.textDim)),
          const SizedBox(height: 4),
          StateStrip(scores: scores, height: bold ? 20 : 14),
        ]),
      );
}
