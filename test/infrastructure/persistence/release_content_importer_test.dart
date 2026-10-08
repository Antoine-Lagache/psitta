import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/infrastructure/persistence/dao/content_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/sentence_group_dao.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';
import 'package:psitta/infrastructure/persistence/release/release_content_importer.dart';

import 'support/persistence_test_database.dart';

void main() {
  test('fresh install imports both sides and every sentence; reopening is idempotent', () async {
    final db = await PersistenceTestDatabase.create();
    try {
      Future<bool> importRelease() => ReleaseContentImporter(
        db.database,
        loadAsset: (path) => File(path).readAsBytes(),
      ).importIfEmpty();

      expect(await importRelease(), isTrue);
      expect(await db.countRows('exercise'), 2725);
      expect(await db.countRows('word_exercise'), 1297);
      expect(await db.countRows('sentence_exercise'), 1428);
      expect(await db.countRows('sentence_group'), 1428);
      expect(await db.countRows('sentence_instance'), 2629);
      expect(await db.countRows('sentence_state'), 2629);
      expect(await db.countRows('content'), 3926);
      expect(await db.countRows('field_value'), 7852);

      final firstWord = await ExerciseDao(db.database).getById(1);
      expect(firstWord, isA<WordExercisePersistence>());
      final wordContent = await ContentDao(db.database)
          .getById((firstWord! as WordExercisePersistence).contentId);
      expect(wordContent!.fieldValues.map((field) => field.textValue), [
        contains('私'),
        contains('I; me'),
      ]);

      final firstSentence = await ExerciseDao(db.database).getById(1298);
      expect(firstSentence, isA<SentenceExercisePersistence>());
      final sentence = firstSentence! as SentenceExercisePersistence;
      final group = await SentenceGroupDao(db.database)
          .getById(sentence.sentenceGroupId);
      expect(group!.sentenceInstances.length, sentence.trainingCountMax);
      final firstInstanceContent = await ContentDao(db.database)
          .getById(group.sentenceInstances.first.contentId);
      expect(
        firstInstanceContent!.fieldValues.map((field) => field.textValue),
        [contains('私は先生です。'), contains('I am a teacher.')],
      );

      await db.reopen();
      expect(await importRelease(), isFalse);
      expect(await db.countRows('exercise'), 2725);
      expect(await db.countRows('field_value'), 7852);
    } finally {
      await db.dispose();
    }
  });

  test('invalid bundled data does not create any exercise', () async {
    final db = await PersistenceTestDatabase.create();
    try {
      final importer = ReleaseContentImporter(
        db.database,
        loadAsset: (path) async {
          final bytes = await File(path).readAsBytes();
          if (path.endsWith('sentence_exercises.jsonl.gz')) bytes[0] ^= 1;
          return bytes;
        },
      );
      await expectLater(importer.importIfEmpty(), throwsFormatException);
      expect(await db.countRows('exercise'), 0);
      expect(await db.countRows('field_definition'), 0);
    } finally {
      await db.dispose();
    }
  });
}
