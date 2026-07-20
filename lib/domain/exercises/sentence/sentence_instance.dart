import 'package:psitta/domain/content/content.dart';
import 'package:psitta/domain/srs/sentence_state.dart';

class SentenceInstance {
  final int id;
  final Content content;
  final SentenceState state;

  SentenceInstance({required this.id, required this.content, required this.state});
}
