import 'card_model.dart';

class Player {
  final String id;
  final String name;
  int chips;
  bool isSmallBlind;
  bool isBigBlind;
  bool isActive;
  bool isConnected;
  List<CardModel> hand;

  Player({
    required this.id,
    required this.name,
    this.chips = 0,
    this.isSmallBlind = false,
    this.isBigBlind = false,
    this.isActive = true,
    this.isConnected = true,
    this.hand = const [],
  });
}
