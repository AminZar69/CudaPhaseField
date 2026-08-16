## What does this change do?

<!-- Brief description. Link any related issue with "Fixes #123" or "Relates to #123". -->

## Type of change

- [ ] Bug fix
- [ ] Performance improvement
- [ ] New feature / physics capability
- [ ] Documentation only
- [ ] Build system / Makefile

## Correctness verification

<!-- Required for anything touching global_subroutines.f90, device_var.f90,
host_var.f90, main.f90, or compiler flags in the Makefile. See
CONTRIBUTING.md's "Verifying correctness" section for what to check. -->

- [ ] Built and ran cleanly in `BUILD=release`
- [ ] Built and ran cleanly in `BUILD=debug`
- [ ] Tested in single precision
- [ ] Tested in double precision
- [ ] Diagnostic output checked over a real run (not just a few steps) --
      `phi3_min`/`phi3_max` sane, no `Inf`/`NaN` in velocity, `total_mass`
      stable
- [ ] N/A -- this change doesn't touch simulation code (docs/README/CI only)

## Performance verification (if applicable)

<!-- Required if this PR claims a performance improvement. Reasoning about
GPU performance from source alone is not reliable for this codebase -- see
CONTRIBUTING.md for a real example of a change that looked like it should
help and measurably didn't. -->

- GPU(s) benchmarked on:
- Before:
- After:

## Anything reviewers should look at closely?

<!-- e.g. a synchronization pattern you're not 100% sure about, an edge case
you couldn't test, an assumption about array bounds, etc. -->
