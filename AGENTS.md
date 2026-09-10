# OpenMS ProSE package

- This package owns ProSEAlgorithm, its scientific tests and the ProSE executable.
- Keep reusable file-format readers/writers and shared scientific primitives in Core.
- The shared backend exports OpenMS::ProSE and depends on installed, pinned Core only.
  CLI belongs only to the executable. Preserve the public C++ API used by pyOpenMS.
- No vendored/contrib/dependency edits, secrets or source/build-tree SDK fallbacks.
- Coordinate native builds with the task owner; use Debug for development. Run
  relevant tests after changes and distinguish source checks from native acceptance.
- Keep imported attribution and migration-manifest.json accurate. Root-owned helper
  copies under cmake are synchronized from the parent; do not fork their policy.
- Commit coherent changes with OpenMS tags; source pins must be updated before
  consuming a changed SDK. Never replace a library beneath an older pinned binary.
