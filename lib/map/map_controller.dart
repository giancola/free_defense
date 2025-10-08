import 'package:flame/extensions.dart';
import 'package:freedefense/astar/astarnode.dart';
import 'package:freedefense/map/astarmap_minxin.dart';
import 'package:freedefense/base/game_component.dart';

import 'map_tile_component.dart';

class MapController extends GameComponent with AstarMapMixin {
  late Vector2 tileSize;
  late Vector2 mapGrid;

  MapController({
    required this.tileSize,
    required this.mapGrid,
    position,
    size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    for (var w = 0; w < mapGrid.x; w++) {
      for (var h = 0; h < mapGrid.y; h++) {
        this.add(MapTileComponent(
            position: Vector2(w * tileSize.x, h * tileSize.y) +
                (Vector2(tileSize.x / 2, tileSize.y / 2)),
            size: tileSize));
      }
    }

    initBackground();
    astarMapInit(mapGrid);
  }

  void initBackground() {}

  bool testBlock(Vector2 position) {
    // Check if there's already an obstacle at this position
    AstarNode node = AstarNode(position.x ~/ tileSize.x, position.y ~/ tileSize.y);
    bool wasObstacle = !astarMap.obstacleMap[node.x][node.y];
    
    // Add obstacle temporarily for testing
    astarMapAddObstacle(position);
    AstarNode? goal = astarMapResolve(
        gameRef.gameSetting.enemySpawn, gameRef.gameSetting.enemyTarget);
    
    // Only remove the obstacle if it wasn't there before
    if (!wasObstacle) {
      astarMapRemoveObstacle(position);
    }
    
    return goal == null ? true : false;
  }
}
