import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Registers corpus attribution alongside software-package licenses.
/// Assets are read only when the user opens the licenses page.
void registerContentLicenses() {
  LicenseRegistry.addLicense(() => loadContentLicenses(rootBundle));
}

/// Shares one notice and one copy of the common license across corpus sources.
Stream<LicenseEntry> loadContentLicenses(AssetBundle bundle) async* {
  const files = ['CONTENT_NOTICES.txt', 'CC-BY-SA-4.0.txt', 'EDRDG_LICENCE.txt'];
  final texts = await Future.wait(
    files.map((file) => bundle.loadString('assets/legal/$file')),
  );
  yield LicenseEntryWithLineBreaks(['Psitta learning content'], texts.join('\n\n'));
}
