---
name: github-workflow
description: Comprehensive guide for interacting with GitHub using the gh CLI and git. Covers issue/PR identification, searching, CRUD operations, acceptance criteria, cross-referencing, PR workflows, CI interaction, worktrees, and branch management. Use when working with GitHub issues, pull requests, or repository workflows.
---

# GitHub Workflow

## Prerequisites

- `gh` CLI is installed and authenticated (`gh auth status`)
- Repository remote `origin` is configured (`git remote -v`)

---

## Identifying Issues vs Pull Requests

When given a number like `#42`, **infer from context first** before making API calls:

| Context clue | Likely |
|---|---|
| "close #42", "fix #42", "work on #42" | Issue |
| "merge #42", "review #42", "approve #42" | PR |
| "the PR #42", "PR #42" | PR |
| "issue #42", "ticket #42" | Issue |
| "check #42", "look at #42" | Ambiguous — verify |

### Verify when ambiguous

If the user's request likely needs reading the issue/pr anyway, try `gh issue view` first, fall back to `gh pr view`.
Otherwise, use the API as a definitive check:

```bash
gh api repos/{owner}/{repo}/issues/42 --jq '.pull_request'
```

- `null` → **issue**
- JSON object → **PR** (has `url`, `merge_commit_sha`, etc.)

---

## Searching Issues and Pull Requests

### Search by keyword

```bash
gh issue list --search "authentication"
gh pr list --search "login"
```

### Filter by state, label, author, assignee

```bash
gh issue list --state open --label bug
gh pr list --state closed --author octocat
gh issue list --assignee @me
gh pr list --review requested
```

### Search across both issues and PRs

```bash
gh search issues --state open --search "memory leak"
gh search prs --state open --label "breaking-change"
```

### View search results with details

```bash
gh issue list --limit 20 --json number,title,state,labels,createdAt
gh pr list --limit 20 --json number,title,state,headRefName,mergedAt
```

---

## Manipulating Issues

### Create an Issue

```bash
gh issue create \
  --title "Add dark mode support" \
  --body "Implement dark mode following the design spec in Figma..." \
  --label "enhancement" \
  --label "ui"
```

With a body file:

```bash
gh issue create --title "Fix memory leak" --body @ISSUE_BODY.md
```

### View an Issue

```bash
gh issue view 42
gh issue view 42 --json title,body,state,labels,assignees,comments
```

### Update an Issue

```bash
# Edit title and/or body
gh issue edit 42 --title "New title" --body "Updated description"

# Add/remove labels
gh issue edit 42 --add-label "bug" --remove-label "stale"

# Assign
gh issue edit 42 --add-assignee @me --remove-assignee someone-else

# Set milestone
gh issue edit 42 --milestone "v2.0"

# Close or reopen
gh issue close 42
gh issue reopen 42
```

### Delete an Issue

```bash
gh issue delete 42 --yes
```

---

## Acceptance Criteria

### Adding acceptance criteria to an issue

Acceptance criteria go in the issue body as a checklist:

```markdown
## Acceptance Criteria

- [ ] User can toggle dark mode from settings
- [ ] Dark mode persists across page reloads
- [ ] All components respect the dark theme colors
- [ ] No visual regressions on mobile viewports
```

### Updating acceptance criteria

```bash
gh issue edit 42 --body "$(gh issue view 42 | sed '/## Acceptance Criteria/,$d')

## Acceptance Criteria

- [ ] New criterion 1
- [ ] New criterion 2"
```

Or read the current body, modify it, and write back:

```bash
BODY=$(gh issue view 42 --json body --jq '.body')
# Edit $BODY (e.g., mark items complete with -[x])
gh issue edit 42 --body "$BODY"
```

### Checking acceptance criteria status

```bash
gh issue view 42 --json body --jq '.body' | grep -c '^\- \[x\]'   # completed
gh issue view 42 --json body --jq '.body' | grep -c '^\- \[-\]'   # pending
```

---

## Linking and Cross-Referencing Issues

### In commit messages

```bash
git commit -m "fix: resolve memory leak in parser

Closes #42"
```

Keywords that auto-link (and optionally close):

| Keyword | Links? | Closes? |
|---------|--------|---------|
| `Fixes #42` / `Closes #42` | Yes | Yes |
| `Refs #42` | Yes | No |
| `See #42` | Yes | No |
| `Related to #42` | Yes | No |

### In PR descriptions

```markdown
## Description

This PR fixes the memory leak in the parser.

## Related Issues

Closes #42
Refs #38, #41
```

### In issue comments

```bash
gh issue comment 42 --body "This is addressed by PR #50"
```

GitHub auto-links `#NNN` references in comments, bodies, and PR descriptions.

### Cross-referencing between repos

```markdown
owner/repo#42
```

---

## Opening Pull Requests

### Create a PR from the current branch

```bash
gh pr create --title "feat: add dark mode" --body "..."
```

With a body file:

```bash
gh pr create --body @PR_BODY.md
```

### Specify base branch and reviewers

```bash
gh pr create --base main --head feature/dark-mode --reviewer octocat --reviewer dev2
```

### Create PR with linked issue

```bash
gh pr create --title "fix: memory leak" --body "Closes #42"
```

### View PR details

```bash
gh pr view 50
gh pr view 50 --json title,body,state,files,additions,deletions,labels,reviewRequests,assignees,comments
```

### List your PRs

```bash
gh pr list --state open --head feature/dark-mode
gh pr list --author @me --state open
```

---

## Linking PRs to Issues

### At creation time

```bash
gh pr create --title "fix: memory leak" --body "Closes #42"
```

### After creation — add to PR body

```bash
BODY=$(gh pr view 50 --json body --jq '.body')
echo -e "\nCloses #42" >> <(echo "$BODY")   # or edit manually
gh pr edit 50 --body "..."
```

### Add issue references in comments

```bash
gh pr comment 50 --body "This resolves #42 and relates to #38"
```

### Link via commit messages (on merge)

Push commits with closing keywords — they auto-link on merge:

```bash
git commit -m "fix(parser): resolve memory leak in token buffer

Closes #42"
git push
```

---

## Interacting with CI

### Check CI status of a PR

```bash
gh pr checks 50
gh pr checks 50 --json status,state,conclusion,name,createdAt
```

### Wait for CI to pass

```bash
gh pr checks 50 --watch
```

### View check run details

```bash
gh api repos/{owner}/{repo}/check-runs --jq '.check_runs[] | select(.name == "CI") | {name, status, conclusion}'
```

### Re-run failed checks

```bash
gh api repos/{owner}/{repo}/actions/runs --jq '.workflow_runs[] | select(.conclusion == "failure") | .id' | head -1 | xargs -I{} gh api repos/{owner}/{repo}/actions/runs/{}/rerun-failed-jobs -X POST
```

### View PR status checks inline

```bash
gh pr checks 50 --fail
# Exits non-zero if any check failed
```

---

## Using Worktrees and Branches

By default, work on issues should be done in a worktree with the intention of creating a pull request. However, ad-hoc and direct requests often do not require worktrees and PRs.

### Create a worktree for an issue

```bash
# From main, create a worktree linked to a new branch
git worktree add -b feature/dark-mode ../project-dark-mode "main"

# Or checkout an existing PR as a worktree
git worktree add -b pr-42-review ../pr-42-review "refs/pull/42/head"
```

### List worktrees

```bash
git worktree list
```

### Remove a worktree

```bash
git worktree remove ../project-dark-mode   # if branch is deleted or detached
git worktree prune                          # clean up stale entries
```

### Branch naming conventions

Good patterns:
- `feature/description` — new features
- `fix/description` — bug fixes
- `chore/description` — maintenance
- `refactor/description` — code restructuring
- `test/description` — test additions

### Push and track a branch

```bash
git checkout -b feature/dark-mode
# ... make changes ...
git push -u origin feature/dark-mode
```

### Create PR from any branch

```bash
gh pr create --base main --head feature/dark-mode --title "feat: add dark mode"
```

### Sync main before working

```bash
git checkout main
git pull origin main
git checkout feature/dark-mode
git rebase main    # or merge
```

---

## Scripts

Helper scripts in `scripts/` that solve the pain points `gh` CLI doesn't handle well:

### Create issue from file or stdin

`--body @file` doesn't work with `gh` (treats path as literal text). Use this instead:

```bash
# From a file
cat body.md | gh-issue-create --title "Fix memory leak" --label bug

# With explicit body file
github-workflow/scripts/gh-issue-create --title "Fix memory leak" --body-file body.md --label bug
```

### Create issue from short description (template-based)

```bash
gh-issue-from-desc --title "Split run_instance" --desc "CC=40, 280 LOC, needs refactoring" --type refactor
```

Types: `bug`, `feature`, `refactor`, `chore`, `docs` — each gets a template + default labels.

### Edit issue body sections

Appending/modifying sections without clobbering the whole body:

```bash
# Append acceptance criteria
cat ac.md | gh-issue-edit-body 42 --section "## Acceptance Criteria"

# Replace an existing section
cat updated-problem.md | gh-issue-edit-body 42 --replace "## Problem"

# Append raw text
cat notes.md | gh-issue-edit-body 42 --append

# Replace entire body
cat full-body.md | gh-issue-edit-body 42 --full
```

### Create PR from file or stdin

```bash
cat pr-body.md | gh-pr-create --title "feat: add dark mode" --base main --head feature/dark-mode --label enhancement
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Is #N an issue or PR? | `gh api repos/{owner}/{repo}/issues/N --jq '.pull_request'` |
| List open issues | `gh issue list --state open` |
| List open PRs | `gh pr list --state open` |
| Create issue (from file) | `cat body.md \| gh-issue-create --title "..." --label bug` |
| Create issue (template) | `gh-issue-from-desc --title "..." --desc "..." --type refactor` |
| Edit body section | `cat ac.md \| gh-issue-edit-body N --section "## Acceptance Criteria"` |
| Edit issue | `gh issue edit N --title "..." --add-label "bug"` |
| View PR | `gh pr view N` |
| Create PR | `gh pr create --title "..." --body "..."` |
| Check CI | `gh pr checks N` |
| Watch CI | `gh pr checks N --watch` |
| Worktree list | `git worktree list` |
| Worktree add | `git worktree add -b branch ../dir "main"` |
