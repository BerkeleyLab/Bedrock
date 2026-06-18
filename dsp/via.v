// https://adaptivesupport.amd.com/s/question/0D52E00006iHrFnSAK/synthesizable-verilog-connecting-inout-pins?language=en_US
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
