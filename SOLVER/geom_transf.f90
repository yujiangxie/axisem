!=====================
  module geom_transf
!=====================

  use data_mesh
  use data_mesh_preloop
  use subpar_mapping
  use analytic_mapping

  implicit none
  public :: jacobian,alpha,beta
  public :: gamma1,delta,epsilon1,zeta
  public :: alphak,betak,gammak
  public :: deltak,epsilonk,zetak
  public :: jacobian_srf, quadfunc_map,grad_quadfunc_map
  public :: mgrad_pointwise,mgrad_pointwisek
  public :: mapping,s_over_oneplusxi_axis

  logical, parameter :: ana_map=.true. ! We employ analytical mapping here.

  private 
!
  contains
!//////////////////////////////////////////////////////////
!
!dk mapping----------------------------------------------------------
  double precision function mapping(xil,etal,nodes_crd,iaxis,ielem0)
!
  integer          :: iaxis,ielem0
  double precision :: xil,etal,nodes_crd(8,2)!,dumbdummy

  if (     ana_map) mapping = mapping_anal(xil,etal,nodes_crd,iaxis,ielem0)
  if (.not.ana_map) mapping = mapping_subpar(xil,etal,nodes_crd,iaxis) 

!  if(ielem0==1 ) then 
!     dumbdummy=mapping_anal(xi,eta,nodes_crd,iaxis,ielem0)
!     write(6,*)'IELGEOM:',ana_map,xi,eta,dumbdummy
!  endif
  
  if ( iaxis == 1 .and. dabs(mapping/router) < 1.d-12 ) mapping = 0.d0 

  end function mapping
!
!--------------------------------------------------------------------
!
!dk quadfunc_map--------------------------------------------
  double precision function quadfunc_map(p,s,z,nodes_crd,ielem0)
!
!        This routines computes the 
!quadratic functional (s-s(xi,eta))**2 + (z-z(xi,eta))**2
!
  integer :: ielem0
  double precision :: p(2), s,z, nodes_crd(8,2)
!
  if (     ana_map) quadfunc_map = quadfunc_map_anal(p,s,z,nodes_crd,ielem0)
  if (.not.ana_map) quadfunc_map = quadfunc_map_subpar(p,s,z,nodes_crd) 

  end function quadfunc_map
!
!-----------------------------------------------------------------
!
!dk grad_quadfunc_map------------------------------------------
  subroutine grad_quadfunc_map(grd,p,s,z,nodes_crd,ielem0)
!
!       This routine returns the gradient of the quadratic
!functional associated with the mapping.
!
  integer :: ielem0
  double precision :: grd(2),p(2), s,z, nodes_crd(8,2)

  if (     ana_map) call grad_quadfunc_map_anal(grd,p,s,z,nodes_crd,ielem0)
  if (.not.ana_map) call grad_quadfunc_map_subpar(grd,p,s,z,nodes_crd)

  end subroutine grad_quadfunc_map
!
!--------------------------------------------------------------
!
!dk s_over_oneplusxi_axis--------------------------------------------
  double precision function s_over_oneplusxi_axis(xil,etal,nodes_crd,ielem0)
! 
! This routine returns the value of the quantity
!  
!              s/(1+xi) 
!
! when the associated element lies along the axis of 
! symmetry, in the case of an analytical transformation. 
  
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map)s_over_oneplusxi_axis=s_over_oneplusxi_axis_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map)s_over_oneplusxi_axis=s_over_oneplusxi_axis_subpar(xil,etal,nodes_crd) 

  end function s_over_oneplusxi_axis
!
!--------------------------------------------------------------------


!=========================================================================
! -----TARJE-----------
!=========================================================================
!!$!dk one_over_oneplusxi_axis--------------------------------------------
!!$  double precision function one_over_oneplusxi_axis(xi,eta,nodes_crd,ielem0)
!!$! 
!!$! This routine returns the value of the quantity
!!$!  
!!$!              1/(1+xi) 
!!$!
!!$! when the associated element lies along the axis of 
!!$! symmetry, in the case of an analytical transformation. 
!!$  
!!$  integer :: ielem0
!!$  double precision :: xi, eta, nodes_crd(8,2)
!!$! WRONG WRONG WRONG: STILL HAVE TO DEFINE SUBPARAM FOR ONE_OVER_....!!!!!!!!!!!!!!!!!!!!!
!!$  if (.not.ana_map)one_over_oneplusxi_axis=one_over_oneplusxi_axis_subpar(xi,eta,nodes_crd) 
!!$  if (     ana_map)one_over_oneplusxi_axis=one_over_oneplusxi_axis_anal(xi,eta,nodes_crd,ielem0)
!!$
!!$  end function one_over_oneplusxi_axis
!--------------------------------------------------------------------
!=========================================================================
! -----END TARJE-----------
!=========================================================================


!
!dk jacobian----------------------------------------------------
  double precision function jacobian(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) jacobian = jacobian_anal(xil,etal,nodes_crd,ielem0)   
  if (.not.ana_map) jacobian = jacobian_subpar(xil,etal,nodes_crd)

  end function jacobian
!----------------------------------------------------------------
!
!dk jacobian_srf------------------------------------------------------------
  double precision function jacobian_srf(xil,crdedge,ielem0)
!
!       This routine computes the Jacobian of the transformation
!that maps [-1,+1] into a portion of the boundary of domain.  
!
  integer :: ielem0
  double precision :: xil, crdedge(3,2)

  if (     ana_map) then
     if (eltype(ielem0) /= 'linear') &
         jacobian_srf = jacobian_srf_anal(xil,crdedge)  
     if (eltype(ielem0) == 'linear') &
         jacobian_srf = jacobian_srf_subpar(xil,crdedge)  
  end if
  if (.not.ana_map) jacobian_srf = jacobian_srf_subpar(xil,crdedge)

!
  end function jacobian_srf
!---------------------------------------------------------------------------
!
!dk alphak------------------------------------------------------
  double precision function alphak(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) alphak = alphak_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) alphak = alphak_subpar(xil,etal,nodes_crd)

  end function alphak
!---------------------------------------------------------------
!
!dk betak------------------------------------------------------
  double precision function betak(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) betak = betak_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) betak = betak_subpar(xil,etal,nodes_crd)

  end function betak
!---------------------------------------------------------------
!
!dk gammak------------------------------------------------------
  double precision function gammak(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) gammak = gammak_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) gammak = gammak_subpar(xil,etal,nodes_crd)

  end function gammak
!---------------------------------------------------------------
!
!dk deltak------------------------------------------------------
  double precision function deltak(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) deltak = deltak_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) deltak = deltak_subpar(xil,etal,nodes_crd)

  end function deltak
!---------------------------------------------------------------
!
!dk epsilonk----------------------------------------------------
  double precision function epsilonk(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) epsilonk = epsilonk_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) epsilonk = epsilonk_subpar(xil,etal,nodes_crd)

  end function epsilonk
!---------------------------------------------------------------
!
!dk zetak------------------------------------------------------
  double precision function zetak(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) zetak = zetak_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) zetak = zetak_subpar(xil,etal,nodes_crd)
 
  end function zetak
!---------------------------------------------------------------
!
!dk alpha------------------------------------------------------
  double precision function alpha(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) alpha = alpha_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) alpha = alpha_subpar(xil,etal,nodes_crd)

  end function alpha
!---------------------------------------------------------------
!
!dk beta------------------------------------------------------
  double precision function beta(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) beta = beta_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) beta = beta_subpar(xil,etal,nodes_crd)

  end function beta
!---------------------------------------------------------------
!
!dk gamma1------------------------------------------------------
  double precision function gamma1(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) gamma1 = gamma_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) gamma1 = gamma_subpar(xil,etal,nodes_crd)

  end function gamma1
!---------------------------------------------------------------
!
!dk delta------------------------------------------------------
  double precision function delta(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) delta = delta_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) delta = delta_subpar(xil,etal,nodes_crd)

  end function delta
!---------------------------------------------------------------
!
!dk epsilon1----------------------------------------------------
  double precision function epsilon1(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

  if (     ana_map) epsilon1 = epsilon_anal(xil,etal,nodes_crd,ielem0)
  if (.not.ana_map) epsilon1 = epsilon_subpar(xil,etal,nodes_crd)

  end function epsilon1
!---------------------------------------------------------------
!
!dk zeta------------------------------------------------------
  double precision function zeta(xil,etal,nodes_crd,ielem0)
!
  integer :: ielem0
  double precision :: xil, etal, nodes_crd(8,2)

 if (     ana_map) zeta = zeta_anal(xil,etal,nodes_crd,ielem0)
 if (.not.ana_map) zeta = zeta_subpar(xil,etal,nodes_crd)

  end function zeta
!---------------------------------------------------------------
!
!dk mgrad_pointwise------------------------------------------------------
  subroutine mgrad_pointwise(mg,xil,etal,nodes_crd,ielem0)
!
! This routines returns the following matrix:
!                      +                     +
!                      |(ds/dxi)  | (ds/deta)|
!    mg =  s(xi,eta) * | ---------|--------- |(xi,eta)
!                      |(dz/dxi ) | (dz/deta)|
!                      +                     +
!       This 2*2 matrix is needed when defining and storing
!gradient/divergence related arrays.

  implicit none

  integer :: ielem0
  double precision :: mg(2,2)
  double precision :: xil, etal, nodes_crd(8,2)

  if(     ana_map) call mgrad_pointwise_anal(mg,xil,etal,nodes_crd,ielem0)
  if(.not.ana_map) call mgrad_pointwise_subpar(mg,xil,etal,nodes_crd)

  end subroutine mgrad_pointwise
!---------------------------------------------------------------------------
!
!dk mgrad_pointwisek------------------------------------------------------
  subroutine mgrad_pointwisek(mg,xil,etal,nodes_crd,ielem0)
!
! This routines returns the following matrix:
!          +                     +
!          |(ds/dxi)  | (ds/deta)|
!    mg =  | ---------|--------- |(xi,eta)
!          |(dz/dxi ) | (dz/deta)|
!          +                     +
!       This 2*2 matrix is needed when defining and storing
!gradient/divergence related arrays.

  implicit none

  integer :: ielem0
  double precision :: mg(2,2)
  double precision :: xil, etal, nodes_crd(8,2)

  if(     ana_map) call mgrad_pointwisek_anal(mg,xil,etal,nodes_crd,ielem0)
  if(.not.ana_map) call mgrad_pointwisek_subpar(mg,xil,etal,nodes_crd)

  end subroutine mgrad_pointwisek
!---------------------------------------------------------------------------
!
!//////////////////////////////////////////////////////////
!
!=========================
  end module geom_transf
!=========================