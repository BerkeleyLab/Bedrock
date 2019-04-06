/////////////////////////////////////////////////////////
// Useful modules for performing saturating arithmetic //
/////////////////////////////////////////////////////////

// Expand a net's width
module expandWidth #(
    parameter IWIDTH = 8,
    parameter OWIDTH = 12) (
    input  wire [IWIDTH-1:0] I,
    output wire [OWIDTH-1:0] O);

wire signBit;
assign signBit = I[IWIDTH-1];
assign O = {{OWIDTH-IWIDTH{signBit}}, I};
endmodule

// Reduce a net's width
module reduceWidth #(
    parameter IWIDTH = 12,
    parameter OWIDTH = 8) (
    input  wire [IWIDTH-1:0] I,
    output reg  [OWIDTH-1:0] O);

wire signBit;
assign signBit = I[IWIDTH-1];
wire [IWIDTH-OWIDTH-1:0] checkBits;
assign checkBits = I[IWIDTH-2-:IWIDTH-OWIDTH];

always @(I, signBit, checkBits) begin
    if ((signBit == 1'b0) && (|checkBits == 1'b1)) begin
        O = {1'b0, {OWIDTH-1{1'b1}}};
    end
    else if ((signBit == 1'b1) && (&checkBits != 1'b1)) begin
        O = {1'b1, {OWIDTH-1{1'b0}}};
    end
    else begin
        O = I[OWIDTH-1:0];
    end
end
endmodule

// Saturating addition
module saturateAdd #(
    parameter   AWIDTH = 8,
    parameter   BWIDTH = 8,
    parameter SUMWIDTH = 8) (
    input  wire   [AWIDTH-1:0] A,
    input  wire   [BWIDTH-1:0] B,
    output wire [SUMWIDTH-1:0] SUM);

localparam FULLWIDTH = (AWIDTH > BWIDTH) ? AWIDTH+1 : BWIDTH+1;

wire [FULLWIDTH-1:-0] fullWidthA, fullWidthB, fullWidthSum;
assign fullWidthA = {{FULLWIDTH-AWIDTH{A[AWIDTH-1]}}, A};
assign fullWidthB = {{FULLWIDTH-BWIDTH{B[BWIDTH-1]}}, B};
assign fullWidthSum = fullWidthA + fullWidthB;
reduceWidth #(.IWIDTH(FULLWIDTH),.OWIDTH(SUMWIDTH))rw(.I(fullWidthSum),.O(SUM));
endmodule

// Saturating subtraction
module saturateSub #(
    parameter    AWIDTH = 8,
    parameter    BWIDTH = 8,
    parameter DIFFWIDTH = 8) (
    input  wire    [AWIDTH-1:0] A,
    input  wire    [BWIDTH-1:0] B,
    output wire [DIFFWIDTH-1:0] DIFF);

localparam FULLWIDTH = (AWIDTH > BWIDTH) ? AWIDTH+1 : BWIDTH+1;

wire [FULLWIDTH-1:-0] fullWidthA, fullWidthB, fullWidthDiff;
assign fullWidthA = {{FULLWIDTH-AWIDTH{A[AWIDTH-1]}}, A};
assign fullWidthB = {{FULLWIDTH-BWIDTH{B[BWIDTH-1]}}, B};
assign fullWidthDiff = fullWidthA - fullWidthB;
reduceWidth #(.IWIDTH(FULLWIDTH),.OWIDTH(DIFFWIDTH))rw(.I(fullWidthDiff),.O(DIFF));
endmodule
