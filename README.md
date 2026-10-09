# SC-247625: subdirectory import and size limits

Demo repository: `git@github.com:qcastel/dataiku-large-repo.git`

Checkout: `codex/sc247625-subdirectory-limits`

This branch is independent of the old fixtures. Payloads are synthetic and highly
compressible: this tests checked-out file sizes, not actual network throughput.
Files use `.payload` so DSS's default deny list does not silently exclude them.

## Required DSS code and settings

Use the PR 41785 implementation that scopes the size report to `remotePath`.
The current agreed implementation still checks out the repository and applies
sparse checkout only for deny patterns; it does not restrict the checkout to
`remotePath`. DSS copies only the selected subdirectory into the library.

Set these instance properties in the development DSS configuration, then restart
DSS so the values are loaded:

```properties
git.clone.soft.limit.mb=5
git.clone.hard.limit.mb=10
```

Restore your previous settings after testing.

## Fixtures

| Remote path | Content | Size |
| --- | --- | --- |
| `fixtures/scope-small` | `code.py` | A few bytes (DSS reports a minimum of 1 MB) |
| `fixtures/scope-soft` | `large.payload` + `code.py` | 6 MiB without cache |
| `fixtures/scope-soft/cache` | `ignored.payload` | 8 MiB |
| `fixtures/scope-hard` | `part-a.payload` + `part-b.payload` + `code.py` | 12 MiB |
| `outside-large` | `outside.payload` | 40 MiB |

All paths and deny patterns below are relative to the repository root.
Use distinct local target paths so each test creates a separate library.

## 1. Outside files must not trigger a limit on a small import

Create a Git reference with:

- Remote URL: `git@github.com:qcastel/dataiku-large-repo.git`
- Checkout: `codex/sc247625-subdirectory-limits`
- Path in Git repository: `fixtures/scope-small`
- Local target path: `demo-scope-small`
- Denied files: clear the field

Save and retrieve. Expected: success without a size modal; only `code.py` is
imported. The 40 MiB outside file must not cause a hard-limit error.

## 2. Sparse deny filtering inside a subdirectory, then soft limit

Create another reference with:

- Same remote URL and checkout
- Path in Git repository: `fixtures/scope-soft`
- Local target path: `demo-scope-soft`
- Denied files (replace the whole field):

```text
/fixtures/scope-soft/cache/
```

Expected: soft-limit modal, total 6 MB, Git reference path
`fixtures/scope-soft`. Largest entries include
`fixtures/scope-soft/large.payload` (6 MB), and possibly `code.py` (displayed as
1 MB because of the minimum display size). Neither `outside-large` nor `cache`
should appear in the report.

Click Proceed anyway. Expected: library contains `large.payload` and `code.py`,
but not `cache/ignored.payload` or any outside file.

## 3. Included content must still trigger the hard limit

Create another reference with:

- Same remote URL and checkout
- Path in Git repository: `fixtures/scope-hard`
- Local target path: `demo-scope-hard`
- Denied files: clear the field

Expected: hard-limit modal, total 12 MB. Largest entries include
`fixtures/scope-hard/part-a.payload` and
`fixtures/scope-hard/part-b.payload` (6 MB each). Outside files do not appear.
Proceed anyway is unavailable.

Click + beside `part-b.payload`. Expected added pattern:

```text
/fixtures/scope-hard/part-b.payload
```

Click Update & Retry. Expected: soft-limit modal, total 6 MB. Click Proceed
anyway. Only `part-a.payload` and `code.py` are imported.

## 4. Control: remove the deny rule from the soft case

Create another reference with:

- Same remote URL and checkout
- Path in Git repository: `fixtures/scope-soft`
- Local target path: `demo-scope-soft-with-cache`
- Denied files: clear the field

Expected: hard-limit modal, total 14 MB. Report lists `large.payload` (6 MB)
and `cache` (8 MB), both prefixed with `fixtures/scope-soft/`.
This confirms that the previous 6 MB result came from the deny rule.

## 5. Control: import the repository root

Create another reference with:

- Same remote URL and checkout
- Path in Git repository: empty
- Local target path: `demo-scope-root`
- Denied files: clear the field

Expected: hard-limit modal, total approximately 66 MB. Git reference path is
`/`, and `outside-large` (40 MB) is now included in the report.

## Optional: demonstrate a genuinely scoped sparse checkout with Git CLI

This is a Git-only experiment, not the current DSS behavior. Choose an unused
local clone directory:

```sh
git clone --filter=blob:none --no-checkout --single-branch \
  --branch codex/sc247625-subdirectory-limits \
  git@github.com:qcastel/dataiku-large-repo.git \
  /tmp/sc247625-scoped-sparse-checkout

git -C /tmp/sc247625-scoped-sparse-checkout sparse-checkout set --no-cone -- \
  '/fixtures/scope-soft/' '!/fixtures/scope-soft/cache/'

git -C /tmp/sc247625-scoped-sparse-checkout checkout codex/sc247625-subdirectory-limits

find /tmp/sc247625-scoped-sparse-checkout/fixtures -type f

test ! -e /tmp/sc247625-scoped-sparse-checkout/outside-large
test ! -e /tmp/sc247625-scoped-sparse-checkout/fixtures/scope-soft/cache
```

Expected files: `fixtures/scope-soft/code.py` and
`fixtures/scope-soft/large.payload`. Both `test` commands exit successfully.
