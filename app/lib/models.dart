/// Typed models for the pipeline's static JSON. Parsing is strict:
/// missing/invalid fields throw, and the repository falls back to cache —
/// the UI never renders invented numbers.
library;

class CycleData {
  final DateTime generatedAt;
  final String disclaimer;
  final Composite composite;
  final List<Indicator> indicators;
  final double? delta1d;
  final double? delta7d;
  final List<String> attribution;

  CycleData({
    required this.generatedAt,
    required this.disclaimer,
    required this.composite,
    required this.indicators,
    required this.delta1d,
    required this.delta7d,
    required this.attribution,
  });

  factory CycleData.fromJson(Map<String, dynamic> j) {
    final deltas = (j['deltas'] as Map<String, dynamic>? ?? {});
    return CycleData(
      generatedAt: DateTime.parse(j['generatedAt'] as String),
      disclaimer: j['disclaimer'] as String,
      composite: Composite.fromJson(j['composite'] as Map<String, dynamic>),
      indicators: (j['indicators'] as List)
          .map((e) => Indicator.fromJson(e as Map<String, dynamic>))
          .toList(),
      delta1d: (deltas['d1'] as num?)?.toDouble(),
      delta7d: (deltas['d7'] as num?)?.toDouble(),
      attribution:
          (j['attribution'] as List? ?? const []).map((e) => e.toString()).toList(),
    );
  }

  bool get isStale =>
      DateTime.now().toUtc().difference(generatedAt.toUtc()).inHours > 36;
}

class Composite {
  final double score;
  final String regime;
  final double valuation;
  final double trend;
  final String confidence;
  final String? disagreement;

  Composite({
    required this.score,
    required this.regime,
    required this.valuation,
    required this.trend,
    required this.confidence,
    required this.disagreement,
  });

  factory Composite.fromJson(Map<String, dynamic> j) => Composite(
        score: (j['score'] as num).toDouble(),
        regime: j['regime'] as String,
        valuation: (j['valuation'] as num).toDouble(),
        trend: (j['trend'] as num).toDouble(),
        confidence: j['confidence'] as String,
        disagreement: j['disagreement'] as String?,
      );
}

class Indicator {
  final String key;
  final String name;
  final String group; // valuation | trend
  final double raw;
  final String unit;
  final double score;
  final String state; // bear | neutral | bull
  final String detail;
  final String asOf;
  final bool estimated;
  final String sourceNote;

  Indicator({
    required this.key,
    required this.name,
    required this.group,
    required this.raw,
    required this.unit,
    required this.score,
    required this.state,
    required this.detail,
    required this.asOf,
    required this.estimated,
    required this.sourceNote,
  });

  factory Indicator.fromJson(Map<String, dynamic> j) => Indicator(
        key: j['key'] as String,
        name: j['name'] as String,
        group: j['group'] as String,
        raw: (j['raw'] as num).toDouble(),
        unit: j['unit'] as String,
        score: (j['score'] as num).toDouble(),
        state: j['state'] as String,
        detail: j['detail'] as String,
        asOf: j['asOf'] as String,
        estimated: j['estimated'] as bool? ?? false,
        sourceNote: j['sourceNote'] as String? ?? '',
      );
}

class HistoryRow {
  final String date;
  final double score;
  final Map<String, double> indicatorScores;

  HistoryRow({required this.date, required this.score, required this.indicatorScores});

  factory HistoryRow.fromJson(Map<String, dynamic> j) {
    final scores = <String, double>{};
    for (final e in j.entries) {
      if (e.key != 'date' && e.value is num) {
        scores[e.key] = (e.value as num).toDouble();
      }
    }
    return HistoryRow(
      date: j['date'] as String,
      score: (j['score'] as num).toDouble(),
      indicatorScores: scores,
    );
  }
}

class PricePoint {
  final String date;
  final double value;
  PricePoint(this.date, this.value);
  factory PricePoint.fromJson(Map<String, dynamic> j) =>
      PricePoint(j['date'] as String, (j['value'] as num).toDouble());
}
