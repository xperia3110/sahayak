/// Question data model for Echo Explorers
class Question {
  final String id;
  final String prompt; // The word to find a rhyme for
  final List<String> options; // Answer options
  final String correctAnswer;
  
  const Question({
    required this.id,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
  });
}

/// Bank of rhyming questions for phonological awareness testing
class QuestionBank {
  static const List<Question> rhymingQuestions = [
    // Easy rhymes
    Question(
      id: 'rhyme_cat',
      prompt: 'CAT',
      options: ['BAT', 'DOG', 'SUN', 'FISH'],
      correctAnswer: 'BAT',
    ),
    Question(
      id: 'rhyme_ball',
      prompt: 'BALL',
      options: ['TALL', 'ROCK', 'FISH', 'TREE'],
      correctAnswer: 'TALL',
    ),
    Question(
      id: 'rhyme_cake',
      prompt: 'CAKE',
      options: ['TREE', 'LAKE', 'BIRD', 'CAR'],
      correctAnswer: 'LAKE',
    ),
    Question(
      id: 'rhyme_star',
      prompt: 'STAR',
      options: ['CAR', 'MOON', 'WIND', 'TREE'],
      correctAnswer: 'CAR',
    ),
    Question(
      id: 'rhyme_moon',
      prompt: 'MOON',
      options: ['SPOON', 'TREE', 'ROCK', 'FISH'],
      correctAnswer: 'SPOON',
    ),
    
    // Medium difficulty
    Question(
      id: 'rhyme_tree',
      prompt: 'TREE',
      options: ['BEE', 'BIRD', 'LEAF', 'DOG'],
      correctAnswer: 'BEE',
    ),
    Question(
      id: 'rhyme_fox',
      prompt: 'FOX',
      options: ['BOX', 'WOLF', 'TAIL', 'CAT'],
      correctAnswer: 'BOX',
    ),
    Question(
      id: 'rhyme_light',
      prompt: 'LIGHT',
      options: ['NIGHT', 'LAMP', 'DARK', 'SUN'],
      correctAnswer: 'NIGHT',
    ),
    Question(
      id: 'rhyme_rain',
      prompt: 'RAIN',
      options: ['TRAIN', 'CLOUD', 'WET', 'EAT'],
      correctAnswer: 'TRAIN',
    ),
    Question(
      id: 'rhyme_house',
      prompt: 'HOUSE',
      options: ['MOUSE', 'DOOR', 'ROOM', 'CAR'],
      correctAnswer: 'MOUSE',
    ),
  ];

  /// Get a random subset of questions for a game session
  static List<Question> getRandomQuestions(int count) {
    final shuffled = List<Question>.from(rhymingQuestions)..shuffle();
    return shuffled.take(count).toList();
  }

  /// Build the audio prompt text
  static String getPromptText(Question question) {
    return "Find the word that rhymes with... ${question.prompt}!";
  }
}
