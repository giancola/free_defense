import 'dart:ui';
import 'package:flame/flame.dart';
import 'package:flutter/gestures.dart';
import 'package:freedefense/base/flame_game.dart';
import 'package:freedefense/game/game_controller.dart';
import 'package:freedefense/game/game_setting.dart';
import 'package:freedefense/game/game_view.dart';
import 'package:freedefense/map/easy_map.dart';

import 'enemy_spawner.dart';

class GameMain extends FlameGame {
  EasyMap easyMap;
  Canvas canvas;

  GameView view = GameView();
  GameSetting setting = GameSetting();
  GameController controller = GameController();
  EnemySpawner enemySpawner = EnemySpawner();

  bool recordFps() => true;

  GameMain() {
    initialize();
  }

  void initialize() async {
    await Flame.init(
      fullScreen: true,
      // orientation: DeviceOrientation.portraitUp,
    );

    resize(await Flame.util.initialDimensions());
    easyMap = EasyMap(
        tileSize: setting.tileSize,
        mapScale: setting.mapScale,
        mapSize: setting.mapSize);
    easyMap.registerToGame(this);
    controller.registerToGame(this);
    enemySpawner.registerToGame(this);
  }

  void resize(Size size) {
    setting.setScreenSize(size);
    super.resize(size);
  }

  @override
  void update(double t) {
    super.update(t);
    if (recordFps()) {
      double _fps = fps();
      print('GameMain FPS $_fps');
    }
    // Iterable<GameComponent> test = components
    //     .where((o) => o is! MapTileComponent)
    //     .where((o) => o is! EasyMap);
    // print(test.length);
  }

  void onTapDown(TapDownDetails details) {
    super.onTapDown(details);
  }
}
