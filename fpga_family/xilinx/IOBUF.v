module IOBUF (
	output O,
	inout IO,
	input I,
	input T
);
	bufif0 t (IO, I, T);
	buf b (O, IO);
endmodule
