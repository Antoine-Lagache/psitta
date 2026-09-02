import 'sentence_instance.dart';

/// Groups sentence variants that belong to the same sentence exercise.
class SentenceGroup {
  final int id;
  final List<SentenceInstance> sentences;

  SentenceGroup({required this.id, required this.sentences});
}
