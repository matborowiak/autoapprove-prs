# autoapprove-prs

A small CLI that approves open GitHub pull requests, but only PRs by authors you list
by name. It runs as you through the [`gh`](https://cli.github.com) CLI and can check once
or keep checking in your terminal on an interval.

> **Think before using this.** An automatic approval skips the review it stands for.
> Use it only where your team agrees a human review isn't needed, for example trusted
> bots or a teammate's low-risk repo, and where branch protection allows it.

## Requirements

- `bash` (the stock macOS 3.2 works) and `gh`
- auth is whatever `gh` already uses in your shell: `GH_TOKEN`, `GITHUB_TOKEN`, or `gh auth login`
- macOS only for the optional approval notifications

## Usage

```
autoapprove-prs --repo <repo> --author <handle> [--author <handle>...] [options]

  -r, --repo <repo>        repo URL, PR URL, git@ remote, or owner/name   [required]
  -a, --author <handle>    allowed PR author; repeat or comma-separate    [required]
  -e, --every <interval>   keep checking on an interval: 30s, 1m, 5m, 1h
  -n, --dry-run            show what would be approved
      --include-drafts     approve drafts too (skipped by default)
  -q, --quiet              print only approvals and errors
      --no-notify          no macOS notification
  -h, --help / -V, --version
```

```bash
# check once
autoapprove-prs --repo https://github.com/acme/widgets --author alice

# keep checking every minute until you press Ctrl+C or close the terminal
autoapprove-prs -r acme/widgets -a alice,bob,app/dependabot --every 1m
```

With `--every` it runs in the foreground of your current shell. Nothing is installed
or left running in the background. A failed check (for example a network blip) is
reported and the loop keeps going.

A PR is approved only if all of these are true:

1. its author is on the `--author` list (case doesn't matter; bots look like `app/dependabot`)
2. you didn't write it
3. it isn't a draft, unless you pass `--include-drafts`
4. you haven't approved its current head commit yet (a new push makes it eligible again)

Exit codes: `0` ok, `1` gh/runtime error, `2` usage error.

## Install

```bash
git clone https://github.com/matborowiak/autoapprove-prs.git
ln -s "$PWD/autoapprove-prs/autoapprove-prs" /usr/local/bin/autoapprove-prs   # or anywhere on your PATH
```

## License

MIT
