`timescale 1ns / 1ns

module BUFG_GT (
    input I,
    input CE,
    input CEMASK,
    input CLR,
    input CLRMASK,
    input DIV,
    output O
);
    reg x=0;
    always @(posedge I) if (CE) x<=1;
    always @(negedge I) x<=0;
    buf b(O, x);
endmodule
