project := phasefield
cc := nvfortran
# -cuda enables CUDA Fortran (this nvfortran version has retired -Mcuda in favor
# of -cuda + -gpu=...). With a .cuf extension nvfortran used to enable CUDA
# Fortran automatically; since these files are now plain .f90 (so editors/GitHub
# recognize them as Fortran), -cuda must be passed explicitly on every compile
# step that contains CUDA Fortran code, not just at link time.
#
# This target GPU is a Quadro P4000 (Pascal, compute capability 6.1). This specific
# HPC SDK 26.5 install only bundles CUDA 13.2 (check with:
# `find / -path '*hpc_sdk*/cuda/*' -maxdepth 8` -- if you see other X.Y folders under
# .../cuda/, a bundled -gpu=cudaX.Y may work instead and this whole workaround is
# unnecessary). CUDA 13.x dropped Maxwell/Pascal/Volta device-code generation
# entirely, so no -gpu=cudaX.Y value selects a working *bundled* toolkit here --
# -gpu=cudaX.Y can only choose among toolkits shipped inside the HPC SDK itself.
#
# The fix: install a standalone CUDA 12.x toolkit (NOT part of the HPC SDK) --
# e.g. CUDA 12.2, matching this driver's reported CUDA 12.2 compatibility -- from
# https://developer.nvidia.com/cuda-toolkit-archive, then point nvfortran at it
# via NVHPC_CUDA_HOME. When NVHPC_CUDA_HOME is set, drop cudaX.Y from -gpu=
# entirely (keep only ccXY); the two are alternatives, not combinable.
#
# Fill in the actual install path below once CUDA 12.2 is installed, e.g.
# /usr/local/cuda-12.2 (or wherever your installer put it).
export NVHPC_CUDA_HOME := /usr/local/cuda-12.2
gpu_target := cc61

# ---- Build mode -------------------------------------------------------------
# Usage: make               -> release (default)
#        make BUILD=debug   -> debug
#        make BUILD=release -> release, explicitly
#        make BUILD=safe    -> safe (see note below -- use this if double
#                               precision misbehaves under release)
#
# release: optimized, no debug info, no runtime checks -- for actual runs.
# debug:   unoptimized, host + device debug info, array-bounds and pointer
#          checks on -- for tracking down crashes/wrong-answers with
#          cuda-gdb or a plain debugger. Notably slower to run.
# safe:    WORKAROUND for a confirmed double-precision correctness bug on this
#          GPU/toolchain combination (Quadro P4000 / Pascal / cc61, nvfortran
#          26.5 host compiler paired with an external CUDA 12.2 device toolkit
#          via NVHPC_CUDA_HOME -- see the note above `NVHPC_CUDA_HOME` for why
#          that pairing exists). With fp_kind set to double precision in
#          precision_m.f90, `release` silently produces wrong results: the
#          velocity field goes to Inf/NaN within roughly the first 1000
#          timesteps, even though phi3/mass stay sane, so it's easy to miss if
#          you're not watching closely. This was bisected across every
#          optimization level (-O1 through -O3 -fast, with and without
#          -Kieee) -- all of them are wrong. Only turning off optimization on
#          BOTH the host (-O0) AND the device side (-gpu=...,debug) together
#          fixes it; either alone is not enough. Root cause is believed to be
#          specific to double-precision codegen on this particular
#          host-compiler/external-device-toolkit pairing, not the source code.
#          If you switch fp_kind to single precision, `release` is fine as-is
#          and `safe` isn't needed.
#
#          When to reach for this: if you're running double precision and see
#          NaN/Inf (or suspiciously exact-zero velocities) in release's
#          output, rebuild with `make BUILD=safe` and confirm the numbers look
#          physically sane again before trusting a result.
BUILD ?= release

srcdir := src
# Object files (and, via -module below, .mod files) are kept per-build-mode
# (obj/release, obj/debug, obj/safe) so switching between modes never links
# stale objects built with different flags, and .mod files from one mode never
# get picked up while compiling another. This also keeps .mod files out of the
# project root entirely. The final binary always lands at bin/phasefield either
# way, so `cd bin && ./phasefield` keeps working regardless of which mode
# produced it.
objdir := obj/$(BUILD)
bindir := bin

ifeq ($(BUILD),debug)
	optflags := -O0 -g -Mbounds -Mchkptr -traceback
	gpu_extra := ,debug,lineinfo
else ifeq ($(BUILD),safe)
	optflags := -O0
	gpu_extra := ,debug
else ifeq ($(BUILD),release)
	optflags := -O3 -fast
	gpu_extra :=
else
	$(error Unknown BUILD '$(BUILD)' -- use BUILD=release, BUILD=debug, or BUILD=safe)
endif

cudaflags := -cuda -gpu=$(gpu_target)$(gpu_extra) $(optflags) -module $(objdir)
ldflags := -cuda -gpu=$(gpu_target)$(gpu_extra) $(optflags)
# -------------------------------------------------------------------------------

objects	:= $(objdir)/precision_m.o $(objdir)/host_var.o $(objdir)/device_var.o $(objdir)/host_subroutines.o $(objdir)/global_subroutines.o $(objdir)/main.o 

$(shell mkdir -p $(objdir) $(bindir))

all: $(project)

####Linking####
$(project): $(objects) 
	$(cc) $(objects) -o $(bindir)/$(project) $(ldflags)
	
####Compilation####	
# precision_m.f90 is plain Fortran (no CUDA Fortran syntax), so no CUDA flags needed here.
# It still gets -O0/-O3 from optflags so debug builds aren't optimizing this file
# away from being steppable either.
$(objdir)/precision_m.o: $(srcdir)/precision_m.f90
	$(cc) $(optflags) -module $(objdir) -c $(srcdir)/precision_m.f90 -o $(objdir)/precision_m.o 
	
$(objdir)/host_var.o: $(srcdir)/host_var.f90
	$(cc) $(cudaflags) -c $(srcdir)/host_var.f90 -o $(objdir)/host_var.o
	
$(objdir)/device_var.o: $(srcdir)/device_var.f90
	$(cc) $(cudaflags) -c $(srcdir)/device_var.f90 -o $(objdir)/device_var.o
	
$(objdir)/host_subroutines.o: $(srcdir)/host_subroutines.f90
	$(cc) $(cudaflags) -c $(srcdir)/host_subroutines.f90 -o $(objdir)/host_subroutines.o
	
$(objdir)/global_subroutines.o: $(srcdir)/global_subroutines.f90
	$(cc) $(cudaflags) -c $(srcdir)/global_subroutines.f90 -o $(objdir)/global_subroutines.o
	
$(objdir)/main.o: $(srcdir)/main.f90
	$(cc) $(cudaflags) -c $(srcdir)/main.f90 -o $(objdir)/main.o 
########
	
clean:	
	rm -rf *mod 
	rm -rf obj
	rm -f $(bindir)/*