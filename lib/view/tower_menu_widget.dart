import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:freedefense/game/game_controller.dart';
import 'package:freedefense/game/game_main.dart';
import 'package:freedefense/game/game_setting.dart';
import 'package:freedefense/map/map_tile_component.dart';
import 'package:freedefense/weapon/weapon_component.dart';

class TowerMenuWidget extends StatefulWidget {
  final GameMain game;
  final Offset position;

  const TowerMenuWidget({
    Key? key,
    required this.game,
    required this.position,
  }) : super(key: key);

  static const String name = 'tower_menu';

  static Widget builder(BuildContext context, GameMain game) {
    if (game is GameMainWithMenu) {
      Offset? pos = game.menuPosition;
      if (pos != null) {
        final screenSize = MediaQuery.of(context).size;
        
        // Estimated menu dimensions (including padding)
        const double menuWidth = 160;
        const double menuHeight = 180;
        const double margin = 20;
        const double edgePadding = 10;
        
        double left = pos.dx + margin;
        double top = pos.dy + margin;
        
        // Flip horizontally if it goes off screen to the right
        if (left + menuWidth > screenSize.width - edgePadding) {
          left = pos.dx - menuWidth - margin;
        }
        
        // Flip vertically if it goes off screen to the bottom
        if (top + menuHeight > screenSize.height - edgePadding) {
          top = pos.dy - menuHeight - margin;
        }
        
        // Final safety bounds
        if (left < edgePadding) left = edgePadding;
        if (top < edgePadding) top = edgePadding;
        if (left + menuWidth > screenSize.width - edgePadding) left = screenSize.width - menuWidth - edgePadding;
        if (top + menuHeight > screenSize.height - edgePadding) top = screenSize.height - menuHeight - edgePadding;
        
        return TowerMenuWidget(
          game: game,
          position: Offset(left, top),
        );
      }
    }
    return const SizedBox.shrink();
  }

  @override
  _TowerMenuWidgetState createState() => _TowerMenuWidgetState();
}

class _TowerMenuWidgetState extends State<TowerMenuWidget> {
  @override
  Widget build(BuildContext context) {
    final weaponSettings = GameSetting().weapons.weapon;
    
    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: GestureDetector(
        onTapDown: (_) {
          // Prevent Flame from handling this event
        },
        child: Listener(
          onPointerDown: (event) {
            // Track when the pointer is down over the menu to distinguish between
            // release over menu vs release outside (which is handled by Flame)
          },
          onPointerUp: (event) {
            // If all buttons are released (buttons == 0), it means the right-click was released
            if (event.buttons == 0) {
              // Check if we should finalize building the tower
              final selectedView = widget.game.weaponFactory.selectedWeapon;
              final buildingWeapon = widget.game.gameController.buildingWeapon;

              print('TowerMenu: PointerUp, buttons == 0');
              print('TowerMenu: current gold: ${widget.game.gamebarView.mineCollected}');
              print('TowerMenu: weapon cost: ${selectedView.cost}');
              print('TowerMenu: mineEnough: ${widget.game.gamebarView.mineCollected >= selectedView.cost}');
              print('TowerMenu: buildingWeapon: ${buildingWeapon != null}');

              if (widget.game.gamebarView.mineCollected >= selectedView.cost && buildingWeapon != null) {
                print('TowerMenu: buildAllowed: ${buildingWeapon.buildAllowed} (blockMap: ${buildingWeapon.blockMap}, blockEnemy: ${buildingWeapon.blockEnemy})');
                if (buildingWeapon.buildAllowed) {
                  print('TowerMenu: Finalizing build');
                  widget.game.gameController.send(buildingWeapon, GameControl.WEAPON_BUILD_DONE);
                  buildingWeapon.onBuildDone();

                  // Clear highlighted tile in GameMain to prevent the cleanup logic below from removing the weapon
                  if (widget.game is GameMainWithMenu) {
                    (widget.game as GameMainWithMenu).highlightedTile = null;
                  }
                  widget.game.gameController.buildingWeapon = null;
                }
              }

              widget.game.overlays.remove(TowerMenuWidget.name);
              if (widget.game is GameMainWithMenu) {
                final gameWithMenu = (widget.game as GameMainWithMenu);
                gameWithMenu.menuPosition = null;
                if (gameWithMenu.highlightedTile != null) {
                  gameWithMenu.highlightedTile!.highlighted = false;
                  gameWithMenu.highlightedTile = null;
                }
                if (widget.game.gameController.buildingWeapon != null) {
                  widget.game.gameController.buildingWeapon!.removeFromParent();
                  widget.game.gameController.buildingWeapon = null;
                }
              }
            }
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(weaponSettings.length, (index) {
                  final setting = weaponSettings[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          widget.game.weaponFactory.select(widget.game.weaponFactory.weapons[index]);
                          // Update preview when hovering over different menu items
                          if (widget.game is GameMainWithMenu) {
                            final gameWithMenu = widget.game as GameMainWithMenu;
                            if (gameWithMenu.highlightedTile != null) {
                              widget.game.gameController.send(gameWithMenu.highlightedTile!, GameControl.WEAPON_BUILDING);
                            }
                          }
                        });
                      },
                      onHover: (_) {
                        // Added onHover to ensure selection is updated even if mouse button is held
                        if (widget.game.weaponFactory.selectedWeapon.weaponType.index != index) {
                          setState(() {
                            widget.game.weaponFactory.select(widget.game.weaponFactory.weapons[index]);
                            // Update preview when hovering over different menu items
                            if (widget.game is GameMainWithMenu) {
                              final gameWithMenu = widget.game as GameMainWithMenu;
                              if (gameWithMenu.highlightedTile != null) {
                                widget.game.gameController.send(gameWithMenu.highlightedTile!, GameControl.WEAPON_BUILDING);
                              }
                            }
                          });
                        }
                      },
                      child: GestureDetector(
                        onTapUp: (_) {
                          setState(() {
                            widget.game.weaponFactory.select(widget.game.weaponFactory.weapons[index]);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: widget.game.weaponFactory.selectedWeapon.weaponType.index == index
                                ? Colors.blue.withValues(alpha: 0.5)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                setting.label,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${setting.cost}',
                                style: const TextStyle(color: Colors.yellow, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

mixin GameMainWithMenu on FlameGame {
  Offset? menuPosition;
  MapTileComponent? highlightedTile;
  WeaponComponent? selectedWeaponForMenu;
}
