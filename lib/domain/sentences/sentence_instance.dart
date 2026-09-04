import 'package:psitta/domain/srs/sentence_state.dart';

/// Links one sentence content item to its independent learning state.
class SentenceInstance {
  final int id;
  final int contentId;
  final SentenceState state;

  SentenceInstance({required this.id, required this.contentId, required this.state});
}
