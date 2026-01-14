import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:joggus/models/game_player.dart';
import 'package:joggus/widgets/turn_time_bar.dart';
import 'package:provider/provider.dart';

import '../models/card_model.dart';
import '../models/player.dart';
import '../services/websocket_service.dart';

class TablePage extends StatelessWidget {
  const TablePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ws = context.watch<WebSocketService>();
    final game = ws.gameState;
    final players = game.players;
    final community = game.communityCards;
    final localPlayerId = ws.localPlayerId ?? '';
    final isLocalTurn =
        game.currentPlayerId != null &&
        game.currentPlayerId == localPlayerId &&
        !game.isShowdown;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0F),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double scale = Math.min(
              constraints.maxWidth / 400.0,
              constraints.maxHeight / 700.0,
            ).clamp(0.6, 1.5);

            final double tableWidth =
                constraints.maxWidth * 0.52; // reduzido ~20%
            final double tableHeight =
                constraints.maxHeight * 0.4; // reduzido ~20%

            return Stack(
              children: [
                // Fundo com leve gradiente para reforçar foco no centro
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [
                          const Color(0xFF14351F).withOpacity(0.7),
                          const Color(0xFF0D0D0F),
                        ],
                      ),
                    ),
                  ),
                ),

                // Mesa central
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: tableWidth,
                    height: tableHeight,
                    decoration: BoxDecoration(
                      color: Colors.green[800],
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(150),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.shade900,
                          blurRadius: 12 * scale,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 40 * scale,
                              bottom: 25 * scale,
                            ),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16 * scale,
                                vertical: 8 * scale,
                              ),
                              child: Text(
                                'Pote: ${_formatAmount(game.pot)}',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Cartas comunitárias
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        switchInCurve: Curves.easeOut,
                        child: Row(
                          key: ValueKey(community.length),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4 * scale,
                                    ),
                                    child: AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 500,
                                      ),
                                      opacity: 1.0,
                                      child: _buildCard(
                                        entry.value,
                                        game,
                                        scale,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      if (game.isShowdown && game.winningHand != null)
                        Container(
                          margin: EdgeInsets.only(top: 16 * scale),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24 * scale,
                            vertical: 12 * scale,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(20 * scale),
                            border: Border.all(color: Colors.amber, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.3),
                                blurRadius: 10 * scale,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${game.winnerName ?? "Vencedor"} venceu!',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 18 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4 * scale),
                              if (game.winningHand != 'win by fold')
                                Text(
                                  game.winningHand!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Pot movido para dentro da mesa

                // Jogadores posicionados
                ..._buildPlayers(
                  game,
                  players,
                  localPlayerId,
                  scale,
                  constraints,
                ),

                // Última ação
                if (game.lastActionText != null && !game.isShowdown)
                  Align(
                    alignment: const Alignment(0, -0.35),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(16 * scale),
                        border: Border.all(color: Colors.amber, width: 1.5),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20 * scale,
                          vertical: 10 * scale,
                        ),
                        child: Text(
                          game.lastActionText!,
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Botões de ação (somente para o jogador local)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 10 * scale),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _actionButton(
                            'FOLD',
                            Colors.redAccent,
                            ws,
                            context,
                            scale,
                            enabled: isLocalTurn,
                          ),
                          SizedBox(width: 12 * scale),
                          _actionButton(
                            'CHECK',
                            Colors.blueAccent,
                            ws,
                            context,
                            scale,
                            enabled: isLocalTurn,
                          ),
                          SizedBox(width: 12 * scale),
                          _actionButton(
                            'CALL',
                            Colors.greenAccent,
                            ws,
                            context,
                            scale,
                            enabled: isLocalTurn,
                          ),
                          SizedBox(width: 12 * scale),
                          _actionButton(
                            'BET',
                            Colors.amber,
                            ws,
                            context,
                            scale,
                            enabled: isLocalTurn,
                            onBet: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 🔹 Gera os widgets dos jogadores
  List<Widget> _buildPlayers(
    GameState game,
    List<Player> players,
    String localId,
    double scale,
    BoxConstraints constraints,
  ) {
    if (players.isEmpty) return [];

    final rotatedPlayers = _getRotatedPlayers(players, localId);
    final total = rotatedPlayers.length;
    final positions = _getPlayerAlignments(total, constraints);

    return List.generate(total, (i) {
      final p = rotatedPlayers[i];
      final align = positions[i];
      final isLocal = i == 0; // o local está sempre na parte inferior
      final isCurrent = p.id == game.currentPlayerId;

      double? top, bottom, left, right;
      final offset = (total <= 3 ? 90 : 75) * scale;

      if (isLocal) {
        bottom = offset;
      } else {
        if (align.y < -0.5) {
          top = offset;
        } else if (align.y > 0.5) {
          bottom = offset;
        } else {
          top = offset;
        }
      }

      return Align(
        alignment: isLocal ? const Alignment(0, 0.8) : align,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(10 * scale),
                  decoration: BoxDecoration(
                    color: isCurrent ? Colors.green : Colors.white10,
                    borderRadius: BorderRadius.circular(50 * scale),
                    border: Border.all(
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
                          fontSize: 14 * scale,
                        ),
                      ),
                      SizedBox(height: 2 * scale),
                      Text(
                        '${_formatAmount(p.chips)} fichas',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11 * scale,
                        ),
                      ),
                      Text(
                        p.isBigBlind
                            ? 'BB'
                            : p.isSmallBlind
                            ? 'SB'
                            : '',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11 * scale,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8 * scale),
                if (isCurrent && game.turnStartTime != null && !game.isShowdown)
                  TurnTimerBar(
                    key: ValueKey('${p.id}_${game.turnStartTime}'),
                    isLocal: isLocal,
                  ),
              ],
            ),

            // Cartas (Positioned relative to Info)
            if (isLocal || (game.isShowdown && p.hand.isNotEmpty))
              Positioned(
                top: top,
                bottom: bottom,
                left: left,
                right: right,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: p.hand
                        .map((c) => _buildCard(c, game, scale))
                        .toList(),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  // 🔹 Define as posições dos jogadores em volta da mesa
  List<Alignment> _getPlayerAlignments(int count, BoxConstraints constraints) {
    double radiusX = 0.9;
    double radiusY = 0.8;

    if (constraints.maxWidth > constraints.maxHeight) {
      radiusX = 0.8;
      radiusY = 0.85;
    }

    if (count >= 5) {
      radiusX -= 0.1;
      radiusY += 0.05;
    }

    List<Alignment> positions = [];

    for (int i = 0; i < count; i++) {
      final angle = (2 * 3.14159 / count) * i + 3.14159 / 2; // começa em baixo
      final x = radiusX * (i == 0 ? 0 : Math.cos(angle));
      final y = radiusY * Math.sin(angle);
      positions.add(Alignment(x, y));
    }

    return positions;
  }

  // 🔹 Renderiza uma carta simples
  Widget _buildCard(CardModel c, GameState game, double scale) {
    final isWinning = game.winningCards.contains(c);

    Widget cardWidget = Container(
      margin: EdgeInsets.all(4 * scale),
      width: 40 * scale,
      height: 60 * scale,
      decoration: BoxDecoration(
        color: isWinning ? Colors.yellowAccent : Colors.white,
        borderRadius: BorderRadius.circular(6 * scale),
        boxShadow: [BoxShadow(color: Colors.black, blurRadius: 4 * scale)],
        border: isWinning ? Border.all(color: Colors.red, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${c.rank}${c.suit}',
          style: TextStyle(
            color: (c.suit == '♥' || c.suit == '♦') ? Colors.red : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14 * scale,
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
    BuildContext context,
    double scale, {
    bool onBet = false,
    bool enabled = true,
  }) {
    return ElevatedButton(
      onPressed: enabled
          ? () {
              if (onBet) {
                _showBetDialog(context, ws);
              } else {
                ws.playerAction(text.toLowerCase());
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.grey[900],
        disabledBackgroundColor: Colors.white12,
        disabledForegroundColor: Colors.white54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: 30 * scale,
          vertical: 12 * scale,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.bold),
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

  String _formatAmount(num value) {
    final digits = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }
    return buffer.toString();
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
