# DiceCraft Live Content

Public, signed **data-only** content for DiceCraft. The game source remains private.

`release.json` is the client endpoint. Its Ed25519 signature covers the exact bytes
of all eight JSON catalogs. `manifest.json` and the category directories are verified
readable mirrors, not independent live configuration sources. `public-key.txt` is
public verification material; no signing private key or GitHub token is stored here.

After each approved content push, GitHub Actions verifies the signature, file hashes
and mirrors, then archives an immutable `content-vN` release with `content.zip` and
`SHA256SUMS`. The workflow needs only GitHub's built-in token for this repository;
there is no business server, database, cloud signing key or cross-repository token.

Changing content requires a new higher content version and a valid signature.
Changing these readable files without re-signing fails verification. Installed
clients verify against their bundled trust key, not a key downloaded from here.

The small files in `tools/` are publication verification helpers, not game logic.
Client updates take effect on the next game; an existing run retains its snapshot.
