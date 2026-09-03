/// Builds the right `ToolComponent` subclass for a `ToolDef.id` — spec §6.
library;

import 'package:flame/components.dart';

import '../../../data/models.dart';
import 'beam_lamp_component.dart';
import 'bomb_component.dart';
import 'bulb_component.dart';
import 'frost_lens_component.dart';
import 'mirror_component.dart';
import 'prism_component.dart';
import 'tool_component.dart';
import 'twin_bulb_component.dart';
import 'wall_component.dart';

ToolComponent createTool({
  required ToolDef def,
  required int row,
  required int col,
  required Vector2 center,
}) => switch (def.id) {
  'bulb' => BulbComponent(def: def, row: row, col: col, center: center),
  'beam' => BeamLampComponent(def: def, row: row, col: col, center: center),
  'mirror' => MirrorComponent(def: def, row: row, col: col, center: center),
  'prism' => PrismComponent(def: def, row: row, col: col, center: center),
  'frost' => FrostLensComponent(def: def, row: row, col: col, center: center),
  'wall' => WallComponent(def: def, row: row, col: col, center: center),
  'bomb' => BombComponent(def: def, row: row, col: col, center: center),
  'twin' => TwinBulbComponent(def: def, row: row, col: col, center: center),
  _ => throw ArgumentError('Unknown tool id: ${def.id}'),
};
