# Repo conventions

## Commits and PRs
- Never add session links (`claude.ai/code/session_...`), `Claude-Session:` trailers or `Co-Authored-By:` lines to commit messages, PR descriptions, comments or any file in this repo.
- Keep commit messages and PR descriptions plain, describing only the change.

## READMEs
- Every folder and repo gets a README in the catool format (https://github.com/usrnmhcs5he/catool):
  centered title with badges, one-line bold summary, then Features, Prerequisites,
  Quick start, Output, Usage notes (with a `[!NOTE]` known-limitation callout) and Changelog.
- Only state what is verifiable from the files; do not claim things were tested unless they were.
- Update the relevant README when a folder's contents change.

## Layout
- `graylog/` extractors (JSON) and grok patterns, `mss-clamp/` diagnostic script (old versions in `archive/`), `fan-control/` notes.
- New tools go in their own folder with their own README, linked from the root README.
