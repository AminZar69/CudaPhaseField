project := phasefield
cc := nvfortran
# -cuda enables CUDA Fortran (this nvfortran version has retired -Mcuda in favor
# of -cuda + -gpu=...).
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
cudaflags := -cuda -gpu=cc61
ldflags := -cuda -gpu=cc61
srcdir := src
objdir := obj
bindir := bin
objects	:= $(objdir)/precision_m.o $(objdir)/host_var.o $(objdir)/device_var.o $(objdir)/host_subroutines.o $(objdir)/global_subroutines.o $(objdir)/main.o 

all: $(project)

####Linking####
$(project): $(objects) 
	$(cc) $(objects) -o $(bindir)/$(project) $(ldflags)
	
####Compilation####	
# precision_m.f90 is plain Fortran (no CUDA Fortran syntax), so no CUDA flags needed here.
$(objdir)/precision_m.o: $(srcdir)/precision_m.f90
	$(cc) -c $(srcdir)/precision_m.f90 -o $(objdir)/precision_m.o 
	
$(objdir)/host_var.o: $(srcdir)/host_var.cuf
	$(cc) $(cudaflags) -c $(srcdir)/host_var.cuf -o $(objdir)/host_var.o
	
$(objdir)/device_var.o: $(srcdir)/device_var.cuf
	$(cc) $(cudaflags) -c $(srcdir)/device_var.cuf -o $(objdir)/device_var.o
	
$(objdir)/host_subroutines.o: $(srcdir)/host_subroutines.cuf
	$(cc) $(cudaflags) -c $(srcdir)/host_subroutines.cuf -o $(objdir)/host_subroutines.o
	
$(objdir)/global_subroutines.o: $(srcdir)/global_subroutines.cuf
	$(cc) $(cudaflags) -c $(srcdir)/global_subroutines.cuf -o $(objdir)/global_subroutines.o
	
$(objdir)/main.o: $(srcdir)/main.cuf
	$(cc) $(cudaflags) -c $(srcdir)/main.cuf -o $(objdir)/main.o 
########
	
clean:	
	rm -rf *mod 
	rm -f $(objdir)/*
	rm -f $(bindir)/*