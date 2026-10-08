import 'dart:io';

import 'package:psitta/application/controllers/content_controller.dart';
import 'package:psitta/application/models/content/content.dart';
import 'package:psitta/application/models/content/field.dart';
import 'package:psitta/application/models/content/field_definition.dart';
import 'package:psitta/application/models/content/field_value.dart';
import 'package:psitta/domain/exercise/sentence_exercise.dart';
import 'package:psitta/domain/exercise/word_exercise.dart';
import 'package:psitta/infrastructure/persistence/development/development_data_seeder.dart';
import 'package:psitta/infrastructure/persistence/repositories/content_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/exercise_repository.dart';
import 'package:psitta/infrastructure/persistence/repositories/media_repository.dart';
import 'package:psitta/ui/presentation/content/field_renderer.dart';
import 'package:psitta/ui/presentation/content/media_resolver.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;
  late DevelopmentDataSeeder seeder;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
    seeder = DevelopmentDataSeeder(
      database,
      mediaDirectoryProvider: () async => testDatabase.directory,
    );
  });

  tearDown(() => testDatabase.dispose());

  test('seeds every development exercise once', () async {
    expect(await seeder.seedIfEmpty(), isTrue);
    expect(await seeder.seedIfEmpty(), isFalse);

    expect(await testDatabase.countRows('exercise'), 4);
    expect(await testDatabase.countRows('word_exercise'), 3);
    expect(await testDatabase.countRows('sentence_exercise'), 1);
    expect(await testDatabase.countRows('content'), 5);
    expect(await testDatabase.countRows('media'), 2);
  });

  test('does not modify a database that already contains an exercise', () async {
    final contentId = await testDatabase.insertContent();
    await ExerciseRepository(database).createWordExercise(contentId);

    expect(await seeder.seedIfEmpty(), isFalse);
    expect(await testDatabase.countRows('exercise'), 1);
    expect(await testDatabase.countRows('field_definition'), 0);
    expect(await testDatabase.countRows('media'), 0);
  });

  test('rolls back every database row when seeding fails', () async {
    await database.writeTransaction((transaction) async {
      await transaction.execute('''
        CREATE TRIGGER reject_demo_sentence
        BEFORE INSERT ON sentence_exercise
        BEGIN
          SELECT RAISE(ABORT, 'simulated failure');
        END;
      ''');
    });

    await expectLater(seeder.seedIfEmpty(), throwsA(anything));

    expect(await testDatabase.countRows('exercise'), 0);
    expect(await testDatabase.countRows('content'), 0);
    expect(await testDatabase.countRows('field_definition'), 0);
    expect(await testDatabase.countRows('media'), 0);
    expect(await testDatabase.countRows('sentence_group'), 0);
  });

  test('creates renderable text, HTML, image, and audio values', () async {
    await seeder.seedIfEmpty();

    final exerciseRepository = ExerciseRepository(database);
    final wordExercises = await exerciseRepository.getNewExercises(10, 'word');
    final sentenceExercises = await exerciseRepository.getNewExercises(10, 'sentence');
    final contents = await _loadWordContents(
      database,
      wordExercises.cast<WordExercise>(),
    );

    expect(wordExercises, hasLength(3));
    expect(sentenceExercises.single, isA<SentenceExercise>());
    expect(
      _textValues(contents).any((value) => value.contains('characters: < > &')),
      isTrue,
    );
    expect(_fieldsOfType(contents, FieldValueType.html), isNotEmpty);
    expect(_fieldsOfType(contents, FieldValueType.image), hasLength(1));
    expect(_fieldsOfType(contents, FieldValueType.audio), hasLength(1));

    await _expectMediaFilesExist(contents);
    await _expectFieldsRender(database, contents);
  });
}

Future<List<Content>> _loadWordContents(
  sqlite.SqliteDatabase database,
  Iterable<WordExercise> exercises,
) async {
  final repository = ContentRepository(database);
  final contents = <Content>[];
  for (final exercise in exercises) {
    contents.add((await repository.getById(exercise.contentId))!);
  }
  return contents;
}

Iterable<Field> _fieldsOfType(Iterable<Content> contents, FieldValueType valueType) {
  return contents
      .expand((content) => content.fields)
      .where((field) => field.definition.valueType == valueType);
}

Iterable<String> _textValues(Iterable<Content> contents) {
  return contents
      .expand((content) => content.fields)
      .where((field) => field.value is TextFieldValue)
      .map((field) => (field.value as TextFieldValue).value);
}

Future<void> _expectMediaFilesExist(Iterable<Content> contents) async {
  final mediaFields = contents
      .expand((content) => content.fields)
      .where((field) => field.value is MediaFieldValue);

  for (final field in mediaFields) {
    final media = (field.value as MediaFieldValue).media;
    final file = File(media.path);
    expect(await file.exists(), isTrue);
    expect(await file.length(), media.size);
  }
}

Future<void> _expectFieldsRender(
  sqlite.SqliteDatabase database,
  Iterable<Content> contents,
) async {
  final contentController = ContentController(
    contentRepository: ContentRepository(database),
    mediaRepository: MediaRepository(database),
  );
  final renderer = FieldRenderer(MediaResolver(contentController));
  final fields = contents.expand((content) => content.fields);

  final plainText = fields.firstWhere(
    (field) =>
        field.definition.valueType == FieldValueType.text &&
        (field.value as TextFieldValue).value.contains('characters:'),
  );
  final html = _fieldsOfType(contents, FieldValueType.html).last;
  final audio = _fieldsOfType(contents, FieldValueType.audio).single;

  expect(await renderer.render(plainText), contains('&lt; &gt; &amp;'));
  expect(await renderer.render(html), contains('file://'));
  expect(await renderer.render(audio), startsWith('<audio controls src="file://'));
}
