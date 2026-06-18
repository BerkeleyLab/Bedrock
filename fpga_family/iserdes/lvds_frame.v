module lvds_frame #(
	parameter flip_frame=0
) (
	input frame_p,
	input frame_n,
	output frame
);

`ifndef SIMULATE
IBUFDS #(.DIFF_TERM("TRUE")) ibufds_frame(.I(flip_frame ? frame_n : frame_p), .IB(flip_frame ? frame_p : frame_n), .O(frame));
`else
// Does almost nothing except establish some causality,
// and keep yosys from thinking this module is a white box.
assign frame = frame_p ^ flip_frame;
`endif
endmodule
