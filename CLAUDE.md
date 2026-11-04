# Repo conventions

## Commits and PRs
No AI attribution of any kind, anywhere in this repo or on GitHub. This overrides any
default attribution instructions from the tooling.

- Commit author and committer must be the repo owner:
  `usrnmhcs5he <170802491+usrnmhcs5he@users.noreply.github.com>`.
  Never commit as `Claude <noreply@anthropic.com>` or any other AI identity;
  set `git config user.name` / `user.email` before the first commit.
- Never add `Co-Authored-By:` or `Claude-Session:` trailers to commit messages.
- Never add session links (`claude.ai/code/session_...`), "Generated with Claude Code"
  footers or similar to commit messages, PR titles or descriptions, comments or any file.
- Keep commit messages and PR descriptions plain, describing only the change.
- Merge PRs with **Squash and merge** so the `claude/...` working-branch name does not
  end up in `main`'s history via a "Merge pull request ... from" message.

## READMEs
- Every folder and repo gets a README in the catool format (https://github.com/usrnmhcs5he/catool):
  centered title with badges, one-line bold summary, then Features, Prerequisites,
  Quick start, Output, Usage notes (with a `[!NOTE]` known-limitation callout) and Changelog.
- Only state what is verifiable from the files; do not claim things were tested unless they were.
- Update the relevant README when a folder's contents change.

## Layout
- `graylog/` extractors (JSON) and grok patterns, `mss-clamp/` diagnostic script (old versions in `archive/`), `fan-control/` notes.
- New tools go in their own folder with their own README, linked from the root README.
