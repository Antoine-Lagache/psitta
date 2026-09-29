import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:psitta/infrastructure/persistence/dao/content_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/field_definition_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/sentence_group_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/sentence_exercise_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/word_exercise_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/sentence_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/content/content_persistence.dart';
import 'package:psitta/infrastructure/persistence/models/content/media_persistence.dart';
import 'package:psitta/infrastructure/persistence/models/field_definition/field_definition_persistence.dart';
import 'package:psitta/infrastructure/persistence/models/sentence/sentence_group_persistence.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

typedef _DefinitionIds = ({
  int frontText,
  int backText,
  int bothText,
  int frontHtml,
  int backHtml,
  int frontImage,
  int backAudio,
});

typedef _DemoMedia = ({MediaPersistence image, MediaPersistence audio});

/// Populates an empty development database with synthetic rendering examples.
final class DevelopmentDataSeeder {
  final sqlite.SqliteDatabase _database;
  final Future<Directory> Function() _mediaDirectoryProvider;

  late final ContentDao _contentDao = ContentDao(_database);
  late final ExerciseDao _exerciseDao = ExerciseDao(_database);
  late final FieldDefinitionDao _definitionDao = FieldDefinitionDao(_database);
  late final SentenceGroupDao _sentenceGroupDao = SentenceGroupDao(_database);

  DevelopmentDataSeeder(
    this._database, {
    Future<Directory> Function()? mediaDirectoryProvider,
  }) : _mediaDirectoryProvider = mediaDirectoryProvider ?? getApplicationSupportDirectory;

  /// Seeds once when no exercise exists, and commits the database rows atomically.
  Future<bool> seedIfEmpty() async {
    if (await _hasExercises()) {
      return false;
    }

    final media = await _DevelopmentMediaFactory(_mediaDirectoryProvider).create();
    return _database.writeTransaction((transaction) async {
      if (await _hasExercisesIn(transaction)) {
        return false;
      }

      await _seed(transaction, media);
      return true;
    });
  }

  Future<bool> _hasExercises() {
    return _database.readTransaction(_hasExercisesIn);
  }

  Future<bool> _hasExercisesIn(sqlite.SqliteReadContext transaction) async {
    final rows = await transaction.getAll('SELECT 1 FROM exercise LIMIT 1');
    return rows.isNotEmpty;
  }

  Future<void> _seed(sqlite.SqliteWriteContext transaction, _DemoMedia media) async {
    final definitions = await _insertDefinitions(transaction);
    await _insertWordExercises(transaction, definitions, media);
    await _insertSentenceExercise(transaction, definitions);
  }

  Future<_DefinitionIds> _insertDefinitions(sqlite.SqliteWriteContext transaction) async {
    return (
      frontText: await _insertDefinition(transaction, 'text', 'front'),
      backText: await _insertDefinition(transaction, 'text', 'back'),
      bothText: await _insertDefinition(transaction, 'text', 'both'),
      frontHtml: await _insertDefinition(transaction, 'html', 'front'),
      backHtml: await _insertDefinition(transaction, 'html', 'back'),
      frontImage: await _insertDefinition(transaction, 'image', 'front'),
      backAudio: await _insertDefinition(transaction, 'audio', 'back'),
    );
  }

  Future<int> _insertDefinition(
    sqlite.SqliteWriteContext transaction,
    String valueType,
    String side,
  ) {
    return _definitionDao.insertInTransaction(
      transaction,
      FieldDefinitionPersistence(valueType: valueType, side: side),
    );
  }

  Future<void> _insertWordExercises(
    sqlite.SqliteWriteContext transaction,
    _DefinitionIds definitions,
    _DemoMedia media,
  ) async {
    final contents = [
      _plainTextContent(definitions),
      _htmlContent(definitions),
      _mediaContent(definitions, media),
    ];

    for (final content in contents) {
      final contentId = await _contentDao.insertInTransaction(transaction, content);
      final exercise = WordExerciseMapper.newWordExercise(contentId);
      await _exerciseDao.insertInTransaction(transaction, exercise);
    }
  }

  ContentPersistence _plainTextContent(_DefinitionIds definitions) {
    return ContentPersistence(
      fieldValues: [
        _textField(
          definitions.frontText,
          'Exercise 1 — characters: < > & " \' é ñ €\nSecond line',
          0,
        ),
        _textField(definitions.backText, 'Word A\nPlain-text answer', 0),
      ],
    );
  }

  ContentPersistence _htmlContent(_DefinitionIds definitions) {
    return ContentPersistence(
      fieldValues: [
        _textField(
          definitions.frontHtml,
          '<h2>Exercise 2</h2><p><strong>HTML</strong> with '
          '<em>formatting</em> and a list:</p><ul><li>Item A</li><li>Item B</li></ul>',
          0,
        ),
        _textField(definitions.backText, 'Word B — HTML exercise answer', 0),
      ],
    );
  }

  ContentPersistence _mediaContent(_DefinitionIds definitions, _DemoMedia media) {
    return ContentPersistence(
      fieldValues: [
        _textField(definitions.bothText, 'Exercise 3 — local media', 0),
        _mediaField(definitions.frontImage, media.image, 1),
        _textField(
          definitions.backHtml,
          '<p>HTML-resolved image:</p><img src="media://${media.image.sha256}">',
          1,
        ),
        _mediaField(definitions.backAudio, media.audio, 2),
      ],
    );
  }

  Future<void> _insertSentenceExercise(
    sqlite.SqliteWriteContext transaction,
    _DefinitionIds definitions,
  ) async {
    final firstId = await _insertSentenceContent(
      transaction,
      definitions,
      'Sentence A — punctuation: ! ? …',
      'Sentence A answer',
    );
    final secondId = await _insertSentenceContent(
      transaction,
      definitions,
      'Sentence B\nSecond line',
      'Sentence B answer',
    );
    final groupId = await _insertSentenceGroup(transaction, firstId, secondId);
    final exercise = SentenceExerciseMapper.newSentenceExercise(groupId, 2);
    await _exerciseDao.insertInTransaction(transaction, exercise);
  }

  Future<int> _insertSentenceGroup(
    sqlite.SqliteWriteContext transaction,
    int firstContentId,
    int secondContentId,
  ) {
    final group = SentenceGroupPersistence(
      sentenceInstances: [
        SentenceMapper.newInstance(firstContentId),
        SentenceMapper.newInstance(secondContentId),
      ],
    );
    return _sentenceGroupDao.insertSentenceGroupInTransaction(transaction, group);
  }

  Future<int> _insertSentenceContent(
    sqlite.SqliteWriteContext transaction,
    _DefinitionIds definitions,
    String front,
    String back,
  ) {
    return _contentDao.insertInTransaction(
      transaction,
      ContentPersistence(
        fieldValues: [
          _textField(definitions.frontText, front, 0),
          _textField(definitions.backText, back, 0),
        ],
      ),
    );
  }

  FieldValuePersistence _textField(int definitionId, String value, int order) {
    return FieldValuePersistence(
      fieldDefinitionId: definitionId,
      textValue: value,
      displayOrder: order,
    );
  }

  FieldValuePersistence _mediaField(int definitionId, MediaPersistence media, int order) {
    return FieldValuePersistence(
      fieldDefinitionId: definitionId,
      media: media,
      displayOrder: order,
    );
  }
}

/// Creates the local files referenced by the synthetic media fields.
final class _DevelopmentMediaFactory {
  final Future<Directory> Function() _directoryProvider;

  const _DevelopmentMediaFactory(this._directoryProvider);

  Future<_DemoMedia> create() async {
    final supportDirectory = await _directoryProvider();
    final directory = Directory('${supportDirectory.path}/development_media');
    await directory.create(recursive: true);

    final image = await _writeMedia(
      File('${directory.path}/image_test.png'),
      base64Decode(_demoImageBase64),
      'image/png',
    );
    final audio = await _writeMedia(
      File('${directory.path}/sound_test.wav'),
      _createWaveBytes(),
      'audio/wav',
    );
    return (image: image, audio: audio);
  }

  Future<MediaPersistence> _writeMedia(
    File file,
    List<int> bytes,
    String mimeType,
  ) async {
    await file.writeAsBytes(bytes, flush: true);
    return MediaPersistence(
      path: file.path,
      mimeType: mimeType,
      size: bytes.length,
      sha256: sha256.convert(bytes).toString(),
    );
  }

  Uint8List _createWaveBytes() {
    const sampleRate = 8000;
    const sampleCount = 2000;
    final data = ByteData(44 + sampleCount * 2);
    _writeWaveHeader(data, sampleRate, sampleCount);
    _writeWaveSamples(data, sampleRate, sampleCount);
    return data.buffer.asUint8List();
  }

  void _writeWaveHeader(ByteData data, int sampleRate, int sampleCount) {
    _writeAscii(data, 0, 'RIFF');
    data.setUint32(4, 36 + sampleCount * 2, Endian.little);
    _writeAscii(data, 8, 'WAVEfmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    _writeAscii(data, 36, 'data');
    data.setUint32(40, sampleCount * 2, Endian.little);
  }

  void _writeWaveSamples(ByteData data, int sampleRate, int sampleCount) {
    for (var index = 0; index < sampleCount; index++) {
      final angle = 2 * pi * 440 * index / sampleRate;
      final sample = (sin(angle) * 8191).round();
      data.setInt16(44 + index * 2, sample, Endian.little);
    }
  }

  void _writeAscii(ByteData data, int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      data.setUint8(offset + index, value.codeUnitAt(index));
    }
  }
}

const _demoImageBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAPAAAAB4CAIAAABD1OhwAAAFVUlEQVR42u3dTyhsXwDA8TO/'
    'GTFKrCgLW1YzRQkZIfMnanZmNQtFFpIs7BSXBRaanc2kWVlOoSzMJKVMipIUtjJSpmRFGsN9i/'
    't7l5if5/fM3Jk59/tdnTnue2PO/bz7zvjTtSiKMjs7K4hKubm5OW1g0x/AmkqasgbYoqrq51m'
    'ikqOs9S9oIYTFYlEURRvrA6Ii7DPUN8bvQf/X0URFS/nPoGFNJUT5u6BhTSVB+Vug9ckvdt9E'
    'BXnb9/b+L5vYb4GGNRUV5dyAhjUVCeVcgoY1FZxy7kHDmgpIOV+gYU0FoZxf0LAmgykbARrWZ'
    'DASI0DDmgyDYRxoWJMBGIwGDWvKK4DCgIY1lPN00gsJGtZQlhA0rKEsIWhYQ1lC0LCGsoSgYQ'
    '1lCUHDGsoSgoY1lCUEDWsoSwga1lCWEDSsWXwJQcOaBZcQNKxZZAlBw5qFlRA0rFlMCUHD2uQL'
    'KCdoWJt20WQGDWsTLpT8oGFtqsUxC2hYm2RBzAUa1tIvghlBm5y13C/cvKBNyNoML9bsoE1y'
    'ps3z77aEQWe9/wsZX1HByCr2H04SyZSNywPJ9J8kV2iSKkAToIkATQRoIkAToIkATQRoIkATAV'
    'oIIWpqarSB3W4PBAL6fDAYtNvt+sPV1dXy8vLb21vtYTgcbm1t7ejo6O/vv76+1iYrKyu7fx'
    'cKhbTJ9fV1bcZms2mDaDT6+cjj42OPx9PT0+N2u5PJZNY/hcXcpP4u62SR9NefVXV1tT5wOB'
    'yZTEZV1dfX17a2Nv1Dqqr6/f6pqalIJKKqajwe9/l86XRaVdWlpSWPx/Phr/r6ibIe6XQ6k8'
    'mkqqrRaDQQCHxxZNFWhDCyijXRlqO5ufno6EgIcXJy4nA49PnHx8eHh4eRkZGtrS0hxPLy8v'
    'z8fFlZmRBibGzMbre/vLz88KlTqdTT05MQwu/3j4+Pcxlly5GDvF5vLBYTQsRiMa/Xq8/HYj'
    'Gfz9fY2Hh5eZlOp8/OznTuVVVVGxsbVqv1h0+9sLDgcrmGh4f39/ddLhfsAJ2DPB7Pzs6OEG'
    'J3d7evr0+f39zcXFtba2tru7m52dvby2Qy2nwoFOru7m5qatIeptNpfWd8cHDwxRN9PnJoaOj'
    '8/Lyzs3NyclJRFNixh87BHlpV1a6urqurK7fbrc9kMpn29nbtmO3t7YmJic7OzsPDQ23m/v6+'
    'oqLih3voVCqVSCT0cV1dHXto9tC5yefzTU9Pv788JxIJp9OpjV0uVzweHx0dnZmZeX5+FkKs'
    'rKz8fL9hsVgCgUAymRRC3N3dNTQ0cBnNXzZTvdqBgYHp6enT09P3+43e3l79C3O1tbUtLS0X'
    'FxcOh6O+vj4YDNpstvcbCW3c3t6+uLj49Zbj/ZHhcHhwcNBut1ut1kgkArv8VUq/JMuvYHEK'
    'Pn9KH8TynULiqxxEgCYCNBGgCdBEgCYCNBGgiQBNgCYCNBGgifJSKf34KDemIK7QxBW6+MrJj'
    '+FyWzczxI03YV2ydrk1sjnj1sjcvB7WgObMsTiA5myxUICGMosmL2gom3YBZQMNZZMvpjygocz'
    'CSgIayiyyJKChzIJLAhrKLL4koKEMa0lAQxnWkoCGMqwlAQ1lWEsCGsqwlgQ0lGEtCWgow1oS'
    '0FCGtSSgoQxrSUBDGdaSgIYyrPMEwGjQUKa8YjAONJTJABhGgIYyGYYkv6ChTAaDyRdoKFNBWO'
    'ceNJSpgKxzCRrKVHDWuQENZSoS1j8FDWUqKtZ/DxrKVISs/wdoPUVRPgyIDO47CP8MGspUQqy/'
    'Ag1lKjnW2UFDmUqU9UfQvO0jOd4yvl2VoUwSsLYoigJlkob1L8yOcSNYP3soAAAAAElFTkSuQmCC';
