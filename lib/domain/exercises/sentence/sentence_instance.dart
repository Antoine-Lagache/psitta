import 'package:psitta/domain/content/sentence.dart';
import 'package:psitta/domain/srs/sentence_state.dart';

class SentenceInstance {
  final int id;
  final Sentence sentence;
  final SentenceState state;

  SentenceInstance({required this.id, required this.sentence, required this.state});
}
