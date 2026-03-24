module IOBUF #(
    parameter integer DRIVE = 12,
    parameter IOSTANDARD = "DEFAULT",
    parameter SLEW = "SLOW"
) (
	output O,
	inout IO,
	input I,
	input T
);
	bufif0 t (IO, I, T);
	buf b (O, IO);
endmodule
