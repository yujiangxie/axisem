!==================================
  module analytic_spheroid_mapping
!==================================
!
!	08/02/2002: This module contains the 
! machinery necessary to describe analytically
! the transformation of the reference element
! into its deformed image in the spheroidal 
! enveloppe. 
! 
    use global_parameters 
   use data_mesh, only : smallval
  implicit none
  public :: map_spheroid,comp_partial_deriv_spheroid
  private
  contains
!//////////////////////////////////////////

!dk map_spheroid------------------------------------------------------
  double precision function map_spheroid(xi,eta,crd_nodes,idir)
!
!	We are working in polar coordinates here: theta
! is the latitude. 
!
  double precision :: xi, eta
  double precision, dimension(8,2),intent(in) :: crd_nodes
  integer :: idir

  double precision :: abot,bbot,atop,btop
  double precision :: thetabarbot,dthetabot 
  double precision :: thetabartop,dthetatop 
  double precision :: sbot,zbot,stop,ztop
  double precision :: sbar,ds,slope,intersect

!  write(61,*)'map_spheroid!'

  map_spheroid = zero
  call compute_parameters_sph(crd_nodes,abot,bbot,atop,btop,&
                              thetabarbot,dthetabot,thetabartop,dthetatop)

  call compute_sz_xi(sbot,zbot,xi,abot,bbot,thetabarbot,dthetabot)
  call compute_sz_xi(stop,ztop,xi,atop,btop,thetabartop,dthetatop)

  sbar = half*(sbot+stop); ds = stop-sbot

!  write(61,*)
! write(61,*)'ds,sbar:',ds,sbar
 
  if (idir == 1) then
!     write(61,*)'Direction 1!'
     map_spheroid = sbar+ds*eta*half

  elseif (idir == 2) then
!     write(61,*)'Direction 2!'
     if (dabs(ds)>smallval) then
!        write(61,*)'abs > smallval... intersect and slope'
     intersect = (zbot*stop-ztop*sbot)/ds   
     slope = (ztop-zbot)/ds
     map_spheroid = slope*(sbar+half*ds*eta)+intersect 
     else
     map_spheroid = half*(zbot+ztop)+eta*(ztop-zbot)*half
     end if
!     write(61,*)'stop,sbot:',stop,sbot
!     write(61,*)'ztop,zbot:',ztop,zbot
  end if
!  write(61,*)'map_spheroid',map_spheroid
!write(61,*)''

  end function map_spheroid
!----------------------------------------------------------------------
!
!dk comp_partial_deriv_spheroid-----------------------
  subroutine comp_partial_deriv_spheroid(dsdxi,dzdxi,dsdeta,dzdeta,xi,eta,&
                                         nodes_crd)

  double precision, intent(out) :: dsdxi,dzdxi,dsdeta,dzdeta
  double precision, intent(in) :: xi,eta
  double precision, dimension(8,2),intent(in) :: nodes_crd

  double precision :: abot,bbot,atop,btop
  double precision :: thetabarbot,dthetabot
  double precision :: thetabartop,dthetatop
  double precision :: sbot,zbot,stop,ztop
  double precision :: sbar,ds,dz,slope,intersect,sxieta
  double precision :: dsbotdxi,dzbotdxi
  double precision :: dstopdxi,dztopdxi
  double precision :: dsbardxi,ddsdxi
  double precision :: dzbardxi,ddzdxi
  double precision :: dslopedxi,dintersectdxi
!
  call compute_parameters_sph(nodes_crd,abot,bbot,atop,btop,&
                              thetabarbot,dthetabot,thetabartop,dthetatop)

  call compute_sz_xi(sbot,zbot,xi,abot,bbot,thetabarbot,dthetabot)
  call compute_sz_xi(stop,ztop,xi,atop,btop,thetabartop,dthetatop)

  sbar = half*(sbot+stop); ds = stop-sbot ; dz = ztop - zbot

  call compute_dsdxi_dzdxi(dsbotdxi,dzbotdxi,xi,abot,bbot,thetabarbot,dthetabot)
  call compute_dsdxi_dzdxi(dstopdxi,dztopdxi,xi,atop,btop,thetabartop,dthetatop)

  dsbardxi = half*(dsbotdxi+dstopdxi)
  ddsdxi = (dstopdxi-dsbotdxi)
 
  dzbardxi = half*(dzbotdxi+dztopdxi)
  ddzdxi = (dztopdxi-dzbotdxi) 
  sxieta = sbar+ds*eta*half

!--------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>
   dsdxi = dsbardxi + half*eta*ddsdxi
  dsdeta = half*ds
!--------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>
!
  if (dabs(ds)>smallval) then
!--------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     intersect = (zbot*stop-ztop*sbot)/ds
     slope = dz/ds
     dslopedxi = (ddzdxi*ds-ddsdxi*dz)/ds**2
     dintersectdxi = ((dzbotdxi*stop-dztopdxi*sbot     &
                       +zbot*dstopdxi-ztop*dsbotdxi)*ds &
                      -ddsdxi*(zbot*stop-ztop*sbot))/ds**2
     dzdxi = (dz/ds)*dsdxi+ sxieta*dslopedxi + dintersectdxi
     dzdeta = (dz/ds)*dsdeta  
!--------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  else
!--------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     dzdxi = zero
    dzdeta = half*dz
!--------->>>>>>>>>>>>>>>>>>>>>>>>>>>>>
  end if

  end subroutine comp_partial_deriv_spheroid
!--------------------------------------------------------------
!
!dk compute_sz_xi------------------------------------------------------
  subroutine compute_sz_xi(s,z,xi,a,b,thetabar,dtheta)

  double precision, intent(out) :: s,z
  double precision, intent(in) :: xi, a, b, thetabar,dtheta
  
  s = a*dcos(thetabar+xi*half*dtheta)
  z = b*dsin(thetabar+xi*half*dtheta)

  end subroutine compute_sz_xi
!----------------------------------------------------------------------
!
!dk compute_dsdxi_dzdxi---------------------------
  subroutine compute_dsdxi_dzdxi(dsdxi,dzdxi,xi,a,b,thetabar,dtheta)

  double precision, intent(out) :: dsdxi,dzdxi
  double precision, intent(in) :: xi,a,b,thetabar,dtheta 

  dsdxi =-a*half*dtheta*dsin(thetabar+xi*half*dtheta)
  dzdxi = b*half*dtheta*dcos(thetabar+xi*half*dtheta)  
 
  end subroutine compute_dsdxi_dzdxi
!-------------------------------------------------
!
!dk compute_parameters_sph---------------------------------
  subroutine compute_parameters_sph(crd_nodes,abot,bbot,atop,btop,&
                              thetabarbot,dthetabot,thetabartop,dthetatop)

  double precision, dimension(8,2),intent(in) :: crd_nodes
  double precision,intent(out) :: abot,bbot,atop,btop
  double precision,intent(out) :: thetabarbot,dthetabot
  double precision,intent(out) :: thetabartop,dthetatop
  double precision :: s1,z1,s3,z3,s5,z5,s7,z7
  double precision :: theta1,theta3,theta5,theta7
!  
  s1 = crd_nodes(1,1) ; z1 = crd_nodes(1,2)
  s3 = crd_nodes(3,1) ; z3 = crd_nodes(3,2)
  s5 = crd_nodes(5,1) ; z5 = crd_nodes(5,2)
  s7 = crd_nodes(7,1) ; z7 = crd_nodes(7,2)
!
  call compute_ab(abot,bbot,s1,z1,s3,z3)
  call compute_theta(theta1,s1,z1,abot,bbot)
  call compute_theta(theta3,s3,z3,abot,bbot) 
!
  call compute_ab(atop,btop,s7,z7,s5,z5)
  call compute_theta(theta5,s5,z5,atop,btop) 
  call compute_theta(theta7,s7,z7,atop,btop) 
!
  thetabarbot = half*(theta1+theta3)
  dthetabot = theta3-theta1
  thetabartop = half*(theta7+theta5)
  dthetatop = theta5 -theta7
!
  end subroutine compute_parameters_sph
!----------------------------------------------------------
!
!dk compute_ab--------------------------------------
  subroutine compute_ab(a,b,s1,z1,s2,z2)

  double precision, intent(out) :: a,b
  double precision, intent(in) :: s1,z1,s2,z2
!
  a = dsqrt(dabs((s2**2*z1**2-z2**2*s1**2)/(z1**2-z2**2)))
  b = dsqrt(dabs((z1**2*s2**2-z2**2*s1**2)/(s2**2-s1**2))) 
  end subroutine compute_ab
!---------------------------------------------------

!---------------------------------------------------

!dk compute_theta---------------------------
subroutine compute_theta(theta,s,z,a,b)
!
!       This routine returns the latitude theta, given s and z.
!
  implicit none
  double precision , intent(out) :: theta
  double precision , intent(in) :: s,z,a,b
!
  double precision :: pi2
!
  pi2 = two*dasin(one) ! TNM has no clue why it doesnt work with the pre-set parameter pi.....

  if (s /=zero ) then
     theta=datan(z*a/(s*b))
  else
     if (z>zero) theta=half*pi2
     if (z<zero) theta=-half*pi2
  end if
!
end subroutine compute_theta

!=======================================
  end module analytic_spheroid_mapping
!=======================================