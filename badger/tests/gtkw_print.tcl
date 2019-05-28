# I am officially no longer a tcl programmer
set fn [ gtkwave::getDumpFileName ]
set n1 [ string length $fn ]
set n2 [ string last ".vcd" $fn ]
if { $n2+4==$n1 } { set fpdf [ string range $fn 0 [ expr $n2-1 ] ] } else { set fpdf $fn }
append fpdf ".pdf"
# https://github.com/acklinr/gtkwave/blob/master/examples/des.tcl
gtkwave::/File/Print_To_File PDF {Letter (8.5" x 11")} Full $fpdf
gtkwave::/File/Quit
