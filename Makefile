project := phasefield
cc := nvfortran
ldflags := -Mcuda
srcdir := src
objdir := obj
bindir := bin
objects	:= $(objdir)/precision_m.o $(objdir)/host_var.o $(objdir)/device_var.o $(objdir)/host_subroutines.o $(objdir)/global_subroutines.o $(objdir)/main.o 

all: $(project)

####Linking####
$(project): $(objects) 
	$(cc) $(objects) -o $(bindir)/$(project) $(ldflags)
	
####Compilation####	
$(objdir)/precision_m.o: $(srcdir)/precision_m.f90
	$(cc) -c $(srcdir)/precision_m.f90 -o $(objdir)/precision_m.o 
	
$(objdir)/host_var.o: $(srcdir)/host_var.cuf
	$(cc) -c $(srcdir)/host_var.cuf -o $(objdir)/host_var.o
	
$(objdir)/device_var.o: $(srcdir)/device_var.cuf
	$(cc) -c $(srcdir)/device_var.cuf -o $(objdir)/device_var.o
	
$(objdir)/host_subroutines.o: $(srcdir)/host_subroutines.cuf
	$(cc) -c $(srcdir)/host_subroutines.cuf -o $(objdir)/host_subroutines.o
	
$(objdir)/global_subroutines.o: $(srcdir)/global_subroutines.cuf
	$(cc) -c $(srcdir)/global_subroutines.cuf -o $(objdir)/global_subroutines.o
	
$(objdir)/main.o: $(srcdir)/main.cuf
	$(cc) -c $(srcdir)/main.cuf -o $(objdir)/main.o 
########
	
clean:	
	rm -rf *mod 
	rm -f $(objdir)/*
	rm -f $(bindir)/*
	
	
	