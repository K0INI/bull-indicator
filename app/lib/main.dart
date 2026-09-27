import 'package:flutter/material.dart';
import 'data/repo.dart';
import 'models.dart';
import 'ui/board.dart';
import 'ui/home.dart';
import 'ui/settings.dart';
import 'ui/theme.dart';
import 'ui/timeline.dart';
import 'ui/widgets.dart';

void main() => runApp(const BullIndicatorApp());

class BullIndicatorApp extends StatelessWidget {
  const BullIndicatorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'KŌINI Bull Indicator',
        debugShowCheckedModeBanner: false,
        theme: Cp.theme(),
        home: const RootShell(),
      );
}

class RootShell extends StatefulWidget {
  final Repo? repo;
  const RootShell({super.key, this.repo});
  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late final Repo _repo = widget.repo ?? Repo();
  int _tab = 0;
  bool _loading = true;
  Loaded<CycleData>? _latest;
  Loaded<List<HistoryRow>>? _history;
  Loaded<Map<String, dynamic>>? _charts;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = _latest?.data == null);
    final results = await Future.wait([
      _repo.latest(),
      _repo.history(),
      _repo.charts(),
    ]);
    if (!mounted) return;
    setState(() {
      _latest = results[0] as Loaded<CycleData>;
      _history = results[1] as Loaded<List<HistoryRow>>;
      _charts = results[2] as Loaded<Map<String, dynamic>>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _latest?.data;
    final history = _history?.data ?? const <HistoryRow>[];
    final fromCache = _latest?.source == LoadSource.cache;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (data == null) {
      body = ErrorState(
        message:
            'Could not load market data.\nCheck your connection and try again.',
        onRetry: _refresh,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: switch (_tab) {
          0 => HomeScreen(data: data, fromCache: fromCache),
          1 => BoardScreen(data: data, history: history),
          2 => TimelineScreen(
              data: data, history: history, charts: _charts?.data),
          _ => SettingsScreen(data: data, onRefresh: _refresh),
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: _tab == 0
            ? const Row(children: [
                BrandMark(size: 26),
                SizedBox(width: 10),
                Text('Bull Indicator'),
              ])
            : Text(switch (_tab) {
          0 => 'Bull Indicator',
          1 => 'Indicator Board',
          2 => 'Timeline',
          _ => 'Settings',
        }),
      ),
      body: body,
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        const DisclaimerBar(),
        NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.speed), label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.table_rows), label: 'Board'),
            NavigationDestination(
                icon: Icon(Icons.timeline), label: 'Timeline'),
            NavigationDestination(
                icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ]),
    );
  }
}
