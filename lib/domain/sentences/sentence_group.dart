import 'package:psitta/domain/srs/grade.dart';

import 'sentence_instance.dart';

/// Groups sentence variants that belong to the same sentence exercise.
class SentenceGroup {
  final int id;
  final List<SentenceInstance> sentences;

  SentenceGroup({required this.id, required this.sentences});

  /// Deterministically selects the least-known sentence in the group.
  SentenceInstance getSentence() {
    double minScore = sentences[0].state.getscore();
    SentenceInstance sentence = sentences[0];

    for (final sentenceInstance in sentences) {
      if (sentenceInstance.state.getscore() < minScore) {
        minScore = sentenceInstance.state.getscore();
        sentence = sentenceInstance;
      }
    }
    return sentence;
  }

  void updateStates(Grade grade) {
    final selected = getSentence();

    for (final instance in sentences) {
      if (identical(instance, selected)) {
        instance.state.updateChosenState(grade);
      } else {
        instance.state.updateOtherState();
      }
    }
  }
}
