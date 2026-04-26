import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../enemy/enemy_setting.dart';
import '../neutral/neutral_setting.dart';
import '../weapon/weapon_setting.dart';

GameSetting gameSetting = GameSetting();

class GameSetting {
  GameSetting._privateConstructor();

  static final GameSetting _instance = GameSetting._privateConstructor();

  factory GameSetting() {
    return _instance;
  }

  EnemySettingV1 enemies = EnemySettingV1();
  WeaponSettingV1 weapons = WeaponSettingV1();
  NeutralSetting neutral = NeutralSetting();

  Vector2 mapGrid = Vector2(10, 10);
  Vector2? preferredMapGrid;
  late Vector2 mapPosition;
  late Vector2 mapSize;
  late Vector2 viewPosition;
  late Vector2 viewSize;
  late Vector2 barPosition;
  late Vector2 barSize;
  late Vector2 mapTileSize;

  double cannonBulletSpeed = 400;
  double cannonBulletDamage = 10;

  Vector2 enemySizeCale = Vector2(0.5, 0.5);
  late Vector2 enemySize;
  late Vector2 enemySpawn;
  late Vector2 enemyTarget;
  double enemySpeed = 80;

  late Vector2 screenSize;

  Vector2 dotMultiple(Vector2 x, Vector2 y) {
    return Vector2(x.x * y.x, x.y * y.y);
  }

  Vector2 dotDivide(Vector2 x, Vector2 y) {
    return Vector2(x.x / y.x, x.y / y.y);
  }

  Vector2 scaleOnMapTile(Vector2 scale) {
    return dotMultiple(mapTileSize, scale);
  }

  Vector2? _previousMapTileSize;

  /// The tile size before the most recent resize. Null if no resize has occurred yet.
  Vector2? get previousMapTileSize => _previousMapTileSize;

  /// Returns the scale factor between old and new mapTileSize after a resize.
  /// Returns null if there was no previous tile size (first call).
  Vector2? get resizeScaleFactor {
    if (_previousMapTileSize == null) return null;
    return dotDivide(mapTileSize, _previousMapTileSize!);
  }

  void setScreenSize(Vector2 size, {bool forceGridUpdate = false}) {
    screenSize = size;
    _previousMapTileSize = loadDone ? mapTileSize.clone() : null;
    optimizeMapGrid(size, forceGridUpdate: forceGridUpdate);

    enemySize = dotMultiple(enemySizeCale, mapTileSize);
    enemySpawn = Vector2(0, 0) + (mapTileSize / 2);
    enemyTarget = Vector2(mapGrid.x - 1, mapGrid.y - 1);
    enemyTarget = dotMultiple(enemyTarget, mapTileSize) + (mapTileSize / 2);

    print('screenSize $screenSize,  mapGrid $mapGrid, mapTileSize $mapTileSize');
  }

  void optimizeMapGrid(Vector2 size, {bool forceGridUpdate = false}) {
    if (loadDone && !forceGridUpdate) {
      // If game is already loaded, we keep mapGrid fixed and only update layout sizes/positions
      _calculateLayout(size);
    } else {
      // First time initialization or forced update
      if (preferredMapGrid != null) {
        mapGrid = preferredMapGrid!;
      } else {
        mapGrid = Vector2(10, 10);
      }

      _calculateLayout(size);

      if (preferredMapGrid == null) {
        mapGrid = mapSize / mapTileSize.x;
        mapGrid = Vector2(mapGrid.x.toInt().toDouble(), mapGrid.y.toInt().toDouble());
        _calculateLayout(size);
      }
    }
  }

  void _calculateLayout(Vector2 size) {
    // Determine the height for top and bottom UI bars
    // We use a fraction of the screen height or a fixed grid-based size.
    // To keep it consistent, let's use a base unit.
    double baseUnit = math.min(size.x, size.y) / 10;

    /*Bar at top*/
    barPosition = Vector2(size.x / 2, baseUnit / 2);
    barSize = Vector2(size.x, baseUnit);

    /*Bottom view area*/
    viewPosition = Vector2(size.x / 2, size.y - (baseUnit * 0.75));
    viewSize = Vector2(size.x, baseUnit * 1.5);

    /*Map in the middle*/
    // Available space for the map
    Vector2 availableMapSize = Vector2(size.x - 2, size.y - barSize.y - viewSize.y - 2);

    // Ensure square tiles
    double tileSize = math.min(availableMapSize.x / mapGrid.x, availableMapSize.y / mapGrid.y);
    mapTileSize = Vector2(tileSize, tileSize);

    // Actual map size based on square tiles
    mapSize = Vector2(mapTileSize.x * mapGrid.x, mapTileSize.y * mapGrid.y);

    // Position of the map's top-left corner, centered in the available space
    double mapLeft = (size.x - mapSize.x) / 2;
    double mapTop = barSize.y + (availableMapSize.y - mapSize.y) / 2;
    mapPosition = Vector2(mapLeft, mapTop);
  }

  bool loadDone = false;

  Future<void> onLoad() async {
    await neutral.load();
    await weapons.load(gameSetting);
    await enemies.load();
  }
}

Future<String> loadAsset(String assetFileName) async {
  return await rootBundle.loadString(assetFileName);
}
