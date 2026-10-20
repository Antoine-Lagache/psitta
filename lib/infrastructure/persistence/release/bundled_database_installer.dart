import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

/// Copies a verified snapshot only when no application database exists.
/// A same-directory rename publishes the complete file after a flushed write.
final class BundledDatabaseInstaller {
  static const assetDirectory = 'assets/database';
  static final _installations = <String, Future<bool>>{};
  final Future<Uint8List> Function(String) _loadAsset;

  BundledDatabaseInstaller({Future<Uint8List> Function(String)? loadAsset})
    : _loadAsset = loadAsset ?? _loadBundledAsset;

  static Future<Uint8List> _loadBundledAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<bool> installIfMissing(String path, {required int latestVersion}) {
    final absolutePath = File(path).absolute.path;
    return _installations.putIfAbsent(
      absolutePath,
      () => _install(absolutePath, latestVersion: latestVersion).whenComplete(() {
        _installations.remove(absolutePath);
      }),
    );
  }

  Future<bool> _install(String path, {required int latestVersion}) async {
    final target = File(path);
    if (await target.exists()) return false;
    await target.parent.create(recursive: true);
    // Serialize installers, including separate desktop application processes.
    final lock = await File('$path.install.lock').open(mode: FileMode.append);
    try {
      await lock.lock(FileLock.blockingExclusive);
      if (await target.exists()) return false;
      // Never publish a new main file next to an orphaned SQLite journal.
      for (final suffix in ['-wal', '-shm', '-journal']) {
        if (await File('$path$suffix').exists()) {
          throw StateError('SQLite sidecar exists without its database: $path$suffix');
        }
      }
      final metadata =
          jsonDecode(utf8.decode(await _loadAsset('$assetDirectory/manifest.json')))
              as Map<String, dynamic>;
      final version = metadata['database_version'];
      if (metadata['format_version'] != 1 ||
          version is! int ||
          version < 1 ||
          version > latestVersion) {
        throw const FormatException('Unsupported bundled database version');
      }
      final compressed = await _loadAsset('$assetDirectory/psitta.db.gz');
      if (sha256.convert(compressed).toString() != metadata['gzip_sha256']) {
        throw const FormatException('Bundled database archive checksum mismatch');
      }
      final bytes = Uint8List.fromList(gzip.decode(compressed));
      if (bytes.length != metadata['database_bytes'] ||
          bytes.length < 100 ||
          sha256.convert(bytes).toString() != metadata['database_sha256'] ||
          ascii.decode(bytes.sublist(0, 16), allowInvalid: true) !=
              'SQLite format 3\u0000' ||
          ByteData.sublistView(bytes).getUint32(60, Endian.big) != version) {
        throw const FormatException('Invalid bundled SQLite database');
      }
      final temporary = File('$path.installing');
      try {
        await temporary.writeAsBytes(bytes, flush: true);
        await temporary.rename(path);
      } finally {
        if (await temporary.exists()) await temporary.delete();
      }
      return true;
    } finally {
      await lock.close();
    }
  }
}
