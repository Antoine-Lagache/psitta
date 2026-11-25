import 'package:psitta/domain/identity/entity_id.dart';
import 'package:test/test.dart';

void main() {
  test('local IDs use value equality but distinguish entity types', () {
    expect(ExerciseProgressId(1), ExerciseProgressId(1));
    expect(ExerciseProgressId(1).hashCode, ExerciseProgressId(1).hashCode);
    expect(ExerciseProgressId(1), isNot(LearningBankId(1)));
    expect(() => ExerciseProgressId(0), throwsArgumentError);
    expect(() => SessionResultId(-1), throwsArgumentError);
  });

  test('portable IDs identify exact changes and distinguish entity types', () {
    final uid = CommitUid('a');
    final exercise = ExerciseId((uid, 0));
    expect(exercise, ExerciseId((CommitUid('a'), 0)));
    expect(exercise.hashCode, ExerciseId((uid, 0)).hashCode);
    expect(exercise, isNot(ContentId((uid, 0))));
    expect(exercise, isNot(ExerciseId((CommitUid('b'), 0))));
    expect(exercise, isNot(ExerciseId((uid, 1))));
    expect(exercise.commitUid, uid);
    expect(exercise.changeId, 0);
    expect(() => SentenceId((uid, -1)), throwsArgumentError);
  });

  test('sentence progress identity includes the local exercise and snapshot', () {
    final sentence = SentenceId((CommitUid('a'), 2));
    final id = SentenceInstanceProgressId((ExerciseProgressId(1), sentence));
    expect(id, SentenceInstanceProgressId((ExerciseProgressId(1), sentence)));
    expect(id, isNot(SentenceInstanceProgressId((ExerciseProgressId(2), sentence))));
    expect(id.exerciseProgressId, ExerciseProgressId(1));
    expect(id.sentenceId, sentence);
  });
}
