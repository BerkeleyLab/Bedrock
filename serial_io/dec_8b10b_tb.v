// Gives some simple cross-check of dec_8b10b against
// tables published in Wikipedia
//   https://en.wikipedia.org/wiki/8b10b
// and also gives a mechanism to convert 10b codes (supplied in a file)
// to human-readable form.
// XXX still kind of raw

module dec_8b10b_tb;

reg clk;
reg fail=0;
integer cc;
integer infile=0;
reg [255:0] init_file;
reg disp;
integer checked=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("dec_8b10b.vcd");
		$dumpvars(5, dec_8b10b_tb);
	end
	if ($value$plusargs("init_file=%s", init_file)) begin
		infile = $fopen(init_file, "r");
	end
	if (!$value$plusargs("init_disp=%s", disp)) disp=0;
	for (cc=0; cc<200; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	if (checked < 10) fail=1;
	if (fail) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish(0);
	end
end

integer rc, inp;
reg valid;
reg [9:0] i10;
always @(posedge clk) begin
	valid <= 0;
	if (infile) begin
		rc = $fscanf(infile, "%x\n", inp);
		if (rc==1) begin
			i10 <= inp;
			valid <= 1;
		end
	end
end

wire [5:0] abcdei = {i10[0], i10[1], i10[2], i10[3], i10[4], i10[5]};
wire [3:0] fghj   = {i10[6], i10[7], i10[8], i10[9]};

reg [4:0] edcba;
reg ki, vi;
always @(*) case (abcdei)
   6'b100111: begin edcba = 5'b00000; ki=0; vi=1; end
   6'b011000: begin edcba = 5'b00000; ki=0; vi=1; end
   6'b011101: begin edcba = 5'b00001; ki=0; vi=1; end
   6'b100010: begin edcba = 5'b00001; ki=0; vi=1; end
   6'b101101: begin edcba = 5'b00010; ki=0; vi=1; end
   6'b010010: begin edcba = 5'b00010; ki=0; vi=1; end
   6'b110001: begin edcba = 5'b00011; ki=0; vi=1; end
   6'b110101: begin edcba = 5'b00100; ki=0; vi=1; end
   6'b001010: begin edcba = 5'b00100; ki=0; vi=1; end
   6'b101001: begin edcba = 5'b00101; ki=0; vi=1; end
   6'b011001: begin edcba = 5'b00110; ki=0; vi=1; end
   6'b111000: begin edcba = 5'b00111; ki=0; vi=1; end
   6'b000111: begin edcba = 5'b00111; ki=0; vi=1; end
   6'b111001: begin edcba = 5'b01000; ki=0; vi=1; end
   6'b100101: begin edcba = 5'b01001; ki=0; vi=1; end
   6'b010101: begin edcba = 5'b01010; ki=0; vi=1; end
   6'b110100: begin edcba = 5'b01011; ki=0; vi=1; end
   6'b001101: begin edcba = 5'b01100; ki=0; vi=1; end
   6'b101100: begin edcba = 5'b01101; ki=0; vi=1; end
   6'b011100: begin edcba = 5'b01110; ki=0; vi=1; end
   6'b010111: begin edcba = 5'b01111; ki=0; vi=1; end
   6'b101000: begin edcba = 5'b01111; ki=0; vi=1; end
   6'b011011: begin edcba = 5'b10000; ki=0; vi=1; end
   6'b100100: begin edcba = 5'b10000; ki=0; vi=1; end
   6'b100011: begin edcba = 5'b10001; ki=0; vi=1; end
   6'b010011: begin edcba = 5'b10010; ki=0; vi=1; end
   6'b110010: begin edcba = 5'b10011; ki=0; vi=1; end
   6'b001011: begin edcba = 5'b10100; ki=0; vi=1; end
   6'b101010: begin edcba = 5'b10101; ki=0; vi=1; end
   6'b011010: begin edcba = 5'b10110; ki=0; vi=1; end
   6'b111010: begin edcba = 5'b10111; ki=0; vi=1; end
   6'b000101: begin edcba = 5'b10111; ki=0; vi=1; end
   6'b110011: begin edcba = 5'b11000; ki=0; vi=1; end
   6'b001100: begin edcba = 5'b11000; ki=0; vi=1; end
   6'b100110: begin edcba = 5'b11001; ki=0; vi=1; end
   6'b010110: begin edcba = 5'b11010; ki=0; vi=1; end
   6'b110110: begin edcba = 5'b11011; ki=0; vi=1; end
   6'b001001: begin edcba = 5'b11011; ki=0; vi=1; end
   6'b001110: begin edcba = 5'b11100; ki=0; vi=1; end
   6'b101110: begin edcba = 5'b11101; ki=0; vi=1; end
   6'b010001: begin edcba = 5'b11101; ki=0; vi=1; end
   6'b011110: begin edcba = 5'b11110; ki=0; vi=1; end
   6'b100001: begin edcba = 5'b11110; ki=0; vi=1; end
   6'b101011: begin edcba = 5'b11111; ki=0; vi=1; end
   6'b010100: begin edcba = 5'b11111; ki=0; vi=1; end
   6'b001111: begin edcba = 5'b11100; ki=1; vi=1; end
   6'b110000: begin edcba = 5'b11100; ki=1; vi=1; end
   default:   begin edcba = 5'bxxxxx; ki=0; vi=0; end
endcase

// Relatively brain-dead accounting for disparity flowing through
// the 5b/6b part of the decoder, to pass on to the 3b/4b part below.
reg [2:0] sum6;
reg disp6, disp6e;
always @(*) begin
	sum6 = abcdei[0] + abcdei[1] + abcdei[2] + abcdei[3] + abcdei[4] + abcdei[5];
	case (sum6)
		3'd2:    begin disp6=0;    disp6e=~disp; end
		3'd3:    begin disp6=disp; disp6e=0;     end // no change
		3'd4:    begin disp6=1;    disp6e=disp;  end
		default: begin disp6=disp; disp6e=1;     end // bad
	endcase
end

reg [2:0] hgf;
reg vj;
wire [5:0] KRDfghj = {ki, disp6, fghj};
always @(*) case (KRDfghj)
   6'b00_1011:  begin hgf = 3'b000; vj=1; end
   6'b01_0100:  begin hgf = 3'b000; vj=1; end
   6'b00_1001:  begin hgf = 3'b001; vj=1; end
   6'b01_1001:  begin hgf = 3'b001; vj=1; end
   6'b00_0101:  begin hgf = 3'b010; vj=1; end
   6'b01_0101:  begin hgf = 3'b010; vj=1; end
   6'b00_1100:  begin hgf = 3'b011; vj=1; end
   6'b01_0011:  begin hgf = 3'b011; vj=1; end
   6'b00_1101:  begin hgf = 3'b100; vj=1; end
   6'b01_0010:  begin hgf = 3'b100; vj=1; end
   6'b00_1010:  begin hgf = 3'b101; vj=1; end
   6'b01_1010:  begin hgf = 3'b101; vj=1; end
   6'b00_0110:  begin hgf = 3'b110; vj=1; end
   6'b01_0110:  begin hgf = 3'b110; vj=1; end
   6'b00_0111:  begin hgf = 3'b111; vj=1; end
   6'b01_1000:  begin hgf = 3'b111; vj=1; end
   6'b10_1011:  begin hgf = 3'b000; vj=1; end
   6'b11_0100:  begin hgf = 3'b000; vj=1; end
   6'b10_0110:  begin hgf = 3'b001; vj=1; end
   6'b11_1001:  begin hgf = 3'b001; vj=1; end
   6'b10_1010:  begin hgf = 3'b010; vj=1; end
   6'b11_0101:  begin hgf = 3'b010; vj=1; end
   6'b10_1100:  begin hgf = 3'b011; vj=1; end
   6'b11_0011:  begin hgf = 3'b011; vj=1; end
   6'b10_1101:  begin hgf = 3'b100; vj=1; end
   6'b11_0010:  begin hgf = 3'b100; vj=1; end
   6'b10_0101:  begin hgf = 3'b101; vj=1; end
   6'b11_1010:  begin hgf = 3'b101; vj=1; end
   6'b10_1001:  begin hgf = 3'b110; vj=1; end
   6'b11_0110:  begin hgf = 3'b110; vj=1; end
   6'b10_0111:  begin hgf = 3'b111; vj=1; end
   6'b11_1000:  begin hgf = 3'b111; vj=1; end
   default:     begin hgf = 3'bxxx; vj=0; end
endcase

reg [2:0] sum4;
reg disp4, disp4e;
always @(*) begin
	sum4 = fghj[0] + fghj[1] + fghj[2] + fghj[3];
	case (sum4)
		3'd1:    begin disp4=0;     disp4e=~disp6; end
		3'd2:    begin disp4=disp6; disp4e=0;      end
		3'd3:    begin disp4=1;     disp4e=disp6;  end
		default: begin disp4=disp6; disp4e=1;      end
	endcase
end

wire t_valid = vi & vj;
wire [8:0] o9 = {ki, hgf, edcba};

wire dispout;
wire [8:0] d9;
wire code_err, disp_err;
dec_8b10b dut(.datain(i10), .dispin(disp),
	.dataout(d9), .dispout(dispout),
	.code_err(code_err), .disp_err(disp_err));
always @(posedge clk) if (valid) disp <= dispout;

reg match;
always @(negedge clk) begin
	if (valid) begin
		match = o9 == d9;
		$display(" %3x   %b %b   %s.%d.%d  %x   %s.%d.%d  %x  %s",
		i10, abcdei, fghj,
		ki?"K":"D", edcba, hgf, o9,
		d9[8]?"K":"D", d9[4:0], d9[7:5], d9, match?".":"*");
		if (!match) fail=1;
		checked += 1;
	end
end

endmodule
