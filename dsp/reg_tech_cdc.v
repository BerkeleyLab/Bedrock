`timescale 1ns / 1ns

// I'm not going to write a test bench for this module,
// but rather assume that if this breaks,
// all the modules that use it will also break.
module reg_tech_cdc(
    input I,
    input C,
    output O
);
parameter POST_STAGES=1;

// Probably OK to stack up various vendor-specific attributes here.
// If incompatibilities are discovered, maybe they can be addressed
// with preprocessor magic.
// Worst-case, you can make a pin-compatible module that
// does black-block instantiation.
(* ASYNC_REG = "TRUE" *) (* magic_cdc *) reg r1=0;
(* ASYNC_REG = "TRUE" *) reg r2=0;
always @(posedge C) begin
    r1 <= I;
    r2 <= r1;
end
assign O = (POST_STAGES==0) ? r1 : r2;

endmodule
