import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../game/game_main.dart';
import '../game/game_setting.dart';

class SplashScreenWidget extends StatefulWidget {
  final GameMain game;

  const SplashScreenWidget({super.key, required this.game});

  static const String name = 'splash';

  static Widget builder(BuildContext context, GameMain game) {
    return SplashScreenWidget(game: game);
  }

  @override
  State<SplashScreenWidget> createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget> {
  final _columnsController = TextEditingController(text: '18');
  final _rowsController = TextEditingController(text: '7');

  @override
  void dispose() {
    _columnsController.dispose();
    _rowsController.dispose();
    super.dispose();
  }

  void _startGame() {
    final double? cols = double.tryParse(_columnsController.text);
    final double? rows = double.tryParse(_rowsController.text);

    if (cols != null && rows != null && cols > 0 && rows > 0) {
      gameSetting.preferredMapGrid = Vector2(cols, rows);
      // Re-trigger optimization with new grid if possible, 
      // but since GameMain.onGameResize hasn't likely called it with the final size yet,
      // we just set the preferred grid.
      // If the game already called setScreenSize, we might need to call it again.
      if (gameSetting.screenSize != null) {
        gameSetting.setScreenSize(gameSetting.screenSize, forceGridUpdate: true);
      }
      
      widget.game.create();
      widget.game.overlays.remove(SplashScreenWidget.name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid positive numbers for grid size')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Game Settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _columnsController,
                decoration: const InputDecoration(
                  labelText: 'Columns',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _rowsController,
                decoration: const InputDecoration(
                  labelText: 'Rows',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Create Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
