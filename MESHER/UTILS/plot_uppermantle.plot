set size ratio -1
#set term x11
#set term postscript portrait solid "Helvetica" 24
set term postscript portrait solid 
set output "../Diags/uppermantle_grid.ps"
set noborder
set noxtics ; set noytics
#set title "Computational Mesh"
plot "../Diags/um_antipode.dat" with l lw .4
#plot "fort.1257" t'' 
#pause -1 "Hit any key to exit..."