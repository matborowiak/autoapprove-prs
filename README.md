# autoapprove-prs

A small CLI that approves open GitHub pull requests, but only PRs by authors you list
by name. It runs as you through the [`gh`](https://cli.github.com) CLI and includes a
helper to run it on a schedule with macOS launchd.

> **Think before using this.** An automatic approval skips the review it stands for.
> Use it only where your team agrees a human review isn't needed, for example trusted
> bots or a teammate's low-risk repo, and where branch protection allows it.

## Requirements

- `bash` (the stock macOS 3.2 works), `gh` logged in with access to the repo
- macOS for `install.sh` and notifications; the CLI itself runs anywhere `gh` does

## Usage

```
autoapprove-prs --repo <repo> --author <handle> [--author <handle>...] [options]

  -r, --repo <repo>        repo URL, PR URL, git@ remote, or owner/name   [required]
  -a, --author <handle>    allowed PR author; repeat or comma-separate    [required]
  -n, --dry-run            show what would be approved
      --include-drafts     approve drafts too (skipped by default)
  -q, --quiet              print only approvals and errors
      --no-notify          no macOS notification
      --token-cmd <cmd>    command that prints a token to use as GH_TOKEN
  -h, --help / -V, --version
```

```bash
./autoapprove-prs --repo https://github.com/acme/widgets --author alice --dry-run
./autoapprove-prs -r acme/widgets -a alice,bob,app/dependabot
```

A PR is approved only if all of these are true:

1. its author is on the `--author` list (case doesn't matter; bots look like `app/dependabot`)
2. you didn't write it
3. it isn't a draft, unless you pass `--include-drafts`
4. you haven't approved its current head commit yet (a new push makes it eligible again)

Exit codes: `0` ok, `1` gh/runtime error, `2` usage error.

## Run it on a schedule (macOS)

```bash
./install.sh --interval 120 -- --repo acme/widgets --author alice,bob
./uninstall.sh              # list installed jobs
./uninstall.sh acme-widgets # remove one (or --all)
```

`install.sh` first checks your arguments with a dry run. It then writes
`~/Library/LaunchAgents/io.github.autoapprove-prs.<owner-repo>.plist` and loads it, logging to
`~/Library/Logs/autoapprove-prs.<owner-repo>.log`. Your repo and author list end up only
in that file on your machine, never in this repo.

### Auth under launchd

launchd doesn't load your shell profile. If `gh auth login` stored your token, nothing
else is needed. If the token only exists as an env var in `~/.zshrc` or similar, put it in
the Keychain and pass `--token-cmd`:

```bash
security add-generic-password -a "$USER" -s autoapprove-prs -w '<token>'
./install.sh -- --repo acme/widgets --author alice \
  --token-cmd 'security find-generic-password -s autoapprove-prs -w'
```

## License

MIT
