project := phasefield
cc := nvfortran
# -cuda enables CUDA Fortran (this nvfortran version has retired -Mcuda in favor
# of -cuda + -gpu=...). With a .cuf extension nvfortran used to enable CUDA
# Fortran automatically; since these files are now plain .f90 (so editors/GitHub
# recognize them as Fortran), -cuda must be passed explicitly on every compile
# step that contains CUDA Fortran code, not just at link time.

# ---- Per-machine overrides (optional) ----------------------------------------
# If a Makefile.local exists next to this file, it's included here and can
# override any variable below -- gpu_target, NVHPC_CUDA_HOME, etc. This is the
# place for machine-specific settings (an old GPU whose codegen support was
# dropped from your HPC SDK's bundled toolkit, a nonstandard install path,
# personal build preferences) that don't belong in the shared Makefile.
# Makefile.local is gitignored -- it's never committed, so your personal setup
# never gets forced onto other contributors, and their setup never overwrites
# yours. See Makefile.local.example for the pattern and a worked example.
-include Makefile.local

# gpu_target defaults to ccnative, which asks nvfortran to auto-detect the
# compute capability of whatever GPU is actually present at build time -- for
# almost everyone on a reasonably current GPU, this means `make` just works
# with no editing required. Override it (in Makefile.local, not here) if you
# need to target a specific architecture, e.g. cross-compiling for a GPU that
# isn't the one in the build machine, or an older architecture that needs the
# workaround described below.
gpu_target ?= ccnative

# ---- Build mode -------------------------------------------------------------
# Usage: make               -> release (default)
#        make BUILD=debug   -> debug
#        make BUILD=release -> release, explicitly
#
# release: optimized, no debug info, no runtime checks -- for actual runs.
# debug:   unoptimized, host + device debug info, array-bounds and pointer
#          checks on -- for tracking down crashes/wrong-answers with
#          cuda-gdb or a plain debugger. Notably slower to run.
BUILD ?= release

srcdir := src
# Object files (and, via -module below, .mod files) are kept per-build-mode
# (obj/release, obj/debug) so switching between `make` and `make BUILD=debug`
# never links stale objects built with different flags, and .mod files from one
# mode never get picked up while compiling the other. This also keeps .mod
# files out of the project root entirely. The final binary always lands at
# bin/phasefield either way, so `cd bin && ./phasefield` keeps working
# regardless of which mode produced it.
objdir := obj/$(BUILD)
bindir := bin

ifeq ($(BUILD),debug)
	optflags := -O0 -g -Mbounds -Mchkptr -traceback
	gpu_extra := ,debug,lineinfo
else ifeq ($(BUILD),release)
	optflags := -O3 -fast
	gpu_extra :=
else
	$(error Unknown BUILD '$(BUILD)' -- use BUILD=release or BUILD=debug)
endif

# maxregcount:64 is not a diagnostic flag -- it's the permanent fix for the
# collision_h register-overshoot bug documented above, and applies to every
# build mode so no kernel can silently fail to launch regardless of BUILD.
cudaflags := -cuda -gpu=$(gpu_target),maxregcount:64$(gpu_extra) $(optflags) -module $(objdir)
ldflags := -cuda -gpu=$(gpu_target),maxregcount:64$(gpu_extra) $(optflags)
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
	
	
