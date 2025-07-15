module OBUFDS #(
    parameter IOSTANDARD = "DEFAULT"
) (
    output O,
    output OB,
    input I
);

buf b (O, I);
not bb (OB, I);

endmodule
