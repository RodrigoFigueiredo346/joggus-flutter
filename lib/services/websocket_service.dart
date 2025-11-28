import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/game_player.dart';
import '../models/player.dart';
import '../models/card_model.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService with ChangeNotifier {
  WebSocketChannel? _channel;
  bool isConnected = false;
  String? localPlayerId;
  String? localPlayerName;

  final GameState _gameState = GameState();
  GameState get gameState => _gameState;

  /// Conecta ao servidor WebSocket
  void connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));
      isConnected = true;
      debugPrint('[WS] Connected to ws://localhost:8080/ws');

      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (err) {
          debugPrint('[WS] Error: $err');
          isConnected = false;
          notifyListeners();
        },
        onDone: () {
          debugPrint('[WS] Connection closed');
          isConnected = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('[WS] Connection failed: $e');
    }
  }

  /// Envia mensagem para o servidor
  void send(String method, Map<String, dynamic> params) {
    if (!isConnected || _channel == null) return;
    if (method == 'create_room' || method == 'join_room') {
      localPlayerName = params['player_name'];
    }

    final msg = jsonEncode({"method": method, "params": params});
    _channel!.sink.add(msg);
    debugPrint('[WS] => $msg');
  }

  /// Fecha a conexão
  void disconnect() {
    _channel?.sink.close();
    isConnected = false;
    notifyListeners();
  }

  /// Processa mensagens recebidas
  void _handleMessage(String message) {
    debugPrint('[WS] <= $message');
    _processMessage(message);
  }

  void _processMessage(String message) {
    try {
      final decoded = jsonDecode(message);
      final method = decoded['method'];
      final params = decoded['params'];

      switch (method) {
        case 'room_created':
          _gameState.roomId = params['room_id'];
          localPlayerId = params['player_id'];
          // localPlayerName = params['player']; // caso o backend envie o nome
          final pname = params['player'] ?? 'Você';
          // adiciona o criador como primeiro jogador, se ainda não existir
          final exists = _gameState.players.any((p) => p.id == localPlayerId);
          if (!exists) {
            _gameState.players.add(
              Player(
                id: localPlayerId!,
                name: pname,
                chips: params['chips'] ?? 1000,
              ),
            );
          }

          notifyListeners();
          break;

        case 'joined_room':
          _gameState.roomId = params['room_id'];
          localPlayerId = params['player_id'];

          // Atualiza lista completa de jogadores vinda do servidor
          if (params['players'] != null) {
            _gameState.players = (params['players'] as List)
                .map(
                  (p) => Player(
                    id: p['player_id'],
                    name: p['player_name'],
                    chips: p['chips'] ?? 0,
                    isSmallBlind: p['blind'] == 'sb',
                    isBigBlind: p['blind'] == 'bb',
                  ),
                )
                .toList();
          }

          notifyListeners();
          break;

        case 'game_started':
          _parseGameStarted(params);
          break;

        case 'turn_start':
          _gameState.currentPlayerName = params['player'];
          _gameState.currentPlayerId = params['player_id'];
          _gameState.pot = params['pot'];
          _gameState.turnStartTime = DateTime.now(); // Inicia o timer
          _gameState.lastActionText = null; // limpa a ação anterior
          notifyListeners();
          break;

        case 'player_action':
          _gameState.pot = params['pot'] ?? _gameState.pot;

          final playerId = params['player_id'];
          final action = params['action'];
          final amount = (params['amount'] ?? 0) as int;

          final player = _gameState.players.firstWhere(
            (p) => p.id == playerId,
            orElse: () => Player(id: '', name: 'unknown'),
          );

          if (player.id.isNotEmpty) {
            player.chips -= amount;
          }

          // cria uma descrição legível da ação
          String actionText = '${player.name} $action';
          if (amount > 0 && action == 'bet') actionText += ' $amount';
          _gameState.lastActionText = actionText;

          // Se vier next_player, já passa a vez
          if (params['next_player'] != null) {
            final nextPid = params['next_player'];
            _gameState.currentPlayerId = nextPid;
            _gameState.turnStartTime = DateTime.now();

            // Tenta atualizar o nome também
            final nextP = _gameState.players.firstWhere(
              (p) => p.id == nextPid,
              orElse: () => Player(id: '', name: ''),
            );
            if (nextP.id.isNotEmpty) {
              _gameState.currentPlayerName = nextP.name;
            }
          } else {
            _gameState.turnStartTime =
                null; // Para o timer até o próximo turn_start
          }

          // força rebuild
          _gameState.players = List.from(_gameState.players);
          notifyListeners();
          break;

        case 'player_joined':
          final pid = params['player_id'];
          final pname = params['player_name'];
          final chips = params['chips'];
          final exists = _gameState.players.any((p) => p.id == pid);
          if (!exists) {
            _gameState.players.add(Player(id: pid, name: pname, chips: chips));
          }
          notifyListeners();
          break;
        case 'deal_flop':
        case 'deal_turn':
        case 'deal_river':
          _updateCommunityCards(params);
          break;

        case 'showdown':
          // Exibe vencedores
          debugPrint('[SHOWDOWN] Winners: ${params['winners']}');
          if (params['cards'] != null) {
            final winningCards = (params['cards'] as List)
                .map((c) => CardModel(rank: c['rank'], suit: c['suit']))
                .toList();
            _gameState.winningCards = winningCards;
            _gameState.winningHand = params['hand'];
            _gameState.isShowdown = true;
            notifyListeners();
          }
          break;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[WS] Error parsing message: $e');
    }
  }

  /// Parse do evento game_started
  void _parseGameStarted(dynamic params) {
    _gameState.isGameStarted = true;
    _gameState.roomId = params['room_id'];
    _gameState.pot = params['pot'] ?? 0;
    _gameState.minBet = params['min_bet'] ?? 0;
    _gameState.currentPlayerName = params['current_player'];
    _gameState.turnStartTime = DateTime.now();

    // Encontra o ID do jogador atual pelo nome
    if (_gameState.currentPlayerName != null) {
      final playersList = (params['players'] as List);
      final currentPlayerObj = playersList.firstWhere(
        (p) => p['name'] == _gameState.currentPlayerName,
        orElse: () => null,
      );
      if (currentPlayerObj != null) {
        _gameState.currentPlayerId = currentPlayerObj['player_id'];
      }
    }

    // Reset de estado para nova rodada
    _gameState.communityCards = [];
    _gameState.winningCards = [];
    _gameState.isShowdown = false;
    _gameState.winningHand = null;
    _gameState.lastActionText = null;

    _gameState.players = (params['players'] as List)
        .map(
          (p) => Player(
            id: p['player_id'] ?? '',
            name: p['name'],
            chips: p['chips'],
            isSmallBlind: p['blind'] == 'sb',
            isBigBlind: p['blind'] == 'bb',
          ),
        )
        .toList();

    if (params['your_hand'] != null) {
      final localPlayer = _gameState.players.firstWhere(
        (p) => p.id == localPlayerId,
        orElse: () => Player(id: '', name: ''),
      );
      if (localPlayer.id.isNotEmpty) {
        localPlayer.hand = (params['your_hand'] as List)
            .map((c) => CardModel.fromJson(c))
            .toList();
      }
    }
  }

  /// Atualiza cartas comunitárias (flop, turn, river)
  void _updateCommunityCards(dynamic params) {
    final newCards = (params as List)
        .map((c) => CardModel(rank: c['rank'], suit: c['suit']))
        .toList();
    _gameState.communityCards = [..._gameState.communityCards, ...newCards];
    notifyListeners();
  }

  void playerAction(String action, {int amount = 0}) {
    final rid = _gameState.roomId;
    final pid = localPlayerId;
    if (rid == null || pid == null) {
      debugPrint('[WS] playerAction ignored: missing roomId/localPlayerId');
      return;
    }

    send('player_action', {
      'room_id': rid,
      'player_id': pid,
      'action': action,
      'amount': amount,
    });
  }

  void startGame() {
    final rid = _gameState.roomId;
    if (rid == null) {
      debugPrint('[WS] startGame ignored: missing roomId');
      return;
    }

    send('start_game', {'room_id': rid});
  }
}
