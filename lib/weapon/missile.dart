import 'dart:math';

import 'package:flame/components.dart';
import 'package:freedefense/base/game_component.dart';
import 'package:freedefense/game/game_setting.dart';
import 'package:freedefense/weapon/bullet_component.dart';
import 'package:freedefense/weapon/weapon_component.dart';
import 'package:freedefense/weapon/weapon_setting.dart';

class Missile extends WeaponComponent {

  Missile({
    required Vector2 position, required WeaponSetting weaponSetting
  }) : super(position: position, weaponSetting: weaponSetting) {
    this.size = weaponSetting.size;
    this.weaponType = WeaponType.MISSILE;
    this.range = weaponSetting.range;
    this.fireInterval = weaponSetting.fireInterval;
    this.sprite = weaponSetting.tower;
    this.barrel.sprite = weaponSetting.barrel[0];
    this.barrel.size = size;
    this.barrel.rotateSpeed = weaponSetting.rotateSpeed;
  }

  @override
  void fireBullet(Vector2 target) {
    BulletComponent bullet =
        BulletComponent(position: _bulletPosition(), size: weaponSetting.bulletSize)
          ..angle = barrel.angle
          ..damage = weaponSetting.currentDamage
          ..sprite = weaponSetting.bullet
          ..speed = weaponSetting.currentBulletSpeed
          ..onExplosion = bulletExplosion;
    bullet.moveTo(target);
    parent?.add(bullet);
  }

  Vector2 _bulletPosition() {
    // double bulletR = (weaponSetting.bulletSize.x + weaponSetting.bulletSize.y) / 4;
    double r = radius /*+ bulletR*/;
    Vector2 localPosition =
        Vector2(r * sin(barrel.angle), -r * cos(barrel.angle));
    localPosition += (size / 2);
    return positionOf(localPosition);
  }

  void bulletExplosion(GameComponent enemy) {
    enemy.add(ExplosionComponent(
        position: enemy.size / 2, size: weaponSetting.explosionSize)
      ..animation = SpriteAnimation.spriteList(weaponSetting.explosionSprites,
          stepTime: 0.06, loop: false));
  }
}
