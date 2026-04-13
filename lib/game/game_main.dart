import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:freedefense/base/game_component.dart';
import 'package:freedefense/game/game_controller.dart';
import 'package:freedefense/game/game_setting.dart';
import 'package:freedefense/map/map_controller.dart';
import 'package:freedefense/map/map_tile_component.dart';
import 'package:freedefense/view/gamebar_view.dart';
import 'package:freedefense/view/tower_menu_widget.dart';
import 'package:freedefense/view/weapon_action_menu_widget.dart';
import 'package:freedefense/view/weapon_factory_view.dart';
import 'package:freedefense/weapon/weapon_component.dart';

class GameMain extends FlameGame with TapCallbacks, SecondaryTapCallbacks, GameMainWithMenu {
  late MapController mapController;
  late WeaponFactoryView weaponFactory;
  late GameController gameController;
  late GamebarView gamebarView;
  bool started = false;

  bool loadDone = false;

  // GameView view = GameView();
  GameSetting gameSetting = GameSetting();
  // GameController controller = GameController();
  // EnemySpawner enemySpawner = EnemySpawner();
  // StatusBar statusBar;
  // GameUtil util;

  GameMain();

  @override
  void onGameResize(Vector2 size) {
    if (!loadDone) setting.setScreenSize(size);
    super.onGameResize(size);
  }

  int currentTimeMillis() {
    return new DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Future<void> onLoad() async {
    int timeRecord = currentTimeMillis();
    await super.onLoad();

    // await setting.onLoad();
    await setting.neutral.load();

    mapController = MapController(
        tileSize: setting.mapTileSize, mapGrid: setting.mapGrid, position: setting.mapPosition, size: setting.mapSize);
    /*game controller should have same range as map */
    gameController = GameController(position: setting.mapPosition, size: setting.mapSize);

    gamebarView = GamebarView();
    weaponFactory = WeaponFactoryView();

    await setting.weapons.load(gameSetting);

    add(mapController);
    add(gameController);
    add(gamebarView);
    add(weaponFactory);

    setting.enemies.load();

    // Initial gold for prepositioning
    gamebarView.mineCollected = 999;

    loadDone = true;
    int d = currentTimeMillis() - timeRecord;
    print("GameMain onLoad done takke $d");
  }

  @override
  void update(double t) {
    super.update(t);
    // if (recordFps()) {
    //   double _fps = fps();
    //   int len = components.length;
    //   print('GameMain FPS $_fps, components $len');
    // }
    // Iterable<Component> test = components
    //     .where((o) => o is! MapTileComponent)
    //     .where((o) => o is!  0x7d2b523304a0) (first time)
    // print(test.length);
  }

  @override
  void render(Canvas canvas) {
    if (started) {
      super.render(canvas);
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.black,
      );
    }
  }

  void create() {
    if (loadDone) {
      /* Re-initialize map and game controller with potentially new grid settings */
      mapController.mapGrid = setting.mapGrid;
      mapController.tileSize = setting.mapTileSize;
      mapController.position = setting.mapPosition;
      mapController.size = setting.mapSize;
      mapController.rebuildGrid();

      gameController.position = setting.mapPosition;
      gameController.size = setting.mapSize;
      gameController.rebuildGates();

      started = true;
      gamebarView.killedEnemy = 0;
      gamebarView.missedEnemy = 0;
      
      // Show start button
      overlays.add('start');
    }
  }

  void start() {
    if (started) {
      gameController.send(GameComponent(), GameControl.ENEMY_SPAWN);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (overlays.activeOverlays.contains(TowerMenuWidget.name) || 
        overlays.activeOverlays.contains(WeaponActionMenuWidget.name)) {
      overlays.remove(TowerMenuWidget.name);
      overlays.remove(WeaponActionMenuWidget.name);
      menuPosition = null;
      selectedWeaponForMenu = null;
      if (highlightedTile != null) {
        highlightedTile!.highlighted = false;
        highlightedTile!.isBlocking = false;
        highlightedTile = null;
      }
      if (gameController.buildingWeapon != null) {
        gameController.buildingWeapon!.removeFromParent();
        gameController.buildingWeapon = null;
      }
    }
  }

  @override
  void onSecondaryTapDown(SecondaryTapDownEvent event) {
    // If a menu is already open, close it before checking for a new one
    if (overlays.activeOverlays.contains(TowerMenuWidget.name) || 
        overlays.activeOverlays.contains(WeaponActionMenuWidget.name)) {
      overlays.remove(TowerMenuWidget.name);
      overlays.remove(WeaponActionMenuWidget.name);
      menuPosition = null;
      selectedWeaponForMenu = null;
      if (highlightedTile != null) {
        highlightedTile!.highlighted = false;
        highlightedTile!.isBlocking = false;
        highlightedTile = null;
      }
      if (gameController.buildingWeapon != null) {
        gameController.buildingWeapon!.removeFromParent();
        gameController.buildingWeapon = null;
      }
    }

    menuPosition = event.canvasPosition.toOffset();
    
    // Highlight the cell under the pointer
    final components = componentsAtPoint(event.canvasPosition);
    WeaponComponent? weapon;
    MapTileComponent? tile;
    
    for (final component in components) {
      if (component is WeaponComponent) {
        weapon = component;
      }
      if (component is MapTileComponent) {
        tile = component;
      }
    }

    if (weapon != null) {
      selectedWeaponForMenu = weapon;
      overlays.add(WeaponActionMenuWidget.name);
      
      // Clear build preview if any
      if (highlightedTile != null) {
        highlightedTile!.highlighted = false;
        highlightedTile!.isBlocking = false;
        highlightedTile = null;
      }
      if (gameController.buildingWeapon != null) {
        gameController.buildingWeapon!.removeFromParent();
        gameController.buildingWeapon = null;
      }
      
      return;
    }

    if (tile != null) {
      if (highlightedTile != null) {
        highlightedTile!.highlighted = false;
        highlightedTile!.isBlocking = false;
      }
      highlightedTile = tile;
      highlightedTile!.highlighted = true;
      
      // Check if placing a tower on this tile blocks the path to the exit
      if (mapController.testBlock(highlightedTile!.position)) {
        highlightedTile!.isBlocking = true;
      } else {
        // Show current tower preview on the cell
        gameController.send(highlightedTile!, GameControl.WEAPON_BUILDING);
        overlays.add(TowerMenuWidget.name);
      }
    }
  }

  @override
  void onSecondaryTapUp(SecondaryTapUpEvent event) {
    // If the menu is not visible, it means the pointer up event should 
    // be handled here (e.g. released outside the menu).
    // If the menu is visible, it has its own Listener that handles onPointerUp.
    if (!overlays.activeOverlays.contains(TowerMenuWidget.name) && !overlays.activeOverlays.contains(WeaponActionMenuWidget.name)) {
      menuPosition = null;
      selectedWeaponForMenu = null;
      if (highlightedTile != null) {
        highlightedTile!.highlighted = false;
        highlightedTile!.isBlocking = false;
        highlightedTile = null;
      }
      // Remove preview
      if (gameController.buildingWeapon != null) {
        gameController.buildingWeapon!.removeFromParent();
        gameController.buildingWeapon = null;
      }
    }
  }

  @override
  void onSecondaryTapCancel(SecondaryTapCancelEvent event) {
    // DO NOT remove the overlay here, as it may be triggered when the mouse
    // enters the Flutter overlay while dragging.
    // overlays.remove(TowerMenuWidget.name);
    // menuPosition = null;
    // if (highlightedTile != null) {
    //   highlightedTile!.highlighted = false;
    //   highlightedTile = null;
    // }
  }
}
