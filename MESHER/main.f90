!
!    Copyright 2013, Tarje Nissen-Meyer, Alexandre Fournier, Martin van Driel
!                    Simon Stähler, Kasra Hosseini, Stephanie Hempel
!
!    This file is part of AxiSEM.
!    It is distributed from the webpage <http://www.axisem.info>
!
!    AxiSEM is free software: you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by
!    the Free Software Foundation, either version 3 of the License, or
!    (at your option) any later version.
!
!    AxiSEM is distributed in the hope that it will be useful,
!    but WITHOUT ANY WARRANTY; without even the implied warranty of
!    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
!    GNU General Public License for more details.
!
!    You should have received a copy of the GNU General Public License
!    along with AxiSEM.  If not, see <http://www.gnu.org/licenses/>.
!

program gllmesh

  use data_grid
  use data_bkgrdmodel,  only: have_fluid,have_solid

  use meshgen,          only : generate_skeleton    ! creates mesh skeleton
  use gllmeshgen                                    ! creates complete gll mesh
  use input
  use numbering
  use pdb,              only : create_pdb
  use test_bkgrdmodel
  use discont_meshing
  use mesh_info
  use parallelization
  use data_mesh

  implicit none

  integer tock, tick

  tick = time()
  
  !- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  ! Need to load/predefine:
  ! 1) points per wavelength
  ! 2) dominant period
  ! 3) bkgrdmodel & discontinuity radii
  call read_params ! input
  !- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  write(6,*)'MAIN: creating subregions/discontinuity model..........'; call flush(6)
  call create_subregions ! discont_meshing

  southern = .true. 

  write(6,*)'MAIN: generating skeleton..............................'; call flush(6)
  call generate_skeleton ! meshgen

  write(6,*)'MAIN: creating gllmesh.................................'; call flush(6)
  call create_gllmesh ! gllmeshgen
  !call test_mapping   ! gllmeshgen

  write(6,*)'MAIN: glob-glob numbering..............................'; call flush(6)
  call define_global_global_numbering ! numbering

  write(6,*)'MAIN: defining regions.................................'; call flush(6)
  call define_regions ! mesh_info

  write(6,*)'MAIN: test model.......................................'; call flush(6)
  call bkgrdmodel_testing ! test_bkgrdmodel

  ! Here starts the distinction between solid and fluid regions
  write(6,*)'MAIN: define subregions................................'; call flush(6)
  call def_fluid_regions ! mesh_info
  call def_solid_regions ! mesh_info
  call extract_fluid_solid_submeshes ! gllmeshgen
  
  write(6,*)'MAIN: glob-slob/flob numbering.........................'; call flush(6)
  if (have_fluid) &
       call define_global_flobal_numbering  ! numbering
  if (have_solid) &
       call define_global_slobal_numbering  ! numbering

  ! Boundary matrices: find corresponding element neighbors
  write(6,*)'MAIN: boundaries.......................................'; call flush(6)
  call define_boundaries  ! mesh_info

  ! Parallelization
  write(6,*)'MAIN: domain decomposition.............................'; call flush(6)
  call create_domain_decomposition !parallelization
 
  write(6,*)'MAIN: creating parallel database.......................'; call flush(6)
  call create_pdb ! pdb

  ! clean up
  call empty_data_mesh
  tock = time()

  write(6,*)''
  write(6,*)'....DONE WITH MESHER !'
  write(6,*)'    Runtime: ', tock-tick, ' s'

end program gllmesh
