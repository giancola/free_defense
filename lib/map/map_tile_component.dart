import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:freedefense/base/game_component.dart';
import 'package:freedefense/game/game_controller.dart';

enum MapTileBuildStatus { Empty, BuildPreview, BuildDone }

enum MapTileBuildEvent { None, BuildPreview, BuildDone, BuildCancel }

class MapTileComponent extends GameComponent with TapCallbacks {
  MapTileBuildStatus buildStatus = MapTileBuildStatus.Empty;
  GameComponent? refComponent;
  bool ableToBuild = true;
  bool highlighted = false;
  Sprite? background;

  MapTileComponent({
    Vector2? position,
    Vector2? size,
  }) : super(
          position: position,
          size: size,
        );

  void render(Canvas c) {
    super.render(c);
    // if (background != null) {
    // background!.renderRect(c, size.toRect());
    c.drawRect(
        size.toRect(),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlighted ? 2 : 1
          ..color = highlighted ? Colors.yellow : Colors.green);
    
    if (highlighted) {
      c.drawRect(
          size.toRect(),
          Paint()
            ..style = PaintingStyle.fill
            ..color = Colors.yellow.withValues(alpha: 0.2));
    }
  }

  @override
  bool onTapDown(TapDownEvent event) {
    gameRef.gameController.send(this, GameControl.WEAPON_BUILDING);
    return false;
  }
}
