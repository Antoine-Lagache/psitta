import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/infrastructure/persistence/dao/content_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/sentence_group_dao.dart';
import 'package:psitta/infrastructure/persistence/models/exercise/exercise_persistence.dart';
import 'package:psitta/infrastructure/persistence/release/release_content_importer.dart';

import 'support/persistence_test_database.dart';

void main() {
  test(
    'fresh install imports both sides and every sentence; reopening is idempotent',
    () async {
      final db = await PersistenceTestDatabase.create();
      try {
        Future<bool> importRelease() => ReleaseContentImporter(
          db.database,
          loadAsset: (path) => File(path).readAsBytes(),
        ).importIfEmpty();

        expect(await importRelease(), isTrue);
        expect(await db.countRows('exercise'), 2677);
        expect(await db.countRows('word_exercise'), 1297);
        expect(await db.countRows('sentence_exercise'), 1380);
        expect(await db.countRows('sentence_group'), 1380);
        expect(await db.countRows('sentence_instance'), 3452);
        expect(await db.countRows('sentence_state'), 3452);
        expect(await db.countRows('content'), 4749);
        expect(await db.countRows('field_value'), 9498);

        final firstWord = await ExerciseDao(db.database).getById(1);
        expect(firstWord, isA<WordExercisePersistence>());
        final wordContent = await ContentDao(
          db.database,
        ).getById((firstWord! as WordExercisePersistence).contentId);
        expect(wordContent!.fieldValues.map((field) => field.textValue), [
          contains('バス'),
          contains('bus'),
        ]);

        final adaptedWords = await db.database.getAll(
          "SELECT fv.text_value FROM word_exercise we "
          "JOIN field_value fv ON fv.content_id = we.content_id "
          "JOIN field_definition fd ON fd.id = fv.field_definition_id "
          "WHERE fd.side = 'back' AND fv.text_value LIKE '%editorial adaptation%'",
        );
        expect(adaptedWords, hasLength(10));
        expect(
          adaptedWords.every(
            (row) => (row['text_value'] as String).contains(
              'Definitions: JMdict; sense selection and usage notes: ChatGPT',
            ),
          ),
          isTrue,
        );

        final firstSentence = await ExerciseDao(db.database).getById(1298);
        expect(firstSentence, isA<SentenceExercisePersistence>());
        final sentence = firstSentence! as SentenceExercisePersistence;
        final group = await SentenceGroupDao(
          db.database,
        ).getById(sentence.sentenceGroupId);
        expect(
          sentence.trainingCountMax,
          (group!.sentenceInstances.length - 1) ~/ 2,
        );
        final firstInstanceContent = await ContentDao(
          db.database,
        ).getById(group.sentenceInstances.first.contentId);
        expect(firstInstanceContent!.fieldValues.map((field) => field.textValue), [
          contains('こんばんは。'),
          contains('Good evening.'),
        ]);

        final sentenceBacks = await db.database.getAll(
          "SELECT fv.text_value FROM sentence_instance si "
          "JOIN field_value fv ON fv.content_id = si.content_id "
          "JOIN field_definition fd ON fd.id = fv.field_definition_id "
          "WHERE fd.side = 'back' ORDER BY si.id",
        );
        expect(sentenceBacks, hasLength(3452));
        final cards = sentenceBacks.map((row) => row['text_value'] as String).toList();
        expect(cards.every((card) => card.contains('Source: Tatoeba')), isTrue);
        expect(
          cards.every(
            (card) =>
                'https://tatoeba.org/en/sentences/show/'.allMatches(card).length == 2,
          ),
          isTrue,
        );
        final annotated = cards
            .where((card) => card.contains('Translation mismatch'))
            .toList();
        expect(annotated, hasLength(15));
        expect(
          annotated.every(
            (card) =>
                card.contains('Tatoeba translation') &&
                card.contains(
                  'Suggested translation (AI-generated; not independently verified)',
                ),
          ),
          isTrue,
        );
        final letterCard = annotated.singleWhere(
          (card) => card.contains('I have been reading a book all morning.'),
        );
        expect(letterCard, contains('I was writing letters all morning.'));

        await db.reopen();
        expect(await importRelease(), isFalse);
        expect(await db.countRows('exercise'), 2677);
        expect(await db.countRows('field_value'), 9498);
      } finally {
        await db.dispose();
      }
    },
  );

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
