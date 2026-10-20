"""Apply the frozen 2026-10-19 curriculum to the reviewed HTML baseline.

Usage: python tools/update_final_curriculum.py ../psitta-content
Run upstream tools/build_v0_1_final_4_3.py first. Uses Python's standard library.
The baseline commit must exist locally (fetch full history for shallow clones).
"""
import copy
import gzip
import hashlib
import html
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
BASELINE = '8824eaf3dc8543fb203e76bc3db10809483e1e0c'
UPSTREAM = 'a447a6186fe0e8c5fc1d1b3c6ea5ded42ac70367'
SOURCE_SHA = '020bdc1582ac2302fcac0ea14ade852a3344e5d0f04ae26f95e227064e8584bd'
ASSETS = 'assets/content/v0_1/'


def baseline(name):
    return subprocess.check_output(['git', 'show', f'{BASELINE}:{ASSETS}{name}'], cwd=ROOT)


def rows(name):
    return [json.loads(line) for line in gzip.decompress(baseline(name)).splitlines()]


def build(upstream):
    source = (upstream / 'data/review/v0_1_final_4_3_curriculum_20261019.json').read_bytes()
    assert hashlib.sha256(source).hexdigest() == SOURCE_SHA, 'Unexpected editorial reference'
    data = json.loads(source)
    old_words = rows('word_exercises.jsonl.gz')
    old_groups = rows('sentence_exercises.jsonl.gz')
    old_instances = {(g['source_group_id'], n): i for g in old_groups
                     for n, i in enumerate(g['instances'], 1)}
    ranks = {w['order']: w['curriculum_order'] for w in data['words']}
    words, groups, seen = [], [], set()
    corrected = 0
    for n, word in enumerate(data['words'], 1):
        assert word['curriculum_order'] == n
        row = copy.deepcopy(old_words[word['order'] - 1])
        row.update(order=n, exercise_id=f'word-{n:04d}',
                   source_word_id=word['order'], recommended_session=word['recommended_session'])
        assert html.escape(word['writing'], quote=True) in row['front_html']
        if 'meaning_provenance' in word:
            senses = [re.sub(r'^\d+:\s*', '', s).strip() for s in
                      re.split(r'\s+\|\s+(?=\d+:\s)', '; '.join(word['meanings']))]
            items = ''.join('<li>' + html.escape(s, quote=True) + '</li>' for s in senses)
            row['back_html'], count = re.subn(r'(<ul\b[^>]*>).*?(</ul>)',
                lambda m: m[1] + items + m[2], row['back_html'], flags=re.S)
            assert count == 1
            row['back_html'] = row['back_html'].replace('Source: JMdict',
                html.escape(word['meaning_provenance']['attribution_label'], quote=True))
            row['meaning_provenance'] = word['meaning_provenance']
            corrected += 1
        if word['order'] == 511:
            assert word['writing'] == '訳' and word['reading'] == 'やく'
            assert '<ruby>訳<rt>わけ</rt></ruby>' in row['back_html']
            row['back_html'] = row['back_html'].replace('<ruby>訳<rt>わけ</rt></ruby>', '<ruby>訳<rt>やく</rt></ruby>')
        words.append(row)
    reading_fixes = 0
    notes = 0
    for n, group in enumerate(data['sentence_groups'], 1):
        assert group['curriculum_order'] == n
        row = dict(exercise_id=f'sentence-{n:04d}', kind='sentence_exercise', order=n,
                   source_group_id=group['id'], recommended_session=group['recommended_session'], instances=[])
        assert len(group['source_instance_refs']) == len(group['instances'])
        for k, (instance, ref) in enumerate(zip(group['instances'], group['source_instance_refs']), 1):
            key = tuple(ref)
            assert key not in seen
            seen.add(key)
            card = copy.deepcopy(old_instances[key])
            assert html.escape(instance['japanese'], quote=True) in card['front_html']
            assert html.escape(instance['english'], quote=True) in card['back_html']
            assert card['back_html'].count('https://tatoeba.org/en/sentences/show/') == 2
            card.update(instance_id=f'sentence-{n:04d}-{k:02d}',
                        source_instance_ref=ref,
                        word_orders=sorted(ranks[w] for w in instance['word_orders']))
            if 511 in instance['word_orders']:
                reading_fixes += card['back_html'].count('<ruby>訳<rt>わけ</rt></ruby>')
                card['back_html'] = card['back_html'].replace('<ruby>訳<rt>わけ</rt></ruby>', '<ruby>訳<rt>やく</rt></ruby>')
            if 'translation_review' in instance:
                review = instance['translation_review']
                assert html.escape(review['suggested_english'], quote=True) in card['back_html']
                assert 'AI-generated; not independently verified' in card['back_html']
                card['translation_review'] = review
                notes += 1
            row['instances'].append(card)
        groups.append(row)
    assert seen == set(old_instances)
    assert (len(words), len(groups), len(seen), corrected, notes, reading_fixes) == (1297, 1380, 3452, 10, 15, 1)
    manifest = json.loads(baseline('manifest.json'))
    manifest.update(source_sha256=SOURCE_SHA, source_kind=data['kind'],
                    source_release_status='frozen_editorial_reference_v0_1_with_documented_exceptions',
                    counts=dict(word_exercises=len(words), sentence_exercises=len(groups), sentence_instances=len(seen)))
    manifest['editorial_reference'] = dict(repository='Antoine-Lagache/psitta-content', commit=UPSTREAM,
        path='data/review/v0_1_final_4_3_curriculum_20261019.json', html_baseline_commit=BASELINE,
        corrected_word_cards=corrected, sentence_reading_corrections=reading_fixes,
        scheduling='Order applied; recommended_session is metadata, not enforced by the app')
    # Baseline coverage numbers describe the old links; do not present them as a new audit.
    prior_reading = manifest.pop('kana_reading')
    manifest['kana_reading'] = dict(human_reviewed=False,
        method='Preserved reviewed baseline HTML by exact source instance reference; corrected one linked 訳 reading to やく',
        baseline_audit=prior_reading, current_coverage_recomputed=False)
    manifest['attribution']['editorial_adaptations'] = '10 word cards explicitly credit ChatGPT for sense selection and usage notes; dictionary glosses remain JMdict'
    manifest['files'] = {}
    for name, output in [('word_exercises.jsonl.gz', words), ('sentence_exercises.jsonl.gz', groups)]:
        raw = ''.join(json.dumps(r, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n' for r in output).encode()
        # GzipFile fixes the filename, time and OS header for reproducibility.
        import io
        buffer = io.BytesIO()
        with gzip.GzipFile(fileobj=buffer, mode='wb', filename='', mtime=0) as f:
            f.write(raw)
        compressed = buffer.getvalue()
        (ROOT / ASSETS / name).write_bytes(compressed)
        manifest['files'][name] = dict(sha256=hashlib.sha256(compressed).hexdigest(), jsonl_sha256=hashlib.sha256(raw).hexdigest())
    (ROOT / ASSETS / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(manifest['counts']))


if __name__ == '__main__':
    build(Path(sys.argv[1]))
