import 'package:flutter/material.dart';
import '../models.dart';
import 'detail.dart';
import 'theme.dart';
import 'widgets.dart';

/// Home — brand "dashboard" layout (Brand Guidelines p.11):
/// large Cycle Score numeral, regime in its band colour, 24h delta,
/// then a tile per indicator coloured by its own regime band.
class HomeScreen extends StatelessWidget {
  final CycleData data;
  final bool fromCache;
  const HomeScreen({super.key, required this.data, required this.fromCache});

  @override
  Widget build(BuildContext context) {
    final c = data.composite;
    final band = Cp.scoreColor(c.score);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (fromCache || data.isStale)
          StaleBanner(
              message:
                  'Showing last saved data from ${data.generatedAt.toLocal().toString().substring(0, 16)}. Pull to refresh.'),
        Card(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label:
                      'Cycle score ${c.score.round()} out of 100, regime ${c.regime}',
                  excludeSemantics: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${c.score.round()}',
                        style: const TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 76,
                          fontWeight: FontWeight.w200,
                          color: Cp.snow,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cycle Score',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                    color: Cp.haze)),
                            const SizedBox(height: 2),
                            Text(c.regime,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: band)),
                            const SizedBox(height: 4),
                            _delta(data.delta1d, '24h'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _scoreBar(c.score),
                const SizedBox(height: 10),
                Text(freshnessLine(data),
                    style: const TextStyle(
                        fontFamily: Cp.mono, fontSize: 11, color: Cp.textDim)),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Expanded(
                child: _groupTile('Valuation', c.valuation,
                    'Price vs long-term value')),
            const SizedBox(width: 10),
            Expanded(
                child: _groupTile('Trend', c.trend, 'Direction of the market')),
          ]),
        ),
        if (c.disagreement != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                const Icon(Icons.call_split, color: Cp.caution, size: 20),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(c.disagreement!,
                        style: const TextStyle(fontSize: 13.5))),
              ]),
            ),
          ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Text('INDICATORS',
              style: TextStyle(
                  fontFamily: Cp.mono,
                  fontSize: 11,
                  letterSpacing: 2,
                  color: Cp.textDim)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(builder: (context, box) {
            final cols = box.maxWidth > 520 ? 4 : 2;
            final w = (box.maxWidth - 10 * (cols - 1)) / cols;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: data.indicators
                  .map((i) => SizedBox(width: w, child: _tile(context, i)))
                  .toList(),
            );
          }),
        ),
      ],
    );
  }

  Widget _delta(double? v, String label) {
    if (v == null) {
      return Text('— ($label)',
          style: const TextStyle(
              fontFamily: Cp.mono, fontSize: 13, color: Cp.textDim));
    }
    final up = v >= 0;
    final color = v.abs() < 0.05 ? Cp.textDim : (up ? Cp.bull : Cp.bear);
    return Text(
      '${up ? '▲' : '▼'} ${up ? '+' : ''}${v.toStringAsFixed(1)} ($label)',
      style: TextStyle(fontFamily: Cp.mono, fontSize: 13, color: color),
    );
  }

  /// Six-band cycle bar with the current position marked.
  Widget _scoreBar(double score) {
    const bands = [
      (20.0, Cp.capitulation),
      (20.0, Cp.accumulation),
      (20.0, Cp.earlyExpansion),
      (15.0, Cp.midBull),
      (13.0, Cp.lateBull),
      (12.0, Cp.euphoria),
    ];
    return LayoutBuilder(builder: (context, box) {
      final x = box.maxWidth * score.clamp(0, 100) / 100;
      return SizedBox(
        height: 18,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            top: 6,
            bottom: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Row(
                children: [
                  for (final (flex, color) in bands)
                    Expanded(
                        flex: (flex * 10).round(),
                        child: Container(color: color.withValues(alpha: 0.85))),
                ],
              ),
            ),
          ),
          Positioned(
            left: x - 2,
            top: 0,
            bottom: 0,
            child: Container(
                width: 4,
                decoration: BoxDecoration(
                    color: Cp.snow, borderRadius: BorderRadius.circular(2))),
          ),
        ]),
      );
    });
  }

  Widget _groupTile(String title, double score, String sub) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Cp.panel, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Cp.haze)),
          const SizedBox(height: 2),
          Text('${score.round()}',
              style: TextStyle(
                  fontFamily: Cp.mono,
                  fontSize: 26,
                  color: Cp.scoreColor(score))),
          Text(sub, style: const TextStyle(fontSize: 11.5, color: Cp.textDim)),
        ]),
      );

  Widget _tile(BuildContext context, Indicator i) => Semantics(
        button: true,
        label: '${i.name}, score ${i.score.round()}',
        excludeSemantics: true,
        child: Material(
          color: Cp.panelRaised,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DetailScreen(indicator: i))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: Cp.haze)),
                  const SizedBox(height: 2),
                  Text('${i.score.round()}',
                      style: TextStyle(
                          fontFamily: Cp.mono,
                          fontSize: 22,
                          color: Cp.scoreColor(i.score))),
                ],
              ),
            ),
          ),
        ),
      );
}
