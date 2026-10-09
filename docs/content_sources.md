# Content sources and licensing

The MIT license covers the application code, not the embedded third-party data.
`assets/legal/CONTENT_NOTICES.txt` describes the scope of the corpus licenses and
Psitta's changes. The compiled/adapted learning dataset is distributed under
CC BY-SA 4.0; the underlying Tatoeba sentences retain their CC BY 2.0 FR license.

| Source | Role in Psitta | Attribution and license |
|---|---|---|
| JMdict (EDRDG; James William Breen) | Word forms, readings and selected English senses | CC BY-SA 4.0; full EDRDG statement and JMdict documentation bundled |
| Tatoeba and its contributors | Direct Japanese-English sentence pairs | CC BY 2.0 France; source notice and original French legal code bundled |
| OpenJLPT | N5/N4 vocabulary selection; grammar files also recorded in the source downloads | CC BY-SA 4.0; exact upstream NOTICE and LICENSE preserved |
| Jonathan Waller's JLPT Resources | Upstream source of OpenJLPT vocabulary/level lists | CC BY, as recorded in OpenJLPT's NOTICE; preserve credit and source link |

OpenJLPT's complete NOTICE also credits KANJIDIC2, its contributors and KanjiVG
(used on its website). Those credits are retained verbatim, without claiming
that Psitta embeds its kanji dataset or stroke diagrams. JLPT levels are
unofficial classifications. Downloading grammar metadata is not evidence that
the final card text comes from that metadata: frozen display meanings come from
JMdict, and sentence texts from Tatoeba.

## Source records

The acquisition record is `config/sources.lock.json` in `psitta-content`.
The dictionary snapshot is dated 2026-10-02; Tatoeba exports are dated 2026-09-26.
OpenJLPT is pinned to `0d1d3410bec90bd4098a7c72de820543cb4f707c`.
The generated corpus comes from `psitta-content` commit
`92ecfebde93fe4f16c473ecb8f08f45c69afd1a1`.

`OPENJLPT_NOTICE.txt` and `CC-BY-SA-4.0.txt` are exact copies of that OpenJLPT
snapshot's NOTICE.md and LICENSE. The EDRDG statement, JMdict documentation
and CC BY 2.0 France legal code are text extractions of their official pages,
with source URLs and retrieval date recorded in each file. Only HTML presentation
has been removed. License texts must not be edited to summarize their terms.

## Attribution in the application

Settings → About Psitta gives a source summary and opens Flutter's license
viewer. Its corpus entries contain all notices, complete legal texts and JMdict
documentation. Loading is deferred until the viewer opens, so adding notices
does not add file reads to the database-import path. No network connection is
needed to read them. The viewer also exposes registered software-package licenses.

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
