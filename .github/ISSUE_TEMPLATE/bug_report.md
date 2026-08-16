---
name: Bug report
about: Wrong results, crashes, or build failures
title: ''
labels: bug
assignees: ''
---

<!--
Please fill in as much of this as you can. Bugs in this codebase have
historically been silent (wrong physics with no crash or error message), so
the environment details below are often the difference between a bug we can
reproduce and one we can't.
-->

## Environment

- GPU model and compute capability (`nvaccelinfo`):
- `nvfortran --version` output:
- CUDA toolkit in use (bundled with HPC SDK, or external via `NVHPC_CUDA_HOME`?):
- OS / distro:
- Build mode (`release`, `debug`, or a custom `Makefile.local` setup):
- Precision (`fp_kind` in `precision_m.f90`: single or double):

## What happened

<!-- Describe the bug. If it's a numerical/correctness issue rather than a
build failure or crash, please paste the printed diagnostic table
(t / phi3_min / phi3_max / ux_max / uy_max / |u_max| / total_mass) -- ideally
from the point where things first look wrong, not just the final line. -->

## What you expected

## Steps to reproduce

1.
2.
3.

## Have you tried the following? (check what applies)

- [ ] Reproduced in `BUILD=debug` as well as `BUILD=release`
- [ ] Tried the other precision mode (single vs double) to see if it's
      precision-specific
- [ ] Confirmed this isn't a known Pascal/older-GPU toolchain issue (see the
      README's Requirements section and `Makefile.local.example`)
- [ ] Ran `make clean` before rebuilding, to rule out stale object files

## Additional context

<!-- Full build log, full program output, or anything else useful. -->
