!================
module commun
!================
!
! This is the communication module which loads/sorts data
! to exchange/examine over the processors.
!
! APRIL 2007:
! At this level, we only call parallel routines, but do not invoke MPI here. 
! This simplifies the construction of a completely serial code in that we 
! only need to decide here whether to call a parallel routine or not.
! It also means that a simulation on one processor, but using the full 
! parallel code in fact never utilizes the parallel routines. 
!
! To make this code purely serial: ---------------------------------------
! 1) remove module commpi.f90
! 2) comment out "use commpi"
! 3) comment out any lines containing "if (nproc>1)"
!    (marked "comment out for serial" below)
! 4) change the Makefile to compile with regular Fortran compiler, not mpif90
!         and delete any entries for commpi
!    alternatively: use the perl script makemake.pl after changing its entry 
!                   to the fortran compiler instead of mpif90 
! -------------------------------------------------------------------------
  
use global_parameters
use data_mesh, ONLY : gvec_solid,gvec_fluid
use commpi ! comment out for serial
use data_proc

implicit none
public :: comm2d ! the general assembly & communication routine
public :: assemb_sum_solid,assemb_3sum_solid ! energy in solid
public :: assemb_sum_fluid,assemb_2sum_fluid ! energy in fluid

public :: assemb_sum_solid2,assemb_3sum_solid2 ! energy in solid
public :: assemb_sum_fluid2,assemb_2sum_fluid2 ! energy in fluid
public :: glob_sum_solid,glob_sum3_solid,glob_sum_fluid

public :: assembmass_sum_solid,assembmass_sum_fluid ! assemble and sum massmat
public :: broadcast_int,broadcast_dble
public :: pinit,pend
public :: pmin,pmax,pmax_int,psum,psum_int,psum_dble
public :: barrier
public :: mpi_asynch_messaging_test_solid,mpi_asynch_messaging_test_fluid
private
contains

!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

!-----------------------------------------------------------------------------
subroutine comm2d(f,nel,nc,domainin)
!
! This is a driver routine to call the assembly of field f of dimension nc
! and either solid or fluid subdomains.
! The global assembly is discarded as it is not necessary during the time loop
! and therefore chose not to store any global numbering arrays.
! If nproc>1, then internode message passing is applied where necessary.
!
!-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

include 'mesh_params.h' 

character(len=5), intent(in)       :: domainin
integer, intent(in)                :: nc,nel
real(kind=realkind), intent(inout) :: f(0:npol,0:npol,nel,nc)

  if (domainin=='total') then
     if (lpr) then
        write(6,*)'PROBLEM: Discarded this case since igloc is not'
        write(6,*)'         known in the solver any longer...'
     endif
     stop
  elseif (domainin=='solid') then
     call pdistsum_solid(f,nc)
  elseif (domainin=='fluid') then
     call pdistsum_fluid(f)
  else
     if (lpr) &
     write(6,*)'Assembly: Domain',domainin,' non-existent!' 
     stop
  end if

end subroutine comm2d
!=============================================================================

!-----------------------------------------------------------------------------
subroutine pdistsum_solid(vec,nc)
!
! This is a driver routine to perform the assembly of field f of dimension nc
! defined in the solid. The assembly/direct stiffness summation is composed of
! the "gather" and "scatter" operations, i.e. to add up all element-edge 
! contributions at the global stage and place them back into local arrays.
! Nissen-Meyer et al., GJI 2007, "A 2-D spectral-element method...", section 4.
! If nproc>1, the asynchronous messaging scheme is invoked to additionally 
! sum & exchange values on processor boundary points.
!
!-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

use data_numbering, ONLY: igloc_solid
use data_mesh, ONLY: gvec_solid

!!!!
use data_time, ONLY : idmpi,iclockmpi
use clocks_mod
!!!!

include 'mesh_params.h' 

integer, intent(in)                :: nc
real(kind=realkind), intent(inout) :: vec(0:npol,0:npol,nel_solid,nc)
integer                            :: ic,iel,jpol,ipol,idest,ipt

! Gather
!----------
  do ic = 1, nc
!----------
     gvec_solid(:) = 0.d0
     do iel = 1, nel_solid
        do jpol = 0, npol
           do ipol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol + 1
              idest = igloc_solid(ipt)
              gvec_solid(idest) = gvec_solid(idest)+vec(ipol,jpol,iel,ic)
           end do
        end do
     end do

! Collect processor boundaries into buffer for each component
     iclockmpi = tick()
     if (nproc>1) call feed_buffer(ic) ! comment for serial
     iclockmpi = tick(id=idmpi,since=iclockmpi)

! Scatter
     do iel = 1, nel_solid
        do jpol = 0, npol
           do ipol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol + 1
              idest = igloc_solid(ipt)
              vec(ipol,jpol,iel,ic) = gvec_solid(idest)
           end do
        end do
     end do
!----------
  end do
!----------

  iclockmpi = tick()
  if (nproc>1) then
! Do message-passing for all components at once
     call send_recv_buffers_solid(nc) ! comment for serial
! Extract back into each component sequentially
     call extract_from_buffer(vec,nc) ! comment for serial
   endif ! nproc>1
   iclockmpi = tick(id=idmpi,since=iclockmpi)

end subroutine pdistsum_solid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine pdistsum_fluid(vec)
!
! This is a driver routine to perform the assembly of field f of dimension nc
! defined in the fluid. The assembly/direct stiffness summation is composed of
! the "gather" and "scatter" operations, i.e. to add up all element-edge 
! contributions at the global stage and place them back into local arrays.
! Nissen-Meyer et al., GJI 2007, "A 2-D spectral-element method...", section 4.
!
!-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

use data_numbering, ONLY: igloc_fluid

!!!!
use data_time, ONLY : idmpi,iclockmpi
use clocks_mod
!!!!

include 'mesh_params.h' 

real(kind=realkind), intent(inout) :: vec(0:npol,0:npol,nel_fluid)
integer                            :: iel,jpol,ipol,idest,ipt

  gvec_fluid(:) = 0.d0

! Gather
  do iel = 1, nel_fluid
     do jpol = 0, npol
        do ipol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol + 1
           idest = igloc_fluid(ipt)
           gvec_fluid(idest) = gvec_fluid(idest) + vec(ipol,jpol,iel) 
        end do
     end do
  end do

  iclockmpi = tick()
  if (nproc>1) call asynch_messaging_fluid ! comment for serial
  iclockmpi = tick(id=idmpi,since=iclockmpi)

! Scatter
  do iel = 1, nel_fluid
     do jpol = 0, npol
        do ipol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol + 1
           idest = igloc_fluid(ipt)
           vec(ipol,jpol,iel) = gvec_fluid(idest)
        end do
     end do
  end do

end subroutine pdistsum_fluid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine mpi_asynch_messaging_test_solid
!
! This is a driver routine to perform the assembly of field f of dimension nc
! defined in the solid. The assembly/direct stiffness summation is composed of
! the "gather" and "scatter" operations, i.e. to add up all element-edge 
! contributions at the global stage and place them back into local arrays.
! Nissen-Meyer et al., GJI 2007, "A 2-D spectral-element method...", section 4.
! If nproc>1, the asynchronous messaging scheme is invoked to additionally 
! sum & exchange values on processor boundary points.
!
! The local arrays are allocatable since this routine is only called before 
! the time loop.
! 
!-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

use data_io, ONLY: save_large_tests
use data_numbering, ONLY: igloc_solid,nglob_solid
use meshes_io, ONLY : fldout_cyl2

include 'mesh_params.h' 

real(kind=realkind),allocatable :: vec(:,:,:,:)
real(kind=realkind),allocatable :: gvec_solid2(:,:)
integer             :: ic,iel,jpol,ipol,idest,ipt
character(len=80)   :: fname 

  allocate(vec(0:npol,0:npol,nel_solid,3))
  allocate(gvec_solid2(nglob_solid,3))

  gvec_solid2(:,:) = 0.d0

!----------
  do ic = 1, 3
!----------

  vec(:,:,:,ic)=real(ic,kind=realkind)

! Gather
     do iel = 1, nel_solid
        do jpol = 0, npol
           do ipol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol + 1
              idest = igloc_solid(ipt)
              gvec_solid2(idest,ic) = vec(ipol,jpol,iel,ic)
           end do
        end do
     end do
!----------
  end do
!----------

   if (nproc>1) &
        call testing_asynch_messaging_solid(gvec_solid2,3) !comment for serial

!----------
  do ic = 1, 3
!----------
! Scatter
     do iel = 1, nel_solid
        do jpol = 0, npol
           do ipol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol + 1
              idest = igloc_solid(ipt)
              vec(ipol,jpol,iel,ic) = gvec_solid2(idest,ic)
           end do
        end do
     end do
!----------
  end do
!----------

  deallocate(gvec_solid2)

  if (save_large_tests) then
     fname = 'messagepassing_solid_1'
     call fldout_cyl2(fname,nel_solid,vec(:,:,:,1),0,npol,0,npol,0,'solid')
     fname = 'messagepassing_solid_2'
     call fldout_cyl2(fname,nel_solid,vec(:,:,:,2),0,npol,0,npol,0,'solid')  
     fname = 'messagepassing_solid_3'
     call fldout_cyl2(fname,nel_solid,vec(:,:,:,3),0,npol,0,npol,0,'solid')  

     write(69,12)appmynum
12 format("  wrote MPI test results to 'messagepassing_solid_",a4,".dat' ")
  endif

  deallocate(vec)

end subroutine mpi_asynch_messaging_test_solid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine mpi_asynch_messaging_test_fluid
!
! This is a driver routine to perform the assembly of field f of dimension nc
! defined in the fluid. The assembly/direct stiffness summation is composed of
! the "gather" and "scatter" operations, i.e. to add up all element-edge 
! contributions at the global stage and place them back into local arrays.
! Nissen-Meyer et al., GJI 2007, "A 2-D spectral-element method...", section 4.
! If nproc>1, the asynchronous messaging scheme is invoked to additionally 
! sum & exchange values on processor boundary points.
!
! The local arrays are allocatable since this routine is only called before 
! the time loop.
!
!-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

use data_io, ONLY: save_large_tests
use data_numbering, ONLY: igloc_fluid
use meshes_io, ONLY : fldout_cyl2

include 'mesh_params.h' 

real(kind=realkind),allocatable :: vec(:,:,:)
integer                         :: iel,jpol,ipol,idest,ipt
character(len=80)               :: fname 

  allocate(vec(0:npol,0:npol,nel_fluid))

  gvec_fluid(:) = 0.d0
  vec(:,:,:)=1.d0

! Gather
  do iel = 1, nel_fluid
     do jpol = 0, npol
        do ipol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol + 1
           idest = igloc_fluid(ipt)
           gvec_fluid(idest) = vec(ipol,jpol,iel)
        end do
     end do
  end do

  if (nproc>1) call testing_asynch_messaging_fluid !comment for serial

! Scatter
  do iel = 1, nel_fluid
     do jpol = 0, npol
        do ipol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol + 1
           idest = igloc_fluid(ipt)
           vec(ipol,jpol,iel) = gvec_fluid(idest)
        end do
     end do
  end do

  if (save_large_tests) then
     fname = 'messagepassing_fluid'
     call fldout_cyl2(fname,nel_fluid,vec(0:npol,0:npol,:),0,npol,0,npol,0,'fluid')
 
     write(69,12)appmynum
12 format("  wrote MPI test results to 'messagepassing_fluid_",a4,".dat' ")
  endif

  deallocate(vec)

end subroutine mpi_asynch_messaging_test_fluid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine assembmass_sum_solid(f1,res)

use data_numbering, ONLY: igloc_solid
include 'mesh_params.h'

real(kind=realkind), dimension(0:npol,0:npol,nel_solid), intent(in) :: f1
double precision, intent(out) :: res
integer ipt, idest,iel, ipol, jpol

  res=0.d0 
  gvec_solid(:) = 0.d0
  do iel = 1, nel_solid
     do ipol = 0, npol
        do jpol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
           idest = igloc_solid(ipt)
           gvec_solid(idest) = gvec_solid(idest) + dble(f1(ipol,jpol,iel))
        end do
     end do
  end do
  res = res + sum(gvec_solid(:))
  if (nproc>1) res=ppsum_dble(res) ! comment for serial

end subroutine assembmass_sum_solid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine assemb_sum_solid(f1,f2,res,nc)

use data_numbering, ONLY: igloc_solid
include 'mesh_params.h'

integer, intent(in) :: nc
real(kind=realkind), dimension(0:npol,0:npol,nel_solid,nc), intent(in) :: f1,f2
real(kind=realkind), intent(out) :: res
integer :: ic , ipt, idest
integer :: iel, ipol, jpol

  res=0.d0 
  
  do ic = 1, nc
     gvec_solid(:) = 0.d0
     do iel = 1, nel_solid
        do ipol = 0, npol
           do jpol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
              idest = igloc_solid(ipt)
              gvec_solid(idest) = gvec_solid(idest) + &
                                    f1(ipol,jpol,iel,ic) * f2(ipol,jpol,iel,ic)
           end do
        end do
     end do
     res = res + sum(gvec_solid)
  enddo

  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine assemb_sum_solid
!=============================================================================



!-----------------------------------------------------------------------------
subroutine glob_sum_solid(f1,res,nc)

use data_numbering, ONLY: igloc_solid
include 'mesh_params.h'

integer, intent(in) :: nc
real(kind=realkind), dimension(0:npol,0:npol,nel_solid,nc), intent(in) :: f1
real(kind=realkind), intent(out) :: res
integer :: ic , ipt, idest
integer :: iel, ipol, jpol

  res=0.d0

  do ic = 1, nc
     gvec_solid(:) = 0.d0
     do iel = 1, nel_solid
        do ipol = 0, npol
           do jpol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
              idest = igloc_solid(ipt)
              gvec_solid(idest) = f1(ipol,jpol,iel,ic)
           end do
        end do
     end do
     res = res + sum(gvec_solid)
  enddo

  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine glob_sum_solid
!=============================================================================



!-----------------------------------------------------------------------------
subroutine glob_sum_fluid(f1,res,nc)

use data_numbering, ONLY: igloc_fluid
include 'mesh_params.h'

integer, intent(in) :: nc 
real(kind=realkind), dimension(0:npol,0:npol,nel_fluid,nc), intent(in) :: f1
real(kind=realkind), intent(out) :: res
integer :: ic , ipt, idest
integer :: iel, ipol, jpol

  res=0.d0

  do ic = 1, nc 
     gvec_fluid(:) = 0.d0
     do iel = 1, nel_fluid
        do ipol = 0, npol
           do jpol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
              idest = igloc_fluid(ipt)
              gvec_fluid(idest) = f1(ipol,jpol,iel,ic)
           end do 
        end do
     end do
     res = res + sum(gvec_fluid)
  enddo

  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine glob_sum_fluid
!=============================================================================




!-----------------------------------------------------------------------------
subroutine glob_sum3_solid(f1,f2,res,nc)

use data_numbering, ONLY: igloc_solid,nglob_solid
include 'mesh_params.h' 

integer, intent(in) :: nc
real(kind=realkind), dimension(0:npol,0:npol,nel_solid,nc), intent(in) :: f1
real(kind=realkind), dimension(0:npol,0:npol,nel_solid), intent(in) :: f2
real(kind=realkind), intent(out) :: res
real(kind=realkind) :: gvec_solid2(nglob_solid)
integer :: ic , ipt, idest
integer :: iel, ipol, jpol

  res=0.d0

  do ic = 1, nc
     gvec_solid(:) = 0.d0
     gvec_solid2(:) = 0.d0
     do iel = 1, nel_solid
        do ipol = 0, npol
           do jpol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
              idest = igloc_solid(ipt)
              gvec_solid(idest) = f1(ipol,jpol,iel,ic)
              gvec_solid2(idest) = f2(ipol,jpol,iel)
           end do
        end do
     end do
     res = res + sum(gvec_solid*gvec_solid*gvec_solid2)
  enddo       
              
  if (nproc>1) res=ppsum(res) ! comment for serial
           
end subroutine glob_sum3_solid
!=============================================================================







!-----------------------------------------------------------------------------
subroutine assemb_sum_solid2(f1,f2,res,nc)

use data_numbering, ONLY: igloc_solid,nglob_solid
include 'mesh_params.h'

integer, intent(in) :: nc
real(kind=realkind), dimension(0:npol,0:npol,nel_solid,nc), intent(in) :: f1,f2
real(kind=realkind), intent(out) :: res
real(kind=realkind) :: gvec_solid2(nglob_solid)
integer :: ic , ipt, idest
integer :: iel, ipol, jpol

  res=0.d0 
  
  do ic = 1, nc
     gvec_solid(:) = 0.d0
     gvec_solid2(:) = 0.d0
     do iel = 1, nel_solid
        do ipol = 0, npol
           do jpol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
              idest = igloc_solid(ipt)
              gvec_solid(idest) = gvec_solid(idest) + f1(ipol,jpol,iel,ic)
              gvec_solid2(idest) = gvec_solid2(idest) + f2(ipol,jpol,iel,ic)
!              gvec_solid(idest) = f1(ipol,jpol,iel,ic)
!              gvec_solid2(idest) = f2(ipol,jpol,iel,ic)
           end do
        end do
     end do
     
     do ipt=1,nglob_solid
        res = res + gvec_solid(ipt)*gvec_solid2(ipt)
     enddo

  enddo

  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine assemb_sum_solid2
!=============================================================================


!-----------------------------------------------------------------------------
subroutine assemb_3sum_solid(f1,res,nc)

use data_matr, ONLY : inv_mass_rho 
use data_numbering, ONLY: igloc_solid
include 'mesh_params.h' 

integer, intent(in) :: nc
real(kind=realkind), dimension(0:npol,0:npol,nel_solid,nc), intent(in) :: f1
real(kind=realkind), intent(out) :: res
integer ic , ipt, idest
integer ielem, ipol, jpol

  res=0.d0
  
  do ic = 1, nc

     gvec_solid(:) = 0.d0
     do ielem = 1, nel_solid
        do ipol = 0, npol
           do jpol = 0, npol
              ipt = (ielem-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
              idest = igloc_solid(ipt)
              gvec_solid(idest) = gvec_solid(idest) + &
                                f1(ipol,jpol,ielem,ic)*f1(ipol,jpol,ielem,ic)/&
                                inv_mass_rho(ipol,jpol,ielem)
           end do
        end do
     end do

     res = res + sum(gvec_solid)

  enddo

  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine assemb_3sum_solid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine assemb_3sum_solid2(f1,res,nc)

use data_numbering, ONLY: igloc_solid,nglob_solid
use data_matr, ONLY : inv_mass_rho
include 'mesh_params.h'

integer, intent(in) :: nc
real(kind=realkind), dimension(0:npol,0:npol,nel_solid,nc), intent(in) :: f1
real(kind=realkind), intent(out) :: res
real(kind=realkind) :: gvec_solid3(nglob_solid)
integer :: ic , ipt, idest
integer :: iel, ipol, jpol

  res=0.d0 
  
  do ic = 1, nc
     gvec_solid(:) = 0.d0
     gvec_solid3(:) = 0.d0
     do iel = 1, nel_solid
        do ipol = 0, npol
           do jpol = 0, npol
              ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
              idest = igloc_solid(ipt)
              gvec_solid(idest) = gvec_solid(idest) + f1(ipol,jpol,iel,ic)
              gvec_solid3(idest)=1.d0/inv_mass_rho(ipol,jpol,iel) ! is already assembled
           end do
        end do
     end do
     
     do ipt=1,nglob_solid
        res = res + gvec_solid(ipt)*gvec_solid(ipt)*gvec_solid3(ipt)
     enddo

  enddo

  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine assemb_3sum_solid2
!=============================================================================

!-----------------------------------------------------------------------------
subroutine assembmass_sum_fluid(f1,res)

use data_numbering, ONLY: igloc_fluid
include 'mesh_params.h' 

real(kind=realkind), dimension(0:npol,0:npol,nel_fluid), intent(in) :: f1
double precision, intent(out) :: res
integer ipt, idest
integer iel, ipol, jpol

  res=0.d0
  
  gvec_fluid(:) = 0.d0
  do iel = 1, nel_fluid
     do ipol = 0, npol
        do jpol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
           idest = igloc_fluid(ipt)
           gvec_fluid(idest) = gvec_fluid(idest) + dble(f1(ipol,jpol,iel))
        end do
     end do
  end do
  res = res + sum(gvec_fluid)

  if (nproc>1) res=ppsum_dble(res) ! comment for serial

end subroutine assembmass_sum_fluid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine assemb_sum_fluid(f1,res)

use data_matr, ONLY : inv_mass_fluid
use data_numbering, ONLY: igloc_fluid
include 'mesh_params.h' 

real(kind=realkind), dimension(0:npol,0:npol,nel_fluid), intent(in) :: f1
real(kind=realkind), intent(out) :: res
integer ipt, idest
integer iel, ipol, jpol

  res=0.d0
  
  gvec_fluid(:) = 0.d0
  do iel = 1, nel_fluid
     do ipol = 0, npol
        do jpol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
           idest = igloc_fluid(ipt)
           gvec_fluid(idest) = gvec_fluid(idest) + f1(ipol,jpol,iel) * &
                            f1(ipol,jpol,iel)/inv_mass_fluid(ipol,jpol,iel)
        end do
     end do
  end do

  res = res + sum(gvec_fluid)
  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine assemb_sum_fluid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine assemb_sum_fluid2(f1,res)

use data_matr, ONLY : inv_mass_fluid
use data_numbering, ONLY: igloc_fluid
include 'mesh_params.h' 

real(kind=realkind), dimension(0:npol,0:npol,nel_fluid), intent(in) :: f1
real(kind=realkind), intent(out) :: res
real(kind=realkind) :: gvec_fluid3(nglob_fluid)
integer ipt, idest
integer iel, ipol, jpol

  res=0.d0
  
  gvec_fluid(:) = 0.d0
  gvec_fluid3(:)=0.d0
  do iel = 1, nel_fluid
     do ipol = 0, npol
        do jpol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
           idest = igloc_fluid(ipt)
           gvec_fluid(idest) = gvec_fluid(idest) + f1(ipol,jpol,iel) 
           gvec_fluid3(idest)= 1.d0/inv_mass_fluid(ipol,jpol,iel)
        end do
     end do
  end do

     do ipt=1,nglob_fluid
        res = res + gvec_fluid(ipt)*gvec_fluid(ipt)*gvec_fluid3(ipt)
     enddo

  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine assemb_sum_fluid2
!=============================================================================

!-----------------------------------------------------------------------------
subroutine assemb_2sum_fluid(f1,f2,res)

use data_numbering, ONLY: igloc_fluid
include 'mesh_params.h'

real(kind=realkind), dimension(0:npol,0:npol,nel_fluid), intent(in) :: f1,f2
real(kind=realkind), intent(out) :: res
integer ipt, idest
integer iel,ipol,jpol

  res=0.d0 
  
  gvec_fluid(:) = 0.d0
  do iel = 1, nel_fluid
     do ipol = 0, npol
        do jpol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
           idest = igloc_fluid(ipt)
           gvec_fluid(idest) = gvec_fluid(idest) + &
                               f1(ipol,jpol,iel)*f2(ipol,jpol,iel)
        end do
     end do
  end do

  res = res + sum(gvec_fluid)
  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine assemb_2sum_fluid
!=============================================================================

!-----------------------------------------------------------------------------
subroutine assemb_2sum_fluid2(f1,f2,res)

use data_matr, ONLY : inv_mass_fluid
use data_numbering, ONLY: igloc_fluid
include 'mesh_params.h' 

real(kind=realkind), dimension(0:npol,0:npol,nel_fluid), intent(in) :: f1,f2
real(kind=realkind), intent(out) :: res
real(kind=realkind) :: gvec_fluid2(nglob_fluid)
integer ipt, idest
integer iel, ipol, jpol

  res=0.d0
  
  gvec_fluid(:) = 0.d0
 gvec_fluid2(:)=0.d0
  do iel = 1, nel_fluid
     do ipol = 0, npol
        do jpol = 0, npol
           ipt = (iel-1)*(npol+1)**2 + jpol*(npol+1) + ipol+1
           idest = igloc_fluid(ipt)
           gvec_fluid(idest) = gvec_fluid(idest) + f1(ipol,jpol,iel) 
           gvec_fluid2(idest)=gvec_fluid2(idest) + f2(ipol,jpol,iel) 
!           gvec_fluid(idest) =  f1(ipol,jpol,iel) 
!           gvec_fluid2(idest)= f2(ipol,jpol,iel) 
        end do
     end do
  end do

     do ipt=1,nglob_fluid
        res = res + gvec_fluid(ipt)*gvec_fluid2(ipt)
     enddo

  if (nproc>1) res=ppsum(res) ! comment for serial

end subroutine assemb_2sum_fluid2
!=============================================================================



!-----------------------------------------------------------------------------
subroutine pinit

include 'mesh_params.h'

! Start message passing interface if parallel simulation
  if (nproc_mesh>1) then 
     call ppinit ! comment for serial
     if (nproc_mesh /= nproc) then        
        write(6,*)mynum,'Problem with number of processors!'
        write(6,*)mynum,'Mesh constructed for:', nproc_mesh
        write(6,*)mynum,'Job submission for:',nproc
        stop
     endif
  else
     nproc=nproc_mesh
     mynum=0
  endif

  lpr = .false.
  if (nproc>1) then
    if (mynum==nproc/2-1) lpr = .true.
  else
    lpr = .true.
 endif

 call define_io_appendix(appmynum,mynum)
! open(unit=50,file='procstrg.txt'//appmynum)
! write(50,12)'Proc',mynum,' '; call flush(50)
! close(50)
! open(unit=50,file='procstrg.txt'//appmynum)
! read(50,12)procstrg
! close(50)
 
 procstrg = 'Proc '//appmynum(3:4)//' '

  if (lpr) &
  write(6,*)'  Initialized run for nproc=',nproc; call flush(6)

  if (nproc>1) then ! comment for serial
     if (realkind==4) mpi_realkind = MPI_REAL ! comment for serial
    if (realkind==8) mpi_realkind = MPI_DOUBLE_PRECISION ! comment for serial
  endif ! comment for serial

end subroutine pinit
!=============================================================================

!-----------------------------------------------------------------------------
subroutine pend

! End message passing interface if parallel
  if (nproc>1) call ppend ! comment for serial

end subroutine pend
!=============================================================================

!-----------------------------------------------------------------------------
subroutine broadcast_int(input_int,input_proc)

integer, intent(in)    :: input_proc
integer, intent(inout) :: input_int

  if (nproc>1) call pbroadcast_int(input_int,input_proc) ! comment for serial
   
end subroutine broadcast_int
!=============================================================================

!-----------------------------------------------------------------------------
subroutine broadcast_dble(input_dble,input_proc)

integer, intent(in)             :: input_proc
double precision, intent(inout) :: input_dble

  if (nproc>1) call pbroadcast_dble(input_dble,input_proc) ! comment for serial

end subroutine broadcast_dble
!=============================================================================

!-----------------------------------------------------------------------------
double precision function pmin(scal)

double precision :: scal
  
  pmin=scal
  if (nproc>1) pmin=ppmin(scal) ! comment for serial

end function pmin
!=============================================================================

!-----------------------------------------------------------------------------
double precision function pmax(scal)

double precision :: scal

  pmax=scal
  if (nproc>1) pmax=ppmax(scal)  ! comment for serial

end function pmax
!=============================================================================

!-----------------------------------------------------------------------------
integer function pmax_int(scal)

integer :: scal

  pmax_int=scal
  if (nproc>1) pmax_int=ppmax_int(scal)  ! comment for serial

end function pmax_int
!=============================================================================

!-----------------------------------------------------------------------------
real(kind=realkind) function psum(scal)

real(kind=realkind) :: scal

  psum=scal
  if (nproc>1) psum=ppsum(scal) ! comment for serial

end function psum
!=============================================================================

!-----------------------------------------------------------------------------
integer function psum_int(scal)

integer :: scal

  psum_int=scal
  if (nproc>1) psum_int=ppsum_int(scal) ! comment for serial

end function psum_int
!=============================================================================

!-----------------------------------------------------------------------------
double precision function psum_dble(scal)

double precision :: scal

  psum_dble=scal
  if (nproc>1) psum_dble=ppsum_dble(scal) ! comment for serial

end function psum_dble
!=============================================================================


!-----------------------------------------------------------------------------
subroutine barrier
 
  if (nproc>1) call pbarrier ! comment for serial

end subroutine barrier
!=============================================================================

!@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

!====================
end module commun
!====================