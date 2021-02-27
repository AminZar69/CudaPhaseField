## GPU-accelerated three-component lattice Boltzmann code
CudaPhaseField is a three-phase flow solver based on the lattice Boltzmann method
taking the advantage of parallel processing via the CUDA API. The code simulates
the 2D coalescence of two immiscible droplets surrounded by the third phase. The
populations are defined in a way to preserve the device memory usage in a coalesced
manner. 	
### Requirements
The nvfortran compiler along with the cuda toolkits needs to be installed to be able to run this package. For more information regarding the nvfortran installation, we kindly refer to the following link <https://docs.nvidia.com/hpc-sdk/index.html>. Moreover, since the CUDA API is utilised, an NVIDIA GPU is required to execute the device kernels on. The output files are generated in the ascii VTK format readable by the paraview which is an open-source visualisation package found via <https://www.paraview.org/download/>.
### Build and execution
    make clean
    make
    cd bin
    ./phasefield
### Example of use
Note that the simulation parameters in the host_var and device_var modules need to be set equally. In addition, the number of blocks as well as threads per block can be determined in the main program. An example of this can be found below:
#### main.cuf
    tblock = dim3(32, 32, 1) 
	grid = dim3(ceiling(real (nx+2)/tblock%x ), ceiling(real(ny+2)/tblock%y), 1)
#### host_var.cuf
    integer,parameter :: nx = 1022
    integer,parameter :: ny = 1022
	real(fp_kind),parameter :: density_host(3) = [1000., 500., 1.]
	integer,parameter :: exhost(0:8) = [0, 1, 0,-1, 0, 1,-1,-1, 1]
    integer,parameter :: eyhost(0:8) = [0, 0, 1, 0,-1, 1, 1,-1,-1]
    real(fp_kind),parameter :: wahost(0:8) = [16,4, 4, 4, 4, 1, 1, 1, 1] / 36.
    real(fp_kind),parameter :: r = 150.
    real(fp_kind),parameter :: densityhost(3) = [1000., 500., 1.]
    real(fp_kind),parameter :: sigmahost(3,3) = reshape((/0.1, 0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1/), (/3,3/))
    real(fp_kind),parameter :: landahost(3) = [(sigmahost(2,1) +  &
        sigmahost(3,1) &
        - sigmahost(3,2)) &
        , (sigmahost(2,1) + sigmahost(3,2) - sigmahost(3,1)) &
        , (sigmahost(3,1) + sigmahost(3,2) - sigmahost(2,1)) ]
    real(fp_kind),parameter :: landathost = 3. / ((1. / landahost(1)) &
        + (1. / landahost(2)) + (1. / landahost(3)))
    real(fp_kind),parameter :: whost = 4.
#### device_var.cuf
    integer, constant, parameter :: nxd = 256
	integer, constant, parameter ::	nyd = 256
    real(fp_kind), constant, parameter :: density(3) = [1000., 500., 1.]
    integer, constant, parameter :: ex(0:8) = [0, 1, 0,-1, 0, 1,-1,-1, 1]
    integer, constant, parameter :: ey(0:8) = [0, 0, 1, 0,-1, 1, 1,-1,-1]
    real(fp_kind), constant, parameter :: wa(0:8) = [16,4, 4, 4, 4, 1, 1, 1, 1] / 36.
    real(fp_kind),parameter :: sigma(3,3) = reshape((/0.1, 0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.1/), (/3,3/))
    real(fp_kind), constant, parameter :: landa(3) = [(sigma(2,1) +  &
        sigma(3,1) &
        - sigma(3,2)) &
        , (sigma(2,1) + sigma(3,2) - sigma(3,1)) &
        , (sigma(3,1) + sigma(3,2) - sigma(2,1)) ]
    real(fp_kind), constant, parameter :: landat = 3. / ((1. / landa(1)) &
        + (1. / landa(2)) + (1. / landa(3)))
    real(fp_kind), constant,parameter :: w = 4.
    


