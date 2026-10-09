import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/ui/app/content_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled corpus notices include all source credits and full licenses', () async {
    final entries = await loadContentLicenses(rootBundle).toList();
    final textBySource = {
      for (final entry in entries)
        entry.packages.single: entry.paragraphs.map((p) => p.text).join('\n'),
    };

    expect(textBySource, hasLength(4));
    expect(textBySource['Psitta learning content'], contains('1,297'));
    expect(textBySource['JMdict / EDRDG'], contains('GENERAL DICTIONARY LICENCE'));
    expect(textBySource['JMdict / EDRDG'], contains('ShareAlike'));
    expect(textBySource['Tatoeba contributors'], contains('2.0 France'));
    expect(textBySource['Tatoeba contributors'], contains('creativecommons.org'));
    expect(
      textBySource['OpenJLPT and upstream contributors'],
      contains('Jonathan Waller'),
    );
    expect(textBySource['OpenJLPT and upstream contributors'], contains('KANJIDIC2'));
    expect(textBySource['OpenJLPT and upstream contributors'], contains('KanjiVG'));
    expect(textBySource['OpenJLPT and upstream contributors'], contains('Section 3'));
  });
}
