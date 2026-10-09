# Content sources and licensing

The MIT license covers the application code, not the embedded third-party data.
`assets/legal/CONTENT_NOTICES.txt` describes the scope of the corpus licenses and
Psitta's changes. The compiled/adapted learning dataset is distributed under
CC BY-SA 4.0; the underlying Tatoeba sentences retain their CC BY 2.0 FR license.

| Source | Role in Psitta | Attribution and license |
|---|---|---|
| JMdict (EDRDG; James William Breen) | Word forms, readings and selected English senses | CC BY-SA 4.0; full EDRDG statement and JMdict documentation bundled |
| Tatoeba and its contributors | Direct Japanese-English sentence pairs | CC BY 2.0 France; attribution and license URL in the shared notice |
| OpenJLPT | N5/N4 vocabulary selection; grammar files also recorded in the source downloads | CC BY-SA 4.0; upstream attribution summarized; shared full license bundled |
| Jonathan Waller's JLPT Resources | Upstream source of OpenJLPT vocabulary/level lists | CC BY, as recorded in OpenJLPT's NOTICE; preserve credit and source link |

OpenJLPT's recommended short attribution is used, including its upstream
credits (Jonathan Waller, JMdict/KANJIDIC2 and Tatoeba). Its full NOTICE is not
required to be copied. KanjiVG is used only on OpenJLPT's website and is not
included in Psitta: its credit and CC BY-SA 3.0 reference have been removed.
JLPT levels are unofficial classifications. The frozen display meanings come
from JMdict, and sentence texts from Tatoeba.

## Source records

The acquisition record is `config/sources.lock.json` in `psitta-content`.
The dictionary snapshot is dated 2026-10-02; Tatoeba exports are dated 2026-09-26.
OpenJLPT is pinned to `0d1d3410bec90bd4098a7c72de820543cb4f707c`.
The generated corpus comes from `psitta-content` commit
`92ecfebde93fe4f16c473ecb8f08f45c69afd1a1`.

`CC-BY-SA-4.0.txt` is an exact copy of the pinned OpenJLPT LICENSE, shared
by JMdict, OpenJLPT and Psitta's adaptations. `EDRDG_LICENCE.txt` and
`JMDICT_DOCUMENTATION.txt` are text extractions of the official pages, with
source URLs and retrieval dates. They remain bundled because EDRDG explicitly
requests documentation and license files in software packages. Their original
text is preserved, including sections concerning other EDRDG dictionaries.

## Attribution in the application

Settings → About Psitta opens Flutter's license viewer. There is one corpus
entry, containing `CONTENT_NOTICES.txt`, one copy of the shared CC BY-SA 4.0
text and the EDRDG statement. The lengthy JMdict documentation remains packaged
but is not appended to the license viewer; its official URL is in the notice.
Tatoeba's attribution and CC BY 2.0 France URL remain in the shared notice;
a separate copy of that legal code is optional (section 4(a) permits a URI).
The duplicate Tatoeba notice and full OpenJLPT NOTICE have been removed.

Software-package notices supplied by Flutter remain registered: consolidation
of data attribution does not remove the notices required by bundled libraries.
Assets are loaded only when the viewer opens. Included texts work offline;
following external documentation or license URLs requires a connection.

This central placement follows the EDRDG's explicit About/Sources-screen guidance
for smartphone/tablet applications and Tatoeba's collective text-attribution
guidance. It avoids repeating notices on every exercise card.

- EDRDG: https://www.edrdg.org/edrdg/licence.html
- Tatoeba: https://en.wiki.tatoeba.org/articles/show/faq
- OpenJLPT: https://github.com/evanclan/OpenJLPT/blob/0d1d3410bec90bd4098a7c72de820543cb4f707c/NOTICE.md
- Jonathan Waller: https://www.tanos.co.uk/jlpt/

## Data maintenance still required for distribution

EDRDG's statement also requires a procedure to keep dictionary data reasonably
current. The existing importer only installs into a database with no exercises;
shipping a new corpus does not update an existing installation.

Before public distribution, implement and validate a content-update path that
preserves learning progress. For each published corpus revision, refresh the
upstream snapshot in `psitta-content`, review affected entries against stable
source identifiers, regenerate the HTML and manifest, update the notices and
test both fresh installation and upgrade. Audit source freshness at least for
each release. Do not silently overwrite frozen data or reset users' progress.

Adding the attribution screen completes the attribution UI; it does not solve
the separate existing-installation update requirement.
