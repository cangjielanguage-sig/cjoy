# AGENTS.md

## Setup

- Cangjie `1.2.0` + stdx. `CANGJIE_STDX_PATH` must point to the `static/stdx` directory
  (e.g. `$HOME/cangjiestdx/linux_x86_64_cjnative/static/stdx`), not the stdx install root.
- For official SDK implementation details, use `CANGJIE_STD_SRC` (Cangjie `std` library source)
  and `CANGJIE_STDX_SRC` (stdx source); these are source-tree roots, not library paths.
  They may be unset in this environment — when unset, look for a checked-out
  `cangjie_stdx-*/src/stdx` tree under `$HOME/cangjiestdx`, and for `std` sources in the
  official `Cangjie/cangjie_runtime` repo (`stdlib/`). Do not expect source under
  `$CANGJIE_HOME` (binary SDK) or `$CANGJIE_STDX_PATH` (compiled binaries).
- README says `cjpm udpate`; the real command is `cjpm update`. `cjpm.lock` is gitignored.
- `src/**/*.macrocall` are generated macro-expansion artifacts and gitignored — never edit them by hand.

## Commands

```bash
cjpm build
cjpm test                                   # full suite; run from repo root
cjpm test -i src/test                       # only high-level suites in src/test
cjpm test -i --filter=FileServerTestCaseSuit.*
cjpm test -i --filter=FileServerTestCaseSuit.testStaticFile

cd examples && cjpm build
cd examples && cjpm run --name examples.simple
```

- When adding/removing/renaming test cases, verify with plain `cjpm test` (no `-i`).
  Incremental runs have left stale test registrations in this repo.
- Do not use `cjpm test --parallel`: high-level suites start real Joy servers on fixed
  localhost ports (18881 / 18882 / 18883 / 31888) and would collide.
- File-server tests read relative paths like `./doc/imgs/...`, so test from the repo root.
  Full runs take tens of seconds because suites sleep 1–2s after starting servers.

## Architecture / wiring

- Framework wraps stdx `net.http.Server`. Entry points: `Joy.default()` / `joy.router` /
  `joy.run(host, port)`; dispatch goes through `TreeRouteDistributor` and the compressed
  prefix tree in `src/framework/{route,tree,engine}.cj`.
- Zero-reflection macro system: `src/macros/macros.cj` re-exports all feature macros;
  feature macro definitions/expansions live in `src/<feature>/macros/`.
- Macro-generated handlers/middleware must be registered at startup:
  `JoyHandlers.registerTo(joy)` and `JoyMiddlewares.registerTo(joy)`. Without this,
  routes silently do not exist.
- `src/test/` holds high-level tests (`*TestCaseSuit`); `*_test.cj` beside source files
  holds low-level tests. `examples/` is a separate cjpm module with `path = "../"` and is
  not covered by the root `cjpm test`.

## Testing gotchas

- stdx `HttpResponse.close()` closes the underlying socket even after the body was fully
  read and the connection returned to the pool. `JoyHttpResponse.close()` drains finite
  bodies instead; for raw stdx `Client` tests, read the body fully and do **not** call
  `rsp.close()`, or the next request fails with `Socket is already closed`.
- Several tests are deliberately `@Skip`; they are not failures to "fix" by default.

## Conventions

- Conventional Commits, English messages (`fix:`, `feat:`, `test:`, `chore:`, ...).
- Every exported function needs Chinese documentation; internal comments in Chinese.
- Code changes must ship tests and must not reduce overall coverage. No secrets in the repo.
