import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:psitta/application/controllers/content_controller.dart';

/// Rewrites internal `media://` references to local file URIs in HTML.
class MediaResolver {
  final ContentController _contentController;

  MediaResolver(this._contentController);

  /// Resolves supported media-bearing attributes in [html].
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

    final media = await _contentController.getMediaBySHA256(sha256);

    if (media == null) {
      throw StateError('Media not found: $sha256');
    }

    element.attributes[attribute] = Uri.file(media.path).toString();
  }
}
