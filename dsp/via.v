// https://forums.xilinx.com/t5/Welcome-Join/synthesizable-verilog-connecting-inout-pins/td-p/284628
/*module via (w, w)
inout w;
wire w;
endmodule
*/
/*
module via (.a(w1), .b(w2));
inout w1;
inout w2;
wire w;
assign w2=w1;
endmodule
*/

module via (.a(w), .b(w));
inout w;
wire w;
endmodule
