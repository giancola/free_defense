import 'dart:collection';
import 'dart:math';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:freedefense/base/game_component.dart';
import 'package:freedefense/base/radar.dart';
import 'package:freedefense/base/scanable.dart';
import 'package:freedefense/enemy/enemy_component.dart';
import 'package:freedefense/enemy/enemy_factory.dart';
import 'package:freedefense/game/game_setting.dart';
import 'package:freedefense/view/weapon_factory_view.dart';
import 'package:freedefense/weapon/weapon_component.dart';

import '../neutral/neutral_component.dart';

GameSetting gameSetting = GameSetting();

enum GameControl {
  WEAPON_BUILDING,
  WEAPON_SELECTED,
  /*change type */
  WEAPON_BUILD_DONE,
  WEAPON_DESTROYED,
  WEAPON_SHOW_PROFILE,
  ENEMY_SPAWN,
  ENEMY_MISSED,
  ENEMY_KILLED,
  ENEMY_NEXT_WAVE,
  GAME_OVER
}

class GameInstruction {
  GameControl instruction;
  GameComponent source;

  GameInstruction(this.source, this.instruction);
  void process(GameController controller) {
    switch (instruction) {
      case GameControl.WEAPON_BUILDING:
        // Use preview = true for WEAPON_BUILDING to ensure the preview component is created
        WeaponComponent? component = controller.gameRef.weaponFactory.buildWeapon(this.source.position, isPreview: true);
        if (component != null) {
          controller.add(component);
          controller.buildingWeapon?.removeFromParent();
          controller.buildingWeapon = component;
          
          // Set opacity to indicate it's a preview
          component.setOpacity(0.5);
          
          // Check if placing a tower on this tile blocks the path to the exit
          // This matches the check in GameMain.onSecondaryTapDown
          component.blockMap = controller.gameRef.mapController.testBlock(component.position);
          
          // blockEnemy is updated by radarScanAlert/Nothing in WeaponComponent.onBuilding
          // but we can also set an initial value
          component.blockEnemy = false; 
        }
        break;
      case GameControl.WEAPON_SELECTED:
        controller.gameRef.weaponFactory.select(source as SingleWeaponView);
        if (controller.buildingWeapon != null) {
          controller.send(controller.buildingWeapon!, GameControl.WEAPON_BUILDING);
        }
        break;
      case GameControl.WEAPON_BUILD_DONE:
        // Check for existing weapon at the same position and remove it
        final newWeapon = source as WeaponComponent;
        controller.children.whereType<WeaponComponent>().forEach((existing) {
          if (existing != newWeapon && existing.position.distanceTo(newWeapon.position) < 1.0) {
            existing.active = false;
            existing.removeFromParent();
            controller.gameRef.weaponFactory.onDestroy(existing);
          }
        });

        // controller.buildingWeapon.buildDone = true;
        newWeapon.setOpacity(1.0);
        controller.gameRef.weaponFactory.onBuildDone(source as WeaponComponent);
        controller.gameRef.mapController.astarMapAddObstacle(source.position);
        controller.buildingWeapon = null;
        controller.processEnemySmartMove();
        break;
      case GameControl.WEAPON_DESTROYED:
        controller.gameRef.weaponFactory.onDestroy(source as WeaponComponent);
        controller.gameRef.mapController.astarMapRemoveObstacle(source.position);
        controller.processEnemySmartMove();
        break;
      case GameControl.ENEMY_SPAWN:
        controller.enemyFactory.start();
        break;
      case GameControl.ENEMY_MISSED:
        controller.gameRef.gamebarView.missedEnemy += 1;
        break;
      case GameControl.ENEMY_KILLED:
        controller.gameRef.gamebarView.killedEnemy += 1;
        break;
      case GameControl.ENEMY_NEXT_WAVE:
        controller.gameRef.gamebarView.wave += 1;
        break;
      case GameControl.GAME_OVER:
        controller.gameRef.overlays.add('gameover');
        controller.gameRef.pauseEngine();
        break;
      default:
    }
  }
}

class GameController extends GameComponent {
  WeaponComponent? buildingWeapon;
  EnemyFactory enemyFactory = EnemyFactory();
  GameController({
    position,
    size,
  }) : super(position: position, size: size, priority: 10) {
    add(enemyFactory);
  }

  @override
  void update(double dt) {
    processInstruction();
    processRadarScan();
    super.update(dt);
  }

  /* Instruction Queue*/
  Queue _instructQ = new Queue<GameInstruction>();
  send(GameComponent source, GameControl _instruct) {
    _instructQ.add(GameInstruction(source, _instruct));
  }

  void processInstruction() {
    while (_instructQ.isNotEmpty) {
      GameInstruction _instruct = _instructQ.removeFirst();
      _instruct.process(this);
    }
  }

  /* Process Routine */
  void processRadarScan() {
    Iterable<Component> radars = children.where((e) => e is Radar && e.radarOn).cast();
    Iterable<Component> scanbles = children.where((e) => e is Scanable && e.scanable).cast();

    radars.forEach((element) {
      (element as Radar).radarScan(scanbles);
    });
  }

  void processEnemySmartMove() {
    Iterable<Component> enemies = children.where((e) => e is EnemyComponent && e.active).cast();
    enemies.forEach((element) {
      (element as EnemyComponent).moveSmart(gateEnd.position);
    });
  }

  /* Load Initialization */
  late NeutralComponent gateStart;
  late NeutralComponent gateEnd;
  @override
  Future<void>? onLoad() {
    super.onLoad();
    // We don't load gates here anymore, as grid size might change.
    // They will be loaded in start() via rebuildGates().
    // However, to avoid late initialization errors if referenced before start:
    gateStart = NeutralComponent(position: Vector2.zero(), size: Vector2.zero(), neutualType: NeutralType.GATE_START);
    gateEnd = NeutralComponent(position: Vector2.zero(), size: Vector2.zero(), neutualType: NeutralType.GATE_END);
    return null;
  }

  void onResize(Vector2 position, Vector2 size, Vector2 tileSize) {
    this.position = position;
    this.size = size;
    rebuildGates();
    children.whereType<WeaponComponent>().forEach((weapon) {
      // Reposition based on grid
      int w = (weapon.position.x / weapon.size.x).floor();
      int h = (weapon.position.y / weapon.size.y).floor();
      weapon.size = tileSize;
      weapon.position = Vector2(w * tileSize.x, h * tileSize.y) + (tileSize / 2);
    });
    // Enemies are trickier because they are moving.
    // For now, let's just scale their size.
    children.whereType<EnemyComponent>().forEach((enemy) {
      enemy.size = gameSetting.dotMultiple(gameSetting.enemySizeCale, tileSize);
    });
  }

  void rebuildGates() async {
    // Remove existing gates if they exist
    if (gateStart.parent != null) {
      gateStart.removeFromParent();
    }
    if (gateEnd.parent != null) {
      gateEnd.removeFromParent();
    }

    /*fixed gate positions: start top-left (0,0), end lower-right (max-1, max-1)*/
    Vector2 start = Vector2(0, 0);
    Vector2 end = Vector2(gameSetting.mapGrid.x - 1, gameSetting.mapGrid.y - 1);

    start = gameSetting.dotMultiple(start, gameSetting.mapTileSize) + (gameSetting.mapTileSize / 2);
    end = gameSetting.dotMultiple(end, gameSetting.mapTileSize) + (gameSetting.mapTileSize / 2);

    final images = Images();
    gateStart = NeutralComponent(position: start, size: gameSetting.mapTileSize, neutualType: NeutralType.GATE_START)
      ..sprite = Sprite(await images.load('blackhole.png'));
    gateEnd = NeutralComponent(position: end, size: gameSetting.mapTileSize, neutualType: NeutralType.GATE_END)
      ..sprite = Sprite(await images.load('whitehole.png'));
    add(gateStart);
    add(gateEnd);
  }
}
