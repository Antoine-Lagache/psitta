import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers the corpus notices alongside Flutter's software-package licenses.
/// Assets are read only when the user opens the licenses page.
void registerContentLicenses() {
  LicenseRegistry.addLicense(() => loadContentLicenses(rootBundle));
}

/// Loads the complete notices offline, including OpenJLPT's upstream credits.
Stream<LicenseEntry> loadContentLicenses(AssetBundle bundle) async* {
  const entries = [
    ('Psitta learning content', ['CONTENT_NOTICES.txt', 'CC-BY-SA-4.0.txt']),
    (
      'JMdict / EDRDG',
      ['EDRDG_LICENCE.txt', 'CC-BY-SA-4.0.txt', 'JMDICT_DOCUMENTATION.txt'],
    ),
    ('Tatoeba contributors', ['TATOEBA_NOTICE.txt', 'CC-BY-2.0-FR.txt']),
    ('OpenJLPT and upstream contributors', ['OPENJLPT_NOTICE.txt', 'CC-BY-SA-4.0.txt']),
  ];

  for (final (name, files) in entries) {
    final texts = await Future.wait(
      files.map((file) => bundle.loadString('assets/legal/$file')),
    );
    yield LicenseEntryWithLineBreaks([name], texts.join('\n\n'));
  }
}
