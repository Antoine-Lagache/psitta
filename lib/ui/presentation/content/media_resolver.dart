import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:psitta/infrastructure/persistence/repositories/media_repository.dart';

class MediaResolver {
  final MediaRepository _mediaRepository;

  MediaResolver(this._mediaRepository);

  Future<String> resolve(String html) async {
    final fragment = html_parser.parseFragment(html);

    // Only simple URI-valued attributes are supported for now.
    // URI-list attributes such as `srcset` are intentionally not handled.
    final elements = fragment.querySelectorAll('[src], [poster]');

    for (final element in elements) {
      await _resolveAttribute(element, 'src');
      await _resolveAttribute(element, 'poster');
    }

    return fragment.outerHtml;
  }

  Future<void> _resolveAttribute(Element element, String attribute) async {
    final value = element.attributes[attribute];

    if (value == null || !value.startsWith('media://')) {
      return;
    }

    final sha256 = value.substring('media://'.length);

    final media = await _mediaRepository.getBySHA256(sha256);

    if (media == null) {
      throw StateError('Media not found: $sha256');
    }

    element.attributes[attribute] = Uri.file(media.path).toString();
  }
}
