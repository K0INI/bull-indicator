import 'dart:convert';
import 'dart:io';

import 'package:bull_indicator/data/repo.dart';
import 'package:bull_indicator/main.dart';
import 'package:bull_indicator/models.dart';
import 'package:bull_indicator/education.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

String fixture() =>
    File('assets/fixtures/latest.json').readAsStringSync();

Repo fakeRepo({bool fail = false}) => Repo(
      client: MockClient((req) async {
        if (fail) return http.Response('down', 503);
        if (req.url.path.endsWith('latest.json')) {
          return http.Response(fixture(), 200,
              headers: {'content-type': 'application/json'});
        }
        if (req.url.path.endsWith('history.json')) {
          return http.Response(
              jsonEncode([
                {'date': '2026-09-26', 'score': 47.1, 'valuation': 40.0, 'trend': 54.0, 'wma200': 59.0},
                {'date': '2026-09-27', 'score': 47.9, 'valuation': 41.2, 'trend': 54.6, 'wma200': 59.8},
              ]),
              200);
        }
        return http.Response(jsonEncode({'price1y': [], 'price4y': []}), 200);
      }),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('models', () {
    test('parses pipeline latest.json strictly', () {
      final d = CycleData.fromJson(jsonDecode(fixture()) as Map<String, dynamic>);
      expect(d.composite.score, 47.9);
      expect(d.composite.regime, 'Early Expansion');
      expect(d.indicators.length, 7);
      expect(d.indicators.where((i) => i.group == 'valuation').length, 3);
      expect(d.indicators.firstWhere((i) => i.key == 'mvrvZ').estimated, isTrue);
      expect(d.delta1d, 0.8);
    });

    test('throws on malformed payload instead of inventing data', () {
      expect(() => CycleData.fromJson({'generatedAt': 'nope'}), throwsA(anything));
    });

    test('staleness detection', () {
      final j = jsonDecode(fixture()) as Map<String, dynamic>;
      j['generatedAt'] =
          DateTime.now().toUtc().subtract(const Duration(hours: 50)).toIso8601String();
      expect(CycleData.fromJson(j).isStale, isTrue);
    });
  });

  group('education', () {
    test('every indicator has full education content', () {
      final d = CycleData.fromJson(jsonDecode(fixture()) as Map<String, dynamic>);
      for (final i in d.indicators) {
        final e = education[i.key];
        expect(e, isNotNull, reason: 'missing education for ${i.key}');
        expect(e!.what.length, greaterThan(50));
        expect(e.history.toLowerCase(), contains('failure'));
      }
    });
    test('no buy/sell advice language anywhere in app copy', () {
      final all = education.values
              .map((e) => '${e.what} ${e.why} ${e.howToRead} ${e.history}')
              .join(' ') +
          methodologyText;
      for (final banned in ['buy now', 'sell now', 'you should buy', 'guaranteed']) {
        expect(all.toLowerCase().contains(banned), isFalse,
            reason: 'found banned phrase "$banned"');
      }
    });
  });

  group('widgets', () {
    testWidgets('home renders score, regime, disclaimer', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RootShell(repo: fakeRepo())));
      await tester.pumpAndSettle();
      expect(find.text('48'), findsOneWidget); // rounded score
      expect(find.text('Early Expansion'), findsOneWidget);
      expect(find.textContaining('Not financial advice'), findsWidgets);
    });

    testWidgets('board lists all seven indicators', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RootShell(repo: fakeRepo())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Board'));
      await tester.pumpAndSettle();
      expect(find.textContaining('MVRV'), findsWidgets);
      expect(find.textContaining('Hash Ribbons'), findsWidgets);
    });

    testWidgets('detail page shows education sections', (tester) async {
      await tester.pumpWidget(MaterialApp(home: RootShell(repo: fakeRepo())));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Board'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('MVRV Z-Score').first);
      await tester.pumpAndSettle();
      expect(find.text('What it is'), findsOneWidget);
      expect(find.text('Historical record & failure modes'), findsOneWidget);
    });

    testWidgets('network failure with no cache shows error state with retry',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: RootShell(repo: fakeRepo(fail: true))));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
