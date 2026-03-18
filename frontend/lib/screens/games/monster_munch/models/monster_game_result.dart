
enum MonsterGameMode { subitizing, comparison }

class MonsterGameResult {
  final String id;
  final MonsterGameMode gameMode;
  final int timestamp;
  final int reactionTimeMs;
  final bool isCorrect;
  
  // Subitizing specific
  final int? itemsShown;
  
  // Comparison specific
  final int? leftValue;
  final int? rightValue;
  final int? distance;
  final String? ratioType;

  final int userAnswer;

  MonsterGameResult({
    required this.id,
    required this.gameMode,
    required this.timestamp,
    required this.reactionTimeMs,
    required this.isCorrect,
    this.itemsShown,
    this.leftValue,
    this.rightValue,
    this.distance,
    this.ratioType,
    required this.userAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_mode': gameMode.toString().split('.').last,
      'timestamp': timestamp,
      'reaction_time_ms': reactionTimeMs,
      'is_correct': isCorrect,
      if (itemsShown != null) 'items_shown': itemsShown,
      if (leftValue != null) 'left_value': leftValue,
      if (rightValue != null) 'right_value': rightValue,
      if (distance != null) 'distance': distance,
      if (ratioType != null) 'ratio_type': ratioType,
      'user_answer': userAnswer,
    };
  }
}
