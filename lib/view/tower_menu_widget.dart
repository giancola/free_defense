import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:freedefense/game/game_main.dart';
import 'package:freedefense/game/game_setting.dart';
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
      final menuState = (game as GameMainWithMenu);
      if (menuState.menuPosition != null) {
        return TowerMenuWidget(
          game: game,
          position: menuState.menuPosition!,
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
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
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
                    // Optional: highlight or select on hover
                    setState(() {
                      widget.game.weaponFactory.select(widget.game.weaponFactory.weapons[index]);
                    });
                  },
                  child: GestureDetector(
                    onTapUp: (_) {
                      // Ensure it's selected when clicked (though onEnter should have done it)
                      setState(() {
                        widget.game.weaponFactory.select(widget.game.weaponFactory.weapons[index]);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.game.weaponFactory.selectedWeapon.weaponType.index == index
                            ? Colors.blue.withOpacity(0.5)
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
    );
  }
}

mixin GameMainWithMenu on FlameGame {
  Offset? menuPosition;
}
