import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:freedefense/game/game_controller.dart';
import 'package:freedefense/game/game_main.dart';
import 'package:freedefense/view/tower_menu_widget.dart';
import 'package:freedefense/weapon/weapon_component.dart';

class WeaponActionMenuWidget extends StatelessWidget {
  final GameMain game;
  final Offset position;
  final WeaponComponent weapon;

  const WeaponActionMenuWidget({
    Key? key,
    required this.game,
    required this.position,
    required this.weapon,
  }) : super(key: key);

  static const String name = 'weapon_action_menu';

  static Widget builder(BuildContext context, GameMain game) {
    if (game is GameMainWithMenu) {
      final pos = game.menuPosition;
      final weapon = game.selectedWeaponForMenu;
      if (pos != null && weapon != null) {
        return WeaponActionMenuWidget(
          game: game,
          position: pos,
          weapon: weapon,
        );
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    int upgradeCost = (weapon.setting.cost * 0.5).toInt();
    int sellPrice = (weapon.setting.cost * 0.5).toInt();
    bool canUpgrade = weapon.barrelModelIndex < 2 && game.gamebarView.mineCollected >= upgradeCost;

    return Positioned(
      left: position.dx,
      top: position.dy,
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
            children: [
              if (weapon.barrelModelIndex < 2)
                _buildMenuItem(
                  label: 'Upgrade',
                  price: upgradeCost,
                  onTap: () {
                    if (canUpgrade) {
                      game.gamebarView.mineCollected -= upgradeCost;
                      weapon.upgradeBarrel();
                      _closeMenu();
                    }
                  },
                  enabled: canUpgrade,
                ),
              _buildMenuItem(
                label: 'X',
                price: sellPrice,
                onTap: () {
                  game.gamebarView.mineCollected += sellPrice;
                  weapon.active = false;
                  weapon.removeFromParent();
                  game.gameController.send(weapon, GameControl.WEAPON_DESTROYED);
                  _closeMenu();
                },
                enabled: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String label,
    required int price,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey,
                fontSize: 14,
                fontWeight: label == 'X' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$price',
              style: TextStyle(
                color: enabled ? Colors.yellow : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeMenu() {
    game.overlays.remove(name);
    if (game is GameMainWithMenu) {
      final gameWithMenu = game as GameMainWithMenu;
      gameWithMenu.menuPosition = null;
      gameWithMenu.selectedWeaponForMenu = null;
    }
  }
}
