/// Loads the bundled JSON content. Everything ships in the APK — there is no
/// network call on any gameplay path (RULE-FORBID: airplane-mode playable).
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

const int kLevelCount = 20;

class Content {
  Content._(this.tools, this.shadows, this.levels);

  final Map<String, ToolDef> tools;
  final Map<String, ShadowDef> shadows;
  final Map<int, Level> levels;

  static Content? _instance;

  /// Loaded once during the loading state and then read synchronously from
  /// component `update()` calls, which must never await.
  static Content get I {
    final c = _instance;
    if (c == null) {
      throw StateError('Content.load() must complete before Content.I is read');
    }
    return c;
  }

  static bool get isLoaded => _instance != null;

  static Future<Content> load() async {
    if (_instance case final c?) return c;

    final toolsJson = jsonDecode(
      await rootBundle.loadString('assets/data/tools.json'),
    );
    final shadowsJson = jsonDecode(
      await rootBundle.loadString('assets/data/shadows.json'),
    );

    final tools = <String, ToolDef>{
      for (final t in toolsJson as List)
        (t as Map<String, dynamic>)['id'] as String: ToolDef.fromJson(t),
    };
    final shadows = <String, ShadowDef>{
      for (final s in shadowsJson as List)
        (s as Map<String, dynamic>)['id'] as String: ShadowDef.fromJson(s),
    };

    final levels = <int, Level>{};
    for (var i = 1; i <= kLevelCount; i++) {
      final raw = await rootBundle.loadString('assets/levels/$i.json');
      levels[i] = Level.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    }

    return _instance = Content._(tools, shadows, levels);
  }

  ToolDef tool(String id) =>
      tools[id] ?? (throw ArgumentError('unknown tool "$id"'));

  ShadowDef shadow(String id) =>
      shadows[id] ?? (throw ArgumentError('unknown shadow "$id"'));

  Level level(int id) =>
      levels[id] ?? (throw ArgumentError('unknown level $id'));

  /// Test seam: lets unit tests inject fixtures without the asset bundle.
  static void debugSet(Content c) => _instance = c;

  static Content debugBuild({
    required Map<String, ToolDef> tools,
    required Map<String, ShadowDef> shadows,
    required Map<int, Level> levels,
  }) => Content._(tools, shadows, levels);
}
