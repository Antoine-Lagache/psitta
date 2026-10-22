# Publication plan

Agreed sequence (2026-10-22):

1. Clean the repository and review README/documentation on `chatGPT/develop`.
   Merge into `main` only at the end, after review and validation.
2. Prepare distribution builds. Test Android and Linux, add Windows and have
   the maintainer test it. Attempt macOS/iOS builds if straightforward, without
   presenting untested builds as validated. Resolve Android release signing.
3. Replace the README-based Psitta.net page with a GitHub Pages presentation
   and platform-specific download links.
4. Create a short presentation video from the real application for Reddit
   and YouTube.
5. Inventory and prioritize future updates after preparing the initial release.

## Deferred ideas (not implemented or required for step 1)

- A separate Android test version for unfinished builds, installable alongside
  the stable app with isolated progress. Decide the package identity, labeling,
  signing and distribution workflow when this work is scheduled.
- Japanese text-to-speech or generated audio for the currently text-only corpus.
  Playback already exists; voice availability and pronunciation need evaluation.
- Progress backup/restore and content updates that preserve learning history.

This list records ideas, not commitments or a prioritized feature roadmap.
