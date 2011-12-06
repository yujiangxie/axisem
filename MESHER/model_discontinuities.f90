module model_discontinuities

  use data_bkgrdmodel

  implicit none

  public :: define_discont
  private

  contains

!--------------------------------------------------------------------------
subroutine define_discont

! wrapper routine to call different model types for number of layers ndisc, 
! discontinuity radii discont(1:ndisc), and corresponding velocities 
! vp(1:ndisc,1:2) and vs(1:ndisc,1:2), where e.g. vs(2,1) is the shear 
! velocity at the top of the 2nd domain (just below discont(2), and 
! vs(2,2) is the shear velocity at the bottom of the 2nd domain discont(3).

select case(bkgrdmodel)
case('ak135')
  write(6,*)'Reading AK135 discontinuities...';call flush(6)
  call ak135_discont
case('prem')
  write(6,*)'Reading PREM discontinuities...';call flush(6)  
  call prem_discont
case('prem_solid')
  write(6,*)'Reading PREM_SOLID discontinuities...';call flush(6)  
   call prem_solid_discont
case('prem_light')
  write(6,*)'Reading PREM_LIGHT discontinuities...';call flush(6)  
  call prem_light_discont   
case('prem_onecrust')
  write(6,*)'Reading PREM_ONECRUST discontinuities...';call flush(6)  
  call prem_onecrust_discont
case('prem_solid_light')
  write(6,*)'Reading PREM_SOLID_LIGHT discontinuities...';call flush(6)  
  call prem_solid_light_discont
case('iasp91')
  write(6,*)'Reading IASP91 discontinuities...';call flush(6)  
  call iasp91_discont
case('solar')
  write(6,*)'Reading solar stealth discontinuities...';call flush(6)  
  call solar_discont
case default
  write(6,*)'Reading step-wise model from file:',bkgrdmodel
  call arbitr_discont
end select

end subroutine define_discont
!--------------------------------------------------------------------------

!--------------------------------------------------------------------------
subroutine ak135_discont
! Kennett et al., 1995: Constrains on seismic velocities in the Earth

ndisc=9

allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2))

! upper crust
discont(1)=6371.
vp(1,:)=5.8
vs(1,:)=3.46

! lower crust
discont(2)=6351.
vp(2,:)=6.5
vs(2,:)=3.85

! moho -> 210
discont(3)=6336.
vp(3,1)=8.04
vs(3,1)=4.48
vp(3,2)=8.3
vs(3,2)=4.518

! 210 -> 410
discont(4)=6161.
vp(4,1)=8.3
vs(4,1)=4.523
vp(4,2)=9.03
vs(4,2)=4.870

! 410 -> 660
discont(5)=5961.
vp(5,1)=9.36
vs(5,1)=5.08
vp(5,2)=10.2
vs(5,2)=5.61

! 660 -> D''
discont(6)=5711.
vp(6,1)=10.79
vs(6,1)=5.96
vp(6,2)=13.649
vs(6,2)=7.249

! D'' -> outer core
discont(7)=3631.
vp(7,1)=13.649
vs(7,1)=7.249
vp(7,2)=13.66
vs(7,2)=7.281

! outer core -> inner core
discont(8)=3479.5
vp(8,1)=8.0
vs(8,1)=0.0
vp(8,2)=10.289
vs(8,2)=0.0

! inner core
discont(9)=1217.5
vp(9,1)=11.043
vs(9,1)=3.504
vp(9,2)=11.262
vs(9,2)=3.668

! numbering relates to regions within, i.e. counting numbers as in discont
! for regions above the respective discontinuities

vp=vp*1000.
vs=vs*1000.
discont=discont*1000.

end subroutine ak135_discont


subroutine prem_discont

! PREM discontinuities to be honored by the mesh
! each index represents the layer *below* its corresponding discontinuity

ndisc=11

allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2))

! UPPER CRUST
discont(1)=6371.
vp(1,:)=5.8
vs(1,:)=3.2

! LOWER CRUST
discont(2)=6356.
vp(2,:)=6.8
vs(2,:)=3.9

! MOHO --> 220
discont(3)=6346.6
vp(3,1)=8.1106
vs(3,1)=4.4910
vp(3,2)=7.9897
vs(3,2)=4.4189

! TRANSITION ZONE: 220 --> 400
discont(4)=6151.
vp(4,1)=8.55895
vs(4,1)=4.64390
vp(4,2)=8.90524
vs(4,2)=4.76990

! 400 --> 600
discont(5)=5971.
vp(5,1)=9.133917
vs(5,1)=4.932487
vp(5,2)=10.15783
vs(5,2)=5.515931

! 600 --> 670
discont(6)=5771.
vp(6,1)=10.15776
vs(6,1)=5.516017
vp(6,2)=10.26617
vs(6,2)=5.570211

! 670 --> 770
discont(7)=5701.
vp(7,1)=10.7513
vs(7,1)=5.9451
vp(7,2)=11.0656
vs(7,2)=6.2405

!LOWER MANTLE: 770 --> TOP D"
discont(8)=5600.
vp(8,1)=11.0656
vs(8,1)=6.2404
vp(8,2)=13.6804
vs(8,2)=7.2659

! D" LAYER
discont(9)=3630.
vp(9,1)=13.6805
vs(9,1)=7.2660
vp(9,2)=13.7166
vs(9,2)=7.2647

! FLUID OUTER CORE: CMB --> ICB
discont(10)=3480.
vp(10,1)=8.0650
vs(10,1)=0.0
vp(10,2)=10.3557
vs(10,2)=0.0

! SOLID INNER CORE: ICB --> CENTER
discont(11)=1221.5
vp(11,1)=11.0283
vs(11,1)=3.5043
vp(11,2)=11.2622
vs(11,2)=3.6678

! numbering relates to regions within, i.e. counting numbers as in discont
! for regions above the respective discontinuities

vp=vp*1000.
vs=vs*1000.
discont=discont*1000.

end subroutine prem_discont
!--------------------------------------------------------------------------

!--------------------------------------------------------------------------
subroutine prem_solid_discont

! PREM discontinuities to be honored by the mesh
! each index represents the layer *below* its corresponding discontinuity

ndisc=11

allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2))

! UPPER CRUST

discont(1)=6371.
vp(1,:)=5.8
vs(1,:)=3.2

! LOWER CRUST
discont(2)=6356.
vp(2,:)=6.8
vs(2,:)=3.9

! MOHO --> 220
discont(3)=6346.6
vp(3,1)=8.1106
vs(3,1)=4.4910
vp(3,2)=7.9897
vs(3,2)=4.4189

! TRANSITION ZONE: 220 --> 400
discont(4)=6151.
vp(4,1)=8.55895
vs(4,1)=4.64390
vp(4,2)=8.90524
vs(4,2)=4.76990

! 400 --> 600
discont(5)=5971.
vp(5,1)=9.133917
vs(5,1)=4.932487
vp(5,2)=10.15783
vs(5,2)=5.515931

! 600 --> 670
discont(6)=5771.
vp(6,1)=10.15776
vs(6,1)=5.516017
vp(6,2)=10.26617
vs(6,2)=5.570211

! 670 --> 770
discont(7)=5701.
vp(7,1)=10.7513
vs(7,1)=5.9451
vp(7,2)=11.0656
vs(7,2)=6.2405

!LOWER MANTLE: 770 --> TOP D"
discont(8)=5600.
vp(8,1)=11.0656
vs(8,1)=6.2404
vp(8,2)=13.6804
vs(8,2)=7.2659

! D" LAYER
discont(9)=3630.
vp(9,1)=13.6805
vs(9,1)=7.2660
vp(9,2)=13.7166
vs(9,2)=7.2647

! FLUID OUTER CORE: CMB --> ICB
discont(10)=3480.
vp(10,1)=8.0650
vs(10,1)=vp(10,1)/sqrt(3.)
vp(10,2)=10.3557
vs(10,2)=vp(10,2)/sqrt(3.)

! SOLID INNER CORE: ICB --> CENTER
discont(11)=1221.5
vp(11,1)=11.0283
vs(11,1)=3.5043
vp(11,2)=11.2622
vs(11,2)=3.6678

! numbering relates to regions within, i.e. counting numbers as in discont
! for regions above the respective discontinuities

vp=vp*1000.
vs=vs*1000.
discont=discont*1000.

end subroutine prem_solid_discont
!--------------------------------------------------------------------------

!--------------------------------------------------------------------------
subroutine prem_onecrust_discont

! PREM discontinuities to be honored by the mesh
! but with lower crust extended to the surface
! each index represents the layer *below* its corresponding discontinuity

ndisc=10

allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2))

! ONE CRUST
discont(1)=6371.
vp(1,:)=5.8
vs(1,:)=3.2

! MOHO --> 220
discont(2)=6346.6
vp(2,1)=8.1106
vs(2,1)=4.4910
vp(2,2)=7.9897
vs(2,2)=4.4189

! TRANSITION ZONE: 220 --> 400
discont(3)=6151.
vp(3,1)=8.55895
vs(3,1)=4.64390
vp(3,2)=8.90524
vs(3,2)=4.76990

! 400 --> 600
discont(4)=5971.
vp(4,1)=9.133917
vs(4,1)=4.932487
vp(4,2)=10.15783
vs(4,2)=5.515931

! 600 --> 670
discont(5)=5771.
vp(5,1)=10.15776
vs(5,1)=5.516017
vp(5,2)=10.26617
vs(5,2)=5.570211

! 670 --> 770
discont(6)=5701.
vp(6,1)=10.7513
vs(6,1)=5.9451
vp(6,2)=11.0656
vs(6,2)=6.2405

!LOWER MANTLE: 770 --> TOP D"
discont(7)=5600.
vp(7,1)=11.0656
vs(7,1)=6.2404
vp(7,2)=13.6804
vs(7,2)=7.2659

! D" LAYER
discont(8)=3630.
vp(8,1)=13.6805
vs(8,1)=7.2660
vp(8,2)=13.7166
vs(8,2)=7.2647

! FLUID OUTER CORE: CMB --> ICB
discont(9)=3480.
vp(9,1)=8.0650
vs(9,1)=0.0
vp(9,2)=10.3557
vs(9,2)=0.0

! SOLID INNER CORE: ICB --> CENTER
discont(10)=1221.5
vp(10,1)=11.0283
vs(10,1)=3.5043
vp(10,2)=11.2622
vs(10,2)=3.6678

! numbering relates to regions within, i.e. counting numbers as in discont
! for regions above the respective discontinuities

vp=vp*1000.
vs=vs*1000.
discont=discont*1000.

end subroutine prem_onecrust_discont
!--------------------------------------------------------------------------


!--------------------------------------------------------------------------
subroutine prem_light_discont

! PREM LIGHT discontinuities to be honored by the mesh:
! isotropic PREM without the crust, extending the upper mantle to the surface
! each index represents the layer *below* its corresponding discontinuity

ndisc=9

allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2))

! 0 --> 220
discont(1)=6371.
vp(1,1)=8.1257
vs(1,1)=4.5000
vp(1,2)=7.9897
vs(1,2)=4.4189

! TRANSITION ZONE: 220 --> 400
discont(2)=6151.
vp(2,1)=8.55895
vs(2,1)=4.64390
vp(2,2)=8.90524
vs(2,2)=4.76990

! 400 --> 600
discont(3)=5971.
vp(3,1)=9.133917
vs(3,1)=4.932487
vp(3,2)=10.15783
vs(3,2)=5.515931

! 600 --> 670
discont(4)=5771.
vp(4,1)=10.15776
vs(4,1)=5.516017
vp(4,2)=10.26617
vs(4,2)=5.570211

! 670 --> 770
discont(5)=5701.
vp(5,1)=10.7513
vs(5,1)=5.9451
vp(5,2)=11.0656
vs(5,2)=6.2405

!LOWER MANTLE: 770 --> TOP D"
discont(6)=5600.
vp(6,1)=11.0656
vs(6,1)=6.2404
vp(6,2)=13.6804
vs(6,2)=7.2659

! D" LAYER
discont(7)=3630.
vp(6,1)=13.6805
vs(7,1)=7.2660
vp(7,2)=13.7166
vs(7,2)=7.2647

! FLUID OUTER CORE: CMB --> ICB
discont(8)=3480.
vp(8,1)=8.0650
vs(8,1)=0.0
vp(8,2)=10.3557
vs(8,2)=0.0

! SOLID INNER CORE: ICB --> CENTER
discont(9)=1221.5
vp(9,1)=11.0283
vs(9,1)=3.5043
vp(9,2)=11.2622
vs(9,2)=3.6678

! numbering relates to regions within, i.e. counting numbers as in discont
! for regions above the respective discontinuities

vp=vp*1000.
vs=vs*1000.
discont=discont*1000.

end subroutine prem_light_discont
!--------------------------------------------------------------------------

!--------------------------------------------------------------------------
subroutine prem_solid_light_discont

! PREM LIGHT discontinuities to be honored by the mesh:
! isotropic PREM without the crust, extending the upper mantle to the surface
! No fluid outer core, but instead vs=vp/sqrt(3)
! each index represents the layer *below* its corresponding discontinuity

ndisc=9

allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2))

! 0 --> 220
discont(1)=6371.
vp(1,1)=8.1257
vs(1,1)=4.5000
vp(1,2)=7.9897
vs(1,2)=4.4189

! TRANSITION ZONE: 220 --> 400
discont(2)=6151.
vp(2,1)=8.55895
vs(2,1)=4.64390
vp(2,2)=8.90524
vs(2,2)=4.76990

! 400 --> 600
discont(3)=5971.
vp(3,1)=9.133917
vs(3,1)=4.932487
vp(3,2)=10.15783
vs(3,2)=5.515931

! 600 --> 670
discont(4)=5771.
vp(4,1)=10.15776
vs(4,1)=5.516017
vp(4,2)=10.26617
vs(4,2)=5.570211

! 670 --> 770
discont(5)=5701.
vp(5,1)=10.7513
vs(5,1)=5.9451
vp(5,2)=11.0656
vs(5,2)=6.2405

!LOWER MANTLE: 770 --> TOP D"
discont(6)=5600.
vp(6,1)=11.0656
vs(6,1)=6.2404
vp(6,2)=13.6804
vs(6,2)=7.2659

! D" LAYER
discont(7)=3630.
vp(6,1)=13.6805
vs(7,1)=7.2660
vp(7,2)=13.7166
vs(7,2)=7.2647

! FLUID OUTER CORE: CMB --> ICB
discont(8)=3480.
vp(8,1)=8.0650
vs(8,1)=vp(8,1)/sqrt(3.)
vp(8,2)=10.3557
vs(8,2)=vp(8,2)/sqrt(3.)

! SOLID INNER CORE: ICB --> CENTER
discont(9)=1221.5
vp(9,1)=11.0283
vs(9,1)=3.5043
vp(9,2)=11.2622
vs(9,2)=3.6678

! numbering relates to regions within, i.e. counting numbers as in discont
! for regions above the respective discontinuities

vp=vp*1000.
vs=vs*1000.
discont=discont*1000.

end subroutine prem_solid_light_discont
!--------------------------------------------------------------------------


!--------------------------------------------------------------------------
subroutine iasp91_discont

! IASP91 discontinuities to be honored by the mesh
! each index represents the layer *below* its corresponding discontinuity

! Tabulated all media parameters just above and below discontinuities
!!$    radius         v_p              v_s            rho
!!$   6371.000       5.800000       3.360000       2.720000    
!!$   6351.000       6.500000       3.750000       2.920000    
!!$   6336.010       6.500000       3.750000       2.920000    
!!$   6335.990       8.039999       4.470003       3.319806    
!!$   6291.010       8.045291       4.485878       3.347059    
!!$   6290.990       8.045293       4.485885       3.347071    
!!$   6251.010       8.049996       4.499995       3.371294    
!!$   6250.990       8.050032       4.500002       3.370357    
!!$   6161.010       8.299976       4.517998       3.360578    
!!$   6160.990       8.300035       4.522027       3.429809    
!!$   5961.010       9.029963       4.869992       3.549229    
!!$   5960.990       9.360033       5.070020       3.931578    
!!$   5711.010       10.19997       5.599978       3.989790    
!!$   5710.990       10.79003       5.950025       4.374491    
!!$   5611.010       11.05577       6.209453       4.436460    
!!$   5610.990       11.05585       6.209506       4.436472    
!!$   3631.010       13.65642       7.264518       5.490973    
!!$   3630.990       13.65640       7.264504       5.490983    
!!$   3482.010       13.69080       7.301500       5.565448    
!!$   3481.990       8.008780      0.0000000E+00   9.900254    
!!$   1217.010       10.25781      0.0000000E+00   12.16863    
!!$   1216.990       11.09145       3.438566       12.76601    
!!$  9.9999998E-03   11.24094       3.564540       13.08850  

ndisc=11

allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2))

! UPPER CRUST
discont(1)=6371.
vp(1,:)=5.8
vs(1,:)=3.36

! LOWER CRUST
discont(2)=6351.
vp(2,:)=6.5
vs(2,:)=3.75

! MOHO --> 120
discont(3)=6336.
vp(3,1)=8.04
vs(3,1)=4.47
vp(3,2)=8.049996
vs(3,2)=4.499995 

! 120 --> 220
discont(4)=6251.
vp(4,1)=8.050032
vs(4,1)=4.500002
vp(4,2)=8.299976
vs(4,2)=4.517998

! 220 --> 400
discont(5)=6161.
vp(5,1)=8.300035
vs(5,1)=4.522027
vp(5,2)=9.029963
vs(5,2)=4.869992

! 400 --> 660
discont(6)=5961.
vp(6,1)=9.360033
vs(6,1)=5.070020
vp(6,2)=10.19997
vs(6,2)=5.599978

! 660 --> 771
discont(7)=5711.
vp(7,1)=10.79003 
vs(7,1)=5.950025
vp(7,2)=11.05577
vs(7,2)=6.209453

! 771 --> D"
discont(8)=5611.
vp(8,1)=11.05585
vs(8,1)=6.209506
vp(8,2)=13.65642
vs(8,2)=7.264518

! D" --> CMB
discont(9)=3631.
vp(9,1)=13.65640
vs(9,1)=7.264504
vp(9,2)=13.69080
vs(9,2)=7.301500

! CMB --> ICB
discont(10)=3482.
vp(10,1)=8.008780
vs(10,1)=0.0
vp(10,2)=10.25781 
vs(10,2)=0.0

! ICB --> CENTER
discont(11)=1217.
vp(11,1)=11.09145
vs(11,1)=3.438566
vp(11,2)=11.24094
vs(11,2)=3.564540

! numbering relates to regions within, i.e. counting numbers as in discont
! for regions above the respective discontinuities

vp=vp*1000.
vs=vs*1000.
discont=discont*1000.

end subroutine iasp91_discont
!--------------------------------------------------------------------------


!--------------------------------------------------------------------------
subroutine arbitr_discont

! discontinuities (read in from a file) to be honored by the mesh

integer :: idom
logical :: bkgrdmodelfile_exists
double precision :: disc1,disc2,rho2,vp2,vs2

! Does the file bkgrdmodel".bm" exist?
inquire(file=bkgrdmodel(1:index(bkgrdmodel,' ')-1)//'.bm', &
        exist=bkgrdmodelfile_exists)

if (bkgrdmodelfile_exists) then
   open(unit=77,file=bkgrdmodel(1:index(bkgrdmodel,' ')-1)//'.bm')

   read(77,*)ndisc
   allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2),rho(ndisc,2))
   do idom=1, ndisc
      read(77,*)discont(idom),rho(idom,1),vp(idom,1),vs(idom,1)
   enddo
   close(77)

! add stealth layer to keep central square "down there"
!af : ok, I see
   if (ndisc==1) then 
      ndisc=2
      disc1=discont(1)
      disc2=discont(1)/4.d0
      rho2=rho(1,1)
      vp2=vp(1,1)
      vs2=vs(1,1)
      deallocate(discont,vp,vs,rho)
      allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2),rho(ndisc,2))
      discont(1)=disc1; discont(2)=disc2
      rho(:,1)=rho2; vp(:,1)=vp2; vs(:,1)=vs2
      write(6,*)'Added a second stealth layer to keep central square small'
   endif

   rho(:,2)=rho(:,1); vp(:,2)=vp(:,1); vs(:,2)=vs(:,1);

else
   write(6,*)'ERROR IN BACKGROUND MODEL: ', &
              bkgrdmodel(1:index(bkgrdmodel,' ')-1),' NON-EXISTENT!'
   write(6,*)'...failed to open file', &
             bkgrdmodel(1:index(bkgrdmodel,' ')-1)//'.bm'
   stop 
endif

end subroutine arbitr_discont
!--------------------------------------------------------------------------

!--------------------------------------------------------------------------
subroutine solar_discont
use data_grid, only: ri
! discontinuities (read in from a file) to be honored by the mesh

integer :: idom,ndisctmp,ii,ind
logical :: bkgrdmodelfile_exists
double precision :: disc1,disc2,rho2,vp2,vs2
double precision, allocatable :: vptmp(:,:),vstmp(:,:),rhotmp(:,:),disconttmp(:)
double precision ::  ddisc

! Does the file bkgrdmodel".bm" exist?
inquire(file=bkgrdmodel(1:index(bkgrdmodel,' ')-1)//'.bm', &
        exist=bkgrdmodelfile_exists)

ndisc=10

if (bkgrdmodelfile_exists) then
   open(unit=77,file=bkgrdmodel(1:index(bkgrdmodel,' ')-1)//'.bm')
   read(77,*)ndisctmp
   allocate(disconttmp(ndisctmp),vptmp(ndisctmp,2),vstmp(ndisctmp,2),rhotmp(ndisctmp,2))
   do idom=1, ndisctmp
      read(77,*)disconttmp(idom),rhotmp(idom,1),vptmp(idom,1),vstmp(idom,1)
   enddo
   close(77)

! create stealth discontinuities
   allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2),rho(ndisc,2))
   discont(1)=maxval(disconttmp)
   ddisc=discont(1)*(0.6d0)/(ndisc+1)
   do idom=2,ndisc
      discont(idom)=discont(1)-dble(idom)*ddisc
      write(6,*)discont(idom),discont(idom)/discont(1)
   enddo

do idom=1,ndisc
   ind=minloc(abs(disconttmp-discont(idom)),1)
   write(6,*)'previous/new discont:',idom,discont(idom),disconttmp(ind)
   discont(idom)=disconttmp(ind)
   vp(idom,1)=vptmp(ind,1)
   vs(idom,1)=vstmp(ind,1)
   rho(idom,1)=rhotmp(ind,1)
  write(6,*)'vp/vs/rho:',vp(idom,1),vs(idom,1),rho(idom,1)
enddo

deallocate(vstmp,vptmp,rhotmp,disconttmp)

! add stealth layer to keep central square "down there"
!af : ok, I see
   if (ndisc==1) then 
      ndisc=2
      disc1=discont(1)
      disc2=discont(1)/4.
      rho2=rho(1,1)
      vp2=vp(1,1)
      vs2=vs(1,1)
      deallocate(discont,vp,vs,rho)
      allocate(discont(ndisc),vp(ndisc,2),vs(ndisc,2),rho(ndisc,2))
      discont(1)=disc1; discont(2)=disc2
      rho(:,1)=rho2; vp(:,1)=vp2; vs(:,1)=vs2
      write(6,*)'Added a second stealth layer to keep central square small'
   endif

   rho(:,2)=rho(:,1); vp(:,2)=vp(:,1); vs(:,2)=vs(:,1);

else
   write(6,*)'ERROR IN BACKGROUND MODEL: ', &
              bkgrdmodel(1:index(bkgrdmodel,' ')-1),' NON-EXISTENT!'
   write(6,*)'...failed to open file', &
             bkgrdmodel(1:index(bkgrdmodel,' ')-1)//'.bm'
   stop 
endif

end subroutine solar_discont
!--------------------------------------------------------------------------


end module model_discontinuities