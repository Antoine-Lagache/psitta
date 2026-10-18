# Japanese exercise fonts

Noto Sans JP, Japanese subset OTF, Medium (500) and Bold (700).
Original, unmodified files from https://github.com/notofonts/noto-cjk:

- `Sans/SubsetOTF/JP/NotoSansJP-Medium.otf`
- `Sans/SubsetOTF/JP/NotoSansJP-Bold.otf`

Retrieved 2026-10-18. SHA-256:

- Medium: `f396a3b57256e4515be9cb41f7aac54766d654890082a9f1b5c2451b5c093d8a`
- Bold: `1b0edfb500b73a4fa8a4fcaae1bbbd403994e08e73e3e0da37e70d3853f42c5f`

License: SIL Open Font License 1.1, copied unchanged to
`assets/legal/NOTO_SANS_JP_OFL.txt` and registered in the app's licenses page.
Both weights cover every kana and CJK ideograph in the v0.1 corpus.

The renderer applies these fonts to Japanese reading blocks in the existing
v0.1 HTML. Reading sizes are increased by 20% (rounded up); translations and
source notices retain their exported styles. This is presentation-only and
requires no content migration or database regeneration. Future exports with
semantic CSS classes should replace the legacy inline-size selector.
