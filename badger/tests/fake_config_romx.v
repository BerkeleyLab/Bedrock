// testing substitute for ROM that is often part of our build process
// Except for these comments, and the module name change, this file was generated by
// python $BEDROCK/build-tools/reverse_json.py lb_demo_slave.v > lb_demo_map.json
// python $BEDROCK/build-tools/build_rom.py -j lb_demo_map.json -v fake_config_romx.v
module fake_config_romx(
	input clk,
	input [10:0] address,
	output [15:0] data
);
reg [15:0] dxx = 0;
assign data = dxx;
always @(posedge clk) case(address)
	11'h000: dxx <= 16'h800a;
	11'h001: dxx <= 16'hb4b7;
	11'h002: dxx <= 16'hc740;
	11'h003: dxx <= 16'hb421;
	11'h004: dxx <= 16'h908c;
	11'h005: dxx <= 16'h7a1e;
	11'h006: dxx <= 16'h69ac;
	11'h007: dxx <= 16'he66d;
	11'h008: dxx <= 16'h1153;
	11'h009: dxx <= 16'h1c1e;
	11'h00a: dxx <= 16'h8b3e;
	11'h00b: dxx <= 16'h800a;
	11'h00c: dxx <= 16'h2d78;
	11'h00d: dxx <= 16'ha08f;
	11'h00e: dxx <= 16'h259d;
	11'h00f: dxx <= 16'h4cbf;
	11'h010: dxx <= 16'h8f50;
	11'h011: dxx <= 16'h5378;
	11'h012: dxx <= 16'h0c75;
	11'h013: dxx <= 16'h5e18;
	11'h014: dxx <= 16'h6517;
	11'h015: dxx <= 16'h4951;
	11'h016: dxx <= 16'h4008;
	11'h017: dxx <= 16'h4c42;
	11'h018: dxx <= 16'h4e4c;
	11'h019: dxx <= 16'h2042;
	11'h01a: dxx <= 16'h4544;
	11'h01b: dxx <= 16'h524f;
	11'h01c: dxx <= 16'h434b;
	11'h01d: dxx <= 16'h2052;
	11'h01e: dxx <= 16'h4f4d;
	11'h01f: dxx <= 16'hc05d;
	11'h020: dxx <= 16'h78da;
	11'h021: dxx <= 16'hbdd0;
	11'h022: dxx <= 16'h4d0a;
	11'h023: dxx <= 16'h8330;
	11'h024: dxx <= 16'h1005;
	11'h025: dxx <= 16'he0bd;
	11'h026: dxx <= 16'ha790;
	11'h027: dxx <= 16'hac5d;
	11'h028: dxx <= 16'hf8d3;
	11'h029: dxx <= 16'h5ae8;
	11'h02a: dxx <= 16'h6586;
	11'h02b: dxx <= 16'h3189;
	11'h02c: dxx <= 16'h55d0;
	11'h02d: dxx <= 16'h8426;
	11'h02e: dxx <= 16'h132a;
	11'h02f: dxx <= 16'h8877;
	11'h030: dxx <= 16'h6fb4;
	11'h031: dxx <= 16'h50d2;
	11'h032: dxx <= 16'h42a9;
	11'h033: dxx <= 16'h6e92;
	11'h034: dxx <= 16'h5578;
	11'h035: dxx <= 16'h2f13;
	11'h036: dxx <= 16'h3e66;
	11'h037: dxx <= 16'h4e52;
	11'h038: dxx <= 16'h7f58;
	11'h039: dxx <= 16'h2787;
	11'h03a: dxx <= 16'h4143;
	11'h03b: dxx <= 16'hceae;
	11'h03c: dxx <= 16'he9bc;
	11'h03d: dxx <= 16'h055b;
	11'h03e: dxx <= 16'h889c;
	11'h03f: dxx <= 16'h4b6b;
	11'h040: dxx <= 16'h7dc6;
	11'h041: dxx <= 16'h0ccb;
	11'h042: dxx <= 16'h8258;
	11'h043: dxx <= 16'h0803;
	11'h044: dxx <= 16'h8f5e;
	11'h045: dxx <= 16'h50e7;
	11'h046: dxx <= 16'hab3c;
	11'h047: dxx <= 16'h286c;
	11'h048: dxx <= 16'h7f53;
	11'h049: dxx <= 16'heb6b;
	11'h04a: dxx <= 16'ha7d6;
	11'h04b: dxx <= 16'h9b14;
	11'h04c: dxx <= 16'he150;
	11'h04d: dxx <= 16'h8356;
	11'h04e: dxx <= 16'hc23a;
	11'h04f: dxx <= 16'hf935;
	11'h050: dxx <= 16'h2390;
	11'h051: dxx <= 16'hf0fd;
	11'h052: dxx <= 16'h5955;
	11'h053: dxx <= 16'h6ec5;
	11'h054: dxx <= 16'h9285;
	11'h055: dxx <= 16'ha822;
	11'h056: dxx <= 16'h0eaa;
	11'h057: dxx <= 16'h3884;
	11'h058: dxx <= 16'h2ae3;
	11'h059: dxx <= 16'ha0ca;
	11'h05a: dxx <= 16'h43a8;
	11'h05b: dxx <= 16'h2a0e;
	11'h05c: dxx <= 16'haada;
	11'h05d: dxx <= 16'h899a;
	11'h05e: dxx <= 16'h841e;
	11'h05f: dxx <= 16'hb157;
	11'h060: dxx <= 16'hd0a2;
	11'h061: dxx <= 16'h1b08;
	11'h062: dxx <= 16'hb876;
	11'h063: dxx <= 16'h8ae2;
	11'h064: dxx <= 16'h004f;
	11'h065: dxx <= 16'hbf80;
	11'h066: dxx <= 16'h45fd;
	11'h067: dxx <= 16'h01a4;
	11'h068: dxx <= 16'h095a;
	11'h069: dxx <= 16'h23ef;
	11'h06a: dxx <= 16'h7150;
	11'h06b: dxx <= 16'he79d;
	11'h06c: dxx <= 16'h5bf3;
	11'h06d: dxx <= 16'ha811;
	11'h06e: dxx <= 16'h3908;
	11'h06f: dxx <= 16'had64;
	11'h070: dxx <= 16'h1c58;
	11'h071: dxx <= 16'hbd13;
	11'h072: dxx <= 16'h665e;
	11'h073: dxx <= 16'hb0c6;
	11'h074: dxx <= 16'hb560;
	11'h075: dxx <= 16'h09c9;
	11'h076: dxx <= 16'hd938;
	11'h077: dxx <= 16'hbccb;
	11'h078: dxx <= 16'h3f5e;
	11'h079: dxx <= 16'hb224;
	11'h07a: dxx <= 16'h4f96;
	11'h07b: dxx <= 16'h6a28;
	11'h07c: dxx <= 16'hce31;
	default: dxx <= 0;
endcase
endmodule