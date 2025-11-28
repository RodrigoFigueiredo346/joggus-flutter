import 'player.dart';
import 'card_model.dart';

class GameState {
  String? roomId;
  List<Player> players;
  List<CardModel> communityCards;
  int pot;
  String? currentPlayerName;
  int minBet;
  bool isGameStarted;
  String? lastActionText;
  String? currentPlayerId;
  DateTime? turnStartTime;
  List<CardModel> winningCards;
  bool isShowdown;
  String? winningHand;

  GameState({
    this.roomId,
    List<Player>? players,
    List<CardModel>? communityCards,
    this.pot = 0,
    this.currentPlayerName,
    this.minBet = 0,
    this.isGameStarted = false,
    this.lastActionText,
    this.currentPlayerId,
    List<CardModel>? winningCards,
    this.isShowdown = false,
    this.winningHand,
  }) : players = players ?? [],
       communityCards = communityCards ?? [],
       winningCards = winningCards ?? [];
}
