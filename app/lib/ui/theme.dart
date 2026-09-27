import 'package:flutter/material.dart';

/// KŌINI Bull Indicator brand system (Brand Guidelines, Edition 01 · 2026).
/// Canvas: Noir + Panel. Accent: Bull Green (gain) / Bear Coral (loss).
/// Type: Jost for everything; JetBrains Mono for data, numerals, labels.
class Cp {
  // Digital accent — bull & bear (brand p.09)
  static const noir = Color(0xFF0A0B0D); // app canvas
  static const panel = Color(0xFF14192C); // cards & panels
  static const panelRaised = Color(0xFF1C2238); // tiles inside panels
  static const snow = Color(0xFFFAFAF7); // on-dark text
  static const bull = Color(0xFF3ECF8E); // primary action & live, gain
  static const bear = Color(0xFFF0506E); // down / loss

  // Core colour — ink & bone (brand p.08), used for secondary/muted text
  static const ink = Color(0xFF0E1B2E);
  static const bone = Color(0xFFF1EDE6);
  static const slate = Color(0xFF3B475D);
  static const haze = Color(0xFFC3CCD8);

  // Aliases used across screens
  static const bg = noir;
  static const surface = panel;
  static const surfaceAlt = panelRaised;
  static const border = Color(0xFF232A40);
  static const text = snow;
  static const textDim = Color(0xFF8E98AB); // haze toned for dark canvas
  static const neutral = Color(0xFF8E98AB);
  static const accent = bull;
  static const caution = Color(0xFFFBBF24);

  // Cycle score palette — one hue per regime band (brand p.10)
  static const capitulation = Color(0xFF3B82F6); // 0–20 deep value
  static const accumulation = Color(0xFF22D3EE); // 21–40 building
  static const earlyExpansion = Color(0xFF3ECF8E); // 41–60 growing
  static const midBull = Color(0xFFFBBF24); // 61–75 heating
  static const lateBull = Color(0xFFF97316); // 76–88 elevated risk
  static const euphoria = Color(0xFFEF4444); // 89–100 historically dangerous

  /// Regime band colour for any 0–100 score.
  static Color scoreColor(double s) {
    if (s <= 20) return capitulation;
    if (s <= 40) return accumulation;
    if (s <= 60) return earlyExpansion;
    if (s <= 75) return midBull;
    if (s <= 88) return lateBull;
    return euphoria;
  }

  /// Direction colour for an indicator's state (gain/loss semantics).
  static Color stateColor(String state) => switch (state) {
        'bull' => bull,
        'bear' => bear,
        _ => neutral,
      };

  static const mono = 'JetBrainsMono';

  static ThemeData theme() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Jost',
        scaffoldBackgroundColor: noir,
        colorScheme: const ColorScheme.dark(
          surface: panel,
          primary: bull,
          secondary: bull,
          error: bear,
          onPrimary: noir,
          onSurface: snow,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: noir,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontFamily: 'Jost',
            color: snow,
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 0.4,
          ),
        ),
        cardTheme: const CardThemeData(
          color: panel,
          elevation: 0,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: panel,
          indicatorColor: bull.withValues(alpha: 0.16),
          iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected) ? bull : textDim)),
          labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontFamily: 'Jost',
              fontSize: 12,
              color: s.contains(WidgetState.selected) ? snow : textDim)),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.selected) ? noir : snow),
            backgroundColor: WidgetStateProperty.resolveWith((s) =>
                s.contains(WidgetState.selected) ? bull : panel),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: bull, foregroundColor: noir),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: bull),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: snow, fontWeight: FontWeight.w200),
          titleMedium: TextStyle(color: snow, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(color: snow, height: 1.45),
          bodySmall: TextStyle(color: textDim, height: 1.4),
        ),
      );
}

const disclaimerText =
    'Not financial advice. Historical indicators can fail. Past cycles do not guarantee future results.';

/// Horned-ring mark (brand p.05). Always the supplied artwork — never redrawn.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/brand/mark-white.png',
        width: size,
        height: size,
        semanticLabel: 'KŌINI Bull Indicator',
      );
}

class DisclaimerBar extends StatelessWidget {
  const DisclaimerBar({super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Cp.noir,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: const Text(
          disclaimerText,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Cp.textDim),
          semanticsLabel: disclaimerText,
        ),
      );
}

class StaleBanner extends StatelessWidget {
  final String message;
  const StaleBanner({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: Cp.caution.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          const Icon(Icons.history, size: 16, color: Cp.caution),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 12, color: Cp.caution)),
          ),
        ]),
      );
}
