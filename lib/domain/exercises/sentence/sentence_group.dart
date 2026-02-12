import 'package:flutter_application_1/domain/content/sentence.dart';
import 'package:flutter_application_1/domain/srs/sentence_state.dart';

import 'sentence_instance.dart';

class SentenceGroup {
  final int groupId;
  final List<SentenceInstance> sentences;

  SentenceGroup({required this.groupId, required this.sentences});
}
