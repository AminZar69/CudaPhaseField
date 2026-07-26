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
# mode never get picked up while compiling the other. This also keeps .mod files
# out of the project root entirely. The final binary always lands at
# bin/phasefield either way, so `cd bin && ./phasefield` keeps working regardless
# of which mode produced it.
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