import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:joggus/models/game_player.dart';
import 'package:joggus/widgets/turn_time_bar.dart';
import 'package:provider/provider.dart';
import '../services/websocket_service.dart';
import '../models/player.dart';
import '../models/card_model.dart';

class TablePage extends StatelessWidget {
  const TablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();
    final game = ws.gameState;
    final players = game.players;
    final community = game.communityCards;
    final localPlayerId = ws.localPlayerId ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Stack(
          children: [
            // Showdown overlay com jogada vencedora e botão
            if (game.isShowdown && game.winningHand != null)
              Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Jogada Vencedora',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          game.winningHand!,
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            ws.startGame();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                          ),
                          child: const Text(
                            'Nova rodada?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Última ação
            if (game.lastActionText != null)
              Align(
                alignment: const Alignment(0, -0.45),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    game.lastActionText!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Mesa central
            Align(
              alignment: Alignment.center,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.green[800],
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [BoxShadow(color: Colors.blueGrey, blurRadius: 5)],
                ),
              ),
            ),

            // Cartas comunitárias
            Align(
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOut,
                child: Row(
                  key: ValueKey(
                    community.length,
                  ), // força rebuild quando muda o número de cartas
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: community
                      .asMap()
                      .entries
                      .map(
                        (entry) => AnimatedSlide(
                          offset: const Offset(0, 0.1),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 500),
                              opacity: 1.0,
                              child: _buildCard(entry.value, game),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            // Pot
            Align(
              alignment: const Alignment(0, -0.2),
              child: Text(
                'Pote: ${game.pot}',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Jogadores posicionados
            ..._buildPlayers(game, players, localPlayerId),

            // Botões de ação (somente para o jogador local)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _actionButton('FOLD', Colors.redAccent, ws, context),
                    const SizedBox(width: 12),
                    _actionButton('CHECK', Colors.blueAccent, ws, context),
                    const SizedBox(width: 12),
                    _actionButton('CALL', Colors.greenAccent, ws, context),
                    const SizedBox(width: 12),
                    _actionButton(
                      'BET',
                      Colors.amber,
                      ws,
                      context,
                      onBet: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Gera os widgets dos jogadores
  List<Widget> _buildPlayers(
    GameState game,
    List<Player> players,
    String localId,
  ) {
    if (players.isEmpty) return [];

    // Local player é o primeiro; os outros seguem em ordem
    final rotatedPlayers = _getRotatedPlayers(players, localId);
    final total = rotatedPlayers.length;
    final positions = _getPlayerAlignments(total);

    return List.generate(total, (i) {
      final p = rotatedPlayers[i];
      final align = positions[i];
      final isLocal = i == 0; // o local está sempre na parte inferior
      final isCurrent = p.id == game.currentPlayerId;

      return Align(
        alignment: isLocal ? const Alignment(0, 0.7) : align,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocal)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: p.hand.map((c) => _buildCard(c, game)).toList(),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent ? Colors.green : Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  // color: isCurrent
                  //     ? Colors.greenAccent
                  //     : Colors.greenAccent.withOpacity(0.4),
                  color: Colors.green,
                  width: isCurrent ? 3 : 1.5,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    p.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${p.chips} fichas',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    p.isBigBlind
                        ? 'BB'
                        : p.isSmallBlind
                        ? 'SB'
                        : '',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (isCurrent && game.turnStartTime != null)
              TurnTimerBar(
                key: ValueKey('${p.id}_${game.turnStartTime}'),
                isLocal: isLocal,
              ),
          ],
        ),
      );
    });
  }

  // 🔹 Define as posições dos jogadores em volta da mesa
  List<Alignment> _getPlayerAlignments(int count) {
    const double radiusX = 0.85; // controla quão longe do centro na horizontal
    const double radiusY = -0.85; // controla quão longe do centro na vertical
    List<Alignment> positions = [];

    for (int i = 0; i < count; i++) {
      // distribui igualmente ao redor do círculo
      final angle = (2 * 3.14159 / count) * i - 3.14159 / 2; // começa em baixo
      final x = radiusX * (i == 0 ? 0 : Math.cos(angle));
      final y = radiusY * Math.sin(angle);
      positions.add(Alignment(x, y));
    }

    return positions;
  }

  // 🔹 Renderiza uma carta simples
  Widget _buildCard(CardModel c, GameState game) {
    final isWinning = game.winningCards.contains(c);

    Widget cardWidget = Container(
      margin: EdgeInsets.all(4),
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        color: isWinning ? Colors.yellowAccent : Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4)],
        border: isWinning ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${c.rank}${c.suit}',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    if (isWinning) {
      return BlinkingCard(child: cardWidget);
    }

    return cardWidget;
  }

  // 🔹 Cria botão de ação genérico
  Widget _actionButton(
    String text,
    Color color,
    WebSocketService ws,
    BuildContext context, {
    bool onBet = false,
  }) {
    return ElevatedButton(
      onPressed: () {
        if (onBet) {
          _showBetDialog(context, ws);
        } else {
          ws.playerAction(text.toLowerCase());
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 🔹 Mostra diálogo para selecionar valor da aposta
  void _showBetDialog(BuildContext context, WebSocketService ws) {
    final localPlayerId = ws.localPlayerId ?? '';
    final localPlayer = ws.gameState.players.firstWhere(
      (p) => p.id == localPlayerId,
      orElse: () => Player(id: '', name: '', chips: 0),
    );

    final maxChips = localPlayer.chips;
    if (maxChips <= 0) return;

    double betAmount = 1;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Selecione o valor da aposta',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Valor: ${betAmount.toInt()}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Slider(
                    value: betAmount,
                    min: 1,
                    max: maxChips.toDouble(),
                    divisions: maxChips > 1 ? maxChips - 1 : 1,
                    activeColor: Colors.amber,
                    inactiveColor: Colors.amber.withOpacity(0.3),
                    onChanged: (value) {
                      setState(() {
                        betAmount = value;
                      });
                    },
                  ),
                  Text(
                    'Max: $maxChips',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ws.playerAction('bet', amount: betAmount.toInt());
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Player> _getRotatedPlayers(List<Player> players, String localId) {
    if (players.isEmpty) return [];
    final index = players.indexWhere((p) => p.id == localId);
    if (index == -1) return players;

    return [...players.sublist(index), ...players.sublist(0, index)];
  }
}

class BlinkingCard extends StatefulWidget {
  final Widget child;
  const BlinkingCard({super.key, required this.child});

  @override
  State<BlinkingCard> createState() => _BlinkingCardState();
}

class _BlinkingCardState extends State<BlinkingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}
