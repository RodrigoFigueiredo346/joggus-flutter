class CardModel {
  final String rank;
  final String suit;

  CardModel({required this.rank, required this.suit});

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(rank: json['rank'], suit: json['suit']);
  }

  Map<String, dynamic> toJson() => {'rank': rank, 'suit': suit};

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardModel && other.rank == rank && other.suit == suit;
  }

  @override
  int get hashCode => rank.hashCode ^ suit.hashCode;
}
