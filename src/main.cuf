!============================== License GPLv3 ===================================
!    CudaPhaseField is three-component flow solver based on th lattice Boltzmann method which runs on the NVIDIA GPU.
!    Copyright (C) 2021 Amin Zar, aminpopjoury@gmail.com


!    This program is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.

!    This program is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.

!    You should have received a copy of the GNU General Public License
!    along with this program.  If not, see <https://www.gnu.org/licenses/>.
!================================================================================

program main
	use cudafor
	use precision_m
	use device_var
	use host_var
	use host_subroutines
	use global_subroutines
	implicit none
	real(fp_kind) :: t1, t2
	type (cudaevent) :: startevent, stopevent
	real :: time
	integer :: istat
	type(dim3) :: grid , tblock

	istat = cudaEventCreate ( startEvent )
	istat = cudaEventCreate ( stopEvent )
	
	!call host_allocation
	!call device_allocation
	call set_host
	call initialize_populations_host
	
	!=========================================================================================
	print '(/a7,6a12/)', 't', 'phi3_min', 'phi3_max', 'ux_max', 'uy_max', '|u_max|', 'total_mass'
	!=========================================================================================
	is_solid_node = is_solid_nodehost

	tblock = dim3(32, 32, 1) ! for static declaration
	!tblock = dim3(16, 16, 1) ! for dynamic declaration
	
	grid = dim3(ceiling(real (nx+2)/tblock%x ), &
	ceiling(real(ny+2)/tblock%y), 1)
	

	
	
	ux = uxhost
	uy = uyhost
	phi1 = phi1_host
	phi2 = phi2_host
	phi3 = phi3_host
	rho = rhohost
	p = phost
	
	istat = cudaEventRecord(startEvent, 0)
	do t = 0, tf
			
				

		h1 = h1_host
		h2 = h2_host
		g  = g_host
		
		
		call phi_cal<<<grid,tblock>>>
		call periodic_phi<<<grid,tblock>>>
		call gradient_cal<<<grid,tblock>>>
		call interface_cal<<<grid,tblock>>>
		call chemical_potential<<<grid,tblock>>>
		call hydro_cal<<<grid,tblock>>>
		call collision_h<<<grid,tblock>>>
		call collision_g1<<<grid,tblock>>>
		call collision_g2<<<grid,tblock>>>
		call periodic_f<<<grid,tblock>>>
		call propagation_h<<<grid,tblock>>>
		call propagation_h2<<<grid,tblock>>>
		call propagation_g<<<grid,tblock>>>
		call propagation_g2<<<grid,tblock>>>
		
	
		
		

		
		
		h1_host = h1
		h2_host = h2
		g_host  = g
		
		
		
		
		if( mod(t,1000)==0 )then	
		
			phi1_host = phi1
			phi2_host = phi2
			phi3_host = phi3
			rhohost = rho
			uxhost = ux
			uyhost = uy
			phost = p
			
			
		
			
			print '(i7,2f12.6,3e12.3,f11.2)', &
				t, minval(phi3_host), &
				maxval(phi3_host), &
				maxval(abs(uxhost)), &
				maxval(abs(uyhost)), &
				sqrt( maxval(uxhost**2+uyhost**2) ), &
				(sum(phi1_host(1:nx, 1:ny)) + sum(phi2_host(1:nx, 1:ny))+ sum(phi3_host(1:nx, 1:ny)))
		end if
		
		
		
		
		
		
		

		if( mod(t,step)==0 )then
			call results_output_host
		end if
  end do
  
	


  istat = cudaEventRecord(stopEvent, 0)
  istat = cudaEventSynchronize (stopEvent)
  istat = cudaEventElapsedTime (time , startEvent , stopEvent )
   
  print '(/a)',' *****************************************'
		write (* ,*) 'Time for kernel execution (s): ' , time/1000.
  print '( a)',' *****************************************'
  istat = cudaEventDestroy (startEvent)
  istat = cudaEventDestroy (stopEvent)
end	