import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psitta/ui/app/content_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('corpus attribution is consolidated and retains required credits', () async {
    final entries = await loadContentLicenses(rootBundle).toList();
    expect(entries, hasLength(1));
    expect(entries.single.packages, ['Psitta learning content']);
    final text = entries.single.paragraphs.map((p) => p.text).join('\n');

    for (final credit in [
      'James William BREEN',
      'EDRDG',
      'Tatoeba',
      'OpenJLPT',
      'Jonathan Waller',
      '1,297',
      'GENERAL DICTIONARY LICENCE',
      'Section 3',
    ]) {
      expect(text, contains(credit));
    }
    expect(text, contains('https://creativecommons.org/licenses/by/2.0/fr/'));
    expect(text, contains('https://creativecommons.org/licenses/by-sa/4.0/'));
    expect(text, isNot(contains('KanjiVG')));
    expect(text, isNot(contains('CC BY-SA 3.0')));
    expect(
      await rootBundle.loadString('assets/legal/JMDICT_DOCUMENTATION.txt'),
      contains('JMdict'),
    );
  });
}
