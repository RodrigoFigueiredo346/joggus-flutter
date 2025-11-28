import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../models/player.dart';
import 'table_page.dart';

class LobbyPage extends StatefulWidget {
  final String playerName;
  final bool isCreator;
  final String? roomId;

  const LobbyPage({
    super.key,
    required this.playerName,
    required this.isCreator,
    this.roomId,
  });

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  late WebSocketService ws;

  @override
  void initState() {
    super.initState();
    ws = Provider.of<WebSocketService>(context, listen: false);

    // Ouve mudanças no estado e verifica quando o jogo começar
    ws.addListener(_onGameStateChange);
  }

  @override
  void dispose() {
    ws.removeListener(_onGameStateChange);
    super.dispose();
  }

  void _onGameStateChange() {
    final game = ws.gameState;
    if (game.isGameStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TablePage()),
        );
      });
    }
  }

  void _startGame() {
    if (widget.roomId != null || ws.gameState.roomId != null) {
      final roomId = widget.roomId ?? ws.gameState.roomId!;
      ws.send('start_game', {'room_id': roomId});
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<WebSocketService>().gameState;
    final players = game.players;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sala ${game.roomId ?? widget.roomId ?? ''}',
          style: const TextStyle(color: Colors.greenAccent),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Aguardando jogadores...',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, index) {
                  final Player p = players[index];
                  return ListTile(
                    leading: const Icon(Icons.person, color: Colors.greenAccent),
                    title: Text(
                      p.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      '${p.chips} fichas',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            if (widget.isCreator)
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                ),
                child: const Text(
                  'Iniciar Jogo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
