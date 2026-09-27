import 'package:flutter/material.dart';
import '../models.dart';
import 'detail.dart';
import 'theme.dart';
import 'widgets.dart';

class BoardScreen extends StatelessWidget {
  final CycleData data;
  final List<HistoryRow> history;
  const BoardScreen({super.key, required this.data, required this.history});

  @override
  Widget build(BuildContext context) {
    final valuation =
        data.indicators.where((i) => i.group == 'valuation').toList();
    final trend = data.indicators.where((i) => i.group == 'trend').toList();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        _header('VALUATION — where price sits vs long-term value'),
        ...valuation.map((i) => _row(context, i)),
        _header('TREND — which way the market is moving'),
        ...trend.map((i) => _row(context, i)),
      ],
    );
  }

  Widget _header(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 11.5,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
                color: Cp.textDim)),
      );

  Widget _row(BuildContext context, Indicator i) {
    final spark = history
        .map((h) => h.indicatorScores[i.key])
        .whereType<double>()
        .toList();
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => DetailScreen(indicator: i))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Semantics(
            label:
                '${i.name}: score ${i.score.round()} out of 100, ${i.state}. ${i.detail}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Cp.stateColor(i.state), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(i.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14.5)),
                  ),
                  if (i.estimated)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Tooltip(
                        message: 'Estimated from delayed data — see Methodology',
                        child:
                            Icon(Icons.info_outline, size: 15, color: Cp.textDim),
                      ),
                    ),
                  ScorePill(score: i.score),
                ]),
                const SizedBox(height: 8),
                Text('${i.raw} ${i.unit}',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Cp.text,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(i.detail,
                    style: const TextStyle(fontSize: 12.5, color: Cp.textDim)),
                if (spark.length > 5) ...[
                  const SizedBox(height: 10),
                  Sparkline(values: spark, color: Cp.stateColor(i.state)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
