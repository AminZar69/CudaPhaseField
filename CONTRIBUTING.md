# Contributing to CudaPhaseField

Thanks for your interest in contributing. This is a GPU-accelerated CUDA Fortran
lattice Boltzmann solver, and some of the usual advice for contributing to a
codebase applies a little differently here because of that -- please read
through this before opening a PR, it'll save both of us time.

## Ways to contribute

- **Bug reports** -- especially anything involving wrong numerical results,
  crashes, or GPU-specific build failures. See the bug report template when
  opening an issue; the fields it asks for are not optional extras, they're
  usually the difference between a bug we can actually reproduce and one we
  can't.
- **Performance improvements** -- kernel optimizations, memory-access
  patterns, reducing host/device synchronization, etc. See the "Performance
  changes" section below before submitting one.
- **Documentation** -- README clarity, code comments, this file.
- **The 3D extension** -- a genuine 3D version of this model is on the
  roadmap. If you're interested in working on this, please open an issue
  first to discuss approach before writing code, since it's a substantial
  undertaking.

## Development setup

You'll need an NVIDIA GPU and the HPC SDK (`nvfortran`) installed -- see the
[Requirements](README.md#requirements) section of the README for install
instructions.

If your GPU's architecture has been dropped from your HPC SDK's *bundled*
CUDA toolkit (this has happened to older architectures as CUDA has moved past
13.0), or you need any other machine-specific build settings, use a
`Makefile.local` (see `Makefile.local.example`) rather than editing the
shared `Makefile` -- that keeps your personal setup out of the diff.

Build and test in **both** modes before submitting anything that touches a
kernel or the build system:
```bash
make clean && make BUILD=release
make clean && make BUILD=debug
```
Both should build cleanly and produce sane output (see "Verifying
correctness" below). `debug` has caught real bugs that `release` alone
didn't, and vice versa -- see the next section for why that matters more here
than it might in most codebases.

## Verifying correctness

This is not a formality for this repo. Wrong results here have historically
been **silent** -- no crash, no error, just quietly incorrect physics -- and
have taken real effort to track down (a kernel launch that was silently
rejected due to a GPU register-budget overshoot, previously, is a specific
example that cost a lot of debugging time before it was found).

Before submitting any change that touches `global_subroutines.f90`,
`device_var.f90`, `host_var.f90`, `main.f90`, or the `Makefile`'s compiler
flags, run the solver for at least a few thousand timesteps and check the
printed diagnostic table:
```
t    phi3_min    phi3_max      ux_max      uy_max     |u_max|  total_mass
```
- `phi3_min`/`phi3_max` should stay close to `[0, 1]` (small drift is normal
  in single precision, see the Precision section of the README).
- `ux_max`/`uy_max`/`|u_max|` should never show `Inf` or `NaN`.
- `total_mass` should stay effectively constant across the whole run.

If you're touching anything performance- or optimization-flag-related,
**test in both single and double precision** (`fp_kind` in `precision_m.f90`)
-- correctness bugs in this codebase have previously appeared in only one of
the two, at only some optimization levels, and (once) only on one GPU
architecture and not another. A change that looks fine in a five-second
single-precision smoke test is not the same as a change that's actually
verified correct.

## Performance changes

Please include **actual before/after timing numbers** in your PR description,
not just a description of why the change should be faster in theory. This
codebase has a real, on-the-record example of a change (removing warp
divergence from a branch in `interface_cal` via `merge()`) that was
reasoned through carefully, looked like it should help, and measurably made
things *slower* once benchmarked -- it was reverted. Reasoning about GPU
performance from source code alone is unreliable; measurement isn't
optional.

If possible, note which GPU(s) you benchmarked on -- a change that helps on
one architecture isn't guaranteed to help (or even be correct) on another;
several real bugs in this codebase have been architecture-dependent.

## Code style

- Every floating-point literal must carry an explicit `_fp_kind` suffix
  (e.g. `1.5_fp_kind`, not `1.5`). Bare literals default to single precision
  in Fortran regardless of what `fp_kind` is set to, which has caused real,
  hard-to-spot bugs in double-precision runs. Bare *integer* literals (array
  indices, loop bounds) don't need this -- only literals used in
  floating-point arithmetic.
- Match the existing tab-based indentation within whichever file you're
  editing.
- If you're adding a new set of per-direction arrays (something like a
  9-element D2Q9 population or a derived quantity per lattice direction),
  prefer a single consolidated array indexed by direction (see `h1`, `h2`,
  `g` in `device_var.f90`) over 9 separately-named scalar arrays -- this
  keeps direction-generic code loopable and was a deliberate refactor away
  from the older pattern still visible in some of the derived/temporary
  arrays.
- Comment non-obvious CUDA-specific reasoning, especially anything involving
  kernel launch ordering, `syncthreads()`, or shared-memory tiling -- the
  *why* a particular synchronization pattern is required is usually far less
  obvious than the code itself, and has been the source of real debugging
  time when missing.

## License and citation

This project is licensed under the GNU GPLv3 (see file headers). By
contributing, you agree your contributions will be licensed under the same
terms.

If your work here is used in academic research, please see the
[Citation](README.md#citation) section of the README.

## Questions

If anything above is unclear, or you're unsure whether an idea is worth
pursuing before investing time in it, open an issue first -- that's cheaper
for everyone than a large PR that needs to be reworked.
