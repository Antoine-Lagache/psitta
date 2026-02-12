import 'package:flutter_application_1/domain/content/sentence.dart';
import 'package:flutter_application_1/domain/srs/sentence_state.dart';

class SentenceInstance {
  final int id;
  final Sentence sentence;
  final SentenceState state;

  SentenceInstance({required this.id, required this.sentence, required this.state});
}
