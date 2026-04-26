import 'package:flame/components.dart';
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
  }) : super(position: position, size: size) {
    anchor = Anchor.topLeft;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    rebuildGrid();
  }

  void onResize(Vector2 position, Vector2 size, Vector2 tileSize) {
    this.position = position;
    this.size = size;
    this.tileSize = tileSize;
    children.whereType<MapTileComponent>().forEach((tile) {
      // Find original grid position based on old tileSize
      // Since MapController is now Anchor.topLeft, tile positions are simple.
      int w = (tile.position.x / tile.size.x).floor();
      int h = (tile.position.y / tile.size.y).floor();
      tile.size = tileSize;
      tile.position = Vector2(w * tileSize.x, h * tileSize.y) + (tileSize / 2);
    });
  }

  void rebuildGrid() {
    // Clear existing MapTileComponents if any
    final existingTiles = children.whereType<MapTileComponent>().toList();
    removeAll(existingTiles);

    for (var w = 0; w < mapGrid.x; w++) {
      for (var h = 0; h < mapGrid.y; h++) {
        this.add(MapTileComponent(
            position: Vector2(w * tileSize.x, h * tileSize.y) + (tileSize / 2),
            size: tileSize));
      }
    }

    initBackground();
    astarMapInit(mapGrid);
  }

  void initBackground() {}

  bool testBlock(Vector2 position) {
    // position is relative to MapController's top-left
    astarMapAddObstacle(position);
    // Since everything is Anchor.topLeft and aligned, we can use global positions
    // or just assume they are already translated correctly.
    // gateStart.position and gateEnd.position are relative to GameController (Anchor.topLeft)
    // which is at the same position as MapController.
    AstarNode? goal = astarMapResolve(
        gameRef.gameController.gateStart.position, gameRef.gameController.gateEnd.position);
    astarMapRemoveObstacle(position);
    return goal == null ? true : false;
  }
}
