import 'package:flutter/material.dart';
import '../education.dart';
import '../models.dart';
import 'theme.dart';
import 'widgets.dart';

class DetailScreen extends StatelessWidget {
  final Indicator indicator;
  const DetailScreen({super.key, required this.indicator});

  @override
  Widget build(BuildContext context) {
    final edu = education[indicator.key];
    final i = indicator;
    return Scaffold(
      appBar: AppBar(title: Text(i.name)),
      bottomNavigationBar: const DisclaimerBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${i.raw} ${i.unit}',
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w800)),
                        ScorePill(score: i.score),
                      ]),
                  const SizedBox(height: 6),
                  Text(i.detail,
                      style:
                          const TextStyle(fontSize: 13.5, color: Cp.textDim)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Cp.stateColor(i.state).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(i.state.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Cp.stateColor(i.state))),
                    ),
                    const SizedBox(width: 8),
                    Text('as of ${i.asOf}',
                        style:
                            const TextStyle(fontSize: 12, color: Cp.textDim)),
                    if (i.estimated) ...[
                      const SizedBox(width: 8),
                      const Text('· estimated',
                          style: TextStyle(fontSize: 12, color: Cp.caution)),
                    ],
                  ]),
                ],
              ),
            ),
          ),
          if (edu != null) ...[
            _section('What it is', edu.what),
            _section('Why it matters', edu.why),
            _section('How to read it', edu.howToRead),
            _section('Historical record & failure modes', edu.history),
          ],
          _section('Source & method', i.sourceNote),
        ],
      ),
    );
  }

  Widget _section(String title, String body) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Cp.accent)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 14, height: 1.55)),
          ]),
        ),
      );
}
