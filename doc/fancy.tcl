# I am officially no longer a tcl programmer
set fn [ gtkwave::getDumpFileName ]
set n1 [ string length $fn ]
set n2 [ string last ".vcd" $fn ]
if { $n2+4==$n1 } { set fpng [ string range $fn 0 [ expr $n2-1 ] ] } else { set fpng $fn }
append fpng "_timing.png"
gtkwave::/File/Grab_To_File $fpng
gtkwave::/File/Quit
